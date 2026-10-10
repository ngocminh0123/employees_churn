/*
    Employee churn - Data quality checks
    Source: employees_churn.employee_info (PostgreSQL, database practice_db)
    Read-only: SELECT/CTE only
*/

-- 1. Duplicate employee IDs checks.
SELECT
    employee_id,
    COUNT(*) AS duplicate_count
FROM employees_churn.employee_info
GROUP BY employee_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, employee_id;

-- 2. Nulls count
SELECT
    COUNT(*) FILTER (WHERE employee_id IS NULL) AS employee_id_null,
    COUNT(*) FILTER (WHERE age IS NULL) AS age_null,
    COUNT(*) FILTER (WHERE gender IS NULL) AS gender_null,
    COUNT(*) FILTER (WHERE education_level IS NULL) AS education_level_null,
    COUNT(*) FILTER (WHERE marital_status IS NULL) AS marital_status_null,
    COUNT(*) FILTER (WHERE tenure IS NULL) AS tenure_null,
    COUNT(*) FILTER (WHERE job_role IS NULL) AS job_role_null,
    COUNT(*) FILTER (WHERE department IS NULL) AS department_null,
    COUNT(*) FILTER (WHERE salary IS NULL) AS salary_null,
    COUNT(*) FILTER (WHERE work_location IS NULL) AS work_location_null,
    COUNT(*) FILTER (WHERE performance_rating IS NULL) AS performance_rating_null,
    COUNT(*) FILTER (WHERE projects_completed IS NULL) AS projects_completed_null,
    COUNT(*) FILTER (WHERE training_hours IS NULL) AS training_hours_null,
    COUNT(*) FILTER (WHERE promotions IS NULL) AS promotions_null,
    COUNT(*) FILTER (WHERE overtime_hours IS NULL) AS overtime_hours_null,
    COUNT(*) FILTER (WHERE satisfaction_level IS NULL) AS satisfaction_level_null,
    COUNT(*) FILTER (WHERE work_life_balance IS NULL) AS work_life_balance_null,
    COUNT(*) FILTER (WHERE average_monthly_hours_worked IS NULL) AS average_monthly_hours_worked_null,
    COUNT(*) FILTER (WHERE absenteeism IS NULL) AS absenteeism_null,
    COUNT(*) FILTER (WHERE distance_from_home IS NULL) AS distance_from_home_null,
    COUNT(*) FILTER (WHERE manager_feedback_score IS NULL) AS manager_feedback_score_null,
    COUNT(*) FILTER (WHERE churn IS NULL) AS churn_null
FROM employees_churn.employee_info;

-- 3. Numeric ranges and invalid-value counts.
SELECT
    MIN(age) AS min_age,
    MAX(age) AS max_age,
    SUM(CASE WHEN age NOT BETWEEN 18 AND 100 THEN 1 ELSE 0 END) AS invalid_age,
    MIN(tenure) AS min_tenure,
    MAX(tenure) AS max_tenure,
    SUM(CASE WHEN tenure < 0 THEN 1 ELSE 0 END) AS invalid_tenure,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    SUM(CASE WHEN salary <= 0 THEN 1 ELSE 0 END) AS invalid_salary,
    MIN(performance_rating) AS min_performance,
    MAX(performance_rating) AS max_performance,
    SUM(CASE WHEN performance_rating NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS invalid_performance,
    MIN(projects_completed) AS min_projects,
    MAX(projects_completed) AS max_projects,
    SUM(CASE WHEN projects_completed < 0 THEN 1 ELSE 0 END) AS invalid_projects,
    MIN(training_hours) AS min_training_hours,
    MAX(training_hours) AS max_training_hours,
    SUM(CASE WHEN training_hours < 0 THEN 1 ELSE 0 END) AS invalid_training,
    MIN(promotions) AS min_promotions,
    MAX(promotions) AS max_promotions,
    SUM(CASE WHEN promotions NOT IN (0, 1) THEN 1 ELSE 0 END) AS invalid_promotions,
    MIN(overtime_hours) AS min_overtime,
    MAX(overtime_hours) AS max_overtime,
    SUM(CASE WHEN overtime_hours < 0 THEN 1 ELSE 0 END) AS invalid_overtime,
    MIN(satisfaction_level) AS min_satisfaction,
    MAX(satisfaction_level) AS max_satisfaction,
    SUM(CASE WHEN satisfaction_level NOT BETWEEN 0 AND 1 THEN 1 ELSE 0 END) AS invalid_satisfaction,
    MIN(average_monthly_hours_worked) AS min_monthly_hours,
    MAX(average_monthly_hours_worked) AS max_monthly_hours,
    SUM(CASE WHEN average_monthly_hours_worked <= 0 THEN 1 ELSE 0 END) AS invalid_monthly_hours,
    MIN(absenteeism) AS min_absenteeism,
    MAX(absenteeism) AS max_absenteeism,
    SUM(CASE WHEN absenteeism < 0 THEN 1 ELSE 0 END) AS invalid_absenteeism,
    MIN(distance_from_home) AS min_distance,
    MAX(distance_from_home) AS max_distance,
    SUM(CASE WHEN distance_from_home < 0 THEN 1 ELSE 0 END) AS invalid_distance,
    MIN(manager_feedback_score) AS min_feedback,
    MAX(manager_feedback_score) AS max_feedback,
    SUM(CASE WHEN manager_feedback_score NOT BETWEEN 1 AND 10 THEN 1 ELSE 0 END) AS invalid_feedback,
    SUM(CASE WHEN churn IS NULL THEN 1 ELSE 0 END) AS invalid_churn
FROM employees_churn.employee_info;