# 🍱 Meals Management API

> **Dự án:** Bus Attendance System (Z103 — ASP.NET Core + ABP Framework)  
> **Cập nhật:** 04/05/2026  
> **Base URL:** `https://{domain}`  
> **Base path:** `/api/services/app/Meals/`  
> **Auth:** Yêu cầu đăng nhập + permission `Meal`

---

## Mục lục

1. [Phân quyền](#1-phân-quyền)
2. [Danh sách đăng ký suất ăn](#2-danh-sách-đăng-ký-suất-ăn)
3. [Xem chi tiết đăng ký](#3-xem-chi-tiết-đăng-ký)
4. [Đăng ký suất ăn](#4-đăng-ký-suất-ăn)
5. [Đăng ký hàng loạt](#5-đăng-ký-hàng-loạt)
6. [Hủy đăng ký](#6-hủy-đăng-ký)
7. [Xóa đăng ký](#7-xóa-đăng-ký)

---

## 1. Phân quyền

| Permission | Mô tả |
|---|---|
| `Meal` | Quyền gốc — truy cập module suất ăn |
| `Meal.MealRegistration` | Xem đăng ký suất ăn |
| `Meal.MealRegistration.View` | Xem tất cả đăng ký |
| `Meal.MealRegistration.Register` | Tự đăng ký suất ăn (chỉ thấy của mình) |
| `Meal.MealRegistration.Kitchen` | Nhà bếp — xem tất cả đăng ký |
| `Meal.MealRegistration.Create` | Admin tạo đăng ký cho người khác |
| `Meal.MealRegistration.Edit` | Sửa đăng ký |
| `Meal.MealRegistration.Delete` | Xóa đăng ký |

### Quy tắc hiển thị dữ liệu

| Vai trò | Thấy gì |
|---|---|
| **Kitchen / View** | Tất cả đăng ký |
| **Register** | Chỉ đăng ký của mình |
| **Admin** | Tất cả |

---

## 2. Danh sách đăng ký suất ăn

```
GET /api/services/app/Meals/GetAllMealRegistrations
```

**Query params:**

| Param | Type | Mô tả |
|---|---|---|
| `MealDate` | DateTime? | Lọc theo ngày |
| `Filter` | string | Tìm kiếm |
| `Sorting` | string | Sắp xếp |
| `SkipCount` | int | Phân trang — bỏ qua N bản ghi |
| `MaxResultCount` | int | Phân trang — số bản ghi tối đa |

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

| Field | Type | Mô tả |
|---|---|---|
| `id` | int | ID đăng ký |
| `userId` | long | ID người dùng |
| `fullName` | string | Họ tên nhân viên |
| `email` | string | Email |
| `department` | string | Phòng ban |
| `mealDate` | string | Ngày ăn (YYYY-MM-DD) |
| `quantity` | int | Số suất |
| `note` | string | Ghi chú (VD: "Không cay") |
| `status` | string | `registered` hoặc `cancelled` |
| `createdAt` | string | Thời điểm đăng ký |

---

## 3. Xem chi tiết đăng ký

```
GET /api/services/app/Meals/GetMealRegistrationForEdit?Id={id}
```

**Permission:** `Meal.MealRegistration.Edit`

**Response:**
```json
{
  "mealRegistration": {
    "id": 1,
    "userId": 10,
    "mealDate": "2026-05-05",
    "quantity": 1,
    "note": "Không cay",
    "status": "registered"
  }
}
```

---

## 4. Đăng ký suất ăn

```
POST /api/services/app/Meals/CreateOrEditMealRegistration
```

**Permission:** `Meal.MealRegistration.Create` hoặc `Meal.MealRegistration.Register`

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

> `id = null` → tạo mới, `id = N` → cập nhật

### Validation

| Quy tắc | Mô tả |
|---|---|
| Khung giờ | Chỉ đăng ký trong **8h → 19h** |
| Ngày tương lai | `mealDate` phải là ngày chưa qua |
| Không trùng | Cùng user + cùng ngày → báo lỗi |

### Lỗi có thể gặp

| Thông báo | Nguyên nhân |
|---|---|
| `Ngoài khung giờ đăng ký (8h-19h)` | Đăng ký ngoài giờ cho phép |
| `Chỉ đăng ký cho ngày tương lai` | `mealDate` đã qua |
| `Đã đăng ký suất ăn cho ngày này` | Trùng user + date |

---

## 5. Đăng ký hàng loạt

```
POST /api/services/app/Meals/BatchMealRegister
```

**Permission:** `Meal.MealRegistration.Create` hoặc `Meal.MealRegistration.Register`

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
| 1 | Đăng ký cả tuần (thứ 2 → thứ 6, từ ngày mai) |
| 2 | Đăng ký cả tháng (từ ngày mai đến cuối tháng) |

**Response:**
```json
{
  "totalDays": 22,
  "createdCount": 20,
  "skippedCount": 2,
  "createdDates": ["2026-05-05", "2026-05-06", "2026-05-07"],
  "skippedReasons": [
    "2026-05-01: Ngày nghỉ",
    "2026-05-03: Đã đăng ký trước đó"
  ]
}
```

| Field | Type | Mô tả |
|---|---|---|
| `totalDays` | int | Tổng số ngày trong khoảng |
| `createdCount` | int | Số ngày đăng ký thành công |
| `skippedCount` | int | Số ngày bị bỏ qua |
| `createdDates` | string[] | Danh sách ngày đã đăng ký |
| `skippedReasons` | string[] | Lý do bỏ qua từng ngày |

> Tự bỏ qua các ngày trong `SystemConfig.MealExcludedDays` (VD: Chủ nhật, Thứ 7).

---

## 6. Hủy đăng ký

```
POST /api/services/app/Meals/CancelMealRegistration
```

**Permission:** `Meal.MealRegistration.Edit`

**Request Body:**
```json
{ "id": 1 }
```

> Chuyển trạng thái từ `registered` → `cancelled`. Không xóa khỏi DB.

---

## 7. Xóa đăng ký

```
POST /api/services/app/Meals/DeleteMealRegistration
```

**Permission:** `Meal.MealRegistration.Delete`

**Request Body:**
```json
{ "id": 1 }
```

> Xóa hoàn toàn khỏi DB. Chỉ admin mới có quyền.

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
- `Sorting` — chuỗi sắp xếp (VD: `"MealDate DESC"`, `"FullName ASC"`)
