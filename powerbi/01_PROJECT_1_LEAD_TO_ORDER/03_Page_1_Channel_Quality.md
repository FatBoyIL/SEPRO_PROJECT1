# Page 1 — Channel Quality

## Business question

**Nguồn nào tạo lead chất lượng với chi phí hợp lý, chứ không chỉ CPL thấp?**

## Storytelling style

Executive / Commercial. Page này cố tình ít visual nhưng mỗi visual phải có message rõ.

## Layout

```text
┌─────────────────────────────────────────────────────────────┐
│ Channel Quality                         Date | Campaign      │
├───────────┬───────────┬───────────┬─────────────────────────┤
│ Leads     │ CPL       │ L→Order   │ Order Value / Lead      │
├───────────────────────────────────────┬─────────────────────┤
│ HERO: Channel Quality Bubble          │ Channel Scorecard   │
│ X=CPL; Y=L→Order; Size=Order Value/Ld │ Qualified / Quote   │
│                                       │ Spend / Volume      │
├───────────────────────────────────────┴─────────────────────┤
│ Monthly Spend + Lead-to-Order trend / campaign drill-down   │
└─────────────────────────────────────────────────────────────┘
```

## Visual 1 — KPI strip

- Card 1: `[P1 CQ Leads]`
- Card 2: `[P1 CPL]` → currency VND, display units Auto/Millions.
- Card 3: `[P1 Channel Lead to Order Rate]` → %.
- Card 4: `[P1 Channel Order Value per Lead]` → VND.

## Visual 2 — HERO Scatter / Bubble

Power BI visual: **Scatter chart**.

| Bucket | Field |
|---|---|
| X-axis | `[P1 CPL]` |
| Y-axis | `[P1 Channel Lead to Order Rate]` |
| Size | `[P1 Channel Order Value per Lead]` |
| Details | `dim_campaign[channel]` |
| Tooltips | `[P1 Marketing Spend]`, `[P1 CQ Leads]`, `[P1 Channel Qualified Rate]`, `[P1 Channel Lead to Quote Rate]`, `[P1 CQ Net Order Value]` |

Analytics pane:
- X constant line = overall `[P1 CPL]` reference (manual value after validation, or dynamic reference line if version supports it).
- Y constant line = overall Lead-to-Order rate.

Cách đọc:
- **Upper-left:** convert tốt + CPL thấp → attractive.
- **Upper-right:** convert tốt nhưng đắt → xem order value/lead.
- **Lower-left:** rẻ nhưng quality thấp.
- **Lower-right:** vừa đắt vừa convert thấp → cần review.

Không gắn nhãn “best/worst” chỉ từ một metric.

## Visual 3 — Channel scorecard

Matrix:
- Rows: `dim_campaign[channel]`
- Values:
  - `[P1 CQ Leads]`
  - `[P1 CPL]`
  - `[P1 Channel Qualified Rate]`
  - `[P1 Channel Lead to Quote Rate]`
  - `[P1 Channel Lead to Order Rate]`
  - `[P1 Channel Order Value per Lead]`

Conditional formatting:
- Data bars cho Lead count và Order Value/Lead.
- Background scale cho conversion rates.

## Visual 4 — Trend

Line and clustered column chart:
- X: `dim_date[date]` hoặc Month-Year.
- Column: `[P1 Marketing Spend]`
- Line: `[P1 Channel Lead to Order Rate]`
- Small multiples (optional): `dim_campaign[channel]` nếu số channel ít.

## Slicers

- `dim_date[date]`
- `dim_campaign[channel]`
- `dim_campaign[campaign_name]`

## Insight box

Chỉ viết sau khi nhìn data thật. Cấu trúc:

> **Observation:** Channel A có CPL ... nhưng Lead-to-Order ... và Order Value/Lead ...  
> **Implication:** Không nên phân bổ budget chỉ theo CPL; cần cân bằng acquisition cost với conversion và value.
