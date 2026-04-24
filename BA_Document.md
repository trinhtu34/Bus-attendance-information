# HỆ THỐNG CHẤM CÔNG XE BUS & ĐĂNG KÝ SUẤT ĂN – TÀI LIỆU BA

## Thông tin chung

* **Tên tài liệu**: Tài liệu BA – Hệ thống quản lý chấm công xe bus & đăng ký suất ăn
* **Loại tài liệu**: Phân tích nghiệp vụ / mô tả chức năng
* **Mục tiêu**: Mô tả yêu cầu nghiệp vụ, quy trình, quy tắc kiểm tra, báo cáo và dữ liệu
* **Phạm vi**: Chấm công 01 lượt/ngày bằng QR + GPS + selfie; Đăng ký tuyến xe theo ngày; Đăng ký suất ăn
* **Ngày lập**: 04/2026
* **Cập nhật lần cuối**: 04/2026

---

## Mục lục

1. Giới thiệu chung
2. Mô hình nghiệp vụ tổng thể
3. Đối tượng sử dụng
4. Yêu cầu nghiệp vụ chi tiết
5. Danh sách phân hệ
6. Use case
7. Quy trình To-Be
8. Quy tắc nghiệp vụ
9. Dữ liệu & bảng
10. Báo cáo
11. Màn hình
12. Thông báo (Email)
13. Phi chức năng
14. Nghiệm thu
15. Kết luận

---

# 1. Giới thiệu chung

## 1.1 Bối cảnh

Xây dựng hệ thống phục vụ cán bộ đi xe bus:

* **Chấm công** bằng QR cố định trên xe + GPS + ảnh selfie
* **Đăng ký tuyến xe** theo ngày cụ thể
* **Đăng ký suất ăn** cho ngày trong tương lai

Nguyên tắc chấm công: **"gần điểm đón là được"**

## 1.2 Mục tiêu

* Chấm công **1 lượt/1 lượt đi**
* QR riêng cho từng xe, quét bằng camera điện thoại
* Bắt buộc đăng nhập trước khi chấm công
* Lưu: thời gian server (UTC+7) + GPS + selfie
* Đăng ký tuyến xe theo ngày cụ thể trong tương lai
* Đăng ký suất ăn cho ngày trong tương lai (khung giờ 8:00 → 19:00)
* Gửi email xác nhận khi đăng ký suất ăn
* Báo cáo đa chiều + xuất CSV

## 1.3 Phạm vi

### Trong phạm vi

* Quản lý xe bus, tuyến xe, điểm đón/trả, tài xế
* QR code (tạo, cấp lại, vô hiệu)
* Chấm công (quét QR, GPS, selfie, kiểm tra logic)
* Đăng ký tuyến xe theo ngày
* Đăng ký suất ăn
* Thông báo email
* Báo cáo + xuất CSV
* Cấu hình hệ thống (ngưỡng khoảng cách, toggle GPS/selfie)
* Mobile native app 
  
### Ngoài phạm vi

* GPS realtime xe
* AI nhận diện khuôn mặt
* OTP xác thực

---

# 2. Mô hình nghiệp vụ

## 2.1 Nguyên tắc

* Mỗi xe có 1 QR active
* User phải đăng nhập → quét QR → mở form chấm công
* Lấy GPS + chụp selfie → submit
* Server xác định thời gian (UTC+7), kiểm tra logic
* Chặn trùng lượt (1 user + 1 ngày + 1 tuyến = 1 lần)
* Kiểm tra GPS gần điểm đón (Haversine, ngưỡng cấu hình được)

## 2.2 Luồng chấm công

1. User quét QR trên xe → trình duyệt mở URL chấm công
2. Hệ thống kiểm tra đăng nhập → nếu chưa → redirect login → quay lại
3. Validate QR token → hiển thị thông tin xe + tuyến
4. User bật GPS → lấy tọa độ
5. User chụp selfie → upload
6. User bấm "Gửi chấm công"
7. Server kiểm tra: giờ hợp lệ → không trùng → GPS gần điểm đón
8. Lưu log (success hoặc rejected + lý do)
9. Hiển thị kết quả

## 2.3 Luồng đăng ký tuyến xe

1. User đăng nhập → vào trang "Đăng ký tuyến"
2. Chọn ngày trong tương lai + chọn tuyến
3. Hệ thống kiểm tra: không trùng tuyến+ngày, không trùng giờ với tuyến khác cùng ngày
4. Lưu đăng ký → hiển thị danh sách ngày đã đăng ký
5. User có thể hủy đăng ký (nếu ngày chưa qua)

## 2.4 Luồng đăng ký suất ăn

1. User đăng nhập → vào trang "Suất ăn"
2. Chọn ngày trong tương lai
3. Hệ thống kiểm tra: khung giờ 8:00-19:00, deadline trước 19:00 ngày hôm trước
4. Lưu đăng ký → gửi email xác nhận (nếu user có email)
5. User có thể hủy (trong khung giờ + trước deadline)

---

# 3. Đối tượng sử dụng

| Nhóm | Vai trò |
|------|---------|
| Người dùng (User) | Đăng ký tuyến xe, chấm công, đăng ký suất ăn |
| Quản trị viên (Admin) | Quản lý hệ thống, duyệt tài khoản, xem báo cáo |

---

# 4. Yêu cầu nghiệp vụ chi tiết

## 4.1 Tài khoản & Xác thực

* Đăng ký tài khoản → trạng thái `pending` → admin duyệt → `approved`
* Đăng nhập bằng JWT (HttpOnly cookie, hết hạn 8 giờ)
* Phân quyền: Admin thấy trang admin, User thấy trang user
* Admin có thể tạo tài khoản trực tiếp (auto-approved)
* Admin có thể vô hiệu / kích hoạt lại / xóa tài khoản

## 4.2 Xe bus

* CRUD xe bus (mã xe auto gen: BUS001, BUS002...)
* Gán/đổi/hủy gán tuyến cho xe (1 xe chỉ 1 tuyến active)
* Gán/hủy gán tài xế cho xe (1 tài xế chỉ 1 xe active)
* Toggle trạng thái active/inactive

## 4.3 Tuyến xe

* CRUD tuyến (mã tuyến auto gen: R001, R002...)
* Mỗi tuyến có: giờ bắt đầu, giờ kết thúc, điểm đón, điểm trả
* Toggle trạng thái active/inactive

## 4.4 Điểm đón/trả

* CRUD điểm đón/trả (tên, tọa độ GPS lat/lng)
* Hiển thị trên bản đồ (Leaflet)

## 4.5 Tài xế

* CRUD tài xế (họ tên, SĐT, số GPLX)
* Toggle trạng thái active/inactive

## 4.6 QR Code

* 1 xe = 1 QR active
* QR chứa URL đầy đủ: `https://domain/attendance?token=<unique_token>`
* Có thể cấp lại QR → QR cũ bị vô hiệu, QR mới active
* Lưu lịch sử QR
* Download ảnh QR

## 4.7 Chấm công

* **Bắt buộc đăng nhập** trước khi chấm công
* Chỉ có **1 lượt/ngày** (lượt đi)
* Quét QR → validate token → hiển thị thông tin xe + tuyến
* Bật GPS → lấy tọa độ + độ chính xác
* Chụp selfie (front camera) → upload
* Submit → server kiểm tra:
  - Giờ hiện tại trong khung giờ tuyến (go_start_time → go_end_time)
  - Chưa chấm công hôm nay (cùng user + ngày + tuyến)
  - GPS gần điểm đón (khoảng cách ≤ ngưỡng cấu hình, mặc định 150m)
* Lưu log đầy đủ cả success + rejected (kèm lý do từ chối)

## 4.8 Đăng ký tuyến xe

* User chọn tuyến + chọn ngày cụ thể trong tương lai
* **Không giới hạn khung giờ** — đăng ký bất kỳ lúc nào
* Chỉ chặn: không đăng ký ngày trong quá khứ
* Không đăng ký trùng tuyến + ngày
* Không đăng ký 2 tuyến cùng giờ trong cùng ngày
* Có thể hủy đăng ký (nếu ngày chưa qua)
* Xem danh sách ngày đã đăng ký + lịch sử

## 4.9 Đăng ký suất ăn

* User chọn ngày cụ thể trong tương lai
* **Khung giờ đăng ký: 8:00 → 19:00** (UTC+7)
* **Deadline: trước 19:00 ngày hôm trước** ngày đăng ký
* 1 user chỉ đăng ký 1 lần/ngày
* Có thể hủy (trong khung giờ + trước deadline)
* Gửi **email xác nhận** khi đăng ký thành công (nếu user có email)
* Xem danh sách ngày đã đăng ký + lịch sử

## 4.10 Cấu hình hệ thống

* Ngưỡng khoảng cách GPS (10m → 5000m, mặc định 150m)
* Toggle bắt buộc GPS (on/off)
* Toggle bắt buộc selfie (on/off)

---

# 5. Phân hệ

| Mã | Tên | Chức năng |
|----|-----|-----------|
| PH-01 | Xác thực | Đăng ký, đăng nhập, phân quyền, duyệt tài khoản |
| PH-02 | Xe bus | CRUD xe, gán tuyến, gán tài xế |
| PH-03 | Tuyến xe | CRUD tuyến, điểm đón/trả |
| PH-04 | Tài xế | CRUD tài xế |
| PH-05 | QR | Tạo, cấp lại, vô hiệu QR |
| PH-06 | Chấm công | Quét QR, GPS, selfie, kiểm tra logic, lưu log |
| PH-07 | Đăng ký tuyến | Đăng ký/hủy tuyến theo ngày |
| PH-08 | Suất ăn | Đăng ký/hủy suất ăn, email xác nhận |
| PH-09 | Báo cáo | Thống kê, xuất CSV |
| PH-10 | Cấu hình | Ngưỡng GPS, toggle GPS/selfie |

---

# 6. Use Case

| Mã UC | Tên Use Case | Actor | Kết quả |
|-------|-------------|-------|---------|
| UC01 | Đăng ký tài khoản | Người dùng | Tài khoản pending, chờ admin duyệt |
| UC02 | Đăng nhập | Người dùng | Nhận JWT cookie, truy cập hệ thống |
| UC03 | Duyệt tài khoản | Admin | User chuyển sang approved, đăng nhập được |
| UC04 | Quản lý xe bus | Admin | CRUD xe, gán tuyến/tài xế |
| UC05 | Quản lý tuyến xe | Admin | CRUD tuyến với giờ + điểm đón/trả |
| UC06 | Quản lý tài xế | Admin | CRUD tài xế |
| UC07 | Tạo/cấp lại QR | Admin | Mỗi xe có 1 QR active, cấp lại vô hiệu cũ |
| UC08 | Đăng ký tuyến xe | Người dùng | Chọn tuyến + ngày → đăng ký thành công |
| UC09 | Chấm công | Người dùng | Quét QR → đăng nhập → GPS + selfie → submit |
| UC10 | Kiểm tra chấm công | Hệ thống | Validate giờ, trùng lượt, GPS → success/rejected |
| UC11 | Đăng ký suất ăn | Người dùng | Chọn ngày → đăng ký → email xác nhận |
| UC12 | Xem báo cáo | Admin | Thống kê theo ngày/xe/người, xuất CSV |
| UC13 | Cấu hình hệ thống | Admin | Sửa ngưỡng GPS, toggle GPS/selfie |

---

# 7. Quy trình

## 7.1 Chấm công

```
User quét QR → Mở trình duyệt → Kiểm tra đăng nhập
  ├─ Chưa login → Redirect login → Login → Quay lại trang chấm công
  └─ Đã login → Validate QR → Hiển thị thông tin xe/tuyến
      → Bật GPS → Chụp selfie → Submit
      → Server kiểm tra (giờ, trùng, GPS)
        ├─ OK → Lưu success → Hiển thị xanh ✅
        └─ Fail → Lưu rejected + lý do → Hiển thị đỏ ❌
```

## 7.2 Đăng ký tuyến xe

```
User đăng nhập → Trang đăng ký tuyến
  → Chọn ngày (tương lai) + Chọn tuyến
  → Kiểm tra (không trùng, không cùng giờ)
  → Lưu → Hiển thị danh sách ngày đã đăng ký
  → Có thể hủy (nếu ngày chưa qua)
```

## 7.3 Đăng ký suất ăn

```
User đăng nhập → Trang suất ăn
  → Chọn ngày (tương lai)
  → Kiểm tra (khung giờ 8-19, deadline, chưa đăng ký)
  → Lưu → Gửi email xác nhận
  → Hiển thị danh sách ngày đã đăng ký
  → Có thể hủy (trong khung giờ + trước deadline)
```

## 7.4 Lý do từ chối chấm công

* Ngoài giờ chấm công (giờ tuyến)
* Đã chấm công hôm nay
* QR không hợp lệ / đã vô hiệu
* Xe không hoạt động / chưa gán tuyến
* GPS quá xa điểm đón

---

# 8. Quy tắc nghiệp vụ

| # | Quy tắc | Mô tả |
|---|---------|-------|
| BR-01 | 1 xe = 1 QR active | Cấp lại QR → vô hiệu cũ |
| BR-02 | 1 lượt/ngày | Cùng user + ngày + tuyến = chỉ 1 lần success |
| BR-03 | Server time UTC+7 | Tất cả logic thời gian dùng UTC+7 |
| BR-04 | Bắt buộc đăng nhập | Phải login trước khi chấm công |
| BR-05 | GPS gần điểm đón | Khoảng cách ≤ ngưỡng (cấu hình, mặc định 150m) |
| BR-06 | Tài khoản cần duyệt | Đăng ký → pending → admin approve → approved |
| BR-07 | 1 xe = 1 tuyến active | Đổi tuyến = hủy cũ + gán mới |
| BR-08 | 1 tài xế = 1 xe active | Không gán 1 tài xế cho 2 xe |
| BR-09 | Đăng ký tuyến theo ngày | Chỉ đăng ký ngày tương lai, không giới hạn giờ |
| BR-10 | Không trùng tuyến cùng giờ | Cùng ngày không đăng ký 2 tuyến cùng giờ |
| BR-11 | Suất ăn: khung giờ 8-19 | Chỉ đăng ký/hủy trong 8:00 → 19:00 |
| BR-12 | Suất ăn: deadline | Trước 19:00 ngày hôm trước ngày đăng ký |
| BR-13 | Email xác nhận suất ăn | Gửi email khi đăng ký thành công (nếu có email) |

---

# 9. Dữ liệu & bảng

## 9.1 Entities

* Users (tài khoản + thông tin cá nhân)
* Roles (admin, user)
* Buses (xe bus)
* Routes (tuyến xe)
* Locations (điểm đón/trả)
* Drivers (tài xế)
* Bus Route Assignments (gán xe-tuyến)
* Bus QR Codes (mã QR)
* User Route Registrations (đăng ký tuyến theo ngày)
* Attendance Logs (log chấm công)
* Meal Registrations (đăng ký suất ăn)
* Meal Categories (loại món ăn — Phase 2 - hiện giờ thì chưa làm )
* Meal Items (món ăn — Phase 2 - Hiện giờ thì chưa làm)
* System Config (cấu hình hệ thống)

## 9.2 Bảng chính

```
users(user_id, username, password_hash, role_id, full_name, short_name,
      rank, position, phone, email, department, status, is_deleted)

roles(role_id, role_name, description)

buses(bus_id, bus_code, bus_name, license_plate, driver_id, status, is_deleted)

routes(route_id, route_code, route_name, go_start_time, go_end_time,
       pickup_location_id, dropoff_location_id, status, is_deleted)

locations(location_id, name, lat, lng, is_deleted)

drivers(driver_id, full_name, phone, license_number, status, is_deleted)

bus_route_assignments(assignment_id, bus_id, route_id, status, assigned_at, unassigned_at)

bus_qr_codes(qr_id, bus_id, qr_token, qr_image_url, is_active, created_by)

user_route_registrations(registration_id, user_id, route_id, ride_date, status)

attendance_logs(log_id, user_id, bus_id, route_id, attendance_date, checkin_time,
                gps_lat, gps_lng, gps_accuracy, selfie_url, distance_to_stop_m,
                result_status, reject_reason)

meal_registrations(registration_id, user_id, meal_date, item_id, quantity, status)

system_config(config_id, near_stop_threshold_meter, require_gps, require_selfie)
```

---

# 10. Báo cáo

| Báo cáo | Mô tả |
|---------|-------|
| Theo ngày | Tổng lượt chấm công, success/rejected, nhóm theo xe |
| Theo xe | Danh sách người chấm trong ngày cho 1 xe |
| Theo người | Lịch sử chấm công của 1 nhân viên, filter theo khoảng ngày |
| Xuất CSV | Download file CSV tiếng Việt (UTF-8 BOM) |
| Dashboard | Tổng xe, QR active, tài xế, nhân viên, chấm công hôm nay |
| Suất ăn theo ngày | Tổng số suất + danh sách người đăng ký |
| Lịch sử suất ăn | Filter theo ngày + trạng thái (đã ĐK / đã hủy) |

---

# 11. Màn hình

## Admin

* Dashboard tổng quan
* Quản lý tài khoản (danh sách, duyệt, tạo, sửa, xóa)
* Quản lý xe bus (CRUD, gán tuyến/tài xế, QR)
* Quản lý tuyến xe (CRUD)
* Quản lý điểm đón/trả (bản đồ + danh sách)
* Quản lý tài xế (CRUD)
* Báo cáo chấm công (theo ngày, xuất CSV)
* Quản lý suất ăn (tổng hợp theo ngày, lịch sử)
* Cấu hình hệ thống
* Sidebar responsive (desktop: cố định, mobile: hamburger)

## User

* Đăng ký tuyến xe (chọn ngày + tuyến)
* Đăng ký suất ăn (chọn ngày)
* Trang chấm công (quét QR → GPS → selfie → submit → kết quả)

---

# 12. Thông báo (Email)

| Sự kiện | Người nhận | Nội dung |
|---------|-----------|----------|
| Đăng ký suất ăn thành công | User (nếu có email) | Xác nhận đăng ký + ngày + hướng dẫn hủy |

**Kênh gửi**: Gmail SMTP
**Điều kiện**: User phải có field email trong profile

---

# 13. Phi chức năng

* Mobile responsive (web)
* HTTPS (SSL/TLS qua Certbot)
* JWT HttpOnly cookie (chống XSS)
* GPS + Camera hoạt động qua HTTPS trên mobile
* Thời gian xử lý < 5s
* CI/CD: GitHub Actions auto-deploy

---

# 14. Nghiệm thu

* [ ] Đăng ký tài khoản → pending → admin duyệt → đăng nhập được
* [ ] QR tạo đúng, quét mở đúng trang chấm công
* [ ] Chấm công: GPS + selfie + kiểm tra logic → success/rejected
* [ ] Không trùng lượt (1 user + 1 ngày + 1 tuyến)
* [ ] GPS gần điểm đón → success, xa → rejected
* [ ] Đăng ký tuyến theo ngày, không trùng, hủy được
* [ ] Đăng ký suất ăn trong khung giờ, email xác nhận
* [ ] Báo cáo đúng, xuất CSV tiếng Việt
* [ ] Hoạt động trên mobile 
* [ ] Sidebar responsive

---

# 15. Kết luận

Hệ thống cung cấp giải pháp:

* **Chấm công xe bus** bằng QR + GPS + selfie, đảm bảo kiểm soát
* **Đăng ký tuyến xe** theo ngày linh hoạt
* **Đăng ký suất ăn** với khung giờ + email thông báo
* **Báo cáo đa chiều** cho quản lý

Sẵn sàng phát triển thêm:

* Phase 2 suất ăn: chọn món cụ thể
* AI nhận diện khuôn mặt
