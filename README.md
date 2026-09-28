# Phân tích tình trạng nhân viên nghỉ việc tại ABC Company

**Ngôn ngữ:** Tiếng Việt | [English](README_en.md)

## 1. Bối cảnh kinh doanh

ABC Company có khoảng 10.000 nhân viên và trước đây duy trì hoạt động tương đối ổn định. Tuy nhiên, trong thời gian gần đây, một số dự án bắt đầu chậm tiến độ thường xuyên hơn. Qua rà soát ban đầu, công ty nhận thấy nhiều trường hợp chậm trễ xuất hiện sau khi nhân sự chủ chốt nghỉ việc, khiến đội ngũ thiếu hụt kinh nghiệm, việc bàn giao bị gián đoạn và tiến độ thực hiện bị ảnh hưởng.

Trước tình hình đó, Ban Giám đốc yêu cầu bộ phận Nhân sự tìm hiểu nguyên nhân đằng sau tình trạng nghỉ việc và đánh giá mức độ ảnh hưởng đối với đội ngũ nhân sự chủ chốt. Head of People giao cho People Analyst phân tích dữ liệu nhân sự hiện có, làm rõ thực trạng, xác định những nhóm cần được quan tâm và đề xuất các phương án giữ chân phù hợp.

Từ yêu cầu trên, dự án tập trung trả lời bốn nhóm câu hỏi trọng tâm:

1. Tỷ lệ nghỉ việc hiện ở mức nào và có khác biệt đáng kể giữa các nhóm nhân viên hay không?
2. Những yếu tố nào có liên quan đến tình trạng nghỉ việc và nhóm nào cần được ưu tiên trong các chương trình giữ chân nhân viên?
3. Chính sách thu nhập có bảo đảm công bằng giữa những nhân viên có vai trò và thâm niên tương đương hay không?
4. Những phòng ban hoặc vị trí nào đang ghi nhận nhiều nhân viên có hiệu suất cao nghỉ việc và cần được ưu tiên xử lý?

---

## 2. Cấu trúc dự án

| Tệp | Vai trò |
|---|---|
| [employee_info.xlsx](employee_info.xlsx) | Dữ liệu đầu vào |
| [reporting_marts.sql](reporting_marts.sql) | Tạo các view và reporting mart phục vụ Power BI |
| [employee_churn_dashboard.pbip](employee_churn_dashboard.pbip) | Tệp dự án Power BI |

---

## 3. Dữ liệu đầu vào

`employee_info.xlsx`

| Hạng mục | Kết quả |
|---|---:|
| Số nhân viên | 10.000 |
| Số trường dữ liệu | 22 |
| Nhân viên đã nghỉ việc | 2.028 |
| Tỷ lệ nghỉ việc | 20,28% |
| `employee_id` trùng lặp | 0 |
| Trường thiếu toàn bộ dữ liệu | `work_life_balance` |

### 3.1. Danh mục trường dữ liệu

|  Cột | Mô tả |
|---|---|
| `employee_id` | Mã định danh duy nhất của nhân viên |
| `age` | Tuổi của nhân viên |
| `gender` | Giới tính được ghi nhận gồm `Male`, `Female` và `Other` |
| `education_level` | Trình độ học vấn cao nhất được ghi nhận |
| `marital_status` | Tình trạng hôn nhân gồm `Single`, `Married` và `Divorced` |
| `tenure` | Thâm niên của nhân viên; dự án giả định đơn vị là năm |
| `job_role` | Vị trí công việc gồm `Analyst`, `Developer`, `Manager` và `Sales` |
| `department` | Phòng ban gồm `IT`, `Sales`, `Marketing` và `HR` |
| `salary` | Mức lương được ghi nhận; dữ liệu không nêu đơn vị tiền tệ và kỳ trả lương |
| `work_location` | Hình thức làm việc gồm `Remote`, `Hybrid` và `On-site` |
| `performance_rating` | Điểm đánh giá hiệu suất từ 1 đến 5 |
| `projects_completed` | Số dự án đã hoàn thành; dữ liệu không nêu kỳ đo |
| `training_hours` | Số giờ đào tạo; dữ liệu không nêu kỳ đo |
| `promotions` | Cho biết nhân viên có được thăng chức hay không |
| `overtime_hours` | Số giờ làm thêm; dữ liệu không nêu kỳ đo |
| `satisfaction_level` | Mức độ hài lòng của nhân viên, từ 0 đến 1 |
| `work_life_balance` | Chỉ số cân bằng công việc và cuộc sống; trường này thiếu toàn bộ dữ liệu |
| `average_monthly_hours_worked` | Số giờ làm việc trung bình mỗi tháng |
| `absenteeism` | Số ngày vắng mặt được ghi nhận; dữ liệu không nêu kỳ đo |
| `distance_from_home` | Khoảng cách từ nhà đến nơi làm việc; dữ liệu không nêu đơn vị đo |
| `manager_feedback_score` | Điểm phản hồi của quản lý, từ 1 đến 10 |
| `churn` | `True`: đã nghỉ việc; `False`: chưa nghỉ việc |

Bộ dữ liệu chỉ phản ánh tình hình tại một thời điểm và không có trường `snapshot_date`. Vì vậy, dự án sử dụng năm 2026 làm mốc tham chiếu. Trường `estimated_hire_year = 2026 - tenure` chỉ cho biết năm tuyển dụng ước tính, không phải ngày tuyển dụng thực tế.

---

## 4. Quy trình thực hiện

![Quy trình thực hiện dự án phân tích tình trạng nhân viên nghỉ việc](assets/workflow/employee-churn-workflow-home-v7-human.png)

---

## 5. Kết quả phân tích thực trạng trên Power BI

Dashboard được lưu tại [employee_churn_dashboard.pbip](employee_churn_dashboard.pbip), có kích thước hiển thị 1280 × 720. Phần phân tích thực trạng được trình bày qua bốn trang chính, lần lượt làm rõ quy mô churn, các yếu tố có khả năng liên quan, tình hình thu nhập và rủi ro mất nhân sự có hiệu suất cao.

### 5.1. Executive Overview — Churn ở mức cao nhưng phân bổ khá đồng đều

![Dashboard tổng quan tình trạng nghỉ việc](assets/dashboard/executive-overview.png)

Dashboard ghi nhận **10.000 nhân viên**, trong đó **2.028 người đã nghỉ việc**, tương ứng tỷ lệ churn **20,28%**.

Các phát hiện chính:

- Tỷ lệ churn giữa các phòng ban chỉ dao động từ **20,21% đến 20,75%**. Marketing có tỷ lệ cao nhất, nhưng mức chênh lệch giữa các phòng ban nhìn chung nhỏ.
- Nhóm có thâm niên trên 5 năm ghi nhận tỷ lệ churn **20,93%**, cao hơn nhóm 1 đến dưới 3 năm (**18,51%**). Đây là khác biệt mô tả, chưa đủ để kết luận thâm niên là nguyên nhân dẫn đến nghỉ việc.
- Nhân viên có năm bắt đầu làm việc ước tính là 2018 có tỷ lệ churn cao nhất, đạt **22,69%**. Chỉ số này được suy ra từ thâm niên và mốc phân tích năm 2026, không phải năm tuyển dụng thực tế.
- Churn không tập trung rõ rệt tại một phòng ban riêng lẻ, cho thấy vấn đề giữ chân nhân viên cần được xem xét ở phạm vi toàn công ty.

**Đề xuất:** thay vì chỉ tập trung vào một phòng ban, HR nên xây dựng chương trình giữ chân ở cấp công ty và bổ sung các biện pháp riêng cho những nhóm có mức churn cao hơn baseline.

### 5.2. Churn Drivers — Chưa có yếu tố đơn lẻ giải thích rõ tình trạng nghỉ việc

![Dashboard phân tích các yếu tố liên quan đến tình trạng nghỉ việc](assets/dashboard/churn-drivers.png)

Dashboard đối chiếu tỷ lệ churn theo giới tính, thời gian làm thêm, giờ làm việc, mức độ hài lòng, phản hồi của quản lý, tình trạng thăng tiến và số ngày vắng mặt.

Các phát hiện chính:

- Nữ có tỷ lệ churn **20,99%**, nam **19,91%** và nhóm giới tính khác **12,44%**. Phần lớn nhân viên thuộc hai nhóm nam và nữ, trong khi nhóm giới tính khác có quy mô nhỏ hơn đáng kể.
- Nhóm không làm thêm có tỷ lệ churn **25,00%**, cao nhất trong các nhóm overtime. Tuy nhiên, nhóm này chỉ có 216 nhân viên nên cần thận trọng khi so sánh với các nhóm còn lại.
- Khi số giờ làm trung bình tăng từ nhóm 150–179 giờ lên 270 giờ trở lên, tỷ lệ churn mô tả giảm từ **21,37% xuống 18,32%**. Tỷ lệ churn giữa ba nhóm mức độ hài lòng vẫn dao động quanh 20%.
- Tỷ lệ churn ở ba nhóm phản hồi của quản lý đều quanh mức 20%; tỷ lệ được thăng chức cũng chỉ dao động từ **9,69% đến 10,44%**.
- Số ngày vắng mặt trung bình giữa các phòng ban gần như tương đương, nằm trong khoảng **9,44–9,50 ngày**.

**Đề xuất:** dashboard chưa cho thấy một churn driver có mức chênh lệch nổi bật. Các kết quả trên phản ánh sự khác nhau giữa các nhóm trong dữ liệu hiện tại, không khẳng định quan hệ nguyên nhân – kết quả.

### 5.3. Compensation Fairness — Nhiều trường hợp cần rà soát nhưng chưa thể kết luận bất công

![Dashboard phân tích thu nhập và công bằng lương](assets/dashboard/compensation-fairness.png)

Dashboard đánh giá mức lương theo tình trạng nghỉ việc, hiệu suất, vị trí, giới tính và mức chênh lệch so với những nhân viên khác có cùng vai trò.

Các phát hiện chính:

- Mức lương trung bình toàn công ty là **89.773**, trong khi mức lương median là **89.243**.
- Có **4.233 nhân viên** nhận mức lương thấp hơn trung bình của những người khác cùng vai trò trên 10%; trong đó, **3.090 người** thấp hơn từ 25% trở lên.
- Mức lương trung bình của nhân viên đang làm việc và đã nghỉ việc đều xấp xỉ 90.000, chưa cho thấy lương thấp là yếu tố giải thích trực tiếp cho tình trạng nghỉ việc.
- Lương trung bình không tăng đều theo nhóm hiệu suất: nhóm hiệu suất thấp đạt 89.949, nhóm trung bình 89.269 và nhóm cao 89.846.
- Lương trung bình của nữ thấp hơn nam khoảng **1,19%** trước khi đối chiếu theo vai trò. Khoảng cách sau đối chiếu nhỏ hơn, nhưng vẫn cần thêm dữ liệu về cấp bậc, kỹ năng, địa điểm và lịch sử lương để đánh giá đầy đủ.

**Đề xuất:** các mức chênh lệch trên nên được dùng để lập danh sách rà soát, không phải để tự động kết luận một nhân viên đang bị trả lương thấp hoặc doanh nghiệp có hành vi phân biệt đối xử.

### 5.4. Key Talent Risk — Rủi ro tập trung ở một số nhóm hiệu suất cao trong IT

![Dashboard phân tích rủi ro mất nhân sự có hiệu suất cao](assets/dashboard/key-talent-risk.png)

Dashboard theo dõi **4.092 nhân viên có hiệu suất cao**, trong đó **823 người đã nghỉ việc**; tỷ lệ churn của nhóm này là **20,11%**.

Các phát hiện chính:

- Marketing có tỷ lệ churn cao nhất trong nhóm hiệu suất cao, đạt **23,20%**; tuy nhiên quy mô nhóm chỉ có 388 người, thấp hơn đáng kể so với IT.
- IT có số nhân viên hiệu suất cao nghỉ việc lớn nhất, với **337 trường hợp** trên tổng số 1.645 người.
- Nhóm `IT Analyst` có tỷ lệ churn **23,83%**, tương ứng 112 trên 470 nhân viên hiệu suất cao. Đây là nhóm có tỷ lệ đáng chú ý và cần được ưu tiên tìm hiểu.
- Nhóm `IT Developer` ghi nhận **126 nhân viên hiệu suất cao đã nghỉ việc** trên tổng số 658 người, là số lượng nghỉ việc lớn nhất trong các tổ hợp phòng ban – vị trí được nêu bật.
- Nhóm có thâm niên trên 5 năm ghi nhận tỷ lệ churn **20,87%**; chênh lệch theo hình thức làm việc khá nhỏ, từ **19,81% đến 20,89%**.

Trong dự án, nhân viên có `performance_rating >= 4` được xem là nhóm hiệu suất cao. Đây là proxy phục vụ phân tích, chưa phải định nghĩa chính thức về key talent của doanh nghiệp.

**Đề xuất:** HR và quản lý khối IT nên ưu tiên phỏng vấn giữ chân, trao đổi lộ trình nghề nghiệp và xây dựng kế hoạch kế nhiệm cho các nhóm Analyst và Developer; không sử dụng kết quả này để xếp hạng rủi ro ở cấp cá nhân.

---

## 6. Khuyến nghị kinh doanh

1. Duy trì các buổi career check-in định kỳ giữa nhân viên và quản lý; đồng thời theo dõi tỷ lệ duy trì nhân sự, mức độ hài lòng và khả năng luân chuyển nội bộ.
2. Giao bộ phận Nhân sự và Đãi ngộ rà soát trước các trường hợp có mức lương thấp hơn mức tham chiếu của cùng vị trí từ 25% trở lên. Việc điều chỉnh, nếu có, cần cân nhắc đồng thời trách nhiệm công việc, kinh nghiệm, hiệu suất và phạm vi đảm nhiệm.
3. Rà soát nhu cầu nhân sự, lộ trình phát triển và phương án kế nhiệm đối với hai nhóm `IT Analyst` và `IT Developer`, nơi ghi nhận số lượng nhân viên hiệu suất cao nghỉ việc đáng chú ý.
4. Bổ sung dữ liệu lịch sử trước khi phát triển mô hình dự báo hoặc đánh giá hiệu quả của các chương trình giữ chân nhân viên.

---

## 7. Hạn chế

- Dữ liệu không có chuỗi lịch sử, ngày tuyển dụng, ngày nghỉ việc hoặc lý do nghỉ việc.
- Không phân biệt nghỉ việc tự nguyện và không tự nguyện.
- `work_life_balance` thiếu 100% nên bị loại khỏi phân tích.
- Chưa có `team_id`, `manager_id`, cấp bậc, kỹ năng trọng yếu và lịch sử lương/thăng tiến.
- Dữ liệu tại một thời điểm chỉ phản ánh khác biệt giữa các nhóm, không chứng minh được quan hệ nhân quả.
  
---

## 8. Công nghệ sử dụng

**Nguồn dữ liệu & Lưu trữ**

- **Microsoft Excel:** Nguồn dữ liệu gốc `employee_info.xlsx`.
- **DBeaver:** Import dữ liệu và làm việc với PostgreSQL database.

**Xử lý & Mô hình dữ liệu**

- **PostgreSQL:** Thực hiện biến đổi dữ liệu và xây dựng các bảng fact, dimension phục vụ Power BI.

**Trực quan hóa & Báo cáo**

- **Microsoft Power BI:** Xây dựng dashboard tương tác gồm 7 trang, phục vụ phân tích churn, thu nhập và rủi ro mất nhân sự có hiệu suất cao.
- **Power Query:** Kiểm tra dữ liệu trước khi đưa vào data model.
- **DAX:** Xây dựng measures sử dụng trong dashboard.
