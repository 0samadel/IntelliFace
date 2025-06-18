// ─────────────────────────────────────────────────────────────────────────────
// File    : app/lib/main.dart
// Purpose : The main entry point for the IntelliFace employee application.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Screen Imports
import 'package:intelliface/screens/login_screen.dart';
import 'package:intelliface/screens/home_screen.dart';
import 'package:intelliface/screens/profile_screen.dart';
import 'package:intelliface/screens/todo_list_screen.dart';
import 'package:intelliface/screens/attendance_screen.dart';
import 'package:intelliface/screens/face_scan_screen.dart';

// Your App-wide Styles
import 'package:intelliface/utils/app_styles.dart';

/// The main entry point of the application.
void main() {
  // Ensures that the Flutter binding is initialized before any Flutter-specific code is run.
  // This is required for platform channel communication, like setting preferred orientations.
  WidgetsFlutterBinding.ensureInitialized();

  // Restricts the application to portrait mode only, preventing landscape orientation.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Runs the root widget of the application.
  runApp(const IntelliFaceApp());
}

/// The root widget of the IntelliFace application.
/// It sets up the [MaterialApp], which configures the app's title, theme,
/// and navigation routes.
class IntelliFaceApp extends StatelessWidget {
  const IntelliFaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IntelliFace Employee',

      // Defines the global visual theme for the entire application.
      theme: ThemeData(
        primaryColor: AppColors.primaryBlue,
        scaffoldBackgroundColor: AppColors.pageBackground,
        fontFamily: 'Poppins', // Default font for the app.
        textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.primaryBlue),

        // Theme for all AppBars.
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: AppTextStyles.poppins(18, Colors.white, FontWeight.w600),
          systemOverlayStyle: SystemUiOverlayStyle.light, // Light icons on status bar.
        ),

        // Theme for all ElevatedButtons.
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: AppTextStyles.buttonText
            )
        ),

        // Theme for the bottom navigation bar.
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textSecondary.withOpacity(0.8),
          selectedLabelStyle: AppTextStyles.poppins(10, AppColors.primaryBlue, FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.poppins(10, AppColors.textSecondary.withOpacity(0.8), FontWeight.w500),
          type: BottomNavigationBarType.fixed, // Ensures all labels are always visible.
          elevation: 8.0,
        ),

        // Theme for all input fields (TextFormField).
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primaryBlue, width: 1.5)),
          labelStyle: AppTextStyles.profileEditFieldLabel,
        ),
      ),

      // The initial route to display when the app starts.
      initialRoute: '/loginscreen',

      // Defines the named routes for navigation within the app.
      routes: {
        '/loginscreen': (context) => const LoginScreen(),
        // The '/homescreen' route points to the main navigation container.
        '/homescreen': (context) => const MainNavigationScreen(),
        '/profilescreen': (context) => const ProfileScreen(),
        '/schedulescreen': (context) => const TodoListScreen(), // Alias for To-Do list
        '/attendancescreen': (context) => const AttendanceScreen(),
        '/facescan': (context) => const FaceScanScreen(),
      },
    );
  }
}

/// A stateful widget that acts as the main container for the app's core screens,
/// managed by a [BottomNavigationBar].
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

/// The state for [MainNavigationScreen].
class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // The index of the currently active screen in the bottom navigation bar.
  int _currentIndex = 0;

  // A list of the widgets (screens) to be displayed.
  // The order must match the order of the BottomNavigationBarItems.
  final List<Widget> _screens = [
    const HomeScreen(),
    const TodoListScreen(),
    const ProfileScreen(),
  ];

  /// Callback function that is called when a navigation bar item is tapped.
  /// It updates the state with the new index.
  void _onTabTapped(int index) {
    if(mounted){
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body uses an IndexedStack to display the currently selected screen.
      // IndexedStack keeps all child widgets in the tree, preserving their state
      // even when they are not visible. This is efficient for a small number of screens.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // The bottom navigation bar widget.
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'To-Do'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────