/*
    REPORTING MARTS FOR POWER BI - DRAFT
    Project: ABC Tech Company - Employee Churn Analysis
    Source data: employees_churn.employee_info (PostgreSQL, database practice_db)

    How to use:
      - Chay file nay trong DBeaver gan connection postgres (database practice_db).
      - Tat ca object report nam trong schema employees_churn (cung schema voi du lieu goc).
      - Tat ca chi doc (SELECT), khong thay doi du lieu goc.

    Marking:
      [DESCRIPTIVE] -> dung cho dashboard bao cao.
      [GATED]       -> chua duoc validation, chi exploratory, CHUA dung cho quyet dinh.

    Note: PostgreSQL - cac lenh dung ';' phan tach cau.
*/

CREATE SCHEMA IF NOT EXISTS employees_churn;

-- Drop dependent views first so the script can be rerun safely.
DROP VIEW IF EXISTS employees_churn.vw_power_bi_reconciliation;
DROP VIEW IF EXISTS employees_churn.mart_employee_analytics;

/* ================================================================
   1. EXECUTIVE OVERVIEW - Report Page 3
   ================================================================ */

-- [DESCRIPTIVE] Tong quan toan cong ty.
DROP VIEW IF EXISTS employees_churn.vw_churn_overview;
CREATE VIEW employees_churn.vw_churn_overview AS
SELECT
    COUNT(*) AS total_employees,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
    SUM(CASE WHEN NOT churn THEN 1 ELSE 0 END) AS active_employees,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM employees_churn.employee_info;

-- [DESCRIPTIVE] Churn theo phong ban kem delta so voi toan cong ty.
DROP VIEW IF EXISTS employees_churn.vw_churn_by_department;
CREATE VIEW employees_churn.vw_churn_by_department AS
SELECT
    d.department,
    d.headcount,
    d.churned_employees,
    d.active_employees,
    CAST(d.churn_rate_pct AS NUMERIC(10, 2)) AS churn_rate_pct,
    CAST(c.company_churn_rate_pct AS NUMERIC(10, 2)) AS company_churn_rate_pct,
    CAST(d.churn_rate_pct - c.company_churn_rate_pct AS NUMERIC(10, 2)) AS rate_delta_pp
FROM (
    SELECT
        department,
        COUNT(*) AS headcount,
        SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
        SUM(CASE WHEN NOT churn THEN 1 ELSE 0 END) AS active_employees,
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0) AS churn_rate_pct
    FROM employees_churn.employee_info
    GROUP BY department
) AS d
CROSS JOIN (
    SELECT
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0) AS company_churn_rate_pct
    FROM employees_churn.employee_info
) AS c;

-- [DESCRIPTIVE] Churn theo tham nien (band khong chong lan).
DROP VIEW IF EXISTS employees_churn.vw_churn_by_tenure_band;
CREATE VIEW employees_churn.vw_churn_by_tenure_band AS
SELECT
    b.tenure_band,
    b.headcount,
    b.churned_employees,
    b.active_employees,
    CAST(b.churn_rate_pct AS NUMERIC(10, 2)) AS churn_rate_pct,
    CAST(c.company_churn_rate_pct AS NUMERIC(10, 2)) AS company_churn_rate_pct,
    CAST(b.churn_rate_pct - c.company_churn_rate_pct AS NUMERIC(10, 2)) AS rate_delta_pp
FROM (
    SELECT
        CASE
            WHEN tenure < 1 THEN 'Under 1 year'
            WHEN tenure < 3 THEN '1 to under 3 years'
            WHEN tenure <= 5 THEN '3 to 5 years'
            ELSE 'Over 5 years'
        END AS tenure_band,
        COUNT(*) AS headcount,
        SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
        SUM(CASE WHEN NOT churn THEN 1 ELSE 0 END) AS active_employees,
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0) AS churn_rate_pct
    FROM employees_churn.employee_info
    GROUP BY CASE
        WHEN tenure < 1 THEN 'Under 1 year'
        WHEN tenure < 3 THEN '1 to under 3 years'
        WHEN tenure <= 5 THEN '3 to 5 years'
        ELSE 'Over 5 years'
    END
) AS b
CROSS JOIN (
    SELECT
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
            / NULLIF(COUNT(*), 0) AS company_churn_rate_pct
    FROM employees_churn.employee_info
) AS c;

-- [DESCRIPTIVE] Churn theo 10 tenure decile.
DROP VIEW IF EXISTS employees_churn.vw_churn_by_tenure_decile;
CREATE VIEW employees_churn.vw_churn_by_tenure_decile AS
WITH employee_tenure_decile AS (
    SELECT
        employee_id,
        tenure,
        churn,
        NTILE(10) OVER (ORDER BY tenure, employee_id) AS tenure_decile
    FROM employees_churn.employee_info
)
SELECT
    tenure_decile,
    MIN(tenure) AS min_tenure,
    MAX(tenure) AS max_tenure,
    COUNT(*) AS headcount,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM employee_tenure_decile
GROUP BY tenure_decile;

-- [DESCRIPTIVE] Churn theo estimated hire cohort (2026 - tenure).
DROP VIEW IF EXISTS employees_churn.vw_churn_by_hire_cohort;
CREATE VIEW employees_churn.vw_churn_by_hire_cohort AS
SELECT
    2026 - tenure AS estimated_hire_year,
    COUNT(*) AS headcount,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM employees_churn.employee_info
GROUP BY 2026 - tenure;

/* ================================================================
   2. CHURN DRIVERS - Report Page 4
   ================================================================ */

-- [DESCRIPTIVE] Ma tran gender x churn.
DROP VIEW IF EXISTS employees_churn.vw_gender_churn_matrix;
CREATE VIEW employees_churn.vw_gender_churn_matrix AS
SELECT
    gender,
    COUNT(*) AS headcount,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
    SUM(CASE WHEN NOT churn THEN 1 ELSE 0 END) AS active_employees,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM employees_churn.employee_info
GROUP BY gender;

-- [DESCRIPTIVE] Churn theo number of overtime hours.
DROP VIEW IF EXISTS employees_churn.vw_churn_by_overtime_band;
CREATE VIEW employees_churn.vw_churn_by_overtime_band AS
SELECT
    overtime_band,
    headcount,
    churned_employees,
    CAST(
        100.0 * churned_employees / NULLIF(headcount, 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM (
    SELECT
        CASE
            WHEN overtime_hours = 0 THEN '0 hours'
            WHEN overtime_hours <= 10 THEN '1-10 hours'
            WHEN overtime_hours <= 20 THEN '11-20 hours'
            ELSE 'Over 20 hours'
        END AS overtime_band,
        COUNT(*) AS headcount,
        SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees
    FROM employees_churn.employee_info
    GROUP BY CASE
        WHEN overtime_hours = 0 THEN '0 hours'
        WHEN overtime_hours <= 10 THEN '1-10 hours'
        WHEN overtime_hours <= 20 THEN '11-20 hours'
        ELSE 'Over 20 hours'
    END
) AS o;

-- [DESCRIPTIVE] Ma tran hours x satisfaction x churn (heatmap).
DROP VIEW IF EXISTS employees_churn.vw_hours_satisfaction_churn_matrix;
CREATE VIEW employees_churn.vw_hours_satisfaction_churn_matrix AS
WITH employee_experience_matrix AS (
    SELECT
        CASE
            WHEN average_monthly_hours_worked < 180 THEN '150-179'
            WHEN average_monthly_hours_worked < 210 THEN '180-209'
            WHEN average_monthly_hours_worked < 240 THEN '210-239'
            WHEN average_monthly_hours_worked < 270 THEN '240-269'
            ELSE '270+'
        END AS monthly_hours_band,
        CASE
            WHEN satisfaction_level < 0.40 THEN 'Low'
            WHEN satisfaction_level < 0.70 THEN 'Medium'
            ELSE 'High'
        END AS satisfaction_band,
        churn
    FROM employees_churn.employee_info
)
SELECT
    monthly_hours_band,
    satisfaction_band,
    COUNT(*) AS headcount,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM employee_experience_matrix
GROUP BY monthly_hours_band, satisfaction_band;

-- [DESCRIPTIVE] Feedback band x promotion rate x churn.
DROP VIEW IF EXISTS employees_churn.vw_feedback_promotion_churn;
CREATE VIEW employees_churn.vw_feedback_promotion_churn AS
WITH employee_feedback_band AS (
    SELECT
        CASE
            WHEN manager_feedback_score <= 4 THEN 'Low'
            WHEN manager_feedback_score <= 7 THEN 'Medium'
            ELSE 'High'
        END AS feedback_band,
        promotions,
        churn
    FROM employees_churn.employee_info
)
SELECT
    feedback_band,
    COUNT(*) AS headcount,
    CAST(
        100.0 * AVG(CAST(promotions AS NUMERIC(10, 4)))
        AS NUMERIC(10, 2)
    ) AS promotion_rate_pct,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_employees,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS churn_rate_pct
FROM employee_feedback_band
GROUP BY feedback_band;

-- [DESCRIPTIVE] Absenteeism theo department.
DROP VIEW IF EXISTS employees_churn.vw_department_absenteeism_rank;
CREATE VIEW employees_churn.vw_department_absenteeism_rank AS
SELECT
    department,
    COUNT(*) AS headcount,
    CAST(AVG(CAST(absenteeism AS NUMERIC(18, 4))) AS NUMERIC(18, 2)) AS avg_absenteeism,
    SUM(absenteeism) AS total_absenteeism
FROM employees_churn.employee_info
GROUP BY department;

/* ================================================================
   3. COMPENSATION FAIRNESS - Report Page 5
   ================================================================ */

-- [DESCRIPTIVE] Salary theo job role (avg, min, max, median).
DROP VIEW IF EXISTS employees_churn.vw_salary_by_role;
CREATE VIEW employees_churn.vw_salary_by_role AS
WITH role_median AS (
    SELECT
        job_role,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary
    FROM employees_churn.employee_info
    GROUP BY job_role
)
SELECT
    e.job_role,
    COUNT(*) AS employee_count,
    CAST(AVG(CAST(e.salary AS NUMERIC(18, 2))) AS NUMERIC(18, 2)) AS avg_salary,
    MIN(e.salary) AS min_salary,
    MAX(e.salary) AS max_salary,
    CAST(m.median_salary AS NUMERIC(18, 2)) AS median_salary
FROM employees_churn.employee_info AS e
LEFT JOIN role_median AS m
    ON m.job_role = e.job_role
GROUP BY e.job_role, m.median_salary;

-- [DESCRIPTIVE] Salary theo performance group.
DROP VIEW IF EXISTS employees_churn.vw_salary_by_performance_group;
CREATE VIEW employees_churn.vw_salary_by_performance_group AS
WITH employee_performance_group AS (
    SELECT
        CASE
            WHEN performance_rating <= 2 THEN 'Low (1-2)'
            WHEN performance_rating = 3 THEN 'Medium (3)'
            ELSE 'High (4-5)'
        END AS performance_group,
        salary
    FROM employees_churn.employee_info
)
SELECT
    performance_group,
    COUNT(*) AS employee_count,
    CAST(AVG(CAST(salary AS NUMERIC(18, 2))) AS NUMERIC(18, 2)) AS avg_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary
FROM employee_performance_group
GROUP BY performance_group;

-- [DESCRIPTIVE] Pay fairness: raw va peer-adjusted gap theo gender.
DROP VIEW IF EXISTS employees_churn.vw_pay_fairness;
CREATE VIEW employees_churn.vw_pay_fairness AS
WITH employee_peer_group AS (
    SELECT
        e.*,
        CASE
            WHEN e.tenure < 1 THEN 'Under 1 year'
            WHEN e.tenure < 3 THEN '1 to under 3 years'
            WHEN e.tenure <= 5 THEN '3 to 5 years'
            ELSE 'Over 5 years'
        END AS tenure_band
    FROM employees_churn.employee_info AS e
), peer_salary_window AS (
    SELECT
        p.*,
        SUM(CAST(p.salary AS NUMERIC(38, 4)))
            OVER (PARTITION BY p.job_role, p.tenure_band) AS peer_salary_sum,
        COUNT(*) OVER (PARTITION BY p.job_role, p.tenure_band) AS peer_employee_count
    FROM employee_peer_group AS p
), employee_adjusted_gap AS (
    SELECT
        w.*,
        (w.peer_salary_sum - w.salary)
            / NULLIF(w.peer_employee_count - 1, 0) AS peer_avg_salary_excl_self
    FROM peer_salary_window AS w
), gender_salary AS (
    SELECT
        gender,
        COUNT(*) AS employee_count,
        AVG(CAST(salary AS NUMERIC(18, 4))) AS avg_salary,
        AVG(
            100.0 * (salary - peer_avg_salary_excl_self)
            / NULLIF(peer_avg_salary_excl_self, 0)
        ) AS avg_peer_adjusted_gap_pct
    FROM employee_adjusted_gap
    GROUP BY gender
), gender_salary_with_reference AS (
    SELECT
        g.*,
        MAX(CASE WHEN g.gender = 'Male' THEN g.avg_salary END) OVER () AS male_avg_salary
    FROM gender_salary AS g
)
SELECT
    gender,
    employee_count,
    CAST(avg_salary AS NUMERIC(18, 2)) AS avg_salary,
    CAST(
        100.0 * (avg_salary - male_avg_salary) / NULLIF(male_avg_salary, 0)
        AS NUMERIC(10, 2)
    ) AS raw_gap_vs_male_pct,
    CAST(avg_peer_adjusted_gap_pct AS NUMERIC(10, 2)) AS avg_peer_adjusted_gap_pct
FROM gender_salary_with_reference;

-- [DESCRIPTIVE] Employee-level peer benchmark theo role + tenure band.
DROP VIEW IF EXISTS employees_churn.mart_employee_pay_position;
CREATE VIEW employees_churn.mart_employee_pay_position AS
WITH employee_peer_group AS (
    SELECT
        e.*,
        CASE
            WHEN e.tenure < 1 THEN 'Under 1 year'
            WHEN e.tenure < 3 THEN '1 to under 3 years'
            WHEN e.tenure <= 5 THEN '3 to 5 years'
            ELSE 'Over 5 years'
        END AS tenure_band
    FROM employees_churn.employee_info AS e
), peer_median AS (
    SELECT
        p.job_role,
        p.tenure_band,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.salary) AS peer_median_salary
    FROM employee_peer_group AS p
    GROUP BY p.job_role, p.tenure_band
), employee_peer_benchmark AS (
    SELECT
        p.*,
        m.peer_median_salary,
        COUNT(*) OVER (PARTITION BY p.job_role, p.tenure_band) AS peer_count,
        AVG(CAST(p.salary AS NUMERIC(18, 4)))
            OVER (PARTITION BY p.job_role, p.tenure_band) AS peer_avg_salary,
        NTILE(4) OVER (
            PARTITION BY p.job_role, p.tenure_band
            ORDER BY p.salary, p.employee_id
        ) AS salary_quartile
    FROM employee_peer_group AS p
    LEFT JOIN peer_median AS m
        ON m.job_role = p.job_role
       AND m.tenure_band = p.tenure_band
)
SELECT
    employee_id,
    department,
    job_role,
    tenure,
    tenure_band,
    salary,
    performance_rating,
    projects_completed,
    peer_count,
    CAST(peer_avg_salary AS NUMERIC(18, 2)) AS peer_avg_salary,
    CAST(peer_median_salary AS NUMERIC(18, 2)) AS peer_median_salary,
    salary_quartile,
    CAST(
        100.0 * (salary - peer_median_salary)
        / NULLIF(peer_median_salary, 0)
        AS NUMERIC(10, 2)
    ) AS salary_gap_vs_peer_median_pct,
    churn
FROM employee_peer_benchmark;

-- [DESCRIPTIVE] Employee-level role pay gap + flags -10%/-25%.
DROP VIEW IF EXISTS employees_churn.mart_employee_role_pay_gap;
CREATE VIEW employees_churn.mart_employee_role_pay_gap AS
WITH role_salary_window AS (
    SELECT
        e.*,
        SUM(CAST(e.salary AS NUMERIC(38, 4)))
            OVER (PARTITION BY e.job_role) AS role_salary_sum,
        COUNT(*) OVER (PARTITION BY e.job_role) AS role_employee_count
    FROM employees_churn.employee_info AS e
), employee_role_peer AS (
    SELECT
        r.*,
        (r.role_salary_sum - r.salary)
            / NULLIF(r.role_employee_count - 1, 0) AS role_peer_avg_salary
    FROM role_salary_window AS r
), employee_role_gap AS (
    SELECT
        p.*,
        100.0 * (p.salary - p.role_peer_avg_salary)
            / NULLIF(p.role_peer_avg_salary, 0) AS role_salary_gap_pct
    FROM employee_role_peer AS p
)
SELECT
    employee_id,
    job_role,
    tenure,
    department,
    salary,
    CAST(role_peer_avg_salary AS NUMERIC(18, 2)) AS role_peer_avg_salary,
    CAST(role_salary_gap_pct AS NUMERIC(10, 2)) AS role_salary_gap_pct,
    CASE WHEN role_salary_gap_pct < -10.0 THEN 1 ELSE 0 END AS underpaid_10_flag,
    CASE WHEN role_salary_gap_pct <= -25.0 THEN 1 ELSE 0 END AS underpaid_25_flag,
    performance_rating,
    projects_completed,
    churn
FROM employee_role_gap;

/* ================================================================
   4. KEY TALENT RISK - Report Page 6
   ================================================================ */

-- [DESCRIPTIVE] High-performer churn theo department + role.
DROP VIEW IF EXISTS employees_churn.vw_high_performer_churn;
CREATE VIEW employees_churn.vw_high_performer_churn AS
SELECT
    department,
    job_role,
    COUNT(*) AS high_performer_headcount,
    SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS high_performer_churned,
    CAST(
        100.0 * SUM(CASE WHEN churn THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS NUMERIC(10, 2)
    ) AS high_performer_churn_rate_pct
FROM employees_churn.employee_info
WHERE performance_rating >= 4
GROUP BY department, job_role;

/* ================================================================
   5. EXPLORATORY - GATED (chua du validation)
   ================================================================

   - mart_employee_risk_score: backtest correlation = 0,0029,
     churn khong tang theo decile -> CHUA dung trong dashboard quyet dinh.
   - mart_intervention_candidates: quet 89,91% active employees
     -> qua rong, khong xuat ban.
   Neu sau khi co du lieu lich su ma validation dat, moi dua vao
   dashboard chinh va bao ve bang RLS.
   ================================================================ */

-- Backtest khong dat, nen dam bao cac view employee-level khong ton tai.
DROP VIEW IF EXISTS employees_churn.mart_employee_risk_score;
DROP VIEW IF EXISTS employees_churn.mart_intervention_candidates;

/* ================================================================
   6. POWER BI SEMANTIC MODEL

   Import mart_employee_analytics as the single fact table. The aggregate
   views above remain useful for SQL reconciliation, but should not be
   connected together in the Power BI model.
   ================================================================ */

-- Main employee-grain mart. One row per employee.
DROP VIEW IF EXISTS employees_churn.mart_employee_analytics;
CREATE VIEW employees_churn.mart_employee_analytics AS
SELECT
    e.employee_id,
    e.age,
    CASE
        WHEN e.age < 25 THEN 'Under 25'
        WHEN e.age < 35 THEN '25-34'
        WHEN e.age < 45 THEN '35-44'
        WHEN e.age < 55 THEN '45-54'
        ELSE '55+'
    END AS age_band,
    CASE
        WHEN e.age < 25 THEN 1
        WHEN e.age < 35 THEN 2
        WHEN e.age < 45 THEN 3
        WHEN e.age < 55 THEN 4
        ELSE 5
    END AS age_band_order,
    e.gender,
    e.education_level,
    e.marital_status,
    e.tenure,
    p.tenure_band,
    CASE
        WHEN e.tenure < 1 THEN 1
        WHEN e.tenure < 3 THEN 2
        WHEN e.tenure <= 5 THEN 3
        ELSE 4
    END AS tenure_band_order,
    CAST(2026 AS INTEGER) AS analysis_year,
    2026 - e.tenure AS estimated_hire_year,
    e.job_role,
    e.department,
    CONCAT(e.department, ' | ', e.job_role) AS team_proxy,
    e.work_location,
    e.salary,
    e.performance_rating,
    CASE
        WHEN e.performance_rating <= 2 THEN 'Low (1-2)'
        WHEN e.performance_rating = 3 THEN 'Medium (3)'
        ELSE 'High (4-5)'
    END AS performance_group,
    CASE
        WHEN e.performance_rating <= 2 THEN 1
        WHEN e.performance_rating = 3 THEN 2
        ELSE 3
    END AS performance_group_order,
    e.projects_completed,
    e.training_hours,
    e.promotions,
    e.overtime_hours,
    CASE
        WHEN e.overtime_hours = 0 THEN '0 hours'
        WHEN e.overtime_hours <= 10 THEN '1-10 hours'
        WHEN e.overtime_hours <= 20 THEN '11-20 hours'
        ELSE 'Over 20 hours'
    END AS overtime_band,
    CASE
        WHEN e.overtime_hours = 0 THEN 1
        WHEN e.overtime_hours <= 10 THEN 2
        WHEN e.overtime_hours <= 20 THEN 3
        ELSE 4
    END AS overtime_band_order,
    e.average_monthly_hours_worked,
    CASE
        WHEN e.average_monthly_hours_worked < 180 THEN '150-179'
        WHEN e.average_monthly_hours_worked < 210 THEN '180-209'
        WHEN e.average_monthly_hours_worked < 240 THEN '210-239'
        WHEN e.average_monthly_hours_worked < 270 THEN '240-269'
        ELSE '270+'
    END AS monthly_hours_band,
    CASE
        WHEN e.average_monthly_hours_worked < 180 THEN 1
        WHEN e.average_monthly_hours_worked < 210 THEN 2
        WHEN e.average_monthly_hours_worked < 240 THEN 3
        WHEN e.average_monthly_hours_worked < 270 THEN 4
        ELSE 5
    END AS monthly_hours_band_order,
    e.satisfaction_level,
    CASE
        WHEN e.satisfaction_level < 0.40 THEN 'Low'
        WHEN e.satisfaction_level < 0.70 THEN 'Medium'
        ELSE 'High'
    END AS satisfaction_band,
    CASE
        WHEN e.satisfaction_level < 0.40 THEN 1
        WHEN e.satisfaction_level < 0.70 THEN 2
        ELSE 3
    END AS satisfaction_band_order,
    e.absenteeism,
    e.distance_from_home,
    e.manager_feedback_score,
    CASE
        WHEN e.manager_feedback_score <= 4 THEN 'Low'
        WHEN e.manager_feedback_score <= 7 THEN 'Medium'
        ELSE 'High'
    END AS feedback_band,
    CASE
        WHEN e.manager_feedback_score <= 4 THEN 1
        WHEN e.manager_feedback_score <= 7 THEN 2
        ELSE 3
    END AS feedback_band_order,
    p.peer_count,
    p.peer_avg_salary,
    p.peer_median_salary,
    p.salary_quartile,
    p.salary_gap_vs_peer_median_pct,
    r.role_peer_avg_salary,
    r.role_salary_gap_pct,
    r.underpaid_10_flag,
    r.underpaid_25_flag,
    e.churn
FROM employees_churn.employee_info AS e
LEFT JOIN employees_churn.mart_employee_pay_position AS p
    ON e.employee_id = p.employee_id
LEFT JOIN employees_churn.mart_employee_role_pay_gap AS r
    ON e.employee_id = r.employee_id;

-- Conformed dimensions for slicers and one-to-many relationships.
DROP VIEW IF EXISTS employees_churn.dim_department;
CREATE VIEW employees_churn.dim_department AS
SELECT DISTINCT department
FROM employees_churn.employee_info
WHERE department IS NOT NULL;

DROP VIEW IF EXISTS employees_churn.dim_job_role;
CREATE VIEW employees_churn.dim_job_role AS
SELECT DISTINCT job_role
FROM employees_churn.employee_info
WHERE job_role IS NOT NULL;

DROP VIEW IF EXISTS employees_churn.dim_gender;
CREATE VIEW employees_churn.dim_gender AS
SELECT DISTINCT gender
FROM employees_churn.employee_info
WHERE gender IS NOT NULL;

DROP VIEW IF EXISTS employees_churn.dim_work_location;
CREATE VIEW employees_churn.dim_work_location AS
SELECT DISTINCT work_location
FROM employees_churn.employee_info
WHERE work_location IS NOT NULL;

-- Data dictionary for the Power BI documentation page.
DROP VIEW IF EXISTS employees_churn.mart_data_dictionary;
CREATE VIEW employees_churn.mart_data_dictionary AS
SELECT
    dictionary_scope,
    display_order,
    field_name,
    data_type,
    business_description,
    source_or_logic,
    analysis_role,
    quality_note
FROM (
    VALUES
        ('Input', 1, 'employee_id', 'VARCHAR', 'Unique employee identifier', 'Raw source field', 'Record key and table grain', 'Must be non-null and unique'),
        ('Input', 2, 'age', 'INTEGER', 'Employee age', 'Raw source field', 'Demographic segmentation', 'Validate against a reasonable age range'),
        ('Input', 3, 'gender', 'VARCHAR', 'Recorded employee gender', 'Raw source field', 'Churn segmentation and pay gap analysis', 'Use for descriptive analysis only and do not infer causation'),
        ('Input', 4, 'education_level', 'VARCHAR', 'Highest recorded education level', 'Raw source field', 'Additional employee segmentation', 'Standardize categories when new sources are added'),
        ('Input', 5, 'marital_status', 'VARCHAR', 'Recorded marital status', 'Raw source field', 'Additional employee segmentation', 'Sensitive data that should only be reported in aggregate'),
        ('Input', 6, 'tenure', 'INTEGER', 'Employee tenure in years', 'Raw source field', 'Peer grouping and career analysis', 'Confirm the unit and rounding method'),
        ('Input', 7, 'job_role', 'VARCHAR', 'Employee job role', 'Raw source field', 'Peer grouping, compensation and talent analysis', 'The current dataset contains four roles'),
        ('Input', 8, 'department', 'VARCHAR', 'Employee department', 'Raw source field', 'Organizational segmentation and report filtering', 'The current dataset contains four departments'),
        ('Input', 9, 'salary', 'INTEGER', 'Recorded employee salary', 'Raw source field', 'Compensation analysis', 'Confirm pay period, currency and included components'),
        ('Input', 10, 'work_location', 'VARCHAR', 'Employee work arrangement', 'Raw source field', 'Flexible work segmentation', 'Categories include Remote, Hybrid and On-site'),
        ('Input', 11, 'performance_rating', 'INTEGER', 'Performance rating from 1 to 5', 'Raw source field', 'High performer proxy and compensation analysis', 'A rating of 4 or 5 is used as the temporary high performer definition'),
        ('Input', 12, 'projects_completed', 'INTEGER', 'Number of completed projects', 'Raw source field', 'Performance and workload context', 'Confirm the measurement period'),
        ('Input', 13, 'training_hours', 'INTEGER', 'Recorded training hours', 'Raw source field', 'Employee development analysis', 'Confirm the measurement period'),
        ('Input', 14, 'promotions', 'INTEGER', 'Binary promotion indicator', 'Raw source field', 'Career path analysis', 'The average is interpreted as the promotion rate'),
        ('Input', 15, 'overtime_hours', 'INTEGER', 'Recorded overtime hours', 'Raw source field', 'Workload analysis', 'Confirm the measurement period'),
        ('Input', 16, 'satisfaction_level', 'NUMERIC', 'Employee satisfaction score from 0 to 1', 'Raw source field', 'Employee experience analysis', 'Keep the 0 to 1 scale when creating DAX measures'),
        ('Input', 17, 'work_life_balance', 'NUMERIC', 'Work-life balance score', 'Raw source field', 'Excluded from the current analysis', 'The field is 100% null and excluded from the analytical model'),
        ('Input', 18, 'average_monthly_hours_worked', 'INTEGER', 'Average hours worked per month', 'Raw source field', 'Workload analysis', 'Correlation with churn is -0.0289'),
        ('Input', 19, 'absenteeism', 'INTEGER', 'Recorded absence level', 'Raw source field', 'Employee experience signal', 'Confirm the unit and measurement period'),
        ('Input', 20, 'distance_from_home', 'INTEGER', 'Distance from home to work', 'Raw source field', 'Commute and flexible work context', 'Confirm the distance unit'),
        ('Input', 21, 'manager_feedback_score', 'NUMERIC', 'Manager feedback score from 1 to 10', 'Raw source field', 'Management experience analysis', 'Confirm the scoring method'),
        ('Input', 22, 'churn', 'BOOLEAN', 'Employee churn status', 'TRUE means churned and FALSE means active', 'Primary analysis outcome', 'Non-null with 2,028 TRUE records among 10,000 employees'),

        ('Output', 1, 'employee_id', 'VARCHAR', 'Unique employee identifier', 'Copied from employee_info.employee_id', 'Grain of mart_employee_analytics', 'One row per employee_id'),
        ('Output', 2, 'age', 'INTEGER', 'Employee age', 'Copied from employee_info.age', 'Demographic segmentation', 'Used to derive age_band'),
        ('Output', 3, 'age_band', 'TEXT', 'Age range displayed in the report', 'Under 25; 25-34; 35-44; 45-54; 55+', 'Age segmentation axis and slicer', 'Sort by age_band_order'),
        ('Output', 4, 'age_band_order', 'INTEGER', 'Numeric sort order for age_band', 'Values from 1 to 5', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 5, 'gender', 'VARCHAR', 'Recorded employee gender', 'Copied from employee_info.gender', 'Churn and pay gap analysis', 'Do not use to conclude discrimination'),
        ('Output', 6, 'education_level', 'VARCHAR', 'Highest recorded education level', 'Copied from employee_info.education_level', 'Additional employee segmentation', 'Standardize categories when new sources are added'),
        ('Output', 7, 'marital_status', 'VARCHAR', 'Recorded marital status', 'Copied from employee_info.marital_status', 'Additional employee segmentation', 'Sensitive data'),
        ('Output', 8, 'tenure', 'INTEGER', 'Employee tenure in years', 'Copied from employee_info.tenure', 'Career and peer group analysis', 'Used to estimate hire year'),
        ('Output', 9, 'tenure_band', 'TEXT', 'Non-overlapping tenure range', 'Under 1 year; 1 to under 3 years; 3 to 5 years; Over 5 years', 'Tenure segmentation axis and slicer', 'Sort by tenure_band_order'),
        ('Output', 10, 'tenure_band_order', 'INTEGER', 'Numeric sort order for tenure_band', 'Values from 1 to 4', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 11, 'analysis_year', 'INTEGER', 'Assumed analysis year for the snapshot', 'Constant value 2026', 'Reference year for estimated_hire_year', 'Not an actual snapshot date'),
        ('Output', 12, 'estimated_hire_year', 'INTEGER', 'Estimated employee hire year', '2026 - tenure', 'Exploratory cohort analysis', 'May differ by one year because tenure may be rounded'),
        ('Output', 13, 'job_role', 'VARCHAR', 'Employee job role', 'Copied from employee_info.job_role', 'Peer, salary and talent analysis', 'Relationship key for dim_job_role'),
        ('Output', 14, 'department', 'VARCHAR', 'Employee department', 'Copied from employee_info.department', 'Organizational segmentation', 'Relationship key for dim_department'),
        ('Output', 15, 'team_proxy', 'TEXT', 'Temporary proxy for an employee team', 'Concatenation of department and job_role', 'Analysis when team_id is unavailable', 'Does not replace an actual team identifier'),
        ('Output', 16, 'work_location', 'VARCHAR', 'Employee work arrangement', 'Copied from employee_info.work_location', 'Flexible work segmentation', 'Relationship key for dim_work_location'),
        ('Output', 17, 'salary', 'INTEGER', 'Recorded employee salary', 'Copied from employee_info.salary', 'Compensation KPI and benchmark', 'Confirm the currency and pay unit'),
        ('Output', 18, 'performance_rating', 'INTEGER', 'Performance rating from 1 to 5', 'Copied from employee_info.performance_rating', 'High performer proxy', 'A rating of 4 or 5 is treated as high performance'),
        ('Output', 19, 'performance_group', 'TEXT', 'Grouped performance rating', 'Low 1-2; Medium 3; High 4-5', 'Salary and talent segmentation', 'Sort by performance_group_order'),
        ('Output', 20, 'performance_group_order', 'INTEGER', 'Numeric sort order for performance_group', 'Values from 1 to 3', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 21, 'projects_completed', 'INTEGER', 'Number of completed projects', 'Copied from employee_info.projects_completed', 'Performance context', 'Confirm the measurement period'),
        ('Output', 22, 'training_hours', 'INTEGER', 'Recorded training hours', 'Copied from employee_info.training_hours', 'Employee development analysis', 'Confirm the measurement period'),
        ('Output', 23, 'promotions', 'INTEGER', 'Binary promotion indicator', 'Copied from employee_info.promotions', 'Promotion rate and career analysis', 'The average is interpreted as the promotion rate'),
        ('Output', 24, 'overtime_hours', 'INTEGER', 'Recorded overtime hours', 'Copied from employee_info.overtime_hours', 'Workload KPI', 'Used to derive overtime_band'),
        ('Output', 25, 'overtime_band', 'TEXT', 'Overtime hour range', '0 hours; 1-10 hours; 11-20 hours; Over 20 hours', 'Churn segmentation', 'Sort by overtime_band_order'),
        ('Output', 26, 'overtime_band_order', 'INTEGER', 'Numeric sort order for overtime_band', 'Values from 1 to 4', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 27, 'average_monthly_hours_worked', 'INTEGER', 'Average hours worked per month', 'Copied from employee_info.average_monthly_hours_worked', 'Workload KPI', 'Used to derive monthly_hours_band'),
        ('Output', 28, 'monthly_hours_band', 'TEXT', 'Monthly working hour range', '150-179; 180-209; 210-239; 240-269; 270+', 'Workload heatmap axis', 'Sort by monthly_hours_band_order'),
        ('Output', 29, 'monthly_hours_band_order', 'INTEGER', 'Numeric sort order for monthly_hours_band', 'Values from 1 to 5', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 30, 'satisfaction_level', 'NUMERIC', 'Employee satisfaction score from 0 to 1', 'Copied from employee_info.satisfaction_level', 'Employee experience KPI', 'Used to derive satisfaction_band'),
        ('Output', 31, 'satisfaction_band', 'TEXT', 'Grouped satisfaction level', 'Low below 0.4; Medium below 0.7; High at least 0.7', 'Satisfaction heatmap axis', 'Sort by satisfaction_band_order'),
        ('Output', 32, 'satisfaction_band_order', 'INTEGER', 'Numeric sort order for satisfaction_band', 'Values from 1 to 3', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 33, 'absenteeism', 'INTEGER', 'Recorded absence level', 'Copied from employee_info.absenteeism', 'Employee experience KPI', 'Confirm the unit'),
        ('Output', 34, 'distance_from_home', 'INTEGER', 'Distance from home to work', 'Copied from employee_info.distance_from_home', 'Flexible work context', 'Confirm the distance unit'),
        ('Output', 35, 'manager_feedback_score', 'NUMERIC', 'Manager feedback score from 1 to 10', 'Copied from employee_info.manager_feedback_score', 'Management experience KPI', 'Used to derive feedback_band'),
        ('Output', 36, 'feedback_band', 'TEXT', 'Grouped manager feedback score', 'Low 1-4; Medium above 4 to 7; High above 7 to 10', 'Feedback and promotion analysis', 'Sort by feedback_band_order'),
        ('Output', 37, 'feedback_band_order', 'INTEGER', 'Numeric sort order for feedback_band', 'Values from 1 to 3', 'Technical Sort by column field', 'Hide from report view'),
        ('Output', 38, 'peer_count', 'BIGINT', 'Number of employees in the peer group', 'Count by job_role and tenure_band', 'Benchmark reliability context', 'Small groups require human review'),
        ('Output', 39, 'peer_avg_salary', 'NUMERIC', 'Average salary within the peer group', 'Average salary by job_role and tenure_band', 'Compensation benchmark', 'Does not control for level, skill or location'),
        ('Output', 40, 'peer_median_salary', 'NUMERIC', 'Median salary within the peer group', 'PERCENTILE_CONT(0.5) by job_role and tenure_band', 'Outlier-resistant compensation benchmark', 'Does not control for level, skill or location'),
        ('Output', 41, 'salary_quartile', 'INTEGER', 'Salary quartile within the peer group', 'NTILE(4) ordered by salary', 'Pay position segmentation', 'Not an employee quality ranking'),
        ('Output', 42, 'salary_gap_vs_peer_median_pct', 'NUMERIC', 'Percentage salary gap versus the peer median', '100 * (salary - peer median) / peer median', 'Compensation fairness review', 'A review flag only and not an automatic underpayment conclusion'),
        ('Output', 43, 'role_peer_avg_salary', 'NUMERIC', 'Average salary for the same role excluding the employee', '(role salary sum - salary) / (role employee count - 1)', 'Role-level compensation benchmark', 'Uses a broader peer group than role and tenure'),
        ('Output', 44, 'role_salary_gap_pct', 'NUMERIC', 'Percentage salary gap versus the same-role average', '100 * (salary - role peer average) / role peer average', 'Compensation review', 'Do not use to conclude discrimination'),
        ('Output', 45, 'underpaid_10_flag', 'INTEGER', 'Indicator for salary more than 10% below the same-role average', '1 when role_salary_gap_pct < -10', 'Counts cases requiring review', 'Descriptive flag requiring human review'),
        ('Output', 46, 'underpaid_25_flag', 'INTEGER', 'Indicator for salary at least 25% below the same-role average', '1 when role_salary_gap_pct <= -25', 'Prioritizes compensation review', 'Descriptive flag and not an automatic pay decision'),
        ('Output', 47, 'churn', 'BOOLEAN', 'Employee churn status', 'Copied from employee_info.churn', 'Outcome used by churn measures', 'TRUE means churned and FALSE means active')
) AS dictionary_data(
    dictionary_scope,
    display_order,
    field_name,
    data_type,
    business_description,
    source_or_logic,
    analysis_role,
    quality_note
);

-- QA helper view. It is not imported into the current seven-page report.
DROP VIEW IF EXISTS employees_churn.mart_data_quality_summary;
CREATE VIEW employees_churn.mart_data_quality_summary AS
WITH quality_base AS (
    SELECT
        COUNT(*) AS row_count,
        COUNT(DISTINCT employee_id) AS distinct_employee_count,
        SUM(CASE WHEN employee_id IS NULL THEN 1 ELSE 0 END) AS null_employee_id_count,
        SUM(CASE WHEN churn IS NULL THEN 1 ELSE 0 END) AS invalid_churn_count,
        SUM(CASE WHEN work_life_balance IS NULL THEN 1 ELSE 0 END) AS null_wlb_count
    FROM employees_churn.employee_info
)
SELECT
    q.quality_check,
    q.metric_value,
    q.expected_value,
    q.status,
    q.note,
    CURRENT_TIMESTAMP AS checked_at_utc
FROM quality_base AS b
CROSS JOIN LATERAL (
    VALUES
        (
            'Source row count',
            CAST(b.row_count AS NUMERIC(18, 2)),
            CAST(NULL AS NUMERIC(18, 2)),
            CASE WHEN b.row_count > 0 THEN 'PASS' ELSE 'FAIL' END,
            'Source must contain at least one employee.'
        ),
        (
            'Duplicate employee_id count',
            CAST(
                b.row_count - b.null_employee_id_count - b.distinct_employee_count
                AS NUMERIC(18, 2)
            ),
            CAST(0 AS NUMERIC(18, 2)),
            CASE
                WHEN b.row_count - b.null_employee_id_count = b.distinct_employee_count
                THEN 'PASS' ELSE 'FAIL'
            END,
            'employee_id is expected to be unique.'
        ),
        (
            'Null employee_id count',
            CAST(b.null_employee_id_count AS NUMERIC(18, 2)),
            CAST(0 AS NUMERIC(18, 2)),
            CASE WHEN b.null_employee_id_count = 0 THEN 'PASS' ELSE 'FAIL' END,
            'employee_id is the project grain key.'
        ),
        (
            'Invalid churn count',
            CAST(b.invalid_churn_count AS NUMERIC(18, 2)),
            CAST(0 AS NUMERIC(18, 2)),
            CASE WHEN b.invalid_churn_count = 0 THEN 'PASS' ELSE 'FAIL' END,
            'churn must be either TRUE or FALSE.'
        ),
        (
            'work_life_balance null rate (%)',
            CAST(100.0 * b.null_wlb_count / NULLIF(b.row_count, 0) AS NUMERIC(18, 2)),
            CAST(0 AS NUMERIC(18, 2)),
            CASE WHEN b.null_wlb_count = 0 THEN 'PASS' ELSE 'WARNING' END,
            'Field is excluded from analysis while missing.'
        ),
        (
            'Historical snapshot availability',
            CAST(0 AS NUMERIC(18, 2)),
            CAST(1 AS NUMERIC(18, 2)),
            'WARNING',
            'No snapshot_date or employee history is available.'
        )
) AS q(quality_check, metric_value, expected_value, status, note);

-- Optional governance backlog. It is not imported into the current report.
DROP VIEW IF EXISTS employees_churn.mart_action_backlog;
CREATE VIEW employees_churn.mart_action_backlog AS
SELECT
    action_id,
    priority,
    action_name,
    owner,
    baseline,
    target_kpi,
    status,
    review_cadence,
    decision_gate
FROM (
    VALUES
        (1, 'High', 'Collect monthly employee snapshots', 'People Analytics', '0 months of history', 'At least 6 monthly snapshots', 'Proposed', 'Monthly', 'Required before predictive churn modelling'),
        (2, 'High', 'Capture standardized exit reasons', 'HR Operations', 'No exit_reason field', 'At least 90% of leavers classified', 'Proposed', 'Monthly', 'Required before interpreting churn causes'),
        (3, 'High', 'Repair work-life-balance collection', 'HRIS', '0% populated', 'At least 95% populated', 'Proposed', 'Monthly', 'Required before work-life-balance analysis'),
        (4, 'Medium', 'Review compensation outliers by peer group', 'Compensation Team', 'Descriptive flags only', '100% of -25% outliers reviewed', 'Proposed', 'Quarterly', 'Human review required; no automatic pay decision')
) AS backlog(
    action_id,
    priority,
    action_name,
    owner,
    baseline,
    target_kpi,
    status,
    review_cadence,
    decision_gate
);

-- SQL-side reconciliation between the source and the Power BI fact mart.
DROP VIEW IF EXISTS employees_churn.vw_power_bi_reconciliation;
CREATE VIEW employees_churn.vw_power_bi_reconciliation AS
WITH source_kpi AS (
    SELECT
        COUNT(*) AS row_count,
        COUNT(DISTINCT employee_id) AS employee_count,
        SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_count
    FROM employees_churn.employee_info
), mart_kpi AS (
    SELECT
        COUNT(*) AS row_count,
        COUNT(DISTINCT employee_id) AS employee_count,
        SUM(CASE WHEN churn THEN 1 ELSE 0 END) AS churned_count
    FROM employees_churn.mart_employee_analytics
)
SELECT
    s.row_count AS source_row_count,
    s.employee_count AS source_employee_count,
    s.churned_count AS source_churned_count,
    CAST(100.0 * s.churned_count / NULLIF(s.employee_count, 0) AS NUMERIC(10, 2))
        AS source_churn_rate_pct,
    m.row_count AS mart_row_count,
    m.employee_count AS mart_employee_count,
    m.churned_count AS mart_churned_count,
    CAST(100.0 * m.churned_count / NULLIF(m.employee_count, 0) AS NUMERIC(10, 2))
        AS mart_churn_rate_pct,
    CASE
        WHEN s.row_count = m.row_count
         AND s.employee_count = m.employee_count
         AND s.churned_count = m.churned_count
        THEN 'PASS'
        ELSE 'FAIL'
    END AS reconciliation_status
FROM source_kpi AS s
CROSS JOIN mart_kpi AS m;
