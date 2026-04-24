# API Documentation — Bus Attendance System

> Base URL: `https://blogscloud.click/api` (production) hoặc `http://localhost:8000/api` (dev)

---

## Authentication

- **Phương thức**: JWT access token + refresh token
  - **Web**: HttpOnly cookie (`access_token` + `refresh_token`) — tự động gửi kèm request
  - **Mobile**: Bearer token trong header `Authorization: Bearer <access_token>`, refresh token trong request body
- **Algorithm**: HS256
- **Access token**: hết hạn sau 30 phút (cấu hình qua `JWT_ACCESS_EXPIRE_MINUTES`)
- **Refresh token**: hết hạn sau 7 ngày (cấu hình qua `JWT_REFRESH_EXPIRE_DAYS`), lưu dạng SHA-256 hash trong database
- **Token rotation**: mỗi lần refresh, token cũ bị thu hồi và cấp token mới (giữ nguyên token family)
- **Token reuse detection**: nếu refresh token đã bị thu hồi được sử dụng lại → thu hồi toàn bộ token family (phát hiện token theft)
- **Login**: POST `/api/auth/login` → server set 2 cookie (web) + trả `access_token` và `refresh_token` trong response body (mobile)
- **Refresh**: POST `/api/auth/refresh` → cấp token pair mới bằng refresh token
- **Logout**: POST `/api/auth/logout` → thu hồi refresh token trong DB + xóa cả 2 cookie (web). Mobile gửi refresh token trong body.
- **Dependency**: `get_current_user` đọc JWT từ `Authorization: Bearer` header trước, nếu không có thì đọc từ `Cookie` header
- **Tương thích ngược**: token cũ (8 giờ, không có `token_type`) vẫn được chấp nhận cho đến khi hết hạn
- **Cookie options**:

| Cookie | HttpOnly | Secure | SameSite | Path | Max-Age |
|--------|----------|--------|----------|------|---------|
| `access_token` | ✅ | ✅ (prod) | strict | `/` | 30 phút |
| `refresh_token` | ✅ | ✅ (prod) | strict | `/api/auth` | 7 ngày |

---

## Error Format

Tất cả lỗi trả về format:
```json
{
  "detail": "Mô tả lỗi bằng tiếng Việt"
}
```

HTTP Status codes:
- `400` — Bad request (dữ liệu không hợp lệ, vi phạm business rule)
- `401` — Chưa đăng nhập hoặc token hết hạn
- `403` — Không có quyền (cần admin)
- `404` — Không tìm thấy resource
- `500` — Lỗi server

---

## Soft Delete

Hệ thống sử dụng **soft delete** cho các entity chính (User, Bus, Route, Location, Driver):
- Cột `is_deleted` (0/1) đánh dấu đã xóa
- Khi xóa, các trường unique (email, bus_code, route_code) được append suffix `__del_{timestamp}` để giải phóng constraint
- Trạng thái chuyển sang `inactive` / `disabled`
- Dữ liệu vẫn tồn tại trong DB, chỉ bị ẩn khỏi danh sách

---

## 1. Auth — Xác thực

### POST `/auth/register`
Đăng ký tài khoản mới. Tài khoản ở trạng thái `pending`, cần admin duyệt.

**Auth**: Không cần

**Bước 1**: Lấy danh sách tên từ `GET /api/employee-names` (public, không cần auth) để hiển thị dropdown.

**Request Body**:
```json
{
  "email": "nva@gmail.com",
  "password": "matkhau123",
  "employee_name_id": 1,
  "department": "Phòng Kỹ thuật"
}
```
*Bắt buộc: email, password, employee_name_id. `department` optional.*

**Response** `201`:
```json
{
  "message": "Đăng ký thành công. Vui lòng chờ admin phê duyệt.",
  "user_id": 5
}
```

---

### POST `/auth/login`
Đăng nhập, server set HttpOnly cookie và trả token pair.

**Auth**: Không cần

**Request Body**:
```json
{
  "email": "nva@gmail.com",
  "password": "matkhau123"
}
```

**Response** `200`:
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
*Web: Server set 2 cookie — `access_token` (path=/, 30 phút) và `refresh_token` (path=/api/auth, 7 ngày). Mobile: dùng `access_token` và `refresh_token` trong response body.*

**Lỗi**:
- `401` — Sai email/mật khẩu
- `403` — Tài khoản pending/rejected/disabled

---

### POST `/auth/refresh`
Làm mới access token bằng refresh token. Token cũ bị thu hồi, cấp token pair mới (token rotation).

**Auth**: Không cần (xác thực qua refresh token)

**Request Body** (mobile):
```json
{
  "refresh_token": "a1b2c3d4e5f6..."
}
```
*Web: không cần body — refresh token được gửi tự động qua HttpOnly cookie.*

**Response** `200`:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "f6e5d4c3b2a1..."
}
```
*Web: Server set lại cả 2 cookie với token mới.*

**Lỗi**:
- `401` — Refresh token không được cung cấp
- `401` — Refresh token không hợp lệ
- `401` — Refresh token đã hết hạn, vui lòng đăng nhập lại
- `401` — Phát hiện sử dụng lại token, tất cả phiên đã bị thu hồi (token reuse detection)
- `401` — Tài khoản không hợp lệ (user bị disable hoặc không tồn tại)

---

### POST `/auth/logout`
Đăng xuất — thu hồi refresh token trong database và xóa cookies.

**Auth**: Không cần (endpoint không có dependency xác thực)

**Request Body** (mobile):
```json
{
  "refresh_token": "a1b2c3d4e5f6..."
}
```
*Web: không cần body — refresh token được đọc từ cookie. Body là optional.*

**Response** `200`:
```json
{ "message": "Đã đăng xuất" }
```

---

### GET `/auth/me`
Lấy thông tin user hiện tại.

**Auth**: Cần đăng nhập

**Response** `200`:
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

## 2. Employee Names — Danh sách tên nhân viên

### GET `/employee-names`
Danh sách tên nhân viên active và chưa có user nào sử dụng — dùng cho dropdown đăng ký.

**Auth**: Không cần

**Response** `200`:
```json
[
  { "id": 1, "full_name": "Nguyễn Văn A" },
  { "id": 2, "full_name": "Trần Thị B" }
]
```

**Lưu ý**: Chỉ trả tên `is_active = 1` và chưa có user active (`is_deleted = 0`) nào dùng. Tên "Administrator" và các tên đã được đăng ký sẽ không xuất hiện.

---

### GET `/admin/employee-names`
Danh sách tất cả tên (kể cả inactive) — admin view.

**Auth**: Admin

**Response** `200`:
```json
[
  {
    "id": 1,
    "full_name": "Nguyễn Văn A",
    "is_active": 1,
    "user_count": 1,
    "created_at": "2026-04-20T10:00:00"
  }
]
```

---

### POST `/admin/employee-names`
Thêm tên mới. Nếu tên inactive đã tồn tại → kích hoạt lại thay vì tạo mới.

**Auth**: Admin

**Request Body**:
```json
{ "full_name": "Nguyễn Văn C" }
```

**Response** `200`:
```json
{ "message": "Đã thêm tên 'Nguyễn Văn C'", "id": 3 }
```

---

### PUT `/admin/employee-names/{id}`
Sửa tên hoặc toggle active/inactive.

**Auth**: Admin

**Request Body**:
```json
{ "full_name": "Nguyễn Văn D", "is_active": 0 }
```
*Tất cả fields optional.*

**Response** `200`:
```json
{ "message": "Đã cập nhật tên 'Nguyễn Văn D'" }
```

---

### DELETE `/admin/employee-names/{id}`
Xóa tên. Chỉ cho phép nếu chưa có user nào dùng.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã xóa tên 'Nguyễn Văn C'" }
```

**Lỗi**:
- `400` — Không thể xóa — có N tài khoản đang dùng tên này

---

## 3. Route Registration — Đăng ký tuyến xe (User)

### GET `/registration/routes-available`
Danh sách tuyến xe đang hoạt động.

**Auth**: Cần đăng nhập

**Response** `200`:
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

---

### POST `/registration/register`
Đăng ký tuyến xe cho ngày cụ thể.

**Auth**: Cần đăng nhập

**Request Body**:
```json
{
  "route_id": 1,
  "ride_date": "2026-04-25"
}
```

**Response** `200`:
```json
{ "message": "Đã đăng ký tuyến Hà Nội → Nam Định cho ngày 2026-04-25" }
```

**Business rules**:
- `ride_date` phải là ngày tương lai
- Không đăng ký trùng tuyến + ngày
- Không đăng ký 2 tuyến cùng giờ trong cùng ngày

---

### GET `/registration/my`
Danh sách đăng ký tuyến active trong tương lai của user hiện tại.

**Auth**: Cần đăng nhập

**Response** `200`:
```json
[
  {
    "registration_id": 12,
    "route_id": 1,
    "route_code": "R001",
    "route_name": "Hà Nội → Nam Định",
    "pickup_name": "Bến xe Giáp Bát",
    "ride_date": "2026-04-25",
    "status": "active",
    "registered_at": "2026-04-23T10:30:00"
  }
]
```

---

### GET `/registration/my-dates`
Danh sách ngày đã đăng ký tuyến (tương lai) — dùng cho calendar view.

**Auth**: Cần đăng nhập

**Response** `200`:
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

---

### POST `/registration/cancel/{registration_id}`
Hủy đăng ký tuyến.

**Auth**: Cần đăng nhập

**Response** `200`:
```json
{ "message": "Đã hủy đăng ký tuyến" }
```

---

### GET `/registration/history`
Lịch sử đăng ký tuyến (50 gần nhất).

**Auth**: Cần đăng nhập

**Response** `200`:
```json
[
  {
    "registration_id": 12,
    "route_id": 1,
    "route_code": "R001",
    "route_name": "Hà Nội → Nam Định",
    "pickup_name": "Bến xe Giáp Bát",
    "ride_date": "2026-04-25",
    "status": "active",
    "registered_at": "2026-04-23T10:30:00"
  }
]
```

---

## 3. Attendance — Chấm công

### GET `/qrcodes/validate/{qr_token}`
Validate QR token, lấy thông tin xe. Gọi sau khi quét QR.

**Auth**: Không cần

**Response** `200`:
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

---

### POST `/attendance/upload-selfie`
Upload ảnh selfie.

**Auth**: Cần đăng nhập

**Request**: `multipart/form-data`, field `file` (image JPG/PNG/WEBP, max 5MB)

**Response** `200`:
```json
{
  "selfie_url": "/api/attendance/selfie-image/attendance-selfie/2026-04-23/abc123.jpg",
  "filename": "abc123.jpg"
}
```

---

### GET `/attendance/selfie-image/{path}`
Serve ảnh selfie. **Không cần auth.**

---

### POST `/attendance/submit`
Gửi chấm công. User ID lấy từ JWT cookie.

**Auth**: Cần đăng nhập

**Request Body**:
```json
{
  "qr_token": "hZAFavsEn-2PmibszhnLuH9rSjNnykUh_HRQ9CuAH3I",
  "gps_lat": 21.0285,
  "gps_lng": 105.8542,
  "gps_accuracy": 15.0,
  "selfie_url": "/api/attendance/selfie-image/attendance-selfie/2026-04-23/abc123.jpg"
}
```

**Response thành công** `200`:
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

**Response từ chối** `200`:
```json
{
  "result": "rejected",
  "message": "Ngoài giờ chấm công (06:30 → 08:00). Giờ hiện tại: 09:15"
}
```

**Validation chain** (server kiểm tra theo thứ tự):
1. QR token hợp lệ + active
2. Xe đang hoạt động
3. Xe có tuyến active
4. Giờ hiện tại trong khung giờ tuyến
5. Chưa chấm công hôm nay (cùng user + ngày + tuyến)
6. GPS gần điểm đón (≤ threshold, mặc định 150m)

---

## 4. Meals — Đăng ký suất ăn (User)

### POST `/meals/register`
Đăng ký suất ăn cho ngày cụ thể.

**Auth**: Cần đăng nhập

**Request Body**:
```json
{ "meal_date": "2026-04-25" }
```

**Response** `200`:
```json
{
  "message": "Đã đăng ký suất ăn cho ngày 2026-04-25",
  "registration_id": 8,
  "meal_date": "2026-04-25"
}
```

**Business rules**:
- Khung giờ: 8:00 → 19:00 (UTC+7)
- Deadline: trước 19:00 ngày hôm trước
- 1 user chỉ đăng ký 1 lần/ngày

---

### POST `/meals/cancel`
Hủy đăng ký suất ăn.

**Auth**: Cần đăng nhập

**Request Body**:
```json
{ "meal_date": "2026-04-25" }
```

**Response** `200`:
```json
{ "message": "Đã hủy đăng ký suất ăn ngày 2026-04-25" }
```

---

### GET `/meals/my-dates`
Danh sách ngày đã đăng ký suất ăn (tương lai).

**Auth**: Cần đăng nhập

**Response** `200`:
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

### GET `/meals/my-history`
Lịch sử đăng ký suất ăn (50 gần nhất).

**Auth**: Cần đăng nhập

**Response** `200`:
```json
[
  {
    "registration_id": 8,
    "meal_date": "2026-04-25",
    "status": "registered",
    "created_at": "2026-04-23T10:30:00+07:00"
  }
]
```

---

## 5. Admin — Quản lý tài khoản

### GET `/admin/users`
Danh sách tất cả user.

**Auth**: Admin

**Query params**: `status` (optional: pending/approved/rejected/disabled)

**Response** `200`:
```json
[
  {
    "user_id": 5,
    "email": "nva@gmail.com",
    "full_name": "Nguyễn Văn A",
    "employee_name_id": 1,
    "department": "Phòng Kỹ thuật",
    "role": "user",
    "status": "approved",
    "created_at": "2026-04-20T10:00:00"
  }
]
```

---

### GET `/admin/users/pending`
Danh sách tài khoản chờ duyệt.

**Auth**: Admin

**Response**: Giống `/admin/users` nhưng chỉ status=pending.

---

### POST `/admin/users/{user_id}/approve`
Duyệt tài khoản.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã duyệt tài khoản Nguyễn Văn A" }
```

---

### POST `/admin/users/{user_id}/reject`
Từ chối tài khoản.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã từ chối tài khoản Nguyễn Văn A" }
```

---

### POST `/admin/users/{user_id}/disable`
Vô hiệu tài khoản. Không thể vô hiệu chính mình hoặc admin khác. **Tự động thu hồi tất cả refresh token** của user.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã vô hiệu tài khoản Nguyễn Văn A" }
```

---

### POST `/admin/users/{user_id}/revoke-sessions`
Thu hồi tất cả phiên đăng nhập (refresh token) của user. User sẽ phải đăng nhập lại trên tất cả thiết bị.

**Auth**: Admin

**Response** `200`:
```json
{
  "message": "Đã thu hồi 3 phiên của Nguyễn Văn A",
  "revoked_count": 3
}
```

**Lỗi**:
- `404` — User không tồn tại

---

### POST `/admin/users/{user_id}/enable`
Kích hoạt lại tài khoản (disabled/rejected → approved).

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã kích hoạt lại tài khoản Nguyễn Văn A" }
```

---

### POST `/admin/users`
Admin tạo tài khoản trực tiếp (auto-approved).

**Auth**: Admin

**Request Body**:
```json
{
  "email": "nva@gmail.com",
  "password": "matkhau123",
  "employee_name_id": 1,
  "department": "Phòng Kỹ thuật",
  "role_name": "user"
}
```
*Bắt buộc: email, password, employee_name_id. `department` mặc định "", `role_name` mặc định "user".*

**Response** `200`:
```json
{ "message": "Đã tạo tài khoản Nguyễn Văn A", "user_id": 5 }
```

---

### PUT `/admin/users/{user_id}`
Cập nhật thông tin user.

**Auth**: Admin

**Request Body**:
```json
{
  "employee_name_id": 2,
  "department": "Phòng Hành chính"
}
```
*Tất cả fields optional.*

**Response** `200`:
```json
{ "message": "Đã cập nhật Nguyễn Văn B" }
```

---

### DELETE `/admin/users/{user_id}`
Xóa user (soft delete). Không thể xóa admin hoặc chính mình. Email được append `__del_{timestamp}`.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã xóa Nguyễn Văn A" }
```

---

## 6. Admin — Quản lý xe bus

### GET `/buses`
Danh sách xe bus.

**Auth**: Admin

**Query params**: `status` (optional: active/inactive)

**Response** `200`:
```json
[
  {
    "bus_id": 1,
    "bus_code": "BUS001",
    "bus_name": "Xe số 1",
    "license_plate": "29A-12345",
    "driver_id": 2,
    "driver_name": "Trần Văn B",
    "status": "active",
    "has_active_route": true,
    "active_route_id": 1,
    "route_name": "Hà Nội → Nam Định",
    "has_qr": true,
    "qr_id": 5,
    "qr_image_url": "/api/qrcodes/image/qr/2026-04-21/BUS001_abc.png",
    "created_at": "2026-04-20T10:00:00"
  }
]
```

---

### GET `/buses/{bus_id}`
Lấy thông tin chi tiết 1 xe.

**Auth**: Admin

**Response** `200`: Giống 1 item trong danh sách `/buses`.

---

### POST `/buses`
Tạo xe mới (auto gen mã BUS001, BUS002...).

**Auth**: Admin

**Request Body**:
```json
{
  "bus_name": "Xe số 1",
  "license_plate": "29A-12345",
  "driver_id": null
}
```

**Response** `200`:
```json
{ "message": "Đã tạo xe 'BUS001'", "bus_id": 1, "bus_code": "BUS001" }
```

---

### PUT `/buses/{bus_id}`
Cập nhật thông tin xe.

**Auth**: Admin

**Request Body**:
```json
{
  "bus_name": "Xe số 1 (mới)",
  "license_plate": "29A-99999",
  "driver_id": 3,
  "status": "active"
}
```
*Tất cả fields optional. `status` chỉ nhận "active" hoặc "inactive".*

**Response** `200`:
```json
{ "message": "Đã cập nhật xe 'BUS001'" }
```

---

### POST `/buses/{bus_id}/toggle-status`
Chuyển đổi trạng thái xe (active ↔ inactive).

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Xe 'BUS001' → inactive", "status": "inactive" }
```

---

### DELETE `/buses/{bus_id}`
Xóa xe (soft delete). `bus_code` được append `__del_{timestamp}`.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã xóa xe" }
```

---

### POST `/buses/{bus_id}/assign-route`
Gán tuyến cho xe (1 xe chỉ 1 tuyến active). Nếu xe đã có tuyến, trả lỗi.

**Auth**: Admin

**Request Body**: `{ "route_id": 1 }`

**Response** `200`:
```json
{ "message": "Đã gán xe 'BUS001' vào tuyến 'Hà Nội → Nam Định'" }
```

---

### POST `/buses/{bus_id}/change-route`
Đổi tuyến (atomic: hủy cũ → gán mới). Xe phải đang có tuyến.

**Auth**: Admin

**Request Body**: `{ "route_id": 2 }`

**Response** `200`:
```json
{
  "message": "Đã đổi tuyến xe 'BUS001': 'Hà Nội → Nam Định' → 'Hà Nội → Hải Phòng'",
  "old_route": "Hà Nội → Nam Định",
  "new_route": "Hà Nội → Hải Phòng"
}
```

---

### POST `/buses/{bus_id}/unassign-route`
Hủy gán tuyến cho xe.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã hủy gán tuyến cho xe 'BUS001'" }
```

---

### GET `/buses/{bus_id}/route-history`
Lịch sử gán tuyến của xe.

**Auth**: Admin

**Response** `200`:
```json
[
  {
    "assignment_id": 1,
    "route_id": 1,
    "route_name": "Hà Nội → Nam Định",
    "status": "inactive",
    "assigned_at": "2026-04-20T10:00:00",
    "unassigned_at": "2026-04-22T15:30:00"
  },
  {
    "assignment_id": 2,
    "route_id": 2,
    "route_name": "Hà Nội → Hải Phòng",
    "status": "active",
    "assigned_at": "2026-04-22T15:30:00",
    "unassigned_at": ""
  }
]
```

---

### POST `/buses/{bus_id}/assign-driver`
Gán tài xế (1 driver chỉ 1 xe active).

**Auth**: Admin

**Request Body**: `{ "driver_id": 3 }`

**Response** `200`:
```json
{ "message": "Đã gán tài xế 'Trần Văn B' cho xe 'BUS001'" }
```

---

### POST `/buses/{bus_id}/unassign-driver`
Hủy gán tài xế khỏi xe.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã hủy gán tài xế 'Trần Văn B' khỏi xe 'BUS001'" }
```

---

## 7. Admin — Quản lý tài xế (Drivers)

### GET `/drivers`
Danh sách tài xế.

**Auth**: Admin

**Query params**: `status` (optional: active/inactive)

**Response** `200`:
```json
[
  {
    "driver_id": 1,
    "full_name": "Trần Văn B",
    "phone": "0912345678",
    "license_number": "B2-123456",
    "status": "active",
    "assigned_bus_code": "BUS001",
    "created_at": "2026-04-20T10:00:00"
  }
]
```

---

### POST `/drivers`
Tạo tài xế mới.

**Auth**: Admin

**Request Body**:
```json
{
  "full_name": "Trần Văn B",
  "phone": "0912345678",
  "license_number": "B2-123456"
}
```
*Bắt buộc: full_name. `phone` và `license_number` mặc định "".*

**Response** `200`:
```json
{ "message": "Đã tạo tài xế 'Trần Văn B'", "driver_id": 1 }
```

---

### PUT `/drivers/{driver_id}`
Cập nhật thông tin tài xế.

**Auth**: Admin

**Request Body**:
```json
{
  "full_name": "Trần Văn C",
  "phone": "0999888777",
  "license_number": "B2-654321",
  "status": "inactive"
}
```
*Tất cả fields optional. `status` chỉ nhận "active" hoặc "inactive".*

**Response** `200`:
```json
{ "message": "Đã cập nhật tài xế 'Trần Văn C'" }
```

---

### DELETE `/drivers/{driver_id}`
Xóa tài xế (soft delete). Set `is_deleted=1`, `status=inactive`.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã xóa tài xế 'Trần Văn B'" }
```

---

## 8. Admin — Quản lý tuyến xe (Routes)

### GET `/routes`
Danh sách tuyến xe (không bao gồm đã xóa).

**Auth**: Không cần (public)

**Response** `200`:
```json
[
  {
    "route_id": 1,
    "route_code": "R001",
    "route_name": "Hà Nội → Nam Định",
    "go_start_time": "06:30",
    "go_end_time": "08:00",
    "pickup_location_id": 1,
    "pickup_name": "Bến xe Giáp Bát",
    "dropoff_location_id": 2,
    "dropoff_name": "Bến xe Nam Định",
    "status": "active"
  }
]
```

---

### GET `/routes/{route_id}`
Chi tiết 1 tuyến.

**Auth**: Không cần (public)

**Response** `200`: Giống 1 item trong danh sách `/routes`.

---

### POST `/routes`
Tạo tuyến mới (auto gen mã R001, R002...).

**Auth**: Admin

**Request Body**:
```json
{
  "route_name": "Hà Nội → Nam Định",
  "go_start_time": "06:30",
  "go_end_time": "08:00",
  "pickup_location_id": 1,
  "dropoff_location_id": 2
}
```
*Bắt buộc: route_name, go_start_time, go_end_time. Location IDs optional.*

**Response** `200`:
```json
{ "message": "Đã tạo tuyến 'Hà Nội → Nam Định'", "route_id": 1 }
```

---

### PUT `/routes/{route_id}`
Cập nhật tuyến.

**Auth**: Admin

**Request Body**:
```json
{
  "route_name": "Hà Nội → Hải Phòng",
  "go_start_time": "07:00",
  "go_end_time": "09:00",
  "pickup_location_id": 1,
  "dropoff_location_id": 3,
  "status": "inactive"
}
```
*Tất cả fields optional.*

**Response** `200`:
```json
{ "message": "Đã cập nhật tuyến 'Hà Nội → Hải Phòng'" }
```

---

### DELETE `/routes/{route_id}`
Xóa tuyến (soft delete). `route_code` được append `__del_{timestamp}`, status → inactive.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã xóa tuyến 'Hà Nội → Nam Định'" }
```

---

## 9. Admin — Quản lý điểm đón/trả (Locations)

### GET `/locations`
Danh sách điểm đón/trả (không bao gồm đã xóa).

**Auth**: Không cần (public)

**Response** `200`:
```json
[
  {
    "location_id": 1,
    "name": "Bến xe Giáp Bát",
    "lat": 20.9818,
    "lng": 105.8413
  }
]
```

---

### POST `/locations`
Tạo điểm đón/trả mới.

**Auth**: Admin

**Request Body**:
```json
{
  "name": "Bến xe Giáp Bát",
  "lat": 20.9818,
  "lng": 105.8413
}
```

**Response** `200`:
```json
{ "message": "Đã tạo điểm 'Bến xe Giáp Bát'", "location_id": 1 }
```

---

### PUT `/locations/{location_id}`
Cập nhật điểm đón/trả.

**Auth**: Admin

**Request Body**:
```json
{
  "name": "Bến xe Giáp Bát (mới)",
  "lat": 20.9820,
  "lng": 105.8415
}
```
*Tất cả fields optional.*

**Response** `200`:
```json
{ "message": "Đã cập nhật 'Bến xe Giáp Bát (mới)'" }
```

---

### DELETE `/locations/{location_id}`
Xóa điểm đón/trả (soft delete). Set `is_deleted=1`.

**Auth**: Admin

**Response** `200`:
```json
{ "message": "Đã xóa 'Bến xe Giáp Bát'" }
```

---

## 10. Admin — QR Codes

### POST `/qrcodes/generate/{bus_id}`
Tạo QR mới cho xe. Nếu xe đã có QR active, trả lỗi (dùng reissue thay thế).

**Auth**: Admin

**Response** `200`:
```json
{
  "message": "Đã tạo QR cho xe 'BUS001'",
  "qr_id": 5,
  "qr_token": "hZAFavsEn-2Pmibsz...",
  "qr_image_url": "/api/qrcodes/image/qr/2026-04-23/BUS001_hZAFavsE.png"
}
```

---

### POST `/qrcodes/reissue/{bus_id}`
Cấp lại QR (vô hiệu cũ, tạo mới). Xe phải đang có QR active.

**Auth**: Admin

**Response** `200`:
```json
{
  "message": "Đã cấp lại QR cho xe 'BUS001'. QR cũ đã bị vô hiệu.",
  "qr_id": 6,
  "qr_token": "newToken123...",
  "qr_image_url": "/api/qrcodes/image/qr/2026-04-23/BUS001_newToken.png"
}
```

---

### GET `/qrcodes/bus/{bus_id}`
Lấy thông tin QR active của xe.

**Auth**: Admin

**Response** `200` (có QR):
```json
{
  "has_qr": true,
  "bus_code": "BUS001",
  "qr_id": 5,
  "qr_token": "hZAFavsEn-2Pmibsz...",
  "qr_image_url": "/api/qrcodes/image/qr/2026-04-23/BUS001_hZAFavsE.png",
  "created_at": "2026-04-23T10:00:00"
}
```

**Response** `200` (chưa có QR):
```json
{
  "has_qr": false,
  "bus_code": "BUS001"
}
```

---

### GET `/qrcodes/bus/{bus_id}/history`
Lịch sử QR của xe (active + đã vô hiệu).

**Auth**: Admin

**Response** `200`:
```json
[
  {
    "qr_id": 6,
    "qr_token": "newToken123...",
    "is_active": true,
    "qr_image_url": "/api/qrcodes/image/qr/2026-04-23/BUS001_newToken.png",
    "created_at": "2026-04-23T15:00:00",
    "deactivated_at": ""
  },
  {
    "qr_id": 5,
    "qr_token": "hZAFavsEn-2P...",
    "is_active": false,
    "qr_image_url": "/api/qrcodes/image/qr/2026-04-21/BUS001_hZAFavsE.png",
    "created_at": "2026-04-21T10:00:00",
    "deactivated_at": "2026-04-23T15:00:00"
  }
]
```

---

### GET `/qrcodes/image/{path}`
Serve ảnh QR. **Không cần auth.**

---

### GET `/qrcodes/download/{qr_id}`
Download ảnh QR. **Không cần auth.**

---

## 11. Admin — Báo cáo

### GET `/reports/dashboard`
Dashboard tổng quan.

**Auth**: Admin

**Response** `200`:
```json
{
  "buses": { "total": 5, "active": 4 },
  "qr_active": 4,
  "drivers": { "total": 3, "active": 3 },
  "users_approved": 20,
  "today": {
    "date": "2026-04-23",
    "total": 15,
    "success": 12,
    "rejected": 3
  },
  "recent_logs": [
    {
      "log_id": 100,
      "full_name": "Nguyễn Văn A",
      "email": "nva@gmail.com",
      "bus_code": "BUS001",
      "checkin_time": "07:15",
      "attendance_date": "2026-04-23",
      "result_status": "success"
    }
  ]
}
```

---

### GET `/reports/daily?report_date=2026-04-23`
Báo cáo chấm công theo ngày, nhóm theo xe.

**Auth**: Admin

**Query params**: `report_date` (optional, YYYY-MM-DD, mặc định hôm nay)

**Response** `200`:
```json
{
  "date": "2026-04-23",
  "summary": {
    "total": 15,
    "success": 12,
    "rejected": 3
  },
  "by_bus": [
    {
      "bus_id": 1,
      "bus_code": "BUS001",
      "bus_name": "Xe số 1",
      "success": 8,
      "rejected": 1,
      "total": 9,
      "logs": [
        {
          "log_id": 100,
          "user_id": 5,
          "full_name": "Nguyễn Văn A",
          "email": "nva@gmail.com",
          "department": "Phòng Kỹ thuật",
          "bus_code": "BUS001",
          "route_name": "Hà Nội → Nam Định",
          "attendance_date": "2026-04-23",
          "checkin_time": "07:15:30",
          "gps_lat": 21.0285,
          "gps_lng": 105.8542,
          "distance_m": 45,
          "selfie_url": "/api/attendance/selfie-image/...",
          "result_status": "success",
          "reject_reason": ""
        }
      ]
    }
  ]
}
```

---

### GET `/reports/by-bus/{bus_id}?report_date=2026-04-23`
Báo cáo chấm công cho 1 xe cụ thể theo ngày.

**Auth**: Admin

**Query params**: `report_date` (optional, YYYY-MM-DD, mặc định hôm nay)

**Response** `200`:
```json
{
  "date": "2026-04-23",
  "bus_code": "BUS001",
  "bus_name": "Xe số 1",
  "total": 9,
  "success": 8,
  "rejected": 1,
  "logs": [
    {
      "log_id": 100,
      "user_id": 5,
      "full_name": "Nguyễn Văn A",
      "email": "nva@gmail.com",
      "department": "Phòng Kỹ thuật",
      "bus_code": "BUS001",
      "route_name": "Hà Nội → Nam Định",
      "attendance_date": "2026-04-23",
      "checkin_time": "07:15:30",
      "gps_lat": 21.0285,
      "gps_lng": 105.8542,
      "distance_m": 45,
      "selfie_url": "",
      "result_status": "success",
      "reject_reason": ""
    }
  ]
}
```

---

### GET `/reports/by-employee/{user_id}?date_from=2026-04-01&date_to=2026-04-30`
Lịch sử chấm công của 1 nhân viên (chỉ lấy success).

**Auth**: Admin

**Query params**:
- `date_from` (optional, YYYY-MM-DD)
- `date_to` (optional, YYYY-MM-DD)

**Response** `200`:
```json
{
  "user_id": 5,
  "full_name": "Nguyễn Văn A",
  "email": "nva@gmail.com",
  "total_logs": 15,
  "unique_days": 12,
  "logs": [
    {
      "log_id": 100,
      "user_id": 5,
      "full_name": "Nguyễn Văn A",
      "email": "nva@gmail.com",
      "department": "Phòng Kỹ thuật",
      "bus_code": "BUS001",
      "route_name": "Hà Nội → Nam Định",
      "attendance_date": "2026-04-23",
      "checkin_time": "07:15:30",
      "gps_lat": 21.0285,
      "gps_lng": 105.8542,
      "distance_m": 45,
      "selfie_url": "",
      "result_status": "success",
      "reject_reason": ""
    }
  ]
}
```

---

### GET `/reports/export-csv?report_date=2026-04-23`
Xuất CSV chấm công (UTF-8 BOM, hỗ trợ tiếng Việt trong Excel).

**Auth**: Admin

**Response**: File CSV download (`chamcong_2026-04-23.csv`)

Columns: STT, Ngày, Giờ chấm công, Họ tên, Email, Phòng ban, Mã xe, Tuyến, Khoảng cách (m), Kết quả, Lý do từ chối

---

### GET `/meals/admin/summary?meal_date=2026-04-24`
Tổng hợp suất ăn theo ngày.

**Auth**: Admin

**Query params**: `meal_date` (optional, YYYY-MM-DD, mặc định ngày mai)

**Response** `200`:
```json
{
  "meal_date": "2026-04-24",
  "total": 15,
  "registrations": [
    {
      "registration_id": 8,
      "user_id": 5,
      "full_name": "Nguyễn Văn A",
      "email": "nva@gmail.com",
      "department": "Phòng Kỹ thuật",
      "registered_at": "2026-04-23T10:30:00+07:00"
    }
  ]
}
```

---

### GET `/meals/admin/history?meal_date=2026-04-24&status=registered`
Lịch sử đăng ký suất ăn (admin view) với bộ lọc.

**Auth**: Admin

**Query params**:
- `meal_date` (optional, YYYY-MM-DD)
- `status` (optional: registered/cancelled)

**Response** `200`:
```json
[
  {
    "registration_id": 8,
    "user_id": 5,
    "full_name": "Nguyễn Văn A",
    "email": "nva@gmail.com",
    "department": "Phòng Kỹ thuật",
    "meal_date": "2026-04-24",
    "status": "registered",
    "created_at": "2026-04-23T10:30:00+07:00"
  }
]
```
*Giới hạn 200 bản ghi, sắp xếp theo meal_date giảm dần.*

---

## 12. Admin — Cấu hình hệ thống

### GET `/config`
Lấy cấu hình hiện tại.

**Auth**: Admin

**Response** `200`:
```json
{
  "near_stop_threshold_meter": 150,
  "require_gps": true,
  "require_selfie": true
}
```

---

### PUT `/config`
Cập nhật cấu hình.

**Auth**: Admin

**Request Body**:
```json
{
  "near_stop_threshold_meter": 200,
  "require_gps": true,
  "require_selfie": false
}
```
*Tất cả fields optional. `near_stop_threshold_meter` phải từ 10 đến 5000.*

**Response** `200`:
```json
{
  "message": "Đã cập nhật cấu hình",
  "near_stop_threshold_meter": 200,
  "require_gps": true,
  "require_selfie": false
}
```

---

## Timezone

- Server sử dụng **UTC+7** (Việt Nam) cho tất cả logic thời gian
- Dates format: `YYYY-MM-DD`
- Datetime format: ISO 8601

## File Storage

- Selfie: `uploads/attendance-selfie/YYYY-MM-DD/`
- QR: `uploads/qr/YYYY-MM-DD/`
- Max selfie: 5MB
- Allowed image types: JPG, PNG, WEBP (validated by magic bytes)