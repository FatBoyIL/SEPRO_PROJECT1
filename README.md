# SEPRO 01 — B2B Lead-to-Order Analytics

**Gold Layer | Commercial Analytics | SQL Server + Power BI**

This repository is the **Gold Layer** for Project 01 of my SEPRO Data Analytics Portfolio. It starts from cleaned and standardized Silver Layer tables and focuses on business modeling, KPI validation, analytical marts, diagnostic SQL, and Power BI-ready outputs.

The upstream Silver Layer is maintained separately in:

**Silver Layer repository:** https://github.com/FatBoyIL/SEPRO_Cleaning_Data

**Power bi report in processing you could seek for that in power bi folder or you could see this instead:**

https://drive.google.com/file/d/1aKpIxk63aqfpAHCrnGY1kwh3ppN67bp5/view

https://drive.google.com/file/d/1R_dqMuKu3B-7fE9v0dNAB5pDSZtwQdUD/view

https://drive.google.com/file/d/1tmV3wueijgEy6ixx-4hI_4S4xl3RRAy4/view

**This is the original reports when i'm on board with SEPRO ECO CLEAN**

## Portfolio Context

This project is the commercial starting point of a three-project B2B analytics portfolio:

| Project | Scope | Central question |
|---|---|---|
| **01 — Lead-to-Order** | Marketing + Sales | How does demand become an order? |
| 02 — Inventory & Fulfillment | Sales Order + Inventory + Purchasing + Logistics | Can demand be fulfilled reliably and economically? |
| 03 — Lead-to-Cash | Commercial + Operations + Finance | Where are time and working capital lost end-to-end? |

## Data Disclosure

This case study is modeled on a B2B operating process I have worked with and understand in practice. To protect confidential company information, the transaction-level customer, supplier, pricing, revenue, inventory, and payment records used in this portfolio are **synthetically generated**.

The synthetic data is not presented as actual SEPRO financial or customer data. Its purpose is to reproduce realistic business relationships, data-quality problems, process states, and analytical questions so that I can demonstrate how I approach the project from data preparation to decision support.

## Architecture

```text
Synthetic Source Data
        ↓
Bronze Layer
        ↓
Silver Layer
Clean • Standardize • Validate • Reconcile
        ↓
Gold Layer  ←  THIS REPOSITORY
Dimensions • Facts • Analytical Marts • KPI Validation
        ↓
Business Analysis SQL
        ↓
Power BI / Insight / Recommendation
```

The source package intentionally contains imperfect raw-style data, including duplicates, missing values, text variants, mixed date formats, and repeated business events. Those issues are handled upstream in the Silver Layer. This repository assumes the required Silver tables are already cleaned, typed, and join-safe.

## Business Problem

Marketing generates inquiries, but management needs to understand which sources create **revenue-quality demand**, where leads are lost before becoming orders, and whether Sales response behavior is associated with conversion.

The project focuses on the business flow:

```text
Marketing
   ↓
Lead
   ↓
Qualified
   ↓
Quotation
   ↓
Sales Order
```

## Core Business Questions

1. Which acquisition channels create the highest-quality leads, not just the lowest CPL?
2. Where is the largest funnel leakage from **Lead → Qualified → Quote → Order**?
3. How does first response time relate to Lead-to-Quote and Lead-to-Order conversion?

## Gold Layer Scope

### Shared dimensions

- `gold.dim_date`
- `gold.dim_campaign`
- `gold.dim_customer`
- `gold.dim_employee`
- `gold.dim_product`

### Facts

- `gold.fact_lead`
- `gold.fact_sales_activity`
- `gold.fact_quotation`
- `gold.fact_sales_order`
- `gold.fact_sales_order_line`
- `gold.fact_marketing_daily`

### Analytical marts

- `gold.mart_lead_funnel` — one row per lead
- `gold.mart_sales_response` — response-time bucket summary
- `gold.mart_channel_quality` — channel/campaign quality and value metrics

## Main Source Domains Reviewed

The original synthetic source package for this project includes:

- `leads_raw.csv`
- `sales_activities_raw.csv`
- `quotations_raw.csv`
- `quotation_lines_raw.csv`
- `sales_orders_raw.csv`
- `sales_order_lines_raw.csv`
- `marketing_daily_raw.csv`
- shared reference data such as customers, employees, campaigns, and products

Supporting files such as `project_brief.csv`, `business_interventions.csv`, and analytical frameworks are used as business context rather than treated as transactional facts.

## Key Metrics

- Total Leads
- Qualified Lead Rate
- Lead-to-Quote Rate
- Lead-to-Order Rate
- Quote-to-Order Rate
- Funnel Drop-off Rate
- Median First Response Hours
- CPL
- Order Value per Lead

For exact definitions, grain, population, and cautions, see [`docs/04_metric_definitions.md`](docs/04_metric_definitions.md).

## Analysis Approach

The SQL analysis is organized to make the reasoning visible rather than only return final KPIs:

```text
Validate data readiness
        ↓
Confirm lead grain
        ↓
Measure funnel leakage
        ↓
Investigate lost reasons
        ↓
Profile response-time distribution
        ↓
Compare response buckets vs conversion
        ↓
Evaluate channel quality
        ↓
Produce decision-ready conclusion outputs
```

A key principle in this project is **WHERE before WHY**: I first establish the funnel stage where a lead was lost using event evidence, then use `lost_reason` only as a diagnostic attribute.

## Repository Structure

```text
.
├── README.md
├── docs/
│   ├── 01_project_overview.md
│   ├── 02_business_logic.md
│   ├── 03_data_model.md
│   ├── 04_metric_definitions.md
│   ├── 05_assumptions_limitations.md
│   └── 06_review_guide.md
│
├── sql/
│   ├── 00_setup/
│   ├── 01_gold_model/
│   │   ├── dimensions/
│   │   ├── facts/
│   │   └── marts/
│   ├── 02_validation/
│   ├── 03_analysis/
│   │   ├── 01_core/
│   │   └── 02_diagnostics/
│   └── 99_conclusion/
│
├── powerbi/
├── images/
└── data/
    └── sample/
```

## Reproducibility

Recommended execution order:

1. Prepare and validate Silver Layer tables from the upstream repository.
2. Create/load shared Gold dimensions.
3. Create/load Project 01 fact tables.
4. Create/load analytical marts.
5. Run KPI validation.
6. Run core and diagnostic analysis SQL.
7. Use the Gold marts as Power BI sources.

## Analytical Principles Demonstrated

- Define grain before aggregation.
- Do not use `DISTINCT` to hide fan-out problems.
- Reconcile lifecycle status with quotation/order evidence.
- Prefer median/percentiles for skewed response-time distributions.
- Treat outliers as investigation candidates, not automatic errors.
- Compare channel performance using cost, quality, conversion, and value together.
- Describe observational relationships as **associations**, not causal proof.

## Power BI

The intended reporting structure is:

- Executive Funnel
- Channel Quality
- Sales Response

Dashboard screenshots should be stored under `images/`, while the Power BI file belongs in `powerbi/`.

## Documentation

- [`docs/03_data_model.md`](docs/03_data_model.md) — source-to-Gold lineage, grains, and relationships
- [`docs/04_metric_definitions.md`](docs/04_metric_definitions.md) — KPI contracts
- [`docs/05_assumptions_limitations.md`](docs/05_assumptions_limitations.md) — analytical boundaries and caveats
- [`docs/06_review_guide.md`](docs/06_review_guide.md) — step-by-step review guide

---

**Portfolio note:** the business logic is designed to reflect how I understand and analyze the process in practice; the underlying transaction values are synthetic to protect confidential company information.
