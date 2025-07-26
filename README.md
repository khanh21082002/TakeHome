# Math Solver System

## System Architecture

- **Backend:** Flask + Firebase
- **Frontend:** Flutter

## Core Features
- Accept math problems from students (image/file upload)
- OCR processing and mathematical solving
- Detailed step-by-step solutions
- (Optional) Solution history tracking

## Directory Structure

```
math-solver/
├── backend/                  # Flask server
│   ├── app.py               # Main Flask application
│   ├── firebase/            # Firebase integration
│   ├── services/            # Business logic
│   ├── models/              # Data models
│   └── config.py            # Configuration
├── frontend/                # Flutter application
│   ├── lib/
│   │   ├── screens/         # All screens
│   │   ├── widgets/         # Reusable widgets
│   │   ├── services/        # API services
│   │   ├── models/          # Data models
│   │   └── main.dart        # App entry point
│   ├── assets/              # Images, fonts
│   └── test/
```

## Quick Start Guide

### Backend
```bash
cd backend
pip install flask flask-restful pytesseract openai firebase-admin
python app.py
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

## Environment Configuration
Create `backend/.env` file with:
```
FIREBASE_PROJECT_ID=your_project_id

OPENAI_API_KEY=your_openai_key
GOOGLE_APPLICATION_CREDENTIALS=path/to/service_account.json

GEMINI_API_KEY=your_gemini_key
HUGGINGFACE_API_KEY=your_hf_key
```

## Backend Dependencies
```bash
cd backend
pip install -r requirements.txt
```

## Important Notes
- Install Tesseract OCR for local text recognition
- Configure Firebase credentials for authentication/history features
- API keys are required for AI-powered solutions
- Google Cloud credentials needed for Firebase services

## Additional Requirements 
- Python 3.8+ for backend
- Flutter SDK 3.0+ for mobile development 
- Firebase project with Firestore and Authentication enabled 
- Optional: GPU acceleration for better OCR performance