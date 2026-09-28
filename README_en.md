# Employee Churn Analysis at ABC Company

**Language:** [Tiếng Việt](README.md) | English

## 1. Business Context

ABC Company has approximately 10,000 employees and had previously maintained relatively stable operations. Recently, however, project delays began occurring more frequently. An initial review found that many delays followed the departure of key employees, resulting in gaps in experience, disrupted handovers, and slower project delivery.

In response, the Board of Directors asked the Human Resources department to investigate the reasons behind employee churn and assess its impact on key talent. The Head of People assigned a People Analyst to analyze the available workforce data, describe the current situation, identify groups that require attention, and recommend suitable retention measures.

The project focuses on four business questions:

1. What is the current employee churn rate, and how does it differ across employee groups?
2. Which factors are associated with churn, and which groups should be prioritized in retention programs?
3. Is compensation equitable among employees with comparable roles and tenure?
4. Which departments or roles have lost the most high-performing employees and should receive priority attention?

---

## 2. Project Structure

| File | Purpose |
|---|---|
| [employee_info.xlsx](employee_info.xlsx) | Input dataset |
| [reporting_marts.sql](reporting_marts.sql) | Creates the views and reporting marts used by Power BI |
| [employee_churn_dashboard.pbip](employee_churn_dashboard.pbip) | Power BI project file |

---

## 3. Input Data

`employee_info.xlsx`

| Item | Result |
|---|---:|
| Employees | 10,000 |
| Data fields | 22 |
| Employees who left | 2,028 |
| Churn rate | 20.28% |
| Duplicate `employee_id` values | 0 |
| Field with all values missing | `work_life_balance` |

### 3.1. Data Dictionary

| Column | Description |
|---|---|
| `employee_id` | Unique employee identifier |
| `age` | Employee age |
| `gender` | Recorded gender: `Male`, `Female`, or `Other` |
| `education_level` | Highest recorded education level |
| `marital_status` | Marital status: `Single`, `Married`, or `Divorced` |
| `tenure` | Employee tenure; the project assumes that the unit is years |
| `job_role` | Job role: `Analyst`, `Developer`, `Manager`, or `Sales` |
| `department` | Department: `IT`, `Sales`, `Marketing`, or `HR` |
| `salary` | Recorded salary; the dataset does not specify the currency or pay period |
| `work_location` | Work arrangement: `Remote`, `Hybrid`, or `On-site` |
| `performance_rating` | Performance rating from 1 to 5 |
| `projects_completed` | Number of completed projects; the dataset does not specify the measurement period |
| `training_hours` | Training hours; the dataset does not specify the measurement period |
| `promotions` | Indicates whether the employee has been promoted |
| `overtime_hours` | Overtime hours; the dataset does not specify the measurement period |
| `satisfaction_level` | Employee satisfaction level from 0 to 1 |
| `work_life_balance` | Work-life balance score; all values in this field are missing |
| `average_monthly_hours_worked` | Average number of hours worked per month |
| `absenteeism` | Recorded days of absence; the dataset does not specify the measurement period |
| `distance_from_home` | Distance from home to work; the dataset does not specify the unit |
| `manager_feedback_score` | Manager feedback score from 1 to 10 |
| `churn` | `True`: employee left; `False`: employee has not left |

The dataset is a point-in-time snapshot and does not include a `snapshot_date`. The project therefore uses 2026 as the reference year. The field `estimated_hire_year = 2026 - tenure` represents an estimated starting year, not an actual hire date.

---

## 4. Project Workflow

![Employee churn analysis project workflow](assets/workflow/employee-churn-workflow-home-v7-human.png)

---

## 5. Current-State Analysis in Power BI

The dashboard is stored in [employee_churn_dashboard.pbip](employee_churn_dashboard.pbip) and uses a 1280 × 720 canvas. The current-state analysis is presented across four main pages covering overall churn, potential churn drivers, compensation, and the loss of high-performing employees.

### 5.1. Executive Overview — Churn Is High but Broadly Distributed

![Employee churn executive overview dashboard](assets/dashboard/executive-overview.png)

The dashboard covers **10,000 employees**, of whom **2,028 have left**, resulting in an overall churn rate of **20.28%**.

Key findings:

- Department-level churn ranges from **20.21% to 20.75%**. Marketing has the highest rate, but the differences across departments are small.
- Employees with more than five years of tenure have a churn rate of **20.93%**, compared with **18.51%** for employees with one to under three years of tenure. This is a descriptive difference and does not establish tenure as a cause of churn.
- Employees with an estimated starting year of 2018 have the highest churn rate at **22.69%**. This value is derived from tenure and the 2026 reference year rather than an actual hire date.
- Churn is not concentrated in a single department, suggesting that retention should be addressed across the company.

**Recommendation:** HR should establish a company-wide retention program while adding targeted measures for groups whose churn rate is above the company baseline.

### 5.2. Churn Drivers — No Single Factor Clearly Explains Employee Churn

![Dashboard of factors associated with employee churn](assets/dashboard/churn-drivers.png)

The dashboard compares churn across gender, overtime, working hours, satisfaction, manager feedback, promotion status, and absenteeism.

Key findings:

- Female employees have a churn rate of **20.99%**, compared with **19.91%** for male employees and **12.44%** for the `Other` group. Most employees are recorded as male or female, while the `Other` group is substantially smaller.
- Employees with no overtime have the highest churn rate at **25.00%**. However, this group contains only 216 employees and should be compared with the other groups cautiously.
- As average monthly hours increase from 150–179 hours to 270 hours or more, the descriptive churn rate falls from **21.37% to 18.32%**. Churn remains close to 20% across all three satisfaction groups.
- Churn is close to 20% across the three manager feedback groups, while promotion rates range only from **9.69% to 10.44%**.
- Average absenteeism is almost identical across departments, ranging from **9.44 to 9.50 days**.

**Recommendation:** the dashboard does not reveal a clearly dominant churn driver. These results describe differences within the current dataset and do not establish cause and effect.

### 5.3. Compensation Fairness — Many Cases Require Review, but the Data Does Not Establish Unfair Pay

![Compensation and pay fairness dashboard](assets/dashboard/compensation-fairness.png)

The dashboard examines salary by employment status, performance, role, gender, and variance from other employees in the same role.

Key findings:

- The company-wide average salary is **89,773**, while the median salary is **89,243**.
- **4,233 employees** earn more than 10% below the average of other employees in the same role; **3,090 employees** are at least 25% below that benchmark.
- Average salary is close to 90,000 for both current employees and employees who have left, providing no clear indication that lower pay directly explains churn.
- Average salary does not rise consistently with performance: 89,949 for the low-performance group, 89,269 for the medium group, and 89,846 for the high group.
- Female employees earn approximately **1.19%** less than male employees before role-level comparison. The difference is smaller after comparing employees within the same role, but a complete assessment would require job level, skills, location, and salary history.

**Recommendation:** these pay differences should be used to create a review list, not to automatically conclude that an employee is underpaid or that the company is engaging in discriminatory pay practices.

### 5.4. Key Talent Risk — Risk Is Concentrated in Several High-Performing IT Groups

![High-performing employee churn risk dashboard](assets/dashboard/key-talent-risk.png)

The dashboard tracks **4,092 high-performing employees**, of whom **823 have left**, producing a churn rate of **20.11%** for this group.

Key findings:

- Marketing has the highest churn rate among high-performing employees at **23.20%**. However, the group contains only 388 employees, substantially fewer than IT.
- IT has the largest number of high-performing employees who left: **337 out of 1,645 employees**.
- The `IT Analyst` group has a churn rate of **23.83%**, representing 112 of 470 high-performing employees. This group warrants priority investigation.
- The `IT Developer` group recorded **126 departures among 658 high-performing employees**, the largest departure count among the highlighted department-role combinations.
- Employees with more than five years of tenure have a churn rate of **20.87%**. Differences by work arrangement are small, ranging from **19.81% to 20.89%**.

In this project, employees with `performance_rating >= 4` are treated as high performers. This is an analytical proxy rather than the company's formal definition of key talent.

**Recommendation:** HR and IT managers should prioritize stay interviews, career-path discussions, and succession planning for Analyst and Developer groups. These results should not be used to rank individual employee risk.

---

## 6. Business Recommendations

1. Hold regular career check-ins between employees and managers, while monitoring employee retention, satisfaction, and internal mobility.
2. Ask HR and the Compensation team to review employees whose salary is at least 25% below the benchmark for the same role. Any adjustment should also consider responsibilities, experience, performance, and scope of work.
3. Review workforce requirements, career paths, and succession plans for `IT Analyst` and `IT Developer`, where a notable number of high-performing employees have left.
4. Add historical data before developing a predictive model or assessing the effectiveness of retention programs.

---

## 7. Limitations

- The dataset does not include historical snapshots, hire dates, termination dates, or reasons for leaving.
- Voluntary and involuntary departures cannot be distinguished.
- `work_life_balance` is entirely missing and is excluded from the analysis.
- The dataset does not include `team_id`, `manager_id`, job level, critical skills, or salary and promotion history.
- Point-in-time data can describe differences between groups but cannot establish causality.

---

## 8. Technology Stack

**Data Source & Storage**

- **Microsoft Excel:** Source dataset `employee_info.xlsx`.
- **DBeaver:** Imports data and provides access to the PostgreSQL database.

**Data Processing & Modeling**

- **PostgreSQL:** Transforms the data and builds fact and dimension tables for Power BI.

**Visualization & Reporting**

- **Microsoft Power BI:** Builds a seven-page interactive dashboard covering churn, compensation, and the loss of high-performing employees.
- **Power Query:** Checks the data before loading it into the data model.
- **DAX:** Creates the measures used in the dashboard.
