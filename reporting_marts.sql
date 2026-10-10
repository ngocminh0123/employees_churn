/*
    REPORTING MARTS FOR POWER BI
    Project:Employee Churn Analysis
                                      */

--Tạo 2 bảng mart phụ (mart_employee_pay_position và mart_employee_role_pay_gap) để gộp vào mart chính (mart_employee_analytics)


-- mart_employee_pay_position
-- Employee-level peer benchmark theo role + tenure band.
DROP VIEW IF EXISTS employees_churn.mart_employee_pay_position;
CREATE VIEW employees_churn.mart_employee_pay_position AS

WITH employee_peer_group AS (
    SELECT
        *,
        CASE
            WHEN tenure < 1 THEN 'Under 1 year'
            WHEN tenure < 3 THEN '1 to under 3 years'
            WHEN tenure <= 5 THEN '3 to 5 years'
            ELSE 'Over 5 years'
        END AS tenure_band
    FROM employees_churn.employee_info
)

, peer_median AS (
    SELECT
        job_role,
        tenure_band,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.salary) AS peer_median_salary
    FROM employee_peer_group
    GROUP BY job_role, tenure_band
)

, employee_peer_benchmark AS (
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


--mart_employee_role_pay_gap
-- Employee-level role pay gap + flags -10%/-25%.
DROP VIEW IF EXISTS employees_churn.mart_employee_role_pay_gap;
CREATE VIEW employees_churn.mart_employee_role_pay_gap AS

WITH role_salary_window AS (
    SELECT
        *,
        SUM(CAST(salary AS NUMERIC(38, 4)))
            OVER (PARTITION BY job_role) AS role_salary_sum,
        COUNT(*) OVER (PARTITION BY job_role) AS role_employee_count
    FROM employees_churn.employee_info
)

, employee_role_peer AS (
    SELECT
        *,
        (role_salary_sum - salary) / NULLIF(role_employee_count - 1, 0) AS role_peer_avg_salary
    FROM role_salary_window
)

, employee_role_gap AS (
    SELECT
        *,
        100.0 * (salary - role_peer_avg_salary) / NULLIF(role_peer_avg_salary, 0) AS role_salary_gap_pct
    FROM employee_role_peer
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


--fact table - mart_employee_analytics (mart chính)

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


-- dim tables
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
