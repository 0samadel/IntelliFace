# IntelliFace — Face Recognition Attendance System

**IntelliFace** is a full-stack, AI-powered attendance system using facial recognition. It provides a seamless experience for both employees and administrators across web and mobile platforms.

## Project Structure

```
IntelliFace/
├── intelliface_admin/         # Flutter Web Admin Dashboard
├── intelliface_api/           # Node.js + Express REST API with MongoDB
├── face-rec-service/          # Python Flask Face Recognition Service
└── intelliface_app/           # Flutter Mobile App for Employees
```

---

## Features

- Secure facial recognition login and attendance
- Real-time location tracking
- Admin dashboard with employee & department management
- Employee app for easy check-in/check-out
- Web admin panel for managing attendance, reports, and system settings
- Python microservice for high-accuracy face detection and verification

---

## Tech Stack

| Component              | Stack                                         |
|------------------------|-----------------------------------------------|
| Web Admin Dashboard    | Flutter (Web)                                 |
| Employee App           | Flutter (Android/iOS)                         |
| Backend API            | Node.js, Express, MongoDB Atlas, JWT          |
| Face Recognition       | Python, Flask, OpenCV, dlib, face_recognition |

---

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/0samadel/IntelliFace.git
cd IntelliFace
```

### 2. Setup & Run Components

#### Backend API (`intelliface_api`)
```bash
cd intelliface_api
npm install
# Create `.env` file with MongoDB Atlas URI, JWT secret, etc.
npm start
```

#### Face Recognition Service (`face-rec-service`)
```bash
cd face-rec-service
pip install -r requirements.txt
python app.py
```

#### Web Admin (`intelliface_admin`)
```bash
cd intelliface_admin
flutter pub get
flutter run -d chrome
```

#### Employee App (`intelliface_app`)
```bash
cd intelliface_app
flutter pub get
flutter run
```

---

## API Highlights

| Method | Endpoint                          | Description                  |
|--------|-----------------------------------|------------------------------|
| POST   | `/api/auth/login`                 | User login                   |
| POST   | `/api/faces/enroll/:userId`       | Enroll a user face           |
| POST   | `/api/faces/verify/:userId`       | Verify face scan             |
| GET    | `/api/attendance/`                | Fetch all attendance logs    |

---

## Deployment Suggestions

- API: [Render](https://render.com), Railway, or Heroku  
- Face Service: Docker on Render or EC2  
- Web Admin: Firebase Hosting or Vercel  
- Mobile App: Play Store & App Store (Flutter builds)

---

## Developed By

Osama Adel

---

## Supervisor

Prof. Dr. AHMED EL-HADAD

---

## License

MIT License © 2025 IntelliFace
