// ─────────────────────────────────────────────────────────────────────────────
// File    : lib/screens/todo_list_screen.dart
// Purpose : Implements the To-Do List feature screen.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math'; // For generating random IDs for dummy data

// TODO: IMPORT YOUR ACTUAL STYLES, SERVICES, AND MODELS
import 'package:intelliface/utils/app_styles.dart'; // Assuming this path
import 'package:intelliface/services/todo_service.dart'; // <<<< YOU NEED TO CREATE/HAVE THIS
import 'package:intelliface/models/todo_item_model.dart'; // <<<< YOU NEED TO CREATE/HAVE THIS

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _currentDisplayedMonth;

  final List<TodoItem> _allTodos = [];
  List<TodoItem> _filteredTodos = [];

  TodoItem? _lastDeletedTodo;
  int? _lastDeletedTodoIndex;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _newTaskDueDate;

  late AnimationController _dialogAnimationController;
  late Animation<double> _dialogScaleAnimation;
  late Animation<double> _dialogOpacityAnimation;

  bool _isDialogForEditing = false;
  TodoItem? _editingTodo;
  bool _isLoadingTasks = true;
  bool _isDialogButtonLoading = false;
  String? _errorMessage;

  final TodoService _todoService = TodoService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentDisplayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    _fetchTodosForSelectedDate();

    _dialogAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dialogScaleAnimation = CurvedAnimation(
      parent: _dialogAnimationController,
      curve: Curves.easeOutBack,
    );
    _dialogOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogAnimationController,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dialogAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTodosForSelectedDate() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTasks = true;
      _errorMessage = null;
    });
    try {
      print("FLUTTER TodoListScreen: Fetching todos for date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}");
      final Map<String, dynamic> response = await _todoService.getUserTodos(
        date: _selectedDate,
      );

      if (response['success'] == true && response['data'] is List) {
        final List<dynamic> todosData = response['data'];
        if (!mounted) return;
        setState(() {
          _allTodos.clear();
          _allTodos.addAll(todosData.map((data) => TodoItem.fromJson(data)).toList());
          _filterAndSortLocalTodos();
        });
      } else {
        throw Exception(response['message'] ?? "Failed to fetch todos: Unexpected response structure.");
      }

    } catch (e) {
      print("FLUTTER TodoListScreen: Error fetching todos: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoadingTasks = false);
    }
  }

  void _filterAndSortLocalTodos() {
    setState(() {
      _filteredTodos = List.from(_allTodos);
      _filteredTodos.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (date.month != _currentDisplayedMonth.month || date.year != _currentDisplayedMonth.year) {
        _currentDisplayedMonth = DateTime(date.year, date.month, 1);
      }
    });
    _fetchTodosForSelectedDate();
  }

  void _changeMonth(int increment) {
    setState(() {
      _currentDisplayedMonth = DateTime(
        _currentDisplayedMonth.year,
        _currentDisplayedMonth.month + increment,
        1,
      );
      int daysInNewMonth = DateUtils.getDaysInMonth(_currentDisplayedMonth.year, _currentDisplayedMonth.month);
      _selectedDate = DateTime(
          _currentDisplayedMonth.year,
          _currentDisplayedMonth.month,
          _selectedDate.day > daysInNewMonth ? daysInNewMonth : _selectedDate.day
      );
    });
    _fetchTodosForSelectedDate();
  }

  Future<void> _toggleTodoCompletion(TodoItem todo) async {
    if (!mounted) return;
    final originalStatus = todo.isCompleted;
    setState(() {
      todo.isCompleted = !todo.isCompleted;
      _filterAndSortLocalTodos();
    });

    try {
      await _todoService.updateTodo(todo.id, {'isCompleted': todo.isCompleted});
      print("FLUTTER TodoListScreen: Toggled completion for '${todo.title}' successfully via API.");
    } catch (e) {
      print("FLUTTER TodoListScreen: Error toggling completion for '${todo.title}': $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update task: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: AppColors.error)
        );
        setState(() {
          todo.isCompleted = originalStatus;
          _filterAndSortLocalTodos();
        });
      }
    }
  }

  Future<void> _addOrUpdateTodoItem({TodoItem? existingTodoToUpdate}) async {
    if (!_formKey.currentState!.validate()) return;

    final String title = _titleController.text.trim();
    final String? description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    setState(() => _isDialogButtonLoading = true);

    try {
      if (existingTodoToUpdate != null) {
        print("FLUTTER TodoListScreen: Attempting to UPDATE todo: ${existingTodoToUpdate.id}");
        final Map<String, dynamic> updateData = {
          'title': title,
          if(description != null) 'description': description,
          'dueDate': _newTaskDueDate?.toIso8601String(),
          'isCompleted': existingTodoToUpdate.isCompleted,
        };

        final updatedTodoFromApi = await _todoService.updateTodo(existingTodoToUpdate.id, updateData);
        print("FLUTTER TodoListScreen: API call to updateTodo SUCCEEDED. Response: $updatedTodoFromApi");

        setState(() {
          final index = _allTodos.indexWhere((t) => t.id == updatedTodoFromApi.id);
          if (index != -1) {
            _allTodos[index] = updatedTodoFromApi;
          } else { // Should not happen if editing, but as a fallback
            _allTodos.add(updatedTodoFromApi);
          }
        });
        _filterAndSortLocalTodos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("To-Do updated successfully!"), backgroundColor: AppColors.success)
          );
        }

      } else {
        print("FLUTTER TodoListScreen: Attempting to CREATE todo with Title: '$title', Desc: '$description', DueDate: $_newTaskDueDate");
        final TodoItem createdTodoFromApi = await _todoService.createTodo(
          title: title,
          description: description,
          dueDate: _newTaskDueDate,
        );
        print("FLUTTER TodoListScreen: API call to createTodo SUCCEEDED. Response: $createdTodoFromApi");

        setState(() {
          _allTodos.add(createdTodoFromApi);
        });
        _filterAndSortLocalTodos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("To-Do added successfully!"), backgroundColor: AppColors.success)
          );
        }
      }
      if (mounted) {
        _dialogAnimationController.reverse();
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("FLUTTER TodoListScreen: Error in _addOrUpdateTodoItem: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Operation failed: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: AppColors.error)
        );
      }
    } finally {
      if (mounted) setState(() => _isDialogButtonLoading = false);
    }
  }

  Future<void> _deleteTodoItem(TodoItem todo) async {
    if(!mounted) return;
    final originalTodos = List<TodoItem>.from(_allTodos);
    // final originalIndex = _allTodos.indexOf(todo); // Not strictly needed for this undo version

    setState(() {
      _allTodos.removeWhere((item) => item.id == todo.id);
      _filterAndSortLocalTodos();
    });

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("'${todo.title}' deleted."),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              _allTodos.clear();
              _allTodos.addAll(originalTodos);
              _filterAndSortLocalTodos();
            });
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );

    try {
      await _todoService.deleteTodo(todo.id);
      print("FLUTTER TodoListScreen: Deleted '${todo.title}' successfully via API.");
    } catch (e) {
      print("FLUTTER TodoListScreen: Error deleting '${todo.title}' via API: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete task on server: ${e.toString().replaceFirst("Exception: ", "")}"), backgroundColor: AppColors.error)
        );
        setState(() {
          _allTodos.clear();
          _allTodos.addAll(originalTodos);
          _filterAndSortLocalTodos();
        });
      }
    }
  }

  Future<void> _showAddTaskDialog({TodoItem? existingTodo}) async {
    _isDialogForEditing = existingTodo != null;
    _editingTodo = existingTodo;

    if (_isDialogForEditing && _editingTodo != null) {
      _titleController.text = _editingTodo!.title;
      _descriptionController.text = _editingTodo!.description ?? "";
      _newTaskDueDate = _editingTodo!.dueDate;
    } else {
      _titleController.clear();
      _descriptionController.clear();
      _newTaskDueDate = _selectedDate;
    }
    _formKey.currentState?.reset();
    _dialogAnimationController.forward();

    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Center(
          child: FadeTransition(
            opacity: _dialogOpacityAnimation,
            child: ScaleTransition(
              scale: _dialogScaleAnimation,
              child: Material(
                type: MaterialType.transparency,
                child: Hero(
                  tag: 'add_todo_dialog',
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      final theme = Theme.of(context); // 'theme' is available here
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        constraints: const BoxConstraints(maxWidth: 380),
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _isDialogForEditing ? 'Edit To-Do' : 'Add New To-Do',
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  labelText: "Title",
                                  hintText: "e.g., Finish project report",
                                  // Uses global theme from main.dart
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Title cannot be empty.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  labelText: "Description (Optional)",
                                  hintText: "e.g., Include all sections and charts",
                                  // Uses global theme from main.dart
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                maxLines: 3,
                                minLines: 1,
                              ),
                              const SizedBox(height: 20),
                              // ***** CORRECTED LINE HERE *****
                              Text(
                                "Due Date",
                                style: theme.textTheme.titleSmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500) ??
                                    AppTextStyles.poppins(12, AppColors.textSecondary, FontWeight.w500), // Fallback
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: _newTaskDueDate ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime(DateTime.now().year + 5),
                                    builder: (context, child) {
                                      return Theme(
                                        data: theme.copyWith(
                                          colorScheme: theme.colorScheme.copyWith(
                                            primary: AppColors.primaryBlue,
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null && picked != _newTaskDueDate) {
                                    setDialogState(() {
                                      _newTaskDueDate = picked;
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: AppColors.pageBackground, // Or theme.inputDecorationTheme.fillColor
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border)
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _newTaskDueDate == null
                                            ? 'Select a date'
                                            : DateFormat.yMMMd().format(_newTaskDueDate!),
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                            color: _newTaskDueDate == null ? AppColors.textSecondary : AppColors.textPrimary
                                        ),
                                      ),
                                      Icon(Icons.calendar_month_outlined, color: AppColors.textSecondary),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  TextButton(
                                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                    onPressed: () {
                                      _dialogAnimationController.reverse();
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: _isDialogButtonLoading
                                        ? Container(width: 18, height: 18, margin: const EdgeInsets.only(right: 5), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white,))
                                        : Icon(_isDialogForEditing ? Icons.save_outlined : Icons.add_task_rounded, size: 18),
                                    label: Text(_isDialogForEditing ? 'Save Changes' : 'Add Task'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _isDialogButtonLoading ? null : () => _addOrUpdateTodoItem(existingTodoToUpdate: _editingTodo),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (_dialogAnimationController.status == AnimationStatus.forward ||
          _dialogAnimationController.status == AnimationStatus.completed) {
        _dialogAnimationController.reverse();
      }
      _isDialogForEditing = false;
      _editingTodo = null;
    });
  }

  List<DateTime> _getDaysForWeekDisplay() {
    DateTime firstDayOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday % 7));
    if (MaterialLocalizations.of(context).firstDayOfWeekIndex == 1) {
      firstDayOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    }
    return List.generate(7, (index) => firstDayOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppColors.primaryBlue;
    final lightTextColor = Colors.white.withOpacity(0.85);
    List<DateTime> weekDaysToDisplay = _getDaysForWeekDisplay();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 15,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/homescreen'),
                      ),
                      Text("My To-Do List", style: AppTextStyles.poppins(20, Colors.white, FontWeight.bold)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: Icon(Icons.chevron_left_rounded, color: lightTextColor, size: 30), onPressed: () => _changeMonth(-1)),
                      Text(DateFormat('MMMM, yyyy').format(_currentDisplayedMonth), style: AppTextStyles.poppins(18, Colors.white, FontWeight.w600)),
                      IconButton(icon: Icon(Icons.chevron_right_rounded, color: lightTextColor, size: 30), onPressed: () => _changeMonth(1)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekDaysToDisplay.map((day) {
                      bool isSelected = DateUtils.isSameDay(day, _selectedDate);
                      bool isCurrentMonthDay = day.month == _currentDisplayedMonth.month;
                      return DayDateWidget(date: day, isSelected: isSelected, isCurrentMonthDay: isCurrentMonthDay, onTap: () => _onDateSelected(day), selectedColor: Colors.white, accentColor: accentColor);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
          Expanded(
            child: _isLoadingTasks
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _errorMessage != null
                ? Center( /* Error UI from previous response */
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 50),
                    const SizedBox(height: 16),
                    Text("Error loading tasks", style: AppTextStyles.cardTitle),
                    const SizedBox(height: 8),
                    Text(_errorMessage!, style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                        onPressed: _fetchTodosForSelectedDate,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text("Retry"))
                  ],
                ),
              ),
            )
                : _filteredTodos.isEmpty
                ? Center( /* Empty state UI from previous response */
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_box_outline_blank_rounded, size: 70, color: Colors.grey[350]),
                    const SizedBox(height: 16),
                    Text('No to-dos for ${DateFormat.yMMMd().format(_selectedDate)}', style: AppTextStyles.bodyText1.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    Text('Tap on a date or use the "+" button to add a task.', textAlign: TextAlign.center, style: AppTextStyles.screenSubtitle),
                  ],
                ))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return Dismissible(
                  key: ValueKey<String>(todo.id),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (DismissDirection direction) async {
                    if (direction == DismissDirection.endToStart) {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Delete"),
                            content: Text("Are you sure you want to delete '${todo.title}'?"),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("CANCEL")),
                              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("DELETE", style: TextStyle(color: AppColors.error))),
                            ],
                          );
                        },
                      ) ?? false;
                    } else if (direction == DismissDirection.startToEnd) {
                      _showAddTaskDialog(existingTodo: todo);
                      return false;
                    }
                    return false;
                  },
                  onDismissed: (direction) {
                    if (direction == DismissDirection.endToStart) {
                      _deleteTodoItem(todo);
                    }
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerLeft,
                    child: const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
                      SizedBox(width: 10),
                      Text("EDIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(width: 10),
                      Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 26),
                    ]),
                  ),
                  child: TodoCard(
                    todo: todo,
                    accentColor: accentColor,
                    onToggle: () => _toggleTodoCompletion(todo),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(),
        backgroundColor: accentColor,
        heroTag: 'add_todo_dialog',
        tooltip: 'Add To-Do',
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}

// --- DayDateWidget ---
class DayDateWidget extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isCurrentMonthDay;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color accentColor;

  const DayDateWidget({
    super.key,
    required this.date,
    required this.isSelected,
    required this.isCurrentMonthDay,
    required this.onTap,
    required this.selectedColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dayNameStyle = AppTextStyles.poppins(
        12,
        isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : (isCurrentMonthDay ? Colors.white.withOpacity(0.95) : Colors.white.withOpacity(0.5)),
        FontWeight.w500
    );
    final dateNumStyle = AppTextStyles.poppins(
        15,
        isSelected ? accentColor : (isCurrentMonthDay ? Colors.white : Colors.white.withOpacity(0.6)),
        isSelected ? FontWeight.bold : FontWeight.w600
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width / 8.2,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('E').format(date).substring(0, 2).toUpperCase(), style: dayNameStyle),
            const SizedBox(height: 6),
            Text(DateFormat('d').format(date), style: dateNumStyle),
          ],
        ),
      ),
    );
  }
}

// --- TodoCard ---
class TodoCard extends StatelessWidget {
  final TodoItem todo;
  final Color accentColor;
  final VoidCallback onToggle;

  const TodoCard({
    super.key,
    required this.todo,
    required this.accentColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          splashColor: accentColor.withOpacity(0.1),
          highlightColor: accentColor.withOpacity(0.05),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 7,
                  decoration: BoxDecoration(
                    color: todo.isCompleted ? Colors.grey.shade400 : accentColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 14, bottom: 14, right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          todo.title,
                          style: AppTextStyles.poppins(
                            15.5,
                            todo.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                            FontWeight.w600,
                          ).copyWith(
                            decoration: todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                            decorationColor: AppColors.textSecondary.withOpacity(0.7),
                            decorationThickness: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (todo.description != null && todo.description!.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            todo.description!,
                            style: AppTextStyles.poppins(
                              13.5,
                              todo.isCompleted ? AppColors.textSecondary.withOpacity(0.8) : AppColors.textSecondary,
                              FontWeight.normal,
                            ).copyWith(
                              height: 1.4,
                              decoration: todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                              decorationColor: AppColors.textSecondary.withOpacity(0.6),
                              decorationThickness: 1.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    unselectedWidgetColor: Colors.grey.shade400,
                  ),
                  child: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (bool? value) {
                      onToggle();
                    },
                    activeColor: accentColor,
                    checkColor: Colors.white,
                    side: BorderSide(
                        color: todo.isCompleted ? accentColor.withOpacity(0.7) : Colors.grey.shade400,
                        width: 2.0
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────