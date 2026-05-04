# 🚌 Bus Management API

> **Dự án:** Bus Attendance System (Z103 — ASP.NET Core + ABP Framework)  
> **Cập nhật:** 04/05/2026  
> **Base URL:** `https://{domain}`  
> **Base path:** `/api/services/app/BusAtt/`  
> **Auth:** Yêu cầu đăng nhập + permission `BusAtt`

---

## Mục lục

1. [Điểm đón/trả (Location)](#1-điểm-đóntrả-location)
2. [Tuyến xe (Route)](#2-tuyến-xe-route)
3. [Xe buýt (Bus)](#3-xe-buýt-bus)
4. [Mã QR (QR Code)](#4-mã-qr-qr-code)
5. [Gán tuyến cho xe](#5-gán-tuyến-cho-xe)
6. [Đăng ký tuyến xe](#6-đăng-ký-tuyến-xe)
7. [Chấm công](#7-chấm-công)
8. [Yêu cầu xe đột xuất](#8-yêu-cầu-xe-đột-xuất)
9. [Cấu hình hệ thống](#9-cấu-hình-hệ-thống)

---

## Phân quyền

| Permission                               | Mô tả                       |
|------------------------------------------|-----------------------------|
| `BusAtt`                                 | Quyền gốc — truy cập module |
| `BusAtt.Location`                        | Xem điểm đón/trả            |
| `BusAtt.Location.Create/Edit/Delete`     | CRUD điểm đón/trả           |
| `BusAtt.Route`                           | Xem tuyến xe                |
| `BusAtt.Route.Create/Edit/Delete`        | CRUD tuyến xe               |
| `BusAtt.Bus`                             | Xem xe buýt                 |
| `BusAtt.Bus.Create/Edit/Delete`          | CRUD xe buýt                |
| `BusAtt.QRCode`                          | Xem mã QR                   |
| `BusAtt.QRCode.Create`                   | Tạo/cấp lại mã QR           |
| `BusAtt.Registration`                    | Xem đăng ký tuyến           |
| `BusAtt.Registration.Register`           | Tự đăng ký tuyến            |
| `BusAtt.Registration.Create/Edit/Delete` | Admin quản lý đăng ký       |
| `BusAtt.Attendance`                      | Xem log chấm công           |
| `BusAtt.Attendance.Create`               | Gửi chấm công               |
| `BusAtt.UrgentRequest`                   | Yêu cầu xe đột xuất         |
| `BusAtt.SystemConfig`                    | Xem cấu hình                |
| `BusAtt.SystemConfig.Edit`               | Sửa cấu hình                |

---

## 1. Điểm đón/trả (Location)

### Danh sách điểm đón/trả

```
GET /api/services/app/BusAtt/GetAllLocations
```

**Query params:**

| Param | Type | Mô tả |
|---|---|---|
| `Filter` | string | Tìm theo tên |
| `Sorting` | string | Sắp xếp (VD: `Name ASC`) |
| `SkipCount` | int | Phân trang — bỏ qua N bản ghi |
| `MaxResultCount` | int | Phân trang — số bản ghi tối đa |

**Response:**
```json
{
  "totalCount": 5,
  "items": [
    {
      "location": {
        "id": 1,
        "name": "Cổng chính KDT",
        "lat": 20.969106,
        "lng": 105.869754
      }
    }
  ]
}
```

### Tạo/Sửa điểm đón

```
POST /api/services/app/BusAtt/CreateOrEditLocation
```

**Permission:** `BusAtt.Location.Create` hoặc `BusAtt.Location.Edit`

**Request Body:**
```json
{
  "id": null,
  "name": "Cổng chính KDT",
  "lat": 20.969106,
  "lng": 105.869754
}
```

> `id = null` → tạo mới, `id = N` → cập nhật

### Xóa điểm đón

```
POST /api/services/app/BusAtt/DeleteLocation
```

**Permission:** `BusAtt.Location.Delete`

**Request Body:**
```json
{ "id": 1 }
```

### Dropdown điểm đón

```
GET /api/services/app/BusAtt/GetAllLocationDropDown?current={id}
```

**Response:** `[{ "value": "1", "text": "Cổng chính KDT", "selected": true }]`

---

## 2. Tuyến xe (Route)

### Danh sách tuyến xe

```
GET /api/services/app/BusAtt/GetAllRoutes
```

**Query params:** `Filter`, `Sorting`, `SkipCount`, `MaxResultCount`

**Response:**
```json
{
  "totalCount": 3,
  "items": [
    {
      "route": {
        "id": 1,
        "routeCode": "R001",
        "routeName": "90 KDT - 47 PVD",
        "goStartTime": "07:00",
        "goEndTime": "07:30",
        "pickupLocationId": 1,
        "pickupLocationName": "Cổng chính KDT",
        "dropoffLocationId": 2,
        "dropoffLocationName": "47 Phạm Văn Đồng",
        "status": "active"
      }
    }
  ]
}
```

### Tạo/Sửa tuyến xe

```
POST /api/services/app/BusAtt/CreateOrEditRoute
```

**Permission:** `BusAtt.Route.Create` hoặc `BusAtt.Route.Edit`

**Request Body:**
```json
{
  "id": null,
  "routeCode": "R001",
  "routeName": "90 KDT - 47 PVD",
  "goStartTime": "07:00",
  "goEndTime": "07:30",
  "pickupLocationId": 1,
  "dropoffLocationId": 2,
  "status": "active"
}
```

### Xóa tuyến xe

```
POST /api/services/app/BusAtt/DeleteRoute
```

**Request Body:** `{ "id": 1 }`

---

## 3. Xe buýt (Bus)

### Danh sách xe

```
GET /api/services/app/BusAtt/GetAllBuses
```

**Query params:** `Filter`, `Sorting`, `SkipCount`, `MaxResultCount`

> **Lưu ý:** Tài xế chỉ thấy xe được gán cho mình. Admin thấy tất cả.

**Response:**
```json
{
  "totalCount": 2,
  "items": [
    {
      "bus": {
        "id": 1,
        "busCode": "BUS001",
        "busName": "Xe 45 chỗ",
        "licensePlate": "80A-06537",
        "employeeId": 5,
        "driverName": "Nguyễn Văn Tài",
        "status": "active",
        "activeRouteId": 1,
        "activeRouteName": "90 KDT - 47 PVD"
      }
    }
  ]
}
```

### Tạo/Sửa xe

```
POST /api/services/app/BusAtt/CreateOrEditBus
```

**Permission:** `BusAtt.Bus.Create` hoặc `BusAtt.Bus.Edit`

**Request Body:**
```json
{
  "id": null,
  "busCode": "BUS001",
  "busName": "Xe 45 chỗ",
  "licensePlate": "80A-06537",
  "employeeId": 5,
  "status": "active"
}
```

### Xóa xe

```
POST /api/services/app/BusAtt/DeleteBus
```

**Request Body:** `{ "id": 1 }`

### Dropdown tài xế

```
GET /api/services/app/BusAtt/GetAllEmployeeForDriverDropDown?current={id}
```

**Response:** `[{ "value": "5", "text": "NVT - Nguyễn Văn Tài", "selected": true }]`

---

## 4. Mã QR (QR Code)

### Tạo mã QR cho xe

```
POST /api/services/app/BusAtt/GenerateQRCode?busId={id}
```

**Permission:** `BusAtt.QRCode.Create`

**Response:**
```json
{
  "qrId": 1,
  "qrToken": "abc123def456...",
  "qrImageUrl": "/uploads/qrcodes/BUS001_abc123.png"
}
```

### Cấp lại mã QR

```
POST /api/services/app/BusAtt/ReissueQRCode?busId={id}
```

**Permission:** `BusAtt.QRCode.Create`

> Vô hiệu mã QR cũ, tạo mã mới.

### Xem mã QR đang hoạt động

```
GET /api/services/app/BusAtt/GetActiveQRCode?busId={id}
```

**Response:**
```json
{
  "id": 1,
  "busId": 1,
  "qrToken": "abc123...",
  "qrImageUrl": "/uploads/qrcodes/BUS001_abc123.png",
  "isActive": true,
  "createdAt": "2026-04-20T10:00:00"
}
```

### Lịch sử mã QR

```
GET /api/services/app/BusAtt/GetQRCodeHistory?busId={id}
```

**Response:** `List<BusQRCodeDto>`

---

## 5. Gán tuyến cho xe

### Gán tuyến

```
POST /api/services/app/BusAtt/AssignRouteToBus?busId={busId}&routeId={routeId}
```

**Permission:** `BusAtt.Bus.Edit`

### Bỏ gán tuyến

```
POST /api/services/app/BusAtt/UnassignRouteFromBus?busId={busId}
```

**Permission:** `BusAtt.Bus.Edit`

---

## 6. Đăng ký tuyến xe

### Danh sách đăng ký

```
GET /api/services/app/BusAtt/GetAllRegistrations
```

**Query params:**

| Param | Type | Mô tả |
|---|---|---|
| `RideDate` | DateTime? | Lọc theo ngày đi |
| `Filter` | string | Tìm kiếm |
| `Sorting` | string | Sắp xếp |
| `SkipCount` | int | Phân trang |
| `MaxResultCount` | int | Phân trang |

> User thường chỉ thấy đăng ký của mình. Admin thấy tất cả.

### Tạo/Sửa đăng ký

```
POST /api/services/app/BusAtt/CreateOrEditRegistration
```

**Request Body:**
```json
{
  "id": null,
  "userId": 10,
  "routeId": 1,
  "rideDate": "2026-05-05",
  "status": "active"
}
```

**Validation:**
- `rideDate` phải là ngày trong tương lai
- Không được trùng (cùng user + route + date)

### Đăng ký hàng loạt

```
POST /api/services/app/BusAtt/BatchRegister
```

**Request Body:**
```json
{
  "userId": 10,
  "routeId": 1,
  "batchType": 1,
  "note": ""
}
```

| `batchType` | Mô tả |
|---|---|
| 1 | Đăng ký cả tuần (thứ 2 → thứ 6) |
| 2 | Đăng ký cả tháng |

**Response:**
```json
{
  "totalDays": 22,
  "createdCount": 20,
  "skippedCount": 2,
  "createdDates": ["2026-05-05", "2026-05-06"],
  "skippedReasons": ["2026-05-01: Ngày nghỉ"]
}
```

### Hủy đăng ký

```
POST /api/services/app/BusAtt/CancelRegistration
```

**Request Body:** `{ "id": 1 }`

### Dropdown nhân viên

```
GET /api/services/app/BusAtt/GetAllEmployeeDropDown?current={id}
```

---

## 7. Chấm công

### Xác thực mã QR

```
POST /api/services/app/BusAtt/ValidateQRToken?token={qrToken}
```

**Auth:** Không yêu cầu (public — dùng cho mobile)

**Response:**
```json
{
  "busId": 1,
  "busCode": "BUS001",
  "busName": "Xe 45 chỗ",
  "licensePlate": "80A-06537",
  "routeId": 1,
  "routeCode": "R001",
  "routeName": "90 KDT - 47 PVD",
  "goStartTime": "07:00",
  "goEndTime": "07:30",
  "pickupLocationName": "Cổng chính KDT",
  "pickupLat": 20.969106,
  "pickupLng": 105.869754,
  "gpsThresholdMeter": 150,
  "requireGps": true,
  "requireSelfie": true
}
```

### Upload selfie

```
POST /api/services/app/BusAtt/UploadSelfie
```

**Auth:** Yêu cầu đăng nhập  
**Request:** `multipart/form-data` với file ảnh (JPG/PNG/WEBP, tối đa 5MB)

**Response:**
```json
{ "selfieUrl": "/uploads/selfies/2026-05-04/abc123.jpg" }
```

### Gửi chấm công

```
POST /api/services/app/BusAtt/SubmitAttendance
```

**Auth:** Yêu cầu đăng nhập

**Request Body:**
```json
{
  "qrToken": "abc123...",
  "gpsLat": 20.969106,
  "gpsLng": 105.869754,
  "gpsAccuracy": 13.5,
  "selfieUrl": "/uploads/selfies/2026-05-04/abc.jpg"
}
```

**Response (thành công):**
```json
{
  "result": "success",
  "message": "Chấm công thành công!",
  "employee": "Trịnh Ngọc Tú",
  "busCode": "BUS001",
  "routeName": "90 KDT - 47 PVD",
  "checkinTime": "07:15:30",
  "date": "2026-05-04",
  "distanceM": 45
}
```

**Response (từ chối):**
```json
{
  "result": "rejected",
  "message": "Quá xa điểm đón (2300m > 150m)"
}
```

**Các lý do từ chối:**

| Lý do                | Mô tả                                              |
|----------------------|----------------------------------------------------|
| QR không hợp lệ      | Token sai hoặc đã bị vô hiệu                       |
| Xe không hoạt động   | Xe đã bị disable                                   |
| Xe chưa gán tuyến    | Chưa có BusRouteAssignment active                  |
| Ngoài giờ chấm công  | Thời gian hiện tại ngoài `goStartTime → goEndTime` |
| Đã chấm công hôm nay | Trùng user + route + date                          |
| Quá xa điểm đón      | Khoảng cách GPS > threshold                        |

### Lịch sử chấm công

```
GET /api/services/app/BusAtt/GetAllAttendanceLogs
```

**Permission:** `BusAtt.Attendance`

**Query params:** `AttendanceDate`, `Filter`, `Sorting`, `SkipCount`, `MaxResultCount`

---

## 8. Yêu cầu xe đột xuất

### Tạo yêu cầu

```
POST /api/services/app/BusAtt/CreateUrgentRequest
```

**Request Body:**
```json
{
  "requestedDate": "2026-05-10",
  "requestedTime": "14:00",
  "reason": "Họp đối tác tại chi nhánh 2"
}
```

> Tự động gửi thông báo tới tất cả Bus_Admin.

### Danh sách yêu cầu

```
GET /api/services/app/BusAtt/GetAllUrgentRequests
```

**Query params:** `StatusFilter`, `FromDate`, `ToDate`, `Sorting`, `SkipCount`, `MaxResultCount`

> Bus_Admin thấy tất cả. User thường chỉ thấy yêu cầu của mình.

### Duyệt yêu cầu

```
POST /api/services/app/BusAtt/ApproveUrgentRequest
```

**Permission:** Bus_Admin

**Request Body:**
```json
{
  "requestId": 1,
  "busId": 2
}
```

### Từ chối yêu cầu

```
POST /api/services/app/BusAtt/RejectUrgentRequest
```

**Permission:** Bus_Admin

**Request Body:**
```json
{
  "requestId": 1,
  "rejectionReason": "Không có xe trống"
}
```

---

## 9. Cấu hình hệ thống

### Xem cấu hình

```
GET /api/services/app/BusAtt/GetSystemConfig
```

**Permission:** `BusAtt.SystemConfig`

**Response:**
```json
{
  "nearStopThresholdMeter": 150,
  "requireGPS": true,
  "requireSelfie": true,
  "busExcludedDays": "0,6",
  "mealExcludedDays": "0,6"
}
```

| Field                    | Mô tả                                 |
| --------------------------| ---------------------------------------|
| `nearStopThresholdMeter` | Khoảng cách tối đa tới điểm đón (mét) |
| `requireGPS`             | Bắt buộc GPS khi chấm công            |
| `requireSelfie`          | Bắt buộc selfie khi chấm công         |
| `busExcludedDays`        | Ngày nghỉ xe (0=CN, 6=T7)             |
| `mealExcludedDays`       | Ngày nghỉ suất ăn                     |

### Lưu cấu hình

```
POST /api/services/app/BusAtt/SaveSystemConfig
```

**Permission:** `BusAtt.SystemConfig.Edit`

**Request Body:** (cùng format với response ở trên)

---

## Ghi chú chung

### Format lỗi (ABP Standard)

```json
{
  "error": {
    "code": 0,
    "message": "Mô tả lỗi bằng tiếng Việt",
    "details": null
  }
}
```

### Phân trang

- `SkipCount` (default: 0) — số bản ghi bỏ qua
- `MaxResultCount` (default: 10) — số bản ghi tối đa
- `Sorting` — chuỗi sắp xếp (VD: `"Name ASC"`, `"CreatedAt DESC"`)
