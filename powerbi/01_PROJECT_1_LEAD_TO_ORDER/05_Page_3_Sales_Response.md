# Page 3 — Sales Response

## Business question

**First Response Time của Sales liên hệ thế nào với Quote/Order conversion?**

## Visual concept

Khác Page 1/2: tập trung distribution và group comparison, không dùng funnel/bubble làm hero.

## KPI row

- `[P1 Median First Response Hours]`
- `[P1 P90 First Response Hours]`
- `[P1 No Sales Activity Rate]`
- `[P1 Lead to Quote Rate]`
- `[P1 Lead to Order Rate]`

Baseline đã chạy:
- Median ≈ **13.9h**
- P25 ≈ 8.45h
- P75 ≈ 23.25h
- P90 ≈ 36.64h
- Max ≈ 5637.42h → long-tail / potential outlier, không tự động xóa.

## HERO — Conversion by Response Bucket

Line and clustered column chart:
- X: `mart_lead_funnel[response_bucket]`
- Column: `[P1 Total Leads]`
- Lines: `[P1 Lead to Quote Rate]`, `[P1 Lead to Order Rate]`

Sort bucket theo business order:
`< 4h → 4-12h → 12-24h → > 24h → No Sales Activity`.

Nếu text trong database khác spacing, tạo Sort column trong Power Query thay vì đổi source value.

## Distribution panel

Option A — native: create bins on `first_response_hours` and use column chart.
- X: response hour bin
- Y: lead count
- Add vertical reference lines for P25/Median/P75/P90 where feasible.

Option B — box-and-whisker requires custom visual; chỉ dùng nếu environment cho phép certified visual. Native-only portfolio thì dùng Option A.

## Salesperson diagnostic matrix

Rows: `dim_employee[employee_name]`  
Columns: `mart_lead_funnel[channel]`  
Values:
- `[P1 Total Leads]`
- `[P1 Median First Response Hours]`
- `[P1 Lead to Quote Rate]`
- `[P1 Lead to Order Rate]`

Mục tiêu: tránh kết luận salesperson tốt/xấu mà không xem channel mix và volume.

## Outlier table

Columns:
- `lead_id`
- `channel`
- `first_response_hours`
- `lifecycle_status`
- `order_flag`

Filter bằng measure logic hoặc Power Query flag `first_response_hours > current IQR upper bound` nếu cần một danh sách cố định.

## Interpretation

Dùng wording:

> Lead ở response bucket nhanh hơn có conversion khác nhóm chậm hơn trong dữ liệu quan sát.

Không dùng:

> Response nhanh **gây ra** conversion cao.
