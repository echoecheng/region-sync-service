USE apn_eu;

-- ===================== talent 系列 =====================

CREATE TABLE talent (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200),
    phone VARCHAR(50),
    title VARCHAR(200),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_contact (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    contact_type VARCHAR(50),
    contact_value VARCHAR(200),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_experience (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    company_name VARCHAR(200),
    job_title VARCHAR(200),
    start_date DATE,
    end_date DATE,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_education (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    school_name VARCHAR(200),
    degree VARCHAR(100),
    major VARCHAR(100),
    graduation_year INT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_project (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    project_name VARCHAR(200),
    description TEXT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_skill (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    skill_name VARCHAR(100),
    proficiency VARCHAR(50),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_ownership (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    owner_id BIGINT,
    ownership_type VARCHAR(50),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_modified_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE talent_preference (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    talent_id BIGINT,
    preference_key VARCHAR(100),
    preference_value VARCHAR(500),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===================== company 系列 =====================

CREATE TABLE company (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(200),
    industry VARCHAR(100),
    website VARCHAR(300),
    address VARCHAR(500),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE company_contact (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    company_id BIGINT,
    contact_name VARCHAR(100),
    contact_email VARCHAR(200),
    contact_phone VARCHAR(50),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===================== job 系列 =====================

CREATE TABLE shared_job (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_title VARCHAR(200),
    description TEXT,
    company_id BIGINT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE job (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_title VARCHAR(200),
    description TEXT,
    company_id BIGINT,
    status VARCHAR(50) DEFAULT 'OPEN',
    salary_min DECIMAL(12,2),
    salary_max DECIMAL(12,2),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE job_candidate (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_id BIGINT,
    talent_id BIGINT,
    status VARCHAR(50) DEFAULT 'APPLIED',
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE job_activity (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_id BIGINT,
    activity_type VARCHAR(50),
    description TEXT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE job_note (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_id BIGINT,
    note_content TEXT,
    created_by BIGINT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===================== interview / offer =====================

CREATE TABLE interview (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_candidate_id BIGINT,
    interview_date TIMESTAMP,
    interview_type VARCHAR(50),
    status VARCHAR(50) DEFAULT 'SCHEDULED',
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE interview_feedback (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    interview_id BIGINT,
    feedback TEXT,
    rating INT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE offer (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_candidate_id BIGINT,
    salary DECIMAL(12,2),
    start_date DATE,
    status VARCHAR(50) DEFAULT 'PENDING',
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===================== placement / invoice =====================

CREATE TABLE placement (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_id BIGINT,
    talent_id BIGINT,
    start_date DATE,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'ACTIVE',
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE invoice (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    placement_id BIGINT,
    amount DECIMAL(12,2),
    invoice_date DATE,
    status VARCHAR(50) DEFAULT 'PENDING',
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===================== client / sales =====================

CREATE TABLE client (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    client_name VARCHAR(200),
    industry VARCHAR(100),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE client_contact (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    client_id BIGINT,
    contact_name VARCHAR(100),
    contact_email VARCHAR(200),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE sales_lead (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    lead_name VARCHAR(200),
    status VARCHAR(50) DEFAULT 'NEW',
    assigned_to BIGINT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE sales_lead_project_relation (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    sales_lead_id BIGINT,
    project_id BIGINT,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ===================== system =====================

CREATE TABLE notification (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    title VARCHAR(200),
    content TEXT,
    is_read TINYINT DEFAULT 0,
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE `user` (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(100),
    email VARCHAR(200),
    status VARCHAR(50) DEFAULT 'ACTIVE',
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_role (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    role_name VARCHAR(100),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE user_permission (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    permission_name VARCHAR(100),
    source_region VARCHAR(10) DEFAULT 'EU',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
