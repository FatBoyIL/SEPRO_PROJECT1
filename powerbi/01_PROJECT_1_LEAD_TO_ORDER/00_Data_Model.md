# Project 1 — Data Model

## Business scope

**Marketing → Lead → Qualified → Quotation → Sales Order**

Ba câu hỏi:
1. Channel nào tạo lead chất lượng?
2. Lead rơi nhiều nhất ở stage nào và vì sao?
3. First Response Time liên hệ thế nào với Quote/Order conversion?

## Tables cần load

| Query name trong Power BI | Source | Grain | Vai trò |
|---|---|---|---|
| `dim_date` | `gold.dim_date` | 1 row/date | Date slicer |
| `dim_campaign` | `gold.dim_campaign` | 1 campaign | Channel/campaign |
| `dim_customer` | `gold.dim_customer` | 1 customer | Customer diagnostic |
| `dim_employee` | `gold.dim_employee` | 1 employee | Salesperson diagnostic |
| `mart_lead_funnel` | `gold.mart_lead_funnel` | 1 lead | Funnel + response KPI |
| `mart_channel_quality` | `gold.mart_channel_quality` | date × campaign | Spend + channel economics |
| `pbi_p1_lead_diagnostic` | Native SQL trong `01_Source_Queries.sql` | 1 lead | WHERE → WHY bằng `lost_reason` |

## Relationships

```text
dim_date[date_key]        1 ─── * mart_lead_funnel[created_date_key]
dim_campaign[campaign_key] 1 ─ * mart_lead_funnel[campaign_key]
dim_customer[customer_key] 1 ─ * mart_lead_funnel[customer_key]
dim_employee[employee_key] 1 ─ * mart_lead_funnel[employee_key]

dim_date[date_key]        1 ─── * mart_channel_quality[date_key]
dim_campaign[campaign_key] 1 ─ * mart_channel_quality[campaign_key]

dim_date[date_key]        1 ─── * pbi_p1_lead_diagnostic[created_date_key]
dim_campaign[campaign_key] 1 ─ * pbi_p1_lead_diagnostic[campaign_key]
dim_employee[employee_key] 1 ─ * pbi_p1_lead_diagnostic[employee_key]
```

Cross-filter direction: **Single** từ dimension → fact/mart.

Không nối `mart_lead_funnel` trực tiếp với `mart_channel_quality`.

## Date table

Mark `dim_date[date]` as Date Table. Sort `month_name` bằng `month` khi cần.

## Vì sao dùng hai mart?

- Funnel/response cần grain **1 lead** → `mart_lead_funnel`.
- CPL và marketing spend cần grain campaign/date → `mart_channel_quality`.

Nếu lấy spend rồi join vào lead-grain trực tiếp, marketing spend có thể bị nhân theo số lead.
