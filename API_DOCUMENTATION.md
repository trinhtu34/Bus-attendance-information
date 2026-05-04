# 📋 API Documentation — Bus Attendance System (Z103)

> **Phiên bản:** 1.0  
> **Cập nhật:** 04/05/2026  
> **Framework:** ASP.NET Core + ABP Framework  
> **Base URL:** `https://{domain}`

---

## Mục lục

1. [Xác thực & Phân quyền](#1-xác-thực--phân-quyền)
2. [Đăng ký & Đăng nhập](#2-đăng-ký--đăng-nhập)
3. [Quản lý xe buýt](#3-quản-lý-xe-buýt)
   - [Điểm đón/trả (Location)](#31-điểm-đóntrả-location)
   - [Tuyến xe (Route)](#32-tuyến-xe-route)
   - [Xe buýt (Bus)](#33-xe-buýt-bus)
   - [Mã QR (QR Code)](#34-mã-qr-qr-code)
   - [Gán tuyến cho xe](#35-gán-tuyến-cho-xe)
4. [Đăng ký tuyến xe](#4-đăng-ký-tuyến-xe)
5. [Chấm công](#5-chấm-công)
6. [Quản lý suất ăn](#6-quản-lý-suất-ăn)
7. [Yêu cầu xe đột xuất](#7-yêu-cầu-xe-đột-xuất)
8. [Cấu hình hệ thống](#8-cấu-hình-hệ-thống)

---

## 1. Xác thực & Phân quyền

### Cơ chế xác thực

Hệ thống sử dụng **Cookie-based Authentication** (ABP Framework). Sau khi đăng nhập thành công, server trả về cookie xác thực, browser tự gửi kèm trong các request tiếp theo.

### Phân quyền (Permissions)

| Permission | Mô tả |
|---|---|
| `BusAtt` | Quyền gốc — truy cập module Bus Attendance |
| `BusAtt.Location` | Xem điểm đón/trả |
| `BusAtt.Location.Create/Edit/Delete` | CRUD điểm đón/trả |
| `BusAtt.Route` | Xem tuyến xe |
| `BusAtt.Route.Create/Edit/Delete` | CRUD tuyến xe |
| `BusAtt.Bus` | Xem xe buýt |
| `BusAtt.Bus.Create/Edit/Delete` | CRUD xe buýt |
| `BusAtt.QRCode` | Xem mã QR |
| `BusAtt.QRCode.Create` | Tạo/cấp lại mã QR |
| `BusAtt.Registration` | Xem đăng ký tuyến |
| `BusAtt.Registration.Register` | Tự đăng ký tuyến |
| `BusAtt.Registration.Create/Edit/Delete` | Admin quản lý đăng ký |
| `BusAtt.Attendance` | Xem log chấm công |
| `BusAtt.Attendance.Create` | Gửi chấm công |
| `Meal.MealRegistration` | Xem đăng ký suất ăn |
| `Meal.MealRegistration.Register` | Tự đăng ký suất ăn |
| `Meal.MealRegistration.Kitchen` | Xem tất cả (nhà bếp) |
| `Meal.MealRegistration.Create/Edit/Delete` | Admin quản lý suất ăn |

### Vai trò

| Vai trò | Mô tả |
|---|---|
| **Admin** | Toàn quyền quản lý |
| **Bus_Admin** | Quản lý xe, tuyến, điểm đón, duyệt yêu cầu đột xuất |
| **Driver** | Tài xế — chỉ xem xe được gán |
| **Kitchen** | Nhà bếp — xem tất cả đăng ký suất ăn |
| **User** | Nhân viên — đăng ký tuyến, chấm công, đăng ký suất ăn |

---

## 2. Đăng ký & Đăng nhập

### 2.1 Đăng ký tài khoản

```
POST /Account/Register
```

**Mô tả:** Đăng ký tài khoản mới. Tài khoản sẽ ở trạng thái **inactive** cho đến khi admin phê duyệt.

**Auth:** Không yêu cầu (public)

**Request Body** (form-data):

| Field | Type | Required | Mô tả |
|---|---|---|---|
| `EmployeeId` | int | ✅ | ID nhân viên (chọn từ dropdown) |
| `EmailAddress` | string | ✅ | Email đăng nhập |
| `Password` | string | ✅ | Mật khẩu |
| `PasswordRepeat` | string | ✅ | Nhập lại mật khẩu |

**Response:** Redirect tới trang kết quả đăng ký

**Logic xử lý:**
- Kiểm tra Employee tồn tại và chưa được liên kết (`UserId == null`)
- Tạo User với `IsActive = false` (chờ admin duyệt)
- Liên kết Employee → User (`employee.UserId = user.Id`)
- Gán vai trò từ `Employee.RoleId`
- `ShortName` tự lấy từ `Employee.Code`

---

### 2.2 Lấy thông tin nhân viên (cho form đăng ký)

```
GET /Account/GetEmployeeInfo?employeeId={id}
```

**Mô tả:** Trả về thông tin nhân viên khi chọn từ dropdown đăng ký.

**Auth:** Không yêu cầu

**Response:**
```json
{
  "id": 1,
  "fullName": "Trịnh Ngọc Tú",
  "code": "TNT",
  "workDepartmentName": "Phòng Kỹ thuật"
}
```

---

### 2.3 Đăng nhập

```
POST /Account/Login
```

**Auth:** Không yêu cầu

**Request Body** (form-data):

| Field | Type | Required | Mô tả |
|---|---|---|---|
| `UsernameOrEmailAddress` | string | ✅ | Email hoặc username |
| `Password` | string | ✅ | Mật khẩu |
| `RememberMe` | bool | ❌ | Ghi nhớ đăng nhập |

**Response:**
```json
{
  "targetUrl": "/App",
  "result": 1
}
```

**Mã lỗi `result`:**
| Giá trị | Mô tả |
|---|---|
| 1 | Thành công |
| 2 | Tài khoản chưa kích hoạt |
| 3 | Sai mật khẩu |
| 4 | Tài khoản bị khóa |

---

### 2.4 Đăng xuất

```
GET /Account/Logout
```

**Auth:** Yêu cầu đăng nhập

**Response:** Redirect về trang Login

---

## 3. Quản lý xe buýt

> **Base path:** `/api/services/app/BusAtt/`  
> **Auth:** Yêu cầu permission `BusAtt`

### 3.1 Điểm đón/trả (Location)

#### Danh sách điểm đón/trả

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

#### Tạo/Sửa điểm đón

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

#### Xóa điểm đón

```
POST /api/services/app/BusAtt/DeleteLocation
```

**Permission:** `BusAtt.Location.Delete`

**Request Body:**
```json
{ "id": 1 }
```

#### Dropdown điểm đón

```
GET /api/services/app/BusAtt/GetAllLocationDropDown?current={id}
```

**Response:** `[{ "value": "1", "text": "Cổng chính KDT", "selected": true }]`

---

### 3.2 Tuyến xe (Route)

#### Danh sách tuyến xe

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

#### Tạo/Sửa tuyến xe

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

#### Xóa tuyến xe

```
POST /api/services/app/BusAtt/DeleteRoute
```

**Request Body:** `{ "id": 1 }`

---

### 3.3 Xe buýt (Bus)

#### Danh sách xe

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

#### Tạo/Sửa xe

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

#### Xóa xe

```
POST /api/services/app/BusAtt/DeleteBus
```

**Request Body:** `{ "id": 1 }`

---

### 3.4 Mã QR (QR Code)

#### Tạo mã QR cho xe

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

#### Cấp lại mã QR

```
POST /api/services/app/BusAtt/ReissueQRCode?busId={id}
```

**Permission:** `BusAtt.QRCode.Create`

> Vô hiệu mã QR cũ, tạo mã mới.

#### Xem mã QR đang hoạt động

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

#### Lịch sử mã QR

```
GET /api/services/app/BusAtt/GetQRCodeHistory?busId={id}
```

**Response:** `List<BusQRCodeDto>`

---

### 3.5 Gán tuyến cho xe

#### Gán tuyến

```
POST /api/services/app/BusAtt/AssignRouteToBus?busId={busId}&routeId={routeId}
```

**Permission:** `BusAtt.Bus.Edit`

#### Bỏ gán tuyến

```
POST /api/services/app/BusAtt/UnassignRouteFromBus?busId={busId}
```

**Permission:** `BusAtt.Bus.Edit`

---

## 4. Đăng ký tuyến xe

#### Danh sách đăng ký

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

#### Tạo/Sửa đăng ký

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

#### Đăng ký hàng loạt

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
  "createdDates": ["2026-05-05", "2026-05-06", ...],
  "skippedReasons": ["2026-05-01: Ngày nghỉ", ...]
}
```

#### Hủy đăng ký

```
POST /api/services/app/BusAtt/CancelRegistration
```

**Request Body:** `{ "id": 1 }`

---

## 5. Chấm công

#### Xác thực mã QR

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

#### Gửi chấm công

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
| Lý do | Mô tả |
|---|---|
| QR không hợp lệ | Token sai hoặc đã bị vô hiệu |
| Xe không hoạt động | Xe đã bị disable |
| Xe chưa gán tuyến | Chưa có BusRouteAssignment active |
| Ngoài giờ chấm công | Thời gian hiện tại ngoài `goStartTime → goEndTime` |
| Đã chấm công hôm nay | Trùng user + route + date |
| Quá xa điểm đón | Khoảng cách GPS > threshold |

#### Upload selfie

```
POST /api/services/app/BusAtt/UploadSelfie
```

**Auth:** Yêu cầu đăng nhập

**Request:** `multipart/form-data` với file ảnh (JPG/PNG/WEBP, tối đa 5MB)

**Response:**
```json
{
  "selfieUrl": "/uploads/selfies/2026-05-04/abc123.jpg"
}
```

#### Lịch sử chấm công

```
GET /api/services/app/BusAtt/GetAllAttendanceLogs
```

**Permission:** `BusAtt.Attendance`

**Query params:** `AttendanceDate`, `Filter`, `Sorting`, `SkipCount`, `MaxResultCount`

---

## 6. Quản lý suất ăn

> **Base path:** `/api/services/app/Meals/`  
> **Auth:** Yêu cầu permission `Meal`

#### Danh sách đăng ký suất ăn

```
GET /api/services/app/Meals/GetAllMealRegistrations
```

**Query params:**

| Param | Type | Mô tả |
|---|---|---|
| `MealDate` | DateTime? | Lọc theo ngày |
| `Filter` | string | Tìm kiếm |
| `Sorting` | string | Sắp xếp |
| `SkipCount` | int | Phân trang |
| `MaxResultCount` | int | Phân trang |

> **Kitchen/View** thấy tất cả. **Register** chỉ thấy của mình.

**Response:**
```json
{
  "totalCount": 15,
  "items": [
    {
      "mealRegistration": {
        "id": 1,
        "userId": 10,
        "fullName": "Trịnh Ngọc Tú",
        "email": "tu@company.com",
        "department": "Phòng Kỹ thuật",
        "mealDate": "2026-05-05",
        "quantity": 1,
        "note": "",
        "status": "registered",
        "createdAt": "2026-05-04T08:30:00"
      }
    }
  ]
}
```

#### Đăng ký suất ăn

```
POST /api/services/app/Meals/CreateOrEditMealRegistration
```

**Request Body:**
```json
{
  "id": null,
  "userId": 10,
  "mealDate": "2026-05-05",
  "quantity": 1,
  "note": "Không cay",
  "status": "registered"
}
```

**Validation:**
- Chỉ đăng ký trong khung giờ **8h → 19h**
- `mealDate` phải là ngày trong tương lai
- Không được trùng (cùng user + date)

#### Đăng ký suất ăn hàng loạt

```
POST /api/services/app/Meals/BatchMealRegister
```

**Request Body:**
```json
{
  "userId": 10,
  "batchType": 1,
  "note": ""
}
```

| `batchType` | Mô tả |
|---|---|
| 1 | Đăng ký cả tuần |
| 2 | Đăng ký cả tháng |

**Response:**
```json
{
  "totalDays": 22,
  "createdCount": 20,
  "skippedCount": 2,
  "createdDates": ["2026-05-05", ...],
  "skippedReasons": ["2026-05-01: Ngày nghỉ"]
}
```

> Tự bỏ qua các ngày trong `SystemConfig.MealExcludedDays`

#### Hủy đăng ký suất ăn

```
POST /api/services/app/Meals/CancelMealRegistration
```

**Request Body:** `{ "id": 1 }`

#### Xóa đăng ký suất ăn

```
POST /api/services/app/Meals/DeleteMealRegistration
```

**Permission:** `Meal.MealRegistration.Delete`

**Request Body:** `{ "id": 1 }`

---

## 7. Yêu cầu xe đột xuất

#### Tạo yêu cầu

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

#### Danh sách yêu cầu

```
GET /api/services/app/BusAtt/GetAllUrgentRequests
```

**Query params:** `StatusFilter`, `FromDate`, `ToDate`, `Sorting`, `SkipCount`, `MaxResultCount`

> Bus_Admin thấy tất cả. User thường chỉ thấy yêu cầu của mình.

#### Duyệt yêu cầu

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

#### Từ chối yêu cầu

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

## 8. Cấu hình hệ thống

#### Xem cấu hình

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

| Field | Mô tả |
|---|---|
| `nearStopThresholdMeter` | Khoảng cách tối đa tới điểm đón (mét) |
| `requireGPS` | Bắt buộc GPS khi chấm công |
| `requireSelfie` | Bắt buộc selfie khi chấm công |
| `busExcludedDays` | Ngày nghỉ xe (0=CN, 6=T7) |
| `mealExcludedDays` | Ngày nghỉ suất ăn |

#### Lưu cấu hình

```
POST /api/services/app/BusAtt/SaveSystemConfig
```

**Permission:** `BusAtt.SystemConfig.Edit`

**Request Body:** (cùng format với response ở trên)

---

## Ghi chú chung

### Format lỗi

Tất cả lỗi trả về dạng ABP standard:
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

Tất cả API danh sách hỗ trợ phân trang ABP:
- `SkipCount` (default: 0) — số bản ghi bỏ qua
- `MaxResultCount` (default: 10) — số bản ghi tối đa
- `Sorting` — chuỗi sắp xếp (VD: `"Name ASC"`, `"CreatedAt DESC"`)

### Multi-tenancy

Tất cả dữ liệu được cách ly theo `TenantId`. Tenant được xác định qua subdomain hoặc cookie `abp.tenantid`.
