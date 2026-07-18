-- ============================================================
-- Everest Spelling Bee — MySQL Database Initialization Script
-- ============================================================

CREATE DATABASE IF NOT EXISTS spelling_bee
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE spelling_bee;

-- ── 1. Users (Super Admin + Examiners) ─────────────────────

CREATE TABLE IF NOT EXISTS users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  role        ENUM('superadmin', 'examiner') NOT NULL DEFAULT 'examiner',
  name        VARCHAR(255) NOT NULL,
  school      VARCHAR(255) DEFAULT NULL,
  email       VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ── 2. Global Settings ─────────────────────────────────────

CREATE TABLE IF NOT EXISTS global_settings (
  id              INT PRIMARY KEY,
  timer_seconds   INT NOT NULL DEFAULT 1800,
  initial_shields INT NOT NULL DEFAULT 5,
  initial_passes  INT NOT NULL DEFAULT 5
) ENGINE=InnoDB;

-- Seed default settings (30 minutes, 5 shields, 5 passes)
INSERT INTO global_settings (id, timer_seconds, initial_shields, initial_passes)
VALUES (1, 1800, 5, 5)
ON DUPLICATE KEY UPDATE id = id;

-- ── 3. Students ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS students (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  examiner_id     INT DEFAULT NULL,
  name            VARCHAR(255) NOT NULL,
  grade           VARCHAR(10) NOT NULL,
  section         VARCHAR(50) DEFAULT NULL,
  school_name     VARCHAR(255) DEFAULT NULL,
  school_address  VARCHAR(500) DEFAULT NULL,
  city            VARCHAR(100) DEFAULT NULL,
  district        VARCHAR(100) DEFAULT NULL,
  state           VARCHAR(100) DEFAULT NULL,
  parent_mobile   VARCHAR(20) DEFAULT NULL,
  token           VARCHAR(64) NOT NULL UNIQUE,
  token_status    ENUM('active', 'used') NOT NULL DEFAULT 'active',
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (examiner_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ── 4. Words ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS words (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  grade             VARCHAR(10) NOT NULL,
  spelling_british  VARCHAR(255) NOT NULL,
  spelling_american VARCHAR(255) NOT NULL,
  part_of_speech    VARCHAR(50) DEFAULT NULL,
  meaning           TEXT DEFAULT NULL,
  jumbled_letters   VARCHAR(255) DEFAULT NULL,
  UNIQUE KEY unique_word_grade (grade, spelling_british)
) ENGINE=InnoDB;

-- ── 5. Results ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS results (
  id                      INT AUTO_INCREMENT PRIMARY KEY,
  student_id              INT DEFAULT NULL,
  student_name            VARCHAR(255) NOT NULL,
  grade                   VARCHAR(10) DEFAULT NULL,
  final_score             INT NOT NULL DEFAULT 0,
  correct_answers         INT NOT NULL DEFAULT 0,
  wrong_answers           INT NOT NULL DEFAULT 0,
  passes_used             INT NOT NULL DEFAULT 0,
  time_remaining_seconds  INT NOT NULL DEFAULT 0,
  accuracy                DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ── 6. Seed Super Admin ────────────────────────────────────
-- Password: Admin370
-- bcrypt hash generated with 10 salt rounds
INSERT INTO users (role, name, school, email, password_hash)
VALUES (
  'superadmin',
  'Super Admin',
  NULL,
  'superadmin@gmail.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
)
ON DUPLICATE KEY UPDATE email = email;
