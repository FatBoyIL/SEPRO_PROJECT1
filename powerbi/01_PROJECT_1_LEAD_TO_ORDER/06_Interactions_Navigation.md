# Project 1 — Interactions & Navigation

## Top navigation

Buttons:
1. Channel Quality
2. Funnel Leakage
3. Sales Response

Dùng Page Navigator để tự highlight page hiện tại.

## Global slicers

Sync across 3 pages:
- Date
- Channel

Campaign slicer chỉ sync Page 1 và Page 2 nếu cần.

## Tooltips

Create tooltip page `TT_P1_Channel`:
- Spend
- Leads
- Qualified rate
- Lead-to-Quote
- Lead-to-Order
- Order Value/Lead

Create tooltip page `TT_P1_Lead` only if needed; do not expose email/phone in portfolio.

## Privacy

Không đưa `email` hoặc `phone` vào Power BI portfolio.

## Cross-filter rules

- Channel bubble filters scorecard/trend.
- Lost reason filters diagnostic detail only, not the main funnel.
- Response bucket filters salesperson matrix only if you want a diagnostic view; do not let salesperson selection alter headline channel economics on another page.
