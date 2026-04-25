-- ============================================================
-- Bus Attendance System — Database Schema (MySQL / MariaDB)
-- Generated from SQLAlchemy models (tables.py)
-- Total: 15 tables
-- ============================================================

-- ── 1. ROLES ────────────────────────────────────
CREATE TABLE roles (
    role_id       INT           AUTO_INCREMENT PRIMARY KEY,
    role_name     VARCHAR(50)   NOT NULL UNIQUE,
    description   VARCHAR(200)  DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 2. EMPLOYEE_NAMES ───────────────────────────
CREATE TABLE employee_names (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100)  NOT NULL,
    is_active     SMALLINT      NOT NULL DEFAULT 1,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 3. USERS ────────────────────────────────────
CREATE TABLE users (
    user_id          INT           AUTO_INCREMENT PRIMARY KEY,
    email            VARCHAR(100)  NOT NULL UNIQUE,
    password_hash    VARCHAR(255)  NOT NULL,
    role_id          INT           NOT NULL,
    employee_name_id INT           NOT NULL,
    department       VARCHAR(100)  DEFAULT '',
    status           ENUM('pending','approved','rejected','disabled') NOT NULL DEFAULT 'pending',
    approved_by      INT           NULL,
    approved_at      DATETIME      NULL,
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted       SMALLINT      NOT NULL DEFAULT 0,

    INDEX idx_users_email (email),

    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles(role_id),
    CONSTRAINT fk_users_employee_name
        FOREIGN KEY (employee_name_id) REFERENCES employee_names(id),
    CONSTRAINT fk_users_approver
        FOREIGN KEY (approved_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 4. LOCATIONS ────────────────────────────────
CREATE TABLE locations (
    location_id   INT            AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(150)   NOT NULL,
    lat           DECIMAL(10,7)  NOT NULL,
    lng           DECIMAL(10,7)  NOT NULL,
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted    SMALLINT       NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 5. ROUTES ───────────────────────────────────
CREATE TABLE routes (
    route_id            INT           AUTO_INCREMENT PRIMARY KEY,
    route_code          VARCHAR(50)   NOT NULL UNIQUE,
    route_name          VARCHAR(100)  NOT NULL,
    go_start_time       TIME          NOT NULL,
    go_end_time         TIME          NOT NULL,
    pickup_location_id  INT           NULL,
    dropoff_location_id INT           NULL,
    status              ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted          SMALLINT      NOT NULL DEFAULT 0,

    CONSTRAINT fk_routes_pickup
        FOREIGN KEY (pickup_location_id) REFERENCES locations(location_id),
    CONSTRAINT fk_routes_dropoff
        FOREIGN KEY (dropoff_location_id) REFERENCES locations(location_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 6. DRIVERS ──────────────────────────────────
CREATE TABLE drivers (
    driver_id       INT           AUTO_INCREMENT PRIMARY KEY,
    full_name       VARCHAR(100)  NOT NULL,
    phone           VARCHAR(20)   DEFAULT '',
    license_number  VARCHAR(50)   DEFAULT '',
    status          ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_deleted      SMALLINT      NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 7. BUSES ────────────────────────────────────
CREATE TABLE buses (
    bus_id         INT           AUTO_INCREMENT PRIMARY KEY,
    bus_code       VARCHAR(50)   NOT NULL UNIQUE,
    bus_name       VARCHAR(100)  DEFAULT '',
    license_plate  VARCHAR(20)   DEFAULT '',
    driver_id      INT           NULL,
    status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_deleted     SMALLINT      NOT NULL DEFAULT 0,

    CONSTRAINT fk_buses_driver
        FOREIGN KEY (driver_id) REFERENCES drivers(driver_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 8. BUS_ROUTE_ASSIGNMENTS ────────────────────
CREATE TABLE bus_route_assignments (
    assignment_id  INT       AUTO_INCREMENT PRIMARY KEY,
    bus_id         INT       NOT NULL,
    route_id       INT       NOT NULL,
    status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
    assigned_at    DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unassigned_at  DATETIME  NULL,

    CONSTRAINT fk_bra_bus
        FOREIGN KEY (bus_id) REFERENCES buses(bus_id) ON DELETE CASCADE,
    CONSTRAINT fk_bra_route
        FOREIGN KEY (route_id) REFERENCES routes(route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 9. BUS_QR_CODES ────────────────────────────
CREATE TABLE bus_qr_codes (
    qr_id           INT           AUTO_INCREMENT PRIMARY KEY,
    bus_id          INT           NOT NULL,
    qr_token        VARCHAR(64)   NOT NULL UNIQUE,
    qr_image_url    TEXT          NULL,
    is_active       SMALLINT      NOT NULL DEFAULT 1,
    created_by      INT           NULL,
    created_at      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deactivated_at  DATETIME      NULL,

    CONSTRAINT fk_qr_bus
        FOREIGN KEY (bus_id) REFERENCES buses(bus_id) ON DELETE CASCADE,
    CONSTRAINT fk_qr_creator
        FOREIGN KEY (created_by) REFERENCES users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 10. USER_ROUTE_REGISTRATIONS ────────────────
CREATE TABLE user_route_registrations (
    registration_id  INT       AUTO_INCREMENT PRIMARY KEY,
    user_id          INT       NOT NULL,
    route_id         INT       NOT NULL,
    ride_date        DATE      NULL COMMENT 'NULL = legacy (đăng ký vĩnh viễn), có giá trị = đăng ký theo ngày',
    status           ENUM('active','inactive') NOT NULL DEFAULT 'active',
    registered_at    DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unregistered_at  DATETIME  NULL,

    CONSTRAINT fk_urr_user
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_urr_route
        FOREIGN KEY (route_id) REFERENCES routes(route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 11. SYSTEM_CONFIG ───────────────────────────
CREATE TABLE system_config (
    config_id                INT       AUTO_INCREMENT PRIMARY KEY,
    near_stop_threshold_meter INT      NOT NULL DEFAULT 150,
    require_gps              SMALLINT  NOT NULL DEFAULT 1,
    require_selfie           SMALLINT  NOT NULL DEFAULT 1,
    updated_at               DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 12. ATTENDANCE_LOGS ─────────────────────────
CREATE TABLE attendance_logs (
    log_id            INT            AUTO_INCREMENT PRIMARY KEY,
    user_id           INT            NOT NULL,
    bus_id            INT            NOT NULL,
    route_id          INT            NOT NULL,
    attendance_date   DATE           NOT NULL,
    checkin_time      DATETIME       NOT NULL,
    gps_lat           DECIMAL(10,7)  NULL,
    gps_lng           DECIMAL(10,7)  NULL,
    gps_accuracy      FLOAT          NULL,
    selfie_url        TEXT           NULL,
    distance_to_stop_m FLOAT         NULL,
    result_status     ENUM('success','rejected') NOT NULL,
    reject_reason     TEXT           NULL,
    created_at        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_att_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_att_bus
        FOREIGN KEY (bus_id) REFERENCES buses(bus_id),
    CONSTRAINT fk_att_route
        FOREIGN KEY (route_id) REFERENCES routes(route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 13. MEAL_CATEGORIES (Phase 2) ──────────────
CREATE TABLE meal_categories (
    category_id  INT           AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(100)  NOT NULL,
    description  VARCHAR(200)  DEFAULT '',
    status       ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 14. MEAL_ITEMS (Phase 2) ────────────────────
CREATE TABLE meal_items (
    item_id       INT            AUTO_INCREMENT PRIMARY KEY,
    category_id   INT            NULL,
    name          VARCHAR(150)   NOT NULL,
    description   TEXT           DEFAULT '',
    price         DECIMAL(10,0)  DEFAULT 0,
    image_url     TEXT           NULL,
    status        ENUM('active','inactive') NOT NULL DEFAULT 'active',
    created_at    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_mi_category
        FOREIGN KEY (category_id) REFERENCES meal_categories(category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 15. MEAL_REGISTRATIONS ──────────────────────
CREATE TABLE meal_registrations (
    registration_id  INT           AUTO_INCREMENT PRIMARY KEY,
    user_id          INT           NOT NULL,
    meal_date        DATE          NOT NULL,
    item_id          INT           NULL COMMENT 'NULL = Phase 1 (chỉ đăng ký, chưa chọn món)',
    quantity         INT           NOT NULL DEFAULT 1,
    note             VARCHAR(200)  DEFAULT '',
    status           ENUM('registered','cancelled') NOT NULL DEFAULT 'registered',
    created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelled_at     DATETIME      NULL,

    CONSTRAINT fk_mr_user
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_mr_item
        FOREIGN KEY (item_id) REFERENCES meal_items(item_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ── 16. REFRESH_TOKENS ──────────────────────────
CREATE TABLE refresh_tokens (
    id            INT           AUTO_INCREMENT PRIMARY KEY,
    token_hash    VARCHAR(64)   NOT NULL UNIQUE,
    user_id       INT           NOT NULL,
    token_family  VARCHAR(36)   NOT NULL,
    expires_at    DATETIME      NOT NULL,
    is_revoked    SMALLINT      NOT NULL DEFAULT 0,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    revoked_at    DATETIME      NULL,

    INDEX idx_rt_token_hash (token_hash),
    INDEX idx_rt_token_family (token_family),

    CONSTRAINT fk_rt_user
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
