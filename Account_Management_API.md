# 🔐 Account Management API

> **Dự án:** Bus Attendance System (Z103 — ASP.NET Core + ABP Framework)  
> **Cập nhật:** 04/05/2026  
> **Base URL:** `https://{domain}`

---

## Mục lục

1. [Tổng quan xác thực](#1-tổng-quan-xác-thực)
2. [Đăng nhập — JWT Token (Mobile)](#2-đăng-nhập--jwt-token-mobile)
3. [Làm mới Token (Refresh)](#3-làm-mới-token-refresh)
4. [Lấy thông tin User hiện tại](#4-lấy-thông-tin-user-hiện-tại)
5. [Đăng nhập — Cookie (Web)](#5-đăng-nhập--cookie-web)
6. [Đăng ký tài khoản](#6-đăng-ký-tài-khoản)
7. [Lấy thông tin nhân viên (cho form đăng ký)](#7-lấy-thông-tin-nhân-viên-cho-form-đăng-ký)
8. [Đăng xuất (Web)](#8-đăng-xuất-web)
9. [Mã lỗi](#9-mã-lỗi)

---

## 1. Tổng quan xác thực

Hệ thống hỗ trợ **2 phương thức xác thực**:

| Phương thức | Dùng cho | Cơ chế |
|---|---|---|
| **JWT Bearer Token** | Mobile app, API client | Gửi header `Authorization: Bearer {accessToken}` |
| **Cookie** | Web browser | Tự động qua cookie sau khi login |

### JWT Token Flow

```
Mobile App                          Server
    │                                  │
    ├── POST /api/TokenAuth/Authenticate ──►│ Trả về accessToken + refreshToken
    │                                  │
    ├── GET /api/... (Bearer token) ───►│ Xử lý request
    │                                  │
    ├── (Token hết hạn)                 │
    ├── POST /api/TokenAuth/RefreshToken ──►│ Trả về accessToken mới
    │                                  │
```

---

## 2. Đăng nhập — JWT Token (Mobile)

```
POST /api/TokenAuth/Authenticate
```

**Auth:** Không yêu cầu (public)  
**Content-Type:** `application/json`

### Request Body

```json
{
  "userNameOrEmailAddress": "admin@company.com",
  "password": "123456",
  "tenancyName": "Default"
}
```

| Field                    | Type   | Required | Mô tả                              |
| --------------------------| --------| ----------| ------------------------------------|
| `userNameOrEmailAddress` | string | ✅        | Email hoặc username                |
| `password`               | string | ✅        | Mật khẩu                           |
| `tenancyName`            | string | ❌        | Tên tenant (mặc định: `"Default"`) |

### Response — Thành công (200)

```json
{
  "result": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expireInSeconds": 86400,
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "userId": 1,
    "fullName": "Trịnh Ngọc Tú",
    "email": "admin@company.com",
    "role": "admin"
  },
  "success": true
}
```

| Field | Type | Mô tả |
|---|---|---|
| `accessToken` | string | JWT access token — dùng cho các API request |
| `expireInSeconds` | int | Thời gian hết hạn (86400 = 24 giờ) |
| `refreshToken` | string | Refresh token — dùng để lấy access token mới |
| `userId` | long | ID người dùng |
| `fullName` | string | Họ tên đầy đủ (từ Employee) |
| `email` | string | Email |
| `role` | string | Vai trò: `admin`, `user`, `driver`... |

### Response — Lỗi

```json
{
  "error": {
    "code": 0,
    "message": "Sai tài khoản hoặc mật khẩu",
    "details": null
  },
  "success": false
}
```

| Thông báo lỗi | Nguyên nhân |
|---|---|
| `Sai tài khoản hoặc mật khẩu` | Email/password sai |
| `Tài khoản chưa được kích hoạt. Vui lòng chờ admin phê duyệt.` | Tài khoản mới, chưa được admin duyệt |
| `Tenant không hợp lệ` | TenancyName sai |
| `Tenant đã bị vô hiệu` | Tenant bị disable |
| `Tài khoản đã bị khóa tạm thời` | Nhập sai mật khẩu quá nhiều lần |

### Cách sử dụng Access Token

Sau khi login, gửi token trong header cho mọi API request:

```
GET /api/services/app/BusAtt/GetAllBuses
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 3. Làm mới Token (Refresh)

```
POST /api/TokenAuth/RefreshToken
```

**Auth:** Không yêu cầu (public)  
**Content-Type:** `application/json`

> Gọi khi access token hết hạn. Refresh token có thời hạn **30 ngày**.

### Request Body

```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Response — Thành công (200)

```json
{
  "result": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...(mới)",
    "expireInSeconds": 86400,
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...(mới)"
  },
  "success": true
}
```

> **Lưu ý:** Mỗi lần refresh sẽ trả về **cả access token và refresh token mới**. Client cần lưu lại cả hai.

### Response — Lỗi

| Thông báo lỗi | Nguyên nhân |
|---|---|
| `Refresh token không được để trống` | Không gửi refresh token |
| `Refresh token không hợp lệ hoặc đã hết hạn` | Token sai hoặc quá 30 ngày |
| `Tài khoản không tồn tại hoặc đã bị vô hiệu` | User bị xóa/disable sau khi cấp token |

---

## 4. Lấy thông tin User hiện tại

```
GET /api/TokenAuth/GetCurrentUser
```

**Auth:** ✅ Yêu cầu Bearer Token

### Response — Thành công (200)

```json
{
  "result": {
    "userId": 1,
    "email": "admin@company.com",
    "fullName": "Trịnh Ngọc Tú",
    "employeeCode": "TNT",
    "department": "",
    "role": "admin",
    "isActive": true,
    "tenantId": 1
  },
  "success": true
}
```

| Field | Type | Mô tả |
|---|---|---|
| `userId` | long | ID người dùng |
| `email` | string | Email |
| `fullName` | string | Họ tên đầy đủ |
| `employeeCode` | string | Mã viết tắt nhân viên (VD: `TNT`) |
| `department` | string | Phòng ban |
| `role` | string | Vai trò |
| `isActive` | bool | Trạng thái kích hoạt |
| `tenantId` | int? | ID tenant |

---

## 5. Đăng nhập — Cookie (Web)

```
POST /Account/Login
```

**Auth:** Không yêu cầu  
**Content-Type:** `application/x-www-form-urlencoded`

> Dùng cho web browser. Sau khi login thành công, server set cookie xác thực.

### Request Body (form-data)

| Field | Type | Required | Mô tả |
|---|---|---|---|
| `UsernameOrEmailAddress` | string | ✅ | Email hoặc username |
| `Password` | string | ✅ | Mật khẩu |
| `RememberMe` | bool | ❌ | Ghi nhớ đăng nhập |

### Response

- **Thành công:** Redirect tới `/App` (dashboard)
- **Thất bại:** Hiển thị lại trang login với thông báo lỗi

---

## 6. Đăng ký tài khoản

```
POST /Account/Register
```

**Auth:** Không yêu cầu (public, nhưng cần bật Self Registration)  
**Content-Type:** `application/x-www-form-urlencoded`

> Tài khoản sau khi đăng ký sẽ ở trạng thái **inactive** cho đến khi admin phê duyệt.

### Điều kiện tiên quyết

- Admin đã tạo sẵn nhân viên trong `Dms_Employee` (với mã viết tắt, phòng ban, vai trò)
- Nhân viên chưa được liên kết với tài khoản nào (`UserId == null`)

### Request Body (form-data)

| Field | Type | Required | Mô tả |
|---|---|---|---|
| `EmployeeId` | int | ✅ | ID nhân viên (chọn từ dropdown) |
| `EmailAddress` | string | ✅ | Email đăng nhập |
| `Password` | string | ✅ | Mật khẩu |
| `PasswordRepeat` | string | ✅ | Nhập lại mật khẩu |

### Response

- **Thành công:** Hiển thị trang kết quả đăng ký
  ```
  RegisterResultViewModel {
    TenancyName: "Default",
    NameAndSurname: "Trịnh Ngọc Tú",
    UserName: "admin@company.com",
    EmailAddress: "admin@company.com",
    IsActive: false
  }
  ```
- **Thất bại:** Hiển thị lại form với thông báo lỗi

### Logic xử lý

1. Kiểm tra Employee tồn tại và chưa liên kết (`UserId == null`)
2. Tạo User với `IsActive = false` (chờ admin duyệt)
3. Liên kết Employee → User (`employee.UserId = user.Id`)
4. Gán email vào Employee
5. `ShortName` tự lấy từ `Employee.Code` (mã viết tắt)
6. Gán vai trò từ `Employee.RoleId` (admin đã chọn trước khi tạo nhân viên)

### Lỗi có thể gặp

| Thông báo | Nguyên nhân |
|---|---|
| `Vui lòng chọn nhân viên` | Không chọn EmployeeId |
| `Nhân viên không tồn tại hoặc đã được đăng ký` | Employee đã liên kết user khác |
| `Email đã tồn tại` | Email trùng |

---

## 7. Lấy thông tin nhân viên (cho form đăng ký)

```
GET /Account/GetEmployeeInfo?employeeId={id}
```

**Auth:** Không yêu cầu

> Gọi khi người dùng chọn nhân viên từ dropdown đăng ký. Trả về họ tên và phòng ban để auto-fill vào form.

### Query Parameters

| Param | Type | Required | Mô tả |
|---|---|---|---|
| `employeeId` | int | ✅ | ID nhân viên |

### Response — Thành công (200)

```json
{
  "result": {
    "id": 1,
    "fullName": "Trịnh Ngọc Tú",
    "code": "TNT",
    "workDepartmentName": "Phòng Kỹ thuật"
  }
}
```

| Field | Type | Mô tả |
|---|---|---|
| `id` | int | ID nhân viên |
| `fullName` | string | Họ tên đầy đủ |
| `code` | string | Mã viết tắt (VD: `TNT`, `TNT2`) |
| `workDepartmentName` | string | Tên phòng ban |

### Response — Không tìm thấy

```json
{
  "result": null
}
```

---

## 8. Đăng xuất (Web)

```
GET /Account/Logout
```

**Auth:** Yêu cầu đăng nhập (cookie)

**Response:** Redirect về trang Login

> **Lưu ý cho Mobile:** JWT token không có endpoint logout riêng. Client chỉ cần xóa token khỏi local storage. Token sẽ tự hết hạn sau 24 giờ.

---

## 9. Mã lỗi

### Format lỗi chung (ABP Standard)

```json
{
  "error": {
    "code": 0,
    "message": "Mô tả lỗi bằng tiếng Việt",
    "details": null,
    "validationErrors": null
  },
  "success": false
}
```

### Bảng mã lỗi đăng nhập

| Mã | Mô tả |
|---|---|
| `InvalidUserNameOrEmailAddress` | Email/username không tồn tại |
| `InvalidPassword` | Sai mật khẩu |
| `UserIsNotActive` | Tài khoản chưa kích hoạt (chờ admin duyệt) |
| `InvalidTenancyName` | Tenant không hợp lệ |
| `TenantIsNotActive` | Tenant bị vô hiệu |
| `UserEmailIsNotConfirmed` | Email chưa xác nhận |
| `LockedOut` | Tài khoản bị khóa tạm (nhập sai quá nhiều) |

### HTTP Status Codes

| Code | Mô tả |
|---|---|
| `200` | Thành công |
| `401` | Chưa xác thực (token thiếu hoặc hết hạn) |
| `403` | Không có quyền |
| `500` | Lỗi server (kèm `error.message` chi tiết) |

---

## Phụ lục: JWT Token Structure

### Access Token Claims

| Claim | Mô tả |
|---|---|
| `sub` (UserId) | ID người dùng |
| `unique_name` (UserName) | Username |
| `email` | Email |
| `role` | Vai trò |
| `tenantId` | ID tenant |
| `exp` | Thời điểm hết hạn (Unix timestamp) |
| `iss` | Issuer: `"Zero"` |
| `aud` | Audience: `"Zero"` |

### Refresh Token Claims

| Claim | Mô tả |
|---|---|
| `sub` (UserId) | ID người dùng |
| `token_type` | Luôn là `"refresh"` |
| `tenantId` | ID tenant |
| `exp` | Hết hạn sau 30 ngày |
| `iss` | Issuer: `"Zero"` |
| `aud` | Audience: `"ZeroRefresh"` (khác với access token) |

### Cấu hình JWT (appsettings.json)

```json
{
  "Authentication": {
    "JwtBearer": {
      "IsEnabled": "true",
      "SecurityKey": "Zero_8CFB2EC534E14D56",
      "Issuer": "Zero",
      "Audience": "Zero"
    }
  }
}
```
