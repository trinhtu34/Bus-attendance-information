# Hướng dẫn tích hợp API cho Mobile App

> Base URL: `https://blogscloud.click/api`

---

## 1. Xác thực (Authentication)

Mobile app sử dụng **Bearer Token** cho access token và gửi refresh token trong request body.

### Luồng xác thực

```
1. Login → nhận access_token + refresh_token trong response body
2. Lưu cả 2 token vào SecureStorage
3. Mọi request sau → gửi header: Authorization: Bearer <access_token>
4. Khi nhận 401 → gọi POST /api/auth/refresh với refresh_token → nhận token pair mới
5. Nếu refresh thất bại → chuyển về màn hình login
6. Logout → gọi POST /api/auth/logout với refresh_token → xóa token khỏi bộ nhớ
```

### Login

```
POST /api/auth/login
Content-Type: application/json

{
  "email": "nva@gmail.com",
  "password": "matkhau123"
}
```

**Response 200:**
```json
{
  "user_id": 5,
  "email": "nva@gmail.com",
  "full_name": "Nguyễn Văn A",
  "role": "user",
  "status": "approved",
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "a1b2c3d4e5f6..."
}
```

**Lưu ý:**
- Lưu cả `access_token` và `refresh_token` vào **SecureStorage** (Flutter), **Keychain** (iOS), hoặc **EncryptedSharedPreferences** (Android)
- Access token hết hạn sau **30 phút**
- Refresh token hết hạn sau **7 ngày**
- Khi nhận HTTP 401 → gọi refresh endpoint trước, chỉ chuyển về login khi refresh cũng thất bại

**Lỗi:**
- `401` — Sai email/mật khẩu
- `403` — Tài khoản chưa duyệt / bị vô hiệu

### Refresh Token — Làm mới access token

Khi access token hết hạn (nhận HTTP 401), gọi endpoint này để lấy token pair mới mà không cần đăng nhập lại.

```
POST /api/auth/refresh
Content-Type: application/json

{
  "refresh_token": "a1b2c3d4e5f6..."
}
```

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "f6e5d4c3b2a1..."
}
```

**Quan trọng:**
- Sau khi refresh, **phải cập nhật cả 2 token** trong SecureStorage (token rotation — token cũ bị thu hồi)
- Nếu refresh thất bại (401) → chuyển về màn hình login
- **Không dùng lại refresh token cũ** sau khi đã refresh — server sẽ phát hiện token reuse và thu hồi toàn bộ phiên

**Lỗi:**
- `401` — Refresh token không hợp lệ / đã hết hạn / bị thu hồi

### Gửi request có xác thực

Mọi API yêu cầu đăng nhập đều cần header:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

**Ví dụ lấy thông tin user:**
```
GET /api/auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

### Logout

Gọi API logout với refresh token để thu hồi phiên trên server, sau đó xóa token khỏi bộ nhớ.

```
POST /api/auth/logout
Content-Type: application/json

{
  "refresh_token": "a1b2c3d4e5f6..."
}
```

**Response 200:**
```json
{ "message": "Đã đăng xuất" }
```

**Lưu ý:** Sau khi gọi logout, xóa cả `access_token` và `refresh_token` khỏi SecureStorage.

### Xử lý 401 — Recommended Flow

```
Nhận HTTP 401 từ bất kỳ API nào
  ├── Có refresh_token trong storage?
  │     ├── Có → Gọi POST /api/auth/refresh
  │     │         ├── 200 → Lưu token mới, retry request gốc
  │     │         └── 401 → Xóa token, chuyển về login
  │     └── Không → Chuyển về login
```

---

## 2. Đăng ký tài khoản

### Bước 1: Lấy danh sách tên nhân viên

```
GET /api/employee-names
```

**Auth**: Không cần

**Response 200:**
```json
[
  { "id": 1, "employee_code": "NNC", "full_name": "Nguyễn Ngọc Cương" },
  { "id": 2, "employee_code": "0083", "full_name": "Nguyễn Thành Vinh" },
  { "id": 3, "employee_code": "", "full_name": "Trần Thị B" }
]
```

**Lưu ý:**
- Chỉ trả tên active và chưa có user nào sử dụng. Dùng cho dropdown chọn tên khi đăng ký.
- `employee_code` có thể rỗng `""` nếu admin chưa nhập mã NV.
- Hiển thị dropdown: `"NNC — Nguyễn Ngọc Cương"` hoặc chỉ tên nếu code rỗng.

### Bước 2: Gửi đăng ký

```
POST /api/auth/register
Content-Type: application/json

{
  "email": "nva@gmail.com",
  "password": "matkhau123",
  "employee_name_id": 1,
  "department": "Phòng Kỹ thuật"
}
```

**Bắt buộc:** email, password, employee_name_id. `department` optional.

**Response 201:**
```json
{
  "message": "Đăng ký thành công. Vui lòng chờ admin phê duyệt.",
  "user_id": 5
}
```

**Lưu ý:** Tài khoản mới ở trạng thái `pending`, cần admin duyệt trước khi login được.

---

## 3. Thông tin user

```
GET /api/auth/me
Authorization: Bearer <token>
```

**Response 200:**
```json
{
  "user_id": 5,
  "email": "nva@gmail.com",
  "full_name": "Nguyễn Văn A",
  "employee_name_id": 1,
  "department": "Phòng Kỹ thuật",
  "role": "user",
  "status": "approved"
}
```

---

## 4. Đăng ký tuyến xe

### Xem tuyến xe khả dụng

```
GET /api/registration/routes-available
Authorization: Bearer <token>
```

**Response 200:**
```json
[
  {
    "route_id": 1,
    "route_code": "R001",
    "route_name": "Hà Nội → Nam Định",
    "go_time": "06:30 - 08:00",
    "pickup_name": "Bến xe Giáp Bát",
    "dropoff_name": "Bến xe Nam Định"
  }
]
```

### Đăng ký tuyến

```
POST /api/registration/register
Authorization: Bearer <token>
Content-Type: application/json

{
  "route_id": 1,
  "ride_date": "2026-04-25"
}
```

**Quy tắc:**
- `ride_date` phải là ngày tương lai
- Không đăng ký trùng tuyến + ngày
- Không đăng ký 2 tuyến cùng giờ trong cùng ngày

### Xem đăng ký của tôi

```
GET /api/registration/my-dates
Authorization: Bearer <token>
```

**Response 200:**
```json
{
  "today": "2026-04-23",
  "current_time": "10:30",
  "is_within_hours": true,
  "registrations": [
    {
      "ride_date": "2026-04-25",
      "route_id": 1,
      "route_name": "Hà Nội → Nam Định",
      "route_code": "R001",
      "registration_id": 12
    }
  ]
}
```

### Hủy đăng ký

```
POST /api/registration/cancel/{registration_id}
Authorization: Bearer <token>
```

---

## 5. Chấm công (Attendance)

Luồng chấm công trên mobile:

```
1. Quét QR trên xe → lấy qr_token
2. Validate QR → lấy thông tin xe
3. Chụp selfie → upload ảnh
4. Lấy GPS → gửi chấm công
```

### Bước 1: Validate QR (không cần auth)

```
GET /api/qrcodes/validate/{qr_token}
```

**Response 200:**
```json
{
  "valid": true,
  "bus_id": 1,
  "bus_code": "BUS001",
  "bus_name": "Xe số 1",
  "license_plate": "29A-12345",
  "route": {
    "route_id": 1,
    "route_code": "R001",
    "route_name": "Hà Nội → Nam Định",
    "go_start_time": "06:30",
    "go_end_time": "08:00"
  }
}
```

### Bước 2: Upload selfie

```
POST /api/attendance/upload-selfie
Authorization: Bearer <token>
Content-Type: multipart/form-data

file: <ảnh JPG/PNG/WEBP, max 5MB>
```

**Response 200:**
```json
{
  "selfie_url": "/api/attendance/selfie-image/attendance-selfie/2026-04-23/abc123.jpg",
  "filename": "abc123.jpg"
}
```

### Bước 3: Gửi chấm công

```
POST /api/attendance/submit
Authorization: Bearer <token>
Content-Type: application/json

{
  "qr_token": "hZAFavsEn-2PmibszhnLuH9rSjNnykUh_HRQ9CuAH3I",
  "gps_lat": 21.0285,
  "gps_lng": 105.8542,
  "gps_accuracy": 15.0,
  "selfie_url": "/api/attendance/selfie-image/attendance-selfie/2026-04-23/abc123.jpg"
}
```

**Thành công:**
```json
{
  "result": "success",
  "message": "Chấm công thành công!",
  "data": {
    "employee": "Nguyễn Văn A",
    "bus": "BUS001",
    "route": "Hà Nội → Nam Định",
    "time": "07:15:30",
    "date": "2026-04-23",
    "distance_m": 45
  }
}
```

**Từ chối:**
```json
{
  "result": "rejected",
  "message": "Ngoài giờ chấm công (06:30 → 08:00). Giờ hiện tại: 09:15"
}
```

**Server kiểm tra theo thứ tự:**
1. QR token hợp lệ + active
2. Xe đang hoạt động
3. Xe có tuyến active
4. Giờ hiện tại trong khung giờ tuyến
5. Chưa chấm công hôm nay (cùng user + ngày + tuyến)
6. GPS gần điểm đón (mặc định 150m)

---

## 6. Đăng ký suất ăn

### Đăng ký

```
POST /api/meals/register
Authorization: Bearer <token>
Content-Type: application/json

{ "meal_date": "2026-04-25" }
```

**Quy tắc:**
- Khung giờ đăng ký: 8:00 → 19:00 (UTC+7)
- Deadline: trước 19:00 ngày hôm trước
- 1 user chỉ đăng ký 1 lần/ngày

### Hủy đăng ký

```
POST /api/meals/cancel
Authorization: Bearer <token>
Content-Type: application/json

{ "meal_date": "2026-04-25" }
```

### Xem ngày đã đăng ký

```
GET /api/meals/my-dates
Authorization: Bearer <token>
```

**Response 200:**
```json
{
  "today": "2026-04-23",
  "current_time": "10:30",
  "open_time": "8:00",
  "cutoff_time": "19:00",
  "is_within_hours": true,
  "registered_dates": ["2026-04-24", "2026-04-25"]
}
```

---

## 7. Xử lý lỗi

Tất cả lỗi trả về format:
```json
{ "detail": "Mô tả lỗi bằng tiếng Việt" }
```

| HTTP Status | Ý nghĩa                        | Xử lý trên mobile                            |
| -------------| --------------------------------| ----------------------------------------------|
| 400         | Dữ liệu không hợp lệ           | Hiển thị `detail` cho user                   |
| 401         | Chưa đăng nhập / token hết hạn | Gọi refresh → nếu thất bại → chuyển về login |
| 403         | Không có quyền                 | Hiển thị thông báo                           |
| 404         | Không tìm thấy                 | Hiển thị thông báo                           |
| 500         | Lỗi server                     | Hiển thị "Lỗi hệ thống, vui lòng thử lại"    |

---

## 8. Bảo mật

- Luôn gọi API qua **HTTPS**
- Lưu cả `access_token` và `refresh_token` vào **SecureStorage** (Flutter), **Keychain** (iOS), **EncryptedSharedPreferences** (Android)
- Không lưu token dạng plain text
- Khi logout, gọi `POST /api/auth/logout` với refresh token rồi xóa cả 2 token khỏi bộ nhớ
- Access token hết hạn sau **30 phút** — khi nhận 401, gọi refresh trước khi redirect về login
- Refresh token hết hạn sau **7 ngày** — khi refresh thất bại, redirect về login
- **Không dùng lại refresh token cũ** sau khi đã refresh thành công — server sẽ phát hiện token reuse và thu hồi toàn bộ phiên (bảo vệ chống token theft)
- Admin có thể thu hồi tất cả phiên của user bất kỳ lúc nào — app nên xử lý gracefully khi refresh thất bại

---
