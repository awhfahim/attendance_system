# Attendance System API Documentation

## Overview
This document outlines the REST API endpoints required for the Flutter Attendance System. The backend should be implemented using ASP.NET Core 9 WebAPI with in-memory database.

## Base URL
```
http://localhost:5000/api
```

## Authentication
The API uses JWT Bearer token authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## Database Models

### User Model
```csharp
public class User
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Email { get; set; }
    public string Department { get; set; }
    public string Position { get; set; }
    public string Phone { get; set; }
    public string? ProfileImage { get; set; }
    public bool IsAdmin { get; set; }
    public string PasswordHash { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

### AttendanceRecord Model
```csharp
public class AttendanceRecord
{
    public string Id { get; set; }
    public string UserId { get; set; }
    public DateTime CheckInTime { get; set; }
    public DateTime? CheckOutTime { get; set; }
    public string? CheckInLocation { get; set; }
    public string? CheckOutLocation { get; set; }
    public double? CheckInLatitude { get; set; }
    public double? CheckInLongitude { get; set; }
    public double? CheckOutLatitude { get; set; }
    public double? CheckOutLongitude { get; set; }
    public string Status { get; set; } // "present", "late", "absent", "on_leave"
    public string? Notes { get; set; }
    public int? WorkDuration { get; set; } // in minutes
    public bool IsRemote { get; set; }
    public User User { get; set; } // Navigation property
}
```

## API Endpoints

### 1. Authentication

#### POST /api/auth/login
Login user and get JWT token.

**Request Body:**
```json
{
  "email": "user@company.com",
  "password": "password123"
}
```

**Response (Success):**
```json
{
  "success": true,
  "user": {
    "id": "guid-string",
    "name": "John Doe",
    "email": "user@company.com",
    "department": "IT",
    "position": "Software Developer",
    "phone": "+1234567890",
    "profile_image": null,
    "is_admin": false,
    "created_at": "2025-05-29T10:00:00Z"
  },
  "token": "jwt-token-string"
}
```

**Response (Error):**
```json
{
  "success": false,
  "message": "Invalid email or password"
}
```

### 2. Attendance Management

#### GET /api/attendance/today/{userId}
Get today's attendance record for a user.

**Headers:** `Authorization: Bearer <token>`

**Response (Success):**
```json
{
  "success": true,
  "attendance": {
    "id": "guid-string",
    "user_id": "guid-string",
    "check_in_time": "2025-05-29T09:15:00Z",
    "check_out_time": "2025-05-29T17:30:00Z",
    "check_in_location": "Home Office",
    "check_out_location": "Home Office",
    "check_in_latitude": 40.7128,
    "check_in_longitude": -74.0060,
    "check_out_latitude": 40.7128,
    "check_out_longitude": -74.0060,
    "status": "present",
    "notes": "Working from home",
    "work_duration": 480,
    "is_remote": true
  }
}
```

**Response (No attendance today):**
```json
{
  "success": true,
  "attendance": null
}
```

#### GET /api/attendance/history/{userId}
Get attendance history for a user with pagination.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Records per page (default: 20)

**Response:**
```json
{
  "success": true,
  "records": [
    {
      "id": "guid-string",
      "user_id": "guid-string",
      "check_in_time": "2025-05-28T09:00:00Z",
      "check_out_time": "2025-05-28T17:00:00Z",
      "check_in_location": "Office",
      "check_out_location": "Office",
      "check_in_latitude": 40.7589,
      "check_in_longitude": -73.9851,
      "check_out_latitude": 40.7589,
      "check_out_longitude": -73.9851,
      "status": "present",
      "notes": "In office",
      "work_duration": 480,
      "is_remote": false
    }
  ],
  "total": 50,
  "page": 1,
  "limit": 20
}
```

#### POST /api/attendance/checkin
Check in user attendance.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "location": "Home Office",
  "is_remote": true,
  "notes": "Working from home today"
}
```

**Response:**
```json
{
  "success": true,
  "attendance": {
    "id": "guid-string",
    "user_id": "guid-string",
    "check_in_time": "2025-05-29T09:15:00Z",
    "check_out_time": null,
    "check_in_location": "Home Office",
    "check_out_location": null,
    "check_in_latitude": 40.7128,
    "check_in_longitude": -74.0060,
    "check_out_latitude": null,
    "check_out_longitude": null,
    "status": "present",
    "notes": "Working from home today",
    "work_duration": null,
    "is_remote": true
  }
}
```

#### POST /api/attendance/checkout
Check out user attendance.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "attendance_id": "guid-string",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "location": "Home Office",
  "notes": "Finished work for today"
}
```

**Response:**
```json
{
  "success": true,
  "attendance": {
    "id": "guid-string",
    "user_id": "guid-string",
    "check_in_time": "2025-05-29T09:15:00Z",
    "check_out_time": "2025-05-29T17:30:00Z",
    "check_in_location": "Home Office",
    "check_out_location": "Home Office",
    "check_in_latitude": 40.7128,
    "check_in_longitude": -74.0060,
    "check_out_latitude": 40.7128,
    "check_out_longitude": -74.0060,
    "status": "present",
    "notes": "Finished work for today",
    "work_duration": 495,
    "is_remote": true
  }
}
```

#### GET /api/attendance/summary/{userId}
Get attendance summary for a date range.

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `start`: Start date (ISO 8601 format)
- `end`: End date (ISO 8601 format)

**Response:**
```json
{
  "success": true,
  "summary": {
    "total_days": 22,
    "present_days": 20,
    "absent_days": 2,
    "late_days": 3,
    "total_hours": 176.5,
    "average_hours_per_day": 8.8,
    "remote_days": 15,
    "office_days": 5
  }
}
```

### 3. User Management

#### PUT /api/user/profile/{userId}
Update user profile.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "name": "John Doe Updated",
  "phone": "+1234567890",
  "profile_image": "base64-encoded-image-or-url"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully"
}
```

## Error Responses

All endpoints may return these error responses:

**401 Unauthorized:**
```json
{
  "success": false,
  "message": "Unauthorized access"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "message": "Internal server error"
}
```

## Sample Data for Testing

### Test Users
```json
[
  {
    "id": "1",
    "name": "John Doe",
    "email": "admin@company.com",
    "password": "admin123",
    "department": "IT",
    "position": "Software Developer",
    "phone": "+1234567890",
    "is_admin": true
  },
  {
    "id": "2",
    "name": "Jane Smith",
    "email": "employee@company.com",
    "password": "emp123",
    "department": "Marketing",
    "position": "Marketing Executive",
    "phone": "+1234567891",
    "is_admin": false
  }
]
```

## Business Rules

1. **Check-in Rules:**
   - Users can only check in once per day
   - Check-in time determines if user is late (after 9:00 AM)
   - Location and GPS coordinates are required

2. **Check-out Rules:**
   - Users can only check out if they have checked in
   - Work duration is automatically calculated
   - Users can check out multiple times (updates the record)

3. **Status Calculation:**
   - "present": Checked in on time
   - "late": Checked in after 9:00 AM
   - "absent": No check-in record for the day

4. **Security:**
   - JWT tokens should expire after 24 hours
   - API endpoints require authentication except login
   - Users can only access their own data (except admins)

## Getting Started with ASP.NET Core 9

1. Create a new ASP.NET Core Web API project
2. Install required NuGet packages:
   - Microsoft.EntityFrameworkCore.InMemory
   - Microsoft.AspNetCore.Authentication.JwtBearer
   - System.IdentityModel.Tokens.Jwt
3. Configure in-memory database and JWT authentication
4. Implement the models and controllers as specified
5. Add CORS configuration for Flutter web app
6. Seed initial test data

## Notes

- The Flutter app is currently using mock data (`_useMockData = true`)
- Change `_useMockData` to `false` in the Flutter app once backend is ready
- Update `baseUrl` in the Flutter app to point to your backend
- Ensure CORS is properly configured for the Flutter web app origin
