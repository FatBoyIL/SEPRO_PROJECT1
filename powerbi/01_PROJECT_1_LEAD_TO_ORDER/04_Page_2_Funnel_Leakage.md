# Page 2 — Funnel Leakage

## Business question

**Lead rơi nhiều nhất ở bước nào, và vì sao?**

## Layout

Page này dùng funnel làm hero, nhưng phần dưới trả lời rõ **WHERE → WHY**.

```text
┌─────────────────────────────────────────────────────────────┐
│ Funnel Leakage                         Date | Channel        │
├──────────┬──────────┬──────────┬──────────┬────────────────┤
│ Leads    │ Qualified│ Quoted   │ Ordered  │ L→Order Rate   │
├───────────────────────────────┬─────────────────────────────┤
│ HERO Funnel                  │ Drop-off by Transition      │
│ Lead→Qualified→Quote→Order   │ Count + Rate                │
├───────────────────────────────┼─────────────────────────────┤
│ WHY: Lost Reason             │ Lead diagnostic table       │
└───────────────────────────────┴─────────────────────────────┘
```

## KPI cards

- `[P1 Total Leads]`
- `[P1 Qualified Leads]`
- `[P1 Quoted Leads]`
- `[P1 Ordered Leads]`
- `[P1 Lead to Order Rate]`

## HERO Funnel

Visual: Funnel.
- Category: `p1_funnel_stage[Stage]`
- Values: `[P1 Funnel Stage Count]`
- Sort stage ascending bằng `Sort`.

Tooltip:
- `[P1 Funnel Stage Rate]`

## Drop-off by transition

Column chart:
- X: `p1_funnel_transition[Transition]`
- Y: `[P1 Dropoff Count]`
- Tooltip: `[P1 Dropoff Rate]`

Current validation baseline from SSMS (unfiltered dataset):
- Lead → Qualified: 329
- Qualified → Quote: 197
- Quote → Order: 175
- Largest proportional leakage: Quote → Order ≈ 54.9%

## WHY — Lost Reason

Bar chart:
- Y: `pbi_p1_lead_diagnostic[lost_reason]`
- X: `[P1 Diagnostic Leads]`
- Visual-level filter: `funnel_outcome <> Converted`.

Add slicer/button for `pbi_p1_lead_diagnostic[funnel_outcome]` so recruiter can click specifically `Quote -> Order` and see reasons.

## Detail table

Columns:
- `lead_id`
- `channel`
- `funnel_outcome`
- `lost_reason`
- `budget_status`
- `inquiry_type`
- `purchase_timeline_days`
- `expected_value_vnd`

## Interaction rule

Selecting a transition or lost reason filters detail table, but the main funnel should **not** be cross-filtered by `lost_reason`; otherwise funnel population becomes misleading. Use **Edit interactions** to disable that path.
