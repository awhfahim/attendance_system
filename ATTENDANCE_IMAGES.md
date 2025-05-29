# Attendance Image Display Feature

## Overview
The attendance system now supports capturing and displaying images for check-in and check-out events. Images are uploaded to S3 and displayed in the attendance history and today's attendance card.

## Implementation Details

### Backend
- **Model**: `AttendanceRecord.cs` includes `CheckInImagePath` and `CheckOutImagePath` fields
- **DTOs**: `AttendanceDto` includes image path fields for API responses
- **Controller**: Endpoints accept `IFormFile` parameters for image uploads using multipart/form-data
- **Storage**: Images are uploaded to S3 bucket (implementation pending in `UploadImageToS3()` method)

### Frontend

#### Image Capture
- **Camera Service**: Handles camera permissions and image capture
- **Permission Handling**: Different handling for web vs mobile platforms
- **Image Quality**: Images are compressed to 70% quality and resized to max 1024x1024px
- **User Flow**: Optional image capture during check-in/check-out with dialog confirmation

#### Image Display

##### Components
1. **AttendanceImageWidget**: Reusable widget for displaying attendance images
2. **AttendanceImageThumbnail**: Individual image thumbnail with overlay indicators
3. **FullScreenImageDialog**: Full-screen image viewer with zoom and pan capabilities

##### Features
- **Thumbnail View**: 80px height thumbnails with loading states and error handling
- **Full-Screen View**: Interactive viewer with pinch-to-zoom and pan functionality
- **Visual Indicators**: Color-coded overlays for check-in (green) vs check-out (red)
- **Error Handling**: Graceful fallback for failed image loads
- **Loading States**: Progress indicators during image loading

##### Usage Locations
1. **Today's Attendance Card**: Shows images for current day's attendance
2. **Attendance History**: Shows images for all historical attendance records

#### User Experience
- **Optional Capture**: Users can skip image capture if desired
- **Intuitive Interface**: Clear visual indicators and easy-to-understand controls
- **Responsive Design**: Works on both mobile and web platforms
- **Accessibility**: Proper contrast and touch targets

## Technical Specifications

### Image Format
- **Format**: JPEG
- **Quality**: 70% compression
- **Max Dimensions**: 1024x1024 pixels
- **Upload Method**: Multipart/form-data

### Network Handling
- **Loading States**: Progress indicators during upload/download
- **Error Recovery**: Retry mechanisms and error messages
- **Caching**: Browser-level caching for loaded images

### Security
- **Permissions**: Camera access requires user permission
- **Storage**: Images stored securely in S3 with proper access controls
- **Privacy**: Images only accessible to authorized users

## API Endpoints

### Check-In with Image
```
POST /api/attendance/checkin
Content-Type: multipart/form-data

- latitude: double
- longitude: double
- notes: string (optional)
- checkInImage: file (optional)
```

### Check-Out with Image
```
POST /api/attendance/checkout
Content-Type: multipart/form-data

- latitude: double
- longitude: double
- notes: string (optional)
- checkOutImage: file (optional)
```

### Response Format
```json
{
  "success": true,
  "data": {
    "id": "string",
    "checkInImagePath": "https://s3-bucket-url/image.jpg",
    "checkOutImagePath": "https://s3-bucket-url/image.jpg",
    // ... other attendance fields
  }
}
```

## Future Enhancements
- **Image Compression**: Client-side compression before upload
- **Multiple Images**: Support for multiple images per check-in/out
- **Image Validation**: Server-side image format and size validation
- **Offline Support**: Cache images for offline viewing
- **Image Editing**: Basic editing capabilities (crop, rotate)
