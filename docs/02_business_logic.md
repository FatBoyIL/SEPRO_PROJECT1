# PROJECT 1 – B2B LEAD-TO-ORDER ANALYSIS GUIDE

## 1. Mục tiêu

Trả lời 3 câu hỏi chính:

1. Channel nào tạo ra lead chất lượng?
2. Lead rơi nhiều nhất ở bước nào của funnel?
3. First Response Time của Sales liên hệ thế nào với Quote / Order conversion?

---

## 2. Điều kiện trước khi phân tích

Chạy:

```sql
validate_project1_kpis.sql
```

Chỉ bắt đầu phân tích khi:

```text
failed_checks = 0
PASS - PROJECT 1 KPI VALIDATED
```

---

## 3. Bắt đầu phân tích từ đâu?

Bảng chính:

```sql
SELECT *
FROM gold.mart_lead_funnel;
```

Grain:

```text
1 row = 1 lead
```

Các field quan trọng:

```text
lead_id
channel
lifecycle_status
qualified_flag
quote_flag
order_flag
first_response_hours
response_bucket
order_count
net_order_value_vnd
```

---

# 4. Flow phân tích

## Step 1 – Data Profiling

Mục tiêu: hiểu dữ liệu trước khi phân tích.

Kiểm tra:

- số lượng lead;
- NULL;
- min / max;
- lifecycle status;
- số lead có / không có Sales Activity;
- phân bố `first_response_hours`.

Kỹ thuật:

```text
COUNT
MIN / MAX
NULL check
Frequency distribution
```

---

## Step 2 – Funnel Analysis

Dùng:

```text
gold.mart_lead_funnel
```

Tính:

```text
Total Leads
→ Qualified Leads
→ Quoted Leads
→ Ordered Leads
```

KPI:

```text
Qualified Lead Rate
Lead-to-Quote Rate
Lead-to-Order Rate
```

Sau đó tính:

```text
Drop-off = Previous Stage - Next Stage
```

Mục tiêu:

> Xác định stage nào mất nhiều lead nhất.

---

## Step 3 – First Response Time Analysis

Field:

```text
first_response_hours
```

Không dùng Average trước.

Tính:

```text
Min
P25 / Q1
Median / P50
P75 / Q3
P90
Max
```

Kỹ thuật:

```text
Descriptive Statistics
Median
Percentile
Distribution Analysis
```

Mục tiêu:

> Hiểu Sales thường phản hồi lead trong bao lâu và dữ liệu có bị lệch mạnh hay không.

---

## Step 4 – IQR Outlier Detection

Công thức:

```text
IQR = Q3 - Q1

Lower Bound = Q1 - 1.5 × IQR
Upper Bound = Q3 + 1.5 × IQR
```

Lead ngoài khoảng trên là potential outlier.

Lưu ý:

```text
Outlier ≠ lỗi dữ liệu
```

Phải kiểm tra:

- timestamp sai?
- data entry sai?
- hay Sales thật sự phản hồi rất chậm?

Không tự động xóa outlier.

---

## Step 5 – Response Time vs Conversion

Dùng:

```text
gold.mart_sales_response
```

So sánh các nhóm:

```text
< 4h
4–12h
12–24h
> 24h
No Sales Activity
```

Theo:

```text
Total Leads
Median First Response Hours
Lead-to-Quote Rate
Lead-to-Order Rate
```

Mục tiêu:

> Kiểm tra response time có association với conversion hay không.

Không kết luận:

```text
response nhanh → gây ra conversion cao
```

Chỉ kết luận association nếu chưa có causal design.

---

## Step 6 – Channel Quality Analysis

Dùng:

```text
gold.mart_channel_quality
```

Phân tích:

```text
Marketing Spend
Total Leads
CPL
Qualified Lead Rate
Lead-to-Quote Rate
Lead-to-Order Rate
Order Value per Lead
```

Mục tiêu:

> Channel nào tạo lead chất lượng, không chỉ CPL thấp?

Không đánh giá channel chỉ bằng 1 KPI.

Nên xem cùng lúc:

```text
CPL
+
Qualified Lead Rate
+
Lead-to-Order Rate
+
Order Value per Lead
```

---

## Step 7 – Optional Statistical Analysis

Chỉ làm sau khi các bước trên đã rõ.

Có thể dùng:

### Chi-square Test

Kiểm tra association:

```text
response_bucket
vs
quote_flag / order_flag
```

### Mann-Whitney U Test

So sánh:

```text
first_response_hours
```

giữa:

```text
Ordered Leads
vs
Non-Ordered Leads
```

Đây là phần nâng cao, không bắt buộc cho bản Junior đầu tiên.

---

# 5. Thứ tự làm thực tế

```text
validate_project1_kpis.sql
        ↓
mart_lead_funnel
        ↓
Data Profiling
        ↓
Funnel Analysis
        ↓
Response Time Distribution
        ↓
Median + Percentiles
        ↓
IQR Outlier Detection
        ↓
mart_sales_response
        ↓
Response vs Conversion
        ↓
mart_channel_quality
        ↓
Channel Quality Analysis
        ↓
Optional Statistical Test
        ↓
Power BI
        ↓
Insight
        ↓
Recommendation
```

---

# 6. Kỹ thuật cần dùng cho Project 1

Nên làm chắc:

```text
Data Profiling
Descriptive Statistics
Median
Percentile
IQR
Outlier Detection
Distribution Analysis
Funnel Analysis
Drop-off Analysis
Conversion Rate Analysis
Group Comparison
```

Có thể làm thêm:

```text
Chi-square Test
Mann-Whitney U Test
```

---

# 7. Power BI sau khi phân tích

## Page 1 – Executive Funnel

```text
Total Leads
Qualified Leads
Quoted Leads
Ordered Leads
Conversion Rate
Drop-off
```

## Page 2 – Channel Quality

```text
CPL
Qualified Lead Rate
Lead-to-Order Rate
Order Value per Lead
Channel / Campaign
```

## Page 3 – Sales Response

```text
Median First Response Hours
Response Bucket Distribution
Lead-to-Quote by Response Bucket
Lead-to-Order by Response Bucket
```

---

# 8. Checklist hoàn thành Project 1 Analysis

```text
[ ] KPI validation PASS
[ ] Data profiling
[ ] Funnel analysis
[ ] Drop-off analysis
[ ] Response distribution
[ ] Median / P25 / P75 / P90
[ ] IQR outlier detection
[ ] Outlier investigation
[ ] Response vs conversion
[ ] Channel quality comparison
[ ] Power BI dashboard
[ ] Insight
[ ] Recommendation
[ ] Limitations / association vs causation
```

## Nguyên tắc quan trọng

```text
Validate first
→ Analyze second
→ Visualize third
→ Recommend last
```
