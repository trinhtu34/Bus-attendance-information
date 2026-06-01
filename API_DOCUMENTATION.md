# API Documentation - Bus Attendance & Meeting Booking

> Tài liệu API dành cho team Mobile  
> Base URL: `https://{domain}/api/services/app/`  
> Framework: ASP.NET Boilerplate (ABP)  
> Tất cả endpoint sử dụng method **POST**

---

## Mục lục

1. [Xác thực (Authentication)](#1-xác-thực-authentication)
2. [Headers chung](#2-headers-chung)
3. [Định dạng lỗi](#3-định-dạng-lỗi)
4. [Enum Values](#4-enum-values)
5. [Module BusAtt - Chấm công xe bus](#5-module-busatt---chấm-công-xe-bus)
6. [Module MeetingBooking - Đặt lịch họp](#6-module-meetingbooking---đặt-lịch-họp)

---

## 1. Xác thực (Authentication)

### Đăng nhập lấy Token

```
POST /api/TokenAuth/Authenticate
```

**Mô tả:** Đăng nhập và lấy access token để gọi các API khác.

**Request Body:**
```json
{
  "userNameOrEmailAddress": "string",
  "password": "string",
  "tenancyName": "string (optional - tên tenant)"
}
```

**Response Body:**
```json
{
  "result": {
    "accessToken": "string (JWT token)",
    "encryptedAccessToken": "string",
    "expireInSeconds": 86400,
    "userId": 1
  },
  "success": true,
  "error": null
}
```

---

## 2. Headers chung

| Header          | Giá trị                | Mô tả                                 |
| -----------------| ------------------------| ---------------------------------------|
| `Authorization` | `Bearer {accessToken}` | Token lấy từ API Authenticate         |
| `Content-Type`  | `application/json`     | Định dạng request body                |
| `Abp.TenantId`  | `{tenantId}` (int)     | ID tenant (bắt buộc cho multi-tenant) |

---

## 3. Định dạng lỗi

Khi có lỗi, API trả về format ABP chuẩn:

```json
{
  "result": null,
  "success": false,
  "error": {
    "code": 0,
    "message": "Thông báo lỗi cho người dùng",
    "details": "Chi tiết lỗi (nếu có)",
    "validationErrors": [
      {
        "message": "Trường X là bắt buộc",
        "members": ["fieldName"]
      }
    ]
  }
}
```

---

## 4. Enum Values

### BusAtt Enums

| Enum | Value | Mô tả |
|------|-------|-------|
| **Status** | 1 = Active, 2 = Inactive | Trạng thái chung (Bus, Route, Driver) |
| **AttendanceResult** | 1 = Success, 2 = Rejected | Kết quả điểm danh |
| **BookingRequestStatus** | 0 = Pending, 1 = Approved, 2 = Rejected, 3 = Cancelled | Trạng thái đặt xe |
| **UrgentRequestStatus** | 0 = Pending, 1 = Approved, 2 = Rejected | Trạng thái yêu cầu xe đột xuất |

### MeetingBooking Enums

| Enum | Value | Mô tả |
|------|-------|-------|
| **RoomStatus** | 1 = Active, 2 = Suspended | Trạng thái phòng họp |
| **BookingStatus** | 0 = Draft, 1 = PendingApproval, 2 = Approved, 3 = ServiceAssigned, 4 = Prepared, 5 = Rejected, 6 = Cancelled | Trạng thái đặt lịch họp |
| **HistoryActionType** | 1 = Created, 2 = Updated, 3 = StatusChanged, 4 = Deleted, 5 = ServiceAssigned, 6 = ServiceConfirmed | Loại hành động lịch sử |

---

## 5. Module BusAtt - Chấm công xe bus

### 5.1 Dashboard (DashboardData)

#### 5.1.1 Lấy dữ liệu Dashboard Admin

```
POST /api/services/app/DashboardData/GetAdminDashboardData
```

**Permission:** `Pages.Dashboard.Admin`  
**Mô tả:** Lấy thống kê tổng quan cho admin (xe bus, tài xế, chấm công hôm nay, suất ăn).

**Request Body:** Không có

**Response Body:**
```json
{
  "result": {
    "buses": { "total": 0, "active": 0 },
    "qrActiveCount": 0,
    "drivers": { "total": 0, "active": 0 },
    "approvedUsersCount": 0,
    "today": {
      "date": "string (dd/MM/yyyy)",
      "total": 0,
      "success": 0,
      "rejected": 0
    },
    "meals": {
      "today": 0,
      "thisWeek": 0,
      "thisMonth": 0,
      "todayBySlot": [
        { "slotName": "string", "mealTime": "string", "count": 0 }
      ]
    },
    "busRegistrationsBySlot": [
      { "slotName": "string", "departureTime": "string", "count": 0 }
    ],
    "urgent": {
      "pendingUrgentRequests": 0,
      "pendingBookingRequests": 0
    },
    "permissions": {
      "hasToday": true,
      "hasBus": true,
      "hasMeals": true
    }
  },
  "success": true
}
```

---

#### 5.1.2 Lấy dữ liệu Dashboard User

```
POST /api/services/app/DashboardData/GetUserDashboardData
```

**Permission:** `Pages.Dashboard.User`  
**Mô tả:** Lấy thông tin dashboard cho nhân viên (đăng ký xe sắp tới, suất ăn, thống kê chấm công).

**Request Body:** Không có

**Response Body:**
```json
{
  "result": {
    "fullName": "string",
    "upcomingBusRegistrations": [
      { "rideDate": "string" }
    ],
    "upcomingMealDates": ["string"],
    "attendanceStats": {
      "total": 0,
      "success": 0,
      "rejected": 0
    }
  },
  "success": true
}
```

---

### 5.2 Attendance - Chấm công (BusAttAttendance)

#### 5.2.1 Validate QR Token

```
POST /api/services/app/BusAttAttendance/ValidateQRToken
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Xác thực mã QR khi nhân viên quét. Trả về thông tin xe bus và cấu hình checkin (GPS, selfie).

**Request Body:**
```json
{
  "token": "string (QR token)"
}
```

**Response Body:**
```json
{
  "result": {
    "busId": 0,
    "busCode": "string",
    "busName": "string",
    "licensePlate": "string",
    "pickupLocationName": "string",
    "pickupLat": 0.0,
    "pickupLng": 0.0,
    "gpsThresholdMeter": 200,
    "requireGps": true,
    "requireSelfie": false
  },
  "success": true
}
```

---

#### 5.2.2 Upload Selfie

```
POST /api/services/app/BusAttAttendance/UploadSelfie
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Upload ảnh selfie khi chấm công. Trả về URL ảnh đã lưu.

**Request Body:**
```json
{
  "fileBytes": "byte[] (base64 encoded)",
  "fileName": "string"
}
```

**Response Body:**
```json
{
  "result": "string (URL ảnh đã upload)",
  "success": true
}
```

---

#### 5.2.3 Submit Attendance (Gửi chấm công)

```
POST /api/services/app/BusAttAttendance/SubmitAttendance
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Gửi thông tin chấm công (QR token, GPS, selfie). Hệ thống kiểm tra khoảng cách GPS và trả kết quả.

**Request Body:**
```json
{
  "qrToken": "string (required)",
  "gpsLat": 0.0,
  "gpsLng": 0.0,
  "gpsAccuracy": 0.0,
  "selfieUrl": "string (URL từ UploadSelfie)"
}
```

**Response Body:**
```json
{
  "result": {
    "result": "success | rejected",
    "message": "string",
    "employee": "string (tên nhân viên)",
    "busCode": "string",
    "checkinTime": "string (HH:mm:ss)",
    "date": "string (dd/MM/yyyy)",
    "distanceM": 0.0
  },
  "success": true
}
```

---

#### 5.2.4 Lấy tất cả log chấm công (Admin)

```
POST /api/services/app/BusAttAttendance/GetAllAttendanceLogs
```

**Permission:** `BusAtt.Attendance`  
**Mô tả:** Lấy danh sách log chấm công của tất cả nhân viên (phân trang). Dành cho admin.

**Request Body:**
```json
{
  "filter": "string (tìm kiếm theo tên)",
  "attendanceDate": "2024-01-15T00:00:00 (optional)",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "attendanceLog": {
          "id": 0,
          "tenantId": 1,
          "userId": 0,
          "userFullName": "string",
          "busId": 0,
          "busCode": "string",
          "attendanceDate": "2024-01-15T00:00:00",
          "checkinTime": "2024-01-15T07:30:00",
          "gpsLat": 0.0,
          "gpsLng": 0.0,
          "gpsAccuracy": 0.0,
          "selfieUrl": "string",
          "distanceToStopM": 0.0,
          "resultStatus": 1,
          "rejectReason": "string"
        }
      }
    ]
  },
  "success": true
}
```

---

#### 5.2.5 Lấy log chấm công của tôi

```
POST /api/services/app/BusAttAttendance/GetMyAttendanceLogs
```

**Permission:** `Pages.Dashboard.User`  
**Mô tả:** Lấy danh sách log chấm công của user hiện tại (phân trang).

**Request Body:** Giống `GetAllAttendanceLogs`

**Response Body:** Giống `GetAllAttendanceLogs`

---

#### 5.2.6 Lấy danh sách xe đang hoạt động để checkin

```
POST /api/services/app/BusAttAttendance/GetActiveBusesForCheckin
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Lấy danh sách xe bus đang hoạt động mà user có thể checkin. Bao gồm trạng thái đã checkin hôm nay chưa.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    {
      "busId": 0,
      "busCode": "string",
      "busName": "string",
      "licensePlate": "string",
      "qrToken": "string",
      "hasCheckedInToday": false,
      "checkinTime": "2024-01-15T07:30:00 (null nếu chưa checkin)",
      "checkinResult": "Success | Rejected (null nếu chưa checkin)"
    }
  ],
  "success": true
}
```

---

### 5.3 Bus Management - Quản lý xe bus (BusAttBus)

#### 5.3.1 Lấy danh sách xe bus

```
POST /api/services/app/BusAttBus/GetAllBuses
```

**Permission:** `BusAtt.Bus`  
**Mô tả:** Lấy danh sách xe bus (phân trang, tìm kiếm).

**Request Body:**
```json
{
  "filter": "string (tìm theo mã xe, tên, biển số)",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "bus": {
          "id": 0,
          "tenantId": 1,
          "busCode": "string",
          "busName": "string",
          "licensePlate": "string",
          "employeeId": 0,
          "employeeName": "string",
          "employeeCode": "string",
          "status": 1,
          "hasQR": true,
          "qrId": 0,
          "qrImageUrl": "string",
          "pickupLocationId": 0,
          "pickupLocationName": "string",
          "dropoffLocationId": 0,
          "dropoffLocationName": "string"
        }
      }
    ]
  },
  "success": true
}
```

---

#### 5.3.2 Lấy thông tin xe để chỉnh sửa

```
POST /api/services/app/BusAttBus/GetBusForEdit
```

**Permission:** `BusAtt.Bus.Edit`  
**Mô tả:** Lấy thông tin chi tiết xe bus để hiển thị form chỉnh sửa.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{
  "result": {
    "bus": {
      "id": 0,
      "tenantId": 1,
      "busCode": "string",
      "busName": "string",
      "licensePlate": "string",
      "employeeId": 0,
      "pickupLocationId": 0,
      "dropoffLocationId": 0,
      "status": 1
    }
  },
  "success": true
}
```

---

#### 5.3.3 Tạo hoặc chỉnh sửa xe bus

```
POST /api/services/app/BusAttBus/CreateOrEditBus
```

**Permission:** `BusAtt.Bus.Create` (tạo mới) / `BusAtt.Bus.Edit` (chỉnh sửa)  
**Mô tả:** Tạo mới hoặc cập nhật thông tin xe bus. Nếu `id = null` → tạo mới, nếu có `id` → cập nhật.

**Request Body:**
```json
{
  "id": null,
  "tenantId": 1,
  "busCode": "string (required, max 50)",
  "busName": "string (max 150)",
  "licensePlate": "string (max 20)",
  "employeeId": 0,
  "pickupLocationId": 0,
  "dropoffLocationId": 0,
  "status": 1
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.3.4 Xóa xe bus

```
POST /api/services/app/BusAttBus/DeleteBus
```

**Permission:** `BusAtt.Bus.Delete`  
**Mô tả:** Xóa xe bus theo ID.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.3.5 Lấy dropdown tài xế

```
POST /api/services/app/BusAttBus/GetAllEmployeeForDriverDropDown
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Lấy danh sách nhân viên để chọn làm tài xế (dropdown).

**Request Body:**
```json
{
  "current": 0
}
```

**Response Body:**
```json
{
  "result": [
    { "value": "string", "text": "string", "selected": false }
  ],
  "success": true
}
```

---

#### 5.3.6 Tạo mã QR cho xe bus

```
POST /api/services/app/BusAttBus/GenerateQRCode
```

**Permission:** `BusAtt.QRCode.Create`  
**Mô tả:** Tạo mã QR mới cho xe bus. Mỗi xe chỉ có 1 QR active tại một thời điểm.

**Request Body:**
```json
{
  "busId": 0
}
```

**Response Body:**
```json
{
  "result": {
    "qrId": 0,
    "qrToken": "string",
    "qrImageUrl": "string (URL ảnh QR)"
  },
  "success": true
}
```

---

#### 5.3.7 Cấp lại mã QR

```
POST /api/services/app/BusAttBus/ReissueQRCode
```

**Permission:** `BusAtt.QRCode.Create`  
**Mô tả:** Vô hiệu hóa QR cũ và tạo QR mới cho xe bus.

**Request Body:**
```json
{
  "busId": 0
}
```

**Response Body:** Giống `GenerateQRCode`

---

#### 5.3.8 Lấy QR đang active

```
POST /api/services/app/BusAttBus/GetActiveQRCode
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Lấy thông tin mã QR đang hoạt động của xe bus.

**Request Body:**
```json
{
  "busId": 0
}
```

**Response Body:**
```json
{
  "result": {
    "id": 0,
    "busId": 0,
    "busCode": "string",
    "qrToken": "string",
    "qrImageUrl": "string",
    "isActive": true,
    "creationTime": "2024-01-15T00:00:00",
    "deactivatedAt": null
  },
  "success": true
}
```

---

#### 5.3.9 Lấy lịch sử QR

```
POST /api/services/app/BusAttBus/GetQRCodeHistory
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Lấy lịch sử tất cả mã QR đã tạo cho xe bus.

**Request Body:**
```json
{
  "busId": 0
}
```

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "busId": 0,
      "busCode": "string",
      "qrToken": "string",
      "qrImageUrl": "string",
      "isActive": false,
      "creationTime": "2024-01-15T00:00:00",
      "deactivatedAt": "2024-02-01T00:00:00"
    }
  ],
  "success": true
}
```

---

### 5.4 Location - Quản lý điểm đón/trả (BusAttLocation)

#### 5.4.1 Lấy danh sách điểm đón/trả

```
POST /api/services/app/BusAttLocation/GetAllLocations
```

**Permission:** `BusAtt.Location`  
**Mô tả:** Lấy danh sách tất cả điểm đón/trả (phân trang).

**Request Body:**
```json
{
  "filter": "string (tìm theo tên)",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "location": {
          "id": 0,
          "tenantId": 1,
          "name": "string",
          "lat": 0.0,
          "lng": 0.0
        }
      }
    ]
  },
  "success": true
}
```

---

#### 5.4.2 Lấy thông tin điểm để chỉnh sửa

```
POST /api/services/app/BusAttLocation/GetLocationForEdit
```

**Permission:** `BusAtt.Location.Edit`  
**Mô tả:** Lấy thông tin chi tiết điểm đón/trả để chỉnh sửa.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{
  "result": {
    "location": {
      "id": 0,
      "tenantId": 1,
      "name": "string",
      "lat": 0.0,
      "lng": 0.0
    }
  },
  "success": true
}
```

---

#### 5.4.3 Tạo hoặc chỉnh sửa điểm đón/trả

```
POST /api/services/app/BusAttLocation/CreateOrEditLocation
```

**Permission:** `BusAtt.Location.Create` (tạo) / `BusAtt.Location.Edit` (sửa)  
**Mô tả:** Tạo mới hoặc cập nhật điểm đón/trả. Nếu `id = null` → tạo mới.

**Request Body:**
```json
{
  "id": null,
  "tenantId": 1,
  "name": "string (required, max 150)",
  "lat": 10.762622,
  "lng": 106.660172
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.4.4 Xóa điểm đón/trả

```
POST /api/services/app/BusAttLocation/DeleteLocation
```

**Permission:** `BusAtt.Location.Delete`  
**Mô tả:** Xóa điểm đón/trả theo ID.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.4.5 Lấy dropdown điểm đón/trả

```
POST /api/services/app/BusAttLocation/GetAllLocationDropDown
```

**Permission:** `BusAtt` (class-level)  
**Mô tả:** Lấy danh sách điểm đón/trả dạng dropdown.

**Request Body:**
```json
{
  "current": 0
}
```

**Response Body:**
```json
{
  "result": [
    { "value": "string", "text": "string", "selected": false }
  ],
  "success": true
}
```

---

### 5.5 TimeSlot - Khung giờ xe bus (BusAttTimeSlot)

#### 5.5.1 Lấy tất cả khung giờ

```
POST /api/services/app/BusAttTimeSlot/GetAll
```

**Permission:** `BusAtt.Bus`  
**Mô tả:** Lấy danh sách tất cả khung giờ xe bus (bao gồm cả inactive).

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "displayName": "string",
      "departureTime": "07:00:00",
      "departureTimeFormatted": "07:00",
      "sortOrder": 1,
      "status": 1,
      "requiresAdvanceBooking": true,
      "registrationDeadline": "17:00:00",
      "registrationDeadlineFormatted": "17:00",
      "deadlineDaysBefore": 1
    }
  ],
  "success": true
}
```

---

#### 5.5.2 Tạo hoặc chỉnh sửa khung giờ

```
POST /api/services/app/BusAttTimeSlot/CreateOrEdit
```

**Permission:** `BusAtt.Bus.Create`  
**Mô tả:** Tạo mới hoặc cập nhật khung giờ xe bus.

**Request Body:**
```json
{
  "id": null,
  "displayName": "string",
  "departureTime": "07:00:00",
  "sortOrder": 1,
  "status": 1,
  "requiresAdvanceBooking": true,
  "registrationDeadline": "17:00:00",
  "deadlineDaysBefore": 1
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.5.3 Xóa khung giờ

```
POST /api/services/app/BusAttTimeSlot/Delete
```

**Permission:** `BusAtt.Bus.Create`  
**Mô tả:** Xóa khung giờ xe bus theo ID.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.5.4 Lấy khung giờ đang hoạt động (dropdown)

```
POST /api/services/app/BusAttTimeSlot/GetActiveTimeSlots
```

**Permission:** `BusAtt.Bus`  
**Mô tả:** Lấy danh sách khung giờ đang active để hiển thị dropdown cho user đăng ký.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "displayName": "string",
      "departureTime": "07:00",
      "requiresAdvanceBooking": true,
      "registrationDeadline": "17:00",
      "deadlineDaysBefore": 1
    }
  ],
  "success": true
}
```

---

### 5.6 MealTimeSlot - Buổi ăn (BusAttMealTimeSlot)

#### 5.6.1 Lấy tất cả buổi ăn

```
POST /api/services/app/BusAttMealTimeSlot/GetAll
```

**Permission:** `Meal.MealTimeSlot`  
**Mô tả:** Lấy danh sách tất cả buổi ăn (bao gồm cả inactive).

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "displayName": "string",
      "mealTime": "11:30:00",
      "mealTimeFormatted": "11:30",
      "sortOrder": 1,
      "status": 1,
      "requiresAdvanceBooking": true,
      "registrationDeadline": "09:00:00",
      "registrationDeadlineFormatted": "09:00",
      "deadlineDaysBefore": 0
    }
  ],
  "success": true
}
```

---

#### 5.6.2 Tạo hoặc chỉnh sửa buổi ăn

```
POST /api/services/app/BusAttMealTimeSlot/CreateOrEdit
```

**Permission:** `Meal.MealTimeSlot.Create`  
**Mô tả:** Tạo mới hoặc cập nhật buổi ăn.

**Request Body:**
```json
{
  "id": null,
  "displayName": "string",
  "mealTime": "11:30:00",
  "sortOrder": 1,
  "status": 1,
  "requiresAdvanceBooking": true,
  "registrationDeadline": "09:00:00",
  "deadlineDaysBefore": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.6.3 Xóa buổi ăn

```
POST /api/services/app/BusAttMealTimeSlot/Delete
```

**Permission:** `Meal.MealTimeSlot.Delete`  
**Mô tả:** Xóa buổi ăn theo ID.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.6.4 Lấy buổi ăn đang hoạt động (dropdown)

```
POST /api/services/app/BusAttMealTimeSlot/GetActiveMealTimeSlots
```

**Permission:** `Meal.MealTimeSlot`  
**Mô tả:** Lấy danh sách buổi ăn đang active để hiển thị dropdown cho user đăng ký.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "displayName": "string",
      "mealTime": "11:30",
      "requiresAdvanceBooking": true,
      "registrationDeadline": "09:00",
      "deadlineDaysBefore": 0
    }
  ],
  "success": true
}
```

---

#### 5.6.5 Lấy ngày nghỉ suất ăn

```
POST /api/services/app/BusAttMealTimeSlot/GetMealExcludedDays
```

**Permission:** `Meal.MealTimeSlot`  
**Mô tả:** Lấy chuỗi ngày trong tuần không phục vụ suất ăn (dạng "0,6" - 0=CN, 6=T7).

**Request Body:** Không có

**Response Body:**
```json
{
  "result": "0,6",
  "success": true
}
```

---

#### 5.6.6 Lưu ngày nghỉ suất ăn

```
POST /api/services/app/BusAttMealTimeSlot/SaveMealExcludedDays
```

**Permission:** `Meal.MealTimeSlot.Create`  
**Mô tả:** Lưu cấu hình ngày trong tuần không phục vụ suất ăn.

**Request Body:**
```json
{
  "mealExcludedDays": "0,6"
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

### 5.7 Booking Request - Đặt xe (BusAttBooking)

#### 5.7.1 Tạo yêu cầu đặt xe

```
POST /api/services/app/BusAttBooking/CreateBookingRequest
```

**Permission:** `BusAtt.Booking.Create`  
**Mô tả:** Tạo yêu cầu đặt xe bus cho một ngày cụ thể.

**Request Body:**
```json
{
  "pickupLocationId": 0,
  "locationId": 0,
  "requestedDate": "2024-01-20T00:00:00",
  "requestedTime": "07:00:00"
}
```

**Response Body:**
```json
{
  "result": 123,
  "success": true
}
```
> `result` là ID của booking request vừa tạo.

---

#### 5.7.2 Đặt xe hàng loạt (Batch)

```
POST /api/services/app/BusAttBooking/BatchBookingRequest
```

**Permission:** `BusAtt.Booking.Create`  
**Mô tả:** Đặt xe hàng loạt theo tuần hoặc theo tháng. Hệ thống tự tạo booking cho các ngày còn lại trong tuần/tháng (trừ ngày nghỉ).

**Request Body:**
```json
{
  "pickupLocationId": 0,
  "locationId": 0,
  "requestedTime": "07:00:00",
  "batchType": 1
}
```
> `batchType`: 1 = Theo tuần (đến hết tuần), 2 = Theo tháng (đến hết tháng)

**Response Body:**
```json
{
  "result": {
    "totalDays": 5,
    "createdCount": 4,
    "skippedCount": 1,
    "createdDates": ["2024-01-16T00:00:00", "2024-01-17T00:00:00"],
    "skippedReasons": ["16/01/2024: Đã có đăng ký"]
  },
  "success": true
}
```

---

#### 5.7.3 Lấy yêu cầu đặt xe của tôi

```
POST /api/services/app/BusAttBooking/GetMyBookingRequests
```

**Permission:** `BusAtt.Booking`  
**Mô tả:** Lấy danh sách yêu cầu đặt xe của user hiện tại (phân trang).

**Request Body:**
```json
{
  "statusFilter": 0,
  "fromDate": "2024-01-01T00:00:00",
  "toDate": "2024-01-31T00:00:00",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "id": 0,
        "status": 0,
        "pickupLocationName": "string",
        "locationName": "string",
        "requestedDate": "2024-01-20T00:00:00",
        "requestedTime": "07:00:00",
        "employeeName": "string",
        "busName": "string",
        "driverName": "string",
        "rejectionReason": "string",
        "creationTime": "2024-01-15T10:00:00",
        "processedAt": "2024-01-16T08:00:00"
      }
    ]
  },
  "success": true
}
```

---

#### 5.7.4 Lấy tất cả yêu cầu đặt xe (Admin)

```
POST /api/services/app/BusAttBooking/GetAllBookingRequests
```

**Permission:** `BusAtt.Booking.Process`  
**Mô tả:** Lấy tất cả yêu cầu đặt xe của mọi nhân viên (phân trang). Dành cho admin xử lý.

**Request Body:** Giống `GetMyBookingRequests`

**Response Body:** Giống `GetMyBookingRequests`

---

#### 5.7.5 Duyệt yêu cầu đặt xe

```
POST /api/services/app/BusAttBooking/ApproveBookingRequest
```

**Permission:** `BusAtt.Booking.Process`  
**Mô tả:** Admin duyệt yêu cầu đặt xe và gán xe bus.

**Request Body:**
```json
{
  "requestId": 0,
  "busId": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.7.6 Từ chối yêu cầu đặt xe

```
POST /api/services/app/BusAttBooking/RejectBookingRequest
```

**Permission:** `BusAtt.Booking.Process`  
**Mô tả:** Admin từ chối yêu cầu đặt xe với lý do.

**Request Body:**
```json
{
  "requestId": 0,
  "rejectionReason": "string (max 500)"
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.7.7 Hủy yêu cầu đặt xe

```
POST /api/services/app/BusAttBooking/CancelBookingRequest
```

**Permission:** `BusAtt.Booking`  
**Mô tả:** Nhân viên hủy yêu cầu đặt xe của mình (chỉ khi đang Pending).

**Request Body:**
```json
{
  "requestId": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.7.8 Lấy dropdown xe bus cho đặt xe

```
POST /api/services/app/BusAttBooking/GetAllBusDropDownForBooking
```

**Permission:** `BusAtt.Booking.Process`  
**Mô tả:** Lấy danh sách xe bus dạng dropdown để admin chọn khi duyệt yêu cầu.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    { "value": "string", "displayText": "string" }
  ],
  "success": true
}
```

---

### 5.8 Urgent Request - Yêu cầu xe đột xuất (BusAttUrgentRequest)

#### 5.8.1 Tạo yêu cầu xe đột xuất

```
POST /api/services/app/BusAttUrgentRequest/CreateUrgentRequest
```

**Permission:** `BusAtt.UrgentRequest`  
**Mô tả:** Tạo yêu cầu xe đột xuất với lý do.

**Request Body:**
```json
{
  "requestedDate": "2024-01-20T00:00:00",
  "requestedTime": "14:00:00",
  "reason": "string (required, max 500)"
}
```

**Response Body:**
```json
{
  "result": 123,
  "success": true
}
```
> `result` là ID của urgent request vừa tạo.

---

#### 5.8.2 Lấy tất cả yêu cầu xe đột xuất

```
POST /api/services/app/BusAttUrgentRequest/GetAllUrgentRequests
```

**Permission:** `BusAtt.UrgentRequest`  
**Mô tả:** Lấy danh sách yêu cầu xe đột xuất (phân trang, lọc theo trạng thái/ngày).

**Request Body:**
```json
{
  "statusFilter": 0,
  "fromDate": "2024-01-01T00:00:00",
  "toDate": "2024-01-31T00:00:00",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "id": 0,
        "tenantId": 1,
        "userId": 0,
        "employeeName": "string",
        "requestedDate": "2024-01-20T00:00:00",
        "requestedTime": "14:00:00",
        "reason": "string",
        "status": 0,
        "statusText": "Chờ duyệt",
        "assignedBusId": null,
        "assignedBusName": null,
        "assignedBusLicensePlate": null,
        "driverName": null,
        "rejectionReason": null,
        "creationTime": "2024-01-15T10:00:00",
        "processedAt": null
      }
    ]
  },
  "success": true
}
```

---

#### 5.8.3 Lấy chi tiết yêu cầu xe đột xuất

```
POST /api/services/app/BusAttUrgentRequest/GetUrgentRequestForEdit
```

**Permission:** `BusAtt.UrgentRequest`  
**Mô tả:** Lấy chi tiết một yêu cầu xe đột xuất theo ID.

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{
  "result": {
    "id": 0,
    "tenantId": 1,
    "userId": 0,
    "employeeName": "string",
    "requestedDate": "2024-01-20T00:00:00",
    "requestedTime": "14:00:00",
    "reason": "string",
    "status": 0,
    "statusText": "Chờ duyệt",
    "assignedBusId": null,
    "assignedBusName": null,
    "assignedBusLicensePlate": null,
    "driverName": null,
    "rejectionReason": null,
    "creationTime": "2024-01-15T10:00:00",
    "processedAt": null
  },
  "success": true
}
```

---

#### 5.8.4 Duyệt yêu cầu xe đột xuất

```
POST /api/services/app/BusAttUrgentRequest/ApproveUrgentRequest
```

**Permission:** `BusAtt.UrgentRequest.Process`  
**Mô tả:** Admin duyệt yêu cầu xe đột xuất, gán xe bus và tài xế (optional).

**Request Body:**
```json
{
  "requestId": 0,
  "busId": 0,
  "driverEmployeeId": 0
}
```
> `driverEmployeeId` là optional - chỉ định tài xế cụ thể cho chuyến này.

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.8.5 Từ chối yêu cầu xe đột xuất

```
POST /api/services/app/BusAttUrgentRequest/RejectUrgentRequest
```

**Permission:** `BusAtt.UrgentRequest.Process`  
**Mô tả:** Admin từ chối yêu cầu xe đột xuất với lý do.

**Request Body:**
```json
{
  "requestId": 0,
  "rejectionReason": "string (max 500)"
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 5.8.6 Lấy dropdown xe bus cho yêu cầu đột xuất

```
POST /api/services/app/BusAttUrgentRequest/GetAllBusDropDownForUrgent
```

**Permission:** `BusAtt.UrgentRequest`  
**Mô tả:** Lấy danh sách xe bus dạng dropdown để admin chọn khi duyệt.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    { "value": "string", "displayText": "string" }
  ],
  "success": true
}
```

---

#### 5.8.7 Lấy dropdown tài xế cho yêu cầu đột xuất

```
POST /api/services/app/BusAttUrgentRequest/GetAllDriverDropDownForUrgent
```

**Permission:** `BusAtt.UrgentRequest`  
**Mô tả:** Lấy danh sách tài xế dạng dropdown để admin chọn khi duyệt.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    { "value": "string", "displayText": "string" }
  ],
  "success": true
}
```

---

### 5.9 System Config - Cấu hình hệ thống (BusAttSystemConfig)

#### 5.9.1 Lấy cấu hình hệ thống

```
POST /api/services/app/BusAttSystemConfig/GetSystemConfig
```

**Permission:** `BusAtt.SystemConfig`  
**Mô tả:** Lấy cấu hình hệ thống chấm công (ngưỡng GPS, yêu cầu selfie, ngày nghỉ).

**Request Body:** Không có

**Response Body:**
```json
{
  "result": {
    "id": 1,
    "nearStopThresholdMeter": 200,
    "requireGPS": true,
    "requireSelfie": false,
    "busExcludedDays": "0",
    "mealExcludedDays": "0"
  },
  "success": true
}
```
> `busExcludedDays` / `mealExcludedDays`: Chuỗi ngày trong tuần không hoạt động, dạng "0,6" (0=CN, 1=T2,..., 6=T7)

---

#### 5.9.2 Lưu cấu hình hệ thống

```
POST /api/services/app/BusAttSystemConfig/SaveSystemConfig
```

**Permission:** `BusAtt.SystemConfig.Edit`  
**Mô tả:** Cập nhật cấu hình hệ thống chấm công.

**Request Body:**
```json
{
  "id": 1,
  "nearStopThresholdMeter": 200,
  "requireGPS": true,
  "requireSelfie": false,
  "busExcludedDays": "0,6",
  "mealExcludedDays": "0,6"
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

## 6. Module MeetingBooking - Đặt lịch họp

### 6.1 Room - Quản lý phòng họp (MeetingBookingRoom)

#### 6.1.1 Lấy danh sách phòng họp

```
POST /api/services/app/MeetingBookingRoom/GetAll
```

**Permission:** Authenticated (class-level `[AbpAuthorize]`)  
**Mô tả:** Lấy danh sách phòng họp (phân trang, lọc theo tên/trạng thái).

**Request Body:**
```json
{
  "filter": "string (tìm theo tên/mã phòng)",
  "status": 1,
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "id": 0,
        "tenantId": 1,
        "roomCode": "string",
        "roomName": "string",
        "capacity": 20,
        "floorLocation": "string",
        "status": 1,
        "statusName": "Hoạt động",
        "description": "string",
        "isDeleted": false,
        "creationTime": "2024-01-15T00:00:00",
        "createdByUserId": 0,
        "createdByUserName": "string"
      }
    ]
  },
  "success": true
}
```

---

#### 6.1.2 Lấy dropdown phòng họp đang hoạt động

```
POST /api/services/app/MeetingBookingRoom/GetActiveRoomsDropDown
```

**Permission:** Authenticated  
**Mô tả:** Lấy danh sách phòng họp đang active dạng dropdown.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    { "id": 0, "displayName": "string" }
  ],
  "success": true
}
```

---

#### 6.1.3 Tạo hoặc cập nhật phòng họp

```
POST /api/services/app/MeetingBookingRoom/CreateOrUpdate
```

**Permission:** Authenticated  
**Mô tả:** Tạo mới hoặc cập nhật phòng họp. Nếu `id = null` → tạo mới.

**Request Body:**
```json
{
  "id": null,
  "roomCode": "string (required, max 50)",
  "roomName": "string (required, max 200)",
  "capacity": 20,
  "floorLocation": "string (max 200)",
  "status": 1,
  "description": "string (max 500)"
}
```

**Response Body:**
```json
{
  "result": 123,
  "success": true
}
```
> `result` là ID phòng họp (mới tạo hoặc đã cập nhật).

---

#### 6.1.4 Xóa phòng họp

```
POST /api/services/app/MeetingBookingRoom/Delete
```

**Permission:** Authenticated  
**Mô tả:** Xóa phòng họp theo ID (soft delete).

**Request Body:**
```json
{
  "id": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

### 6.2 Calendar - Lịch phòng họp (MeetingBookingCalendar)

#### 6.2.1 Lấy lịch tuần

```
POST /api/services/app/MeetingBookingCalendar/GetWeeklyCalendar
```

**Permission:** Authenticated  
**Mô tả:** Lấy dữ liệu lịch đặt phòng họp theo tuần. Hiển thị các booking trên calendar view.

**Request Body:**
```json
{
  "weekStartDate": "2024-01-15T00:00:00 (optional, mặc định tuần hiện tại)",
  "roomId": 0,
  "department": "string (optional)",
  "statusFilter": 2
}
```

**Response Body:**
```json
{
  "result": {
    "weekStart": "2024-01-15T00:00:00",
    "weekEnd": "2024-01-21T00:00:00",
    "rooms": [
      {
        "roomId": 0,
        "roomCode": "string",
        "roomName": "string",
        "capacity": 20
      }
    ],
    "timeSlots": [
      {
        "date": "2024-01-15T00:00:00",
        "dayOfWeek": "Thứ Hai",
        "timeLabel": "08:00 - 09:00",
        "bookings": [
          {
            "bookingId": 0,
            "subject": "string",
            "presidingLeader": "string",
            "presidingLeaderUserId": 0,
            "startTime": "2024-01-15T08:00:00",
            "endTime": "2024-01-15T09:00:00",
            "status": 2,
            "roomId": 0,
            "requestedByUserId": 0
          }
        ]
      }
    ]
  },
  "success": true
}
```

---

### 6.3 Request - Yêu cầu đặt lịch họp (MeetingBookingRequest)

#### 6.3.1 Tạo yêu cầu đặt lịch họp

```
POST /api/services/app/MeetingBookingRequest/Create
```

**Permission:** Authenticated  
**Mô tả:** Tạo yêu cầu đặt lịch họp mới. Có thể lưu nháp (`saveAsDraft = true`) hoặc gửi luôn.

**Request Body:**
```json
{
  "subject": "string (required, max 500)",
  "presidingLeader": "string (required, max 200)",
  "presidingLeaderUserId": 0,
  "startTime": "2024-01-20T08:00:00 (required)",
  "endTime": "2024-01-20T09:30:00 (required)",
  "meetingRoomId": 0,
  "attendees": "string (max 1000, danh sách người tham dự dạng text)",
  "attendeeUserIds": [1, 2, 3],
  "proposingDepartment": "string (max 200)",
  "contactPhone": "string (max 20)",
  "logisticsNotes": "string (max 2000, ghi chú hậu cần)",
  "saveAsDraft": false
}
```

**Response Body:**
```json
{
  "result": 123,
  "success": true
}
```
> `result` là ID của booking request vừa tạo.

**Lưu ý:**
- Nếu `saveAsDraft = false`, hệ thống kiểm tra xung đột phòng họp (trùng giờ).
- `attendeeUserIds` dùng để gửi FCM notification cho người tham dự.
- `presidingLeaderUserId` dùng để lưu tham chiếu identity người chủ trì.

---

#### 6.3.2 Cập nhật yêu cầu đặt lịch họp

```
POST /api/services/app/MeetingBookingRequest/Update
```

**Permission:** Authenticated  
**Mô tả:** Cập nhật yêu cầu đặt lịch họp (chỉ khi đang Draft hoặc PendingApproval).

**Request Body:**
```json
{
  "id": 0,
  "subject": "string (required, max 500)",
  "presidingLeader": "string (required, max 200)",
  "startTime": "2024-01-20T08:00:00 (required)",
  "endTime": "2024-01-20T09:30:00 (required)",
  "meetingRoomId": 0,
  "attendees": "string (max 1000)",
  "proposingDepartment": "string (max 200)",
  "contactPhone": "string (max 20)",
  "logisticsNotes": "string (max 2000)",
  "presidingLeaderUserId": 0,
  "attendeeUserIds": [1, 2, 3]
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.3 Gửi yêu cầu (Submit)

```
POST /api/services/app/MeetingBookingRequest/Submit
```

**Permission:** Authenticated  
**Mô tả:** Gửi yêu cầu đặt lịch từ trạng thái Draft sang PendingApproval. Kiểm tra xung đột phòng.

**Request Body:**
```json
{
  "requestId": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.4 Duyệt yêu cầu đặt lịch

```
POST /api/services/app/MeetingBookingRequest/Approve
```

**Permission:** Authenticated (kiểm tra logic bên trong)  
**Mô tả:** Duyệt yêu cầu đặt lịch họp. Có thể đồng thời phân công nhân viên phục vụ.

**Request Body:**
```json
{
  "requestId": 0,
  "serviceStaffUserIds": [1, 2]
}
```
> `serviceStaffUserIds` là optional - danh sách UserId nhân viên phục vụ được phân công.

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.5 Từ chối yêu cầu đặt lịch

```
POST /api/services/app/MeetingBookingRequest/Reject
```

**Permission:** Authenticated  
**Mô tả:** Từ chối yêu cầu đặt lịch họp với lý do.

**Request Body:**
```json
{
  "requestId": 0,
  "rejectionReason": "string (required, max 500)"
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.6 Hủy yêu cầu đặt lịch

```
POST /api/services/app/MeetingBookingRequest/Cancel
```

**Permission:** Authenticated  
**Mô tả:** Hủy yêu cầu đặt lịch họp (người tạo hoặc admin có thể hủy).

**Request Body:**
```json
{
  "requestId": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.7 Lấy tất cả yêu cầu đặt lịch

```
POST /api/services/app/MeetingBookingRequest/GetAll
```

**Permission:** Authenticated  
**Mô tả:** Lấy danh sách tất cả yêu cầu đặt lịch họp (phân trang, lọc).

**Request Body:**
```json
{
  "status": 1,
  "roomId": 0,
  "dateFrom": "2024-01-01T00:00:00",
  "dateTo": "2024-01-31T00:00:00",
  "keyword": "string (tìm theo chủ đề, người chủ trì)",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "id": 0,
        "requesterId": 0,
        "requesterName": "string",
        "subject": "string",
        "presidingLeader": "string",
        "presidingLeaderUserId": 0,
        "startTime": "2024-01-20T08:00:00",
        "endTime": "2024-01-20T09:30:00",
        "meetingRoomId": 0,
        "meetingRoomName": "string",
        "attendees": "string",
        "attendeeUserIds": [1, 2, 3],
        "proposingDepartment": "string",
        "contactPhone": "string",
        "logisticsNotes": "string",
        "status": 1,
        "rejectionReason": null,
        "approvedByUserId": null,
        "approvedAt": null,
        "cancelledAt": null,
        "cancelledByUserId": null,
        "creationTime": "2024-01-15T10:00:00",
        "isServiceConfirmed": null
      }
    ]
  },
  "success": true
}
```

---

#### 6.3.8 Lấy yêu cầu đặt lịch của tôi

```
POST /api/services/app/MeetingBookingRequest/GetMyRequests
```

**Permission:** Authenticated  
**Mô tả:** Lấy danh sách yêu cầu đặt lịch của user hiện tại (phân trang).

**Request Body:** Giống `GetAll`

**Response Body:** Giống `GetAll`

---

#### 6.3.9 Phân công nhân viên phục vụ

```
POST /api/services/app/MeetingBookingRequest/AssignServiceStaff
```

**Permission:** Authenticated  
**Mô tả:** Phân công nhân viên phục vụ cho buổi họp đã được duyệt.

**Request Body:**
```json
{
  "requestId": 0,
  "serviceStaffUserIds": [1, 2, 3]
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.10 Xác nhận chuẩn bị

```
POST /api/services/app/MeetingBookingRequest/ConfirmPreparation
```

**Permission:** Authenticated (nhân viên phục vụ được phân công)  
**Mô tả:** Nhân viên phục vụ xác nhận đã chuẩn bị xong cho buổi họp.

**Request Body:**
```json
{
  "requestId": 0
}
```

**Response Body:**
```json
{ "result": null, "success": true }
```

---

#### 6.3.11 Lấy danh sách phân công phục vụ của tôi

```
POST /api/services/app/MeetingBookingRequest/GetMyServiceAssignments
```

**Permission:** Authenticated  
**Mô tả:** Lấy danh sách buổi họp mà user hiện tại được phân công phục vụ.

**Request Body:**
```json
{
  "status": 3,
  "roomId": 0,
  "dateFrom": "2024-01-01T00:00:00",
  "dateTo": "2024-01-31T00:00:00",
  "keyword": "string",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "requesterId": 0,
      "requesterName": "string",
      "subject": "string",
      "presidingLeader": "string",
      "presidingLeaderUserId": 0,
      "startTime": "2024-01-20T08:00:00",
      "endTime": "2024-01-20T09:30:00",
      "meetingRoomId": 0,
      "meetingRoomName": "string",
      "attendees": "string",
      "attendeeUserIds": [1, 2],
      "proposingDepartment": "string",
      "contactPhone": "string",
      "logisticsNotes": "string",
      "status": 3,
      "rejectionReason": null,
      "approvedByUserId": 0,
      "approvedAt": "2024-01-16T08:00:00",
      "cancelledAt": null,
      "cancelledByUserId": null,
      "creationTime": "2024-01-15T10:00:00",
      "isServiceConfirmed": false
    }
  ],
  "success": true
}
```

---

#### 6.3.12 Lấy tổng quan phân công phục vụ (Admin)

```
POST /api/services/app/MeetingBookingRequest/GetAllServiceAssignments
```

**Permission:** `Dms.MeetingBooking.ViewAllStaff`  
**Mô tả:** Lấy tổng quan tất cả phân công phục vụ (dành cho người có quyền quản lý nhân viên phục vụ).

**Request Body:**
```json
{
  "status": 3,
  "roomId": 0,
  "dateFrom": "2024-01-01T00:00:00",
  "dateTo": "2024-01-31T00:00:00",
  "keyword": "string",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "bookingRequestId": 0,
        "subject": "string",
        "meetingRoomName": "string",
        "startTime": "2024-01-20T08:00:00",
        "endTime": "2024-01-20T09:30:00",
        "presidingLeader": "string",
        "status": 3,
        "totalStaff": 3,
        "confirmedStaff": 2,
        "staffDetails": [
          {
            "userId": 0,
            "fullName": "string",
            "isConfirmed": true,
            "confirmedAt": "2024-01-19T14:00:00"
          }
        ]
      }
    ]
  },
  "success": true
}
```

---

#### 6.3.13 Lấy dropdown nhân viên phục vụ

```
POST /api/services/app/MeetingBookingRequest/GetServiceStaffDropDown
```

**Permission:** Authenticated  
**Mô tả:** Lấy danh sách nhân viên phục vụ dạng dropdown.

**Request Body:** Không có

**Response Body:**
```json
{
  "result": [
    { "userId": 0, "fullName": "string" }
  ],
  "success": true
}
```

---

#### 6.3.14 Lấy dropdown nhân viên phục vụ (phân trang)

```
POST /api/services/app/MeetingBookingRequest/GetServiceStaffDropDownPaged
```

**Permission:** Authenticated  
**Mô tả:** Lấy danh sách nhân viên phục vụ có phân trang và tìm kiếm (dùng cho infinite scroll).

**Request Body:**
```json
{
  "filter": "string (tìm theo tên)",
  "skipCount": 0,
  "maxResultCount": 20
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      { "userId": 0, "fullName": "string" }
    ]
  },
  "success": true
}
```

---

#### 6.3.15 Lấy lịch sử booking

```
POST /api/services/app/MeetingBookingRequest/GetBookingHistory
```

**Permission:** Authenticated  
**Mô tả:** Lấy lịch sử thay đổi của một yêu cầu đặt lịch cụ thể.

**Request Body:**
```json
{
  "requestId": 0
}
```

**Response Body:**
```json
{
  "result": [
    {
      "id": 0,
      "bookingRequestId": 0,
      "actionType": 1,
      "actionByUserName": "string",
      "description": "string",
      "previousValues": "string (JSON)",
      "newValues": "string (JSON)",
      "creationTime": "2024-01-15T10:00:00"
    }
  ],
  "success": true
}
```

---

#### 6.3.16 Lấy tất cả lịch sử (Admin)

```
POST /api/services/app/MeetingBookingRequest/GetAllHistory
```

**Permission:** Authenticated  
**Mô tả:** Lấy toàn bộ lịch sử thay đổi của tất cả booking (phân trang, lọc).

**Request Body:**
```json
{
  "actionType": 1,
  "dateFrom": "2024-01-01T00:00:00",
  "dateTo": "2024-01-31T00:00:00",
  "userName": "string (lọc theo người thực hiện)",
  "keyword": "string",
  "maxResultCount": 10,
  "skipCount": 0,
  "sorting": "string (optional)"
}
```

**Response Body:**
```json
{
  "result": {
    "totalCount": 0,
    "items": [
      {
        "id": 0,
        "bookingRequestId": 0,
        "actionType": 1,
        "actionByUserName": "string",
        "description": "string",
        "previousValues": "string (JSON)",
        "newValues": "string (JSON)",
        "creationTime": "2024-01-15T10:00:00"
      }
    ]
  },
  "success": true
}
```

---

## 7. Ghi chú cho Mobile Team

### 7.1 Quy tắc chung ABP Framework

- **Tất cả API đều dùng method POST** (ABP convention cho Application Services).
- **Response wrapper:** Mọi response đều được wrap trong `{ "result": ..., "success": true/false, "error": ... }`.
- **Phân trang:** Các API có phân trang sử dụng `PagedResultDto` với `totalCount` và `items`.
- **Input phân trang:** Gửi `maxResultCount` (số item/trang) và `skipCount` (bỏ qua bao nhiêu item).
- **Sorting:** Gửi tên property + direction, ví dụ: `"creationTime DESC"`, `"busCode ASC"`.

### 7.2 Xử lý Token hết hạn

- Token mặc định hết hạn sau 86400 giây (24h).
- Khi nhận HTTP 401, gọi lại `/api/TokenAuth/Authenticate` để lấy token mới.

### 7.3 Multi-tenant

- Luôn gửi header `Abp.TenantId` với mọi request.
- Nếu không gửi, hệ thống sẽ dùng host tenant (có thể không có dữ liệu).

### 7.4 Workflow trạng thái

#### Đặt xe bus (BookingRequest):
```
Pending (0) → Approved (1) | Rejected (2) | Cancelled (3)
```

#### Yêu cầu xe đột xuất (UrgentRequest):
```
Pending (0) → Approved (1) | Rejected (2)
```

#### Đặt lịch họp (MeetingBooking):
```
Draft (0) → PendingApproval (1) → Approved (2) → ServiceAssigned (3) → Prepared (4)
                                 ↘ Rejected (5)
                                 ↘ Cancelled (6)
```

### 7.5 Checkin Flow (Mobile)

1. Gọi `GetActiveBusesForCheckin` → hiển thị danh sách xe
2. User chọn xe → dùng `qrToken` hoặc quét QR
3. Gọi `ValidateQRToken` → nhận thông tin cấu hình (GPS, selfie)
4. Nếu `requireSelfie = true` → chụp ảnh → gọi `UploadSelfie`
5. Gọi `SubmitAttendance` với GPS + selfie URL → nhận kết quả

### 7.6 Meeting Booking Flow (Mobile)

1. Gọi `GetActiveRoomsDropDown` → chọn phòng
2. Gọi `Create` với `saveAsDraft = false` → tạo và gửi luôn
3. Admin gọi `Approve` → duyệt + phân công phục vụ
4. Nhân viên phục vụ gọi `GetMyServiceAssignments` → xem danh sách
5. Nhân viên phục vụ gọi `ConfirmPreparation` → xác nhận đã chuẩn bị

---
