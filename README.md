# Online Attendance System

A comprehensive Flutter-based attendance management system with ASP.NET Core 9 WebAPI backend, designed for corporate offices providing remote office support. The system allows employees to mark attendance from home using GPS location tracking.

## Features

### Frontend (Flutter)
- ✅ **Cross-platform support** (Web, Mobile, Desktop)
- ✅ **GPS-based location tracking** for check-in/check-out
- ✅ **JWT authentication** with secure login/logout
- ✅ **Real-time attendance tracking** with local notifications
- ✅ **Attendance history** with filtering and search
- ✅ **Monthly statistics** and analytics
- ✅ **Profile management** with image upload
- ✅ **Responsive Material Design 3 UI**
- ✅ **Admin dashboard** capabilities

### Backend (ASP.NET Core 9)
- ✅ **RESTful API** with comprehensive endpoints
- ✅ **JWT Authentication** with secure token management
- ✅ **Entity Framework Core** with In-Memory database
- ✅ **CORS configuration** for Flutter web app
- ✅ **Swagger documentation** for API testing
- ✅ **BCrypt password hashing** for security
- ✅ **Seeded demo data** for testing

## Architecture

```
attendance_system/
├── frontend/ (Flutter)
│   ├── lib/
│   │   ├── models/         # Data models (User, AttendanceRecord)
│   │   ├── providers/      # State management (Provider pattern)
│   │   ├── services/       # API, Location, Notification services
│   │   ├── screens/        # UI screens
│   │   ├── widgets/        # Reusable UI components
│   │   └── utils/          # Utilities and constants
│   └── web/               # Web-specific configurations
└── backend/ (ASP.NET Core 9)
    └── AttendanceSystemAPI/
        ├── Controllers/    # API endpoints
        ├── Models/        # Database entities
        ├── Services/      # Business logic
        ├── Data/          # Database context
        └── DTOs/          # Data transfer objects
```

## Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- .NET 8 SDK or later
- VS Code (recommended)
- Git

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend/AttendanceSystemAPI
   ```

2. **Restore packages:**
   ```bash
   dotnet restore
   ```

3. **Run the backend:**
   ```bash
   dotnet run
   ```

   The API will be available at: `http://localhost:5070`
   Swagger UI: `http://localhost:5070/swagger`

### Frontend Setup

1. **Navigate to project root:**
   ```bash
   cd /path/to/attendance_system
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Flutter app:**
   ```bash
   # For web (recommended for development)
   flutter run -d chrome
   
   # For mobile (requires emulator/device)
   flutter run
   ```

   The web app will be available at: `http://localhost:3000`

## Demo Credentials

Use these credentials to test the system:

### Admin Account
- **Email:** `admin@company.com`
- **Password:** `admin123`
- **Features:** Full admin access, can view all employee data

### Employee Account
- **Email:** `employee@company.com`
- **Password:** `emp123`
- **Features:** Standard employee access, personal attendance tracking

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout

### Attendance Management
- `POST /api/attendance/checkin` - Check-in with GPS location
- `POST /api/attendance/checkout` - Check-out with GPS location
- `GET /api/attendance/today` - Get today's attendance
- `GET /api/attendance/history` - Get attendance history
- `GET /api/attendance/monthly-stats` - Get monthly statistics

### User Management
- `GET /api/users/profile` - Get user profile
- `PUT /api/users/profile` - Update user profile
- `GET /api/users` - Get all users (admin only)

For complete API documentation, see [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## Development Features

### VS Code Integration
- **Tasks configured** for running both frontend and backend
- **Launch configurations** for debugging
- **Extension recommendations** for Flutter and C# development

### Hot Reload
- Flutter supports hot reload for rapid development
- Backend auto-reloads on file changes in development mode

### Testing
- **Mock data available** for testing without backend
- **Seeded database** with sample users and attendance records
- **Swagger UI** for API testing and documentation

## Demo Credentials

Use these credentials to test the system:

### Admin Account
- **Email:** `admin@company.com`
- **Password:** `admin123`
- **Features:** Full admin access, can view all employee data

### Employee Account
- **Email:** `employee@company.com`
- **Password:** `emp123`
- **Features:** Standard employee access, personal attendance tracking

## Technology Stack

### Frontend
- **Flutter 3.x** - Cross-platform UI framework
- **Provider** - State management
- **HTTP** - API communication
- **Geolocator** - GPS location services
- **SharedPreferences** - Local storage
- **Flutter Local Notifications** - Push notifications

### Backend
- **ASP.NET Core 9** - Web API framework
- **Entity Framework Core** - ORM with In-Memory database
- **JWT Bearer Authentication** - Token-based auth
- **BCrypt.Net** - Password hashing
- **Swagger/OpenAPI** - API documentation

## Security Features

- **JWT Authentication:** Secure token-based authentication
- **Password Hashing:** BCrypt for secure password storage
- **CORS Configuration:** Proper cross-origin resource sharing
- **Input Validation:** Comprehensive data validation
- **Location Verification:** GPS coordinates for attendance verification

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Last Updated:** December 2024
**Version:** 1.0.0
