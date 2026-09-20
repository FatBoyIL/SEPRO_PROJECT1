# Metric Definitions — Project 01: B2B Lead-to-Order Analytics

The metrics below are treated as **metric contracts**: each metric has an explicit business meaning, population, formula, grain, and caution.

| Metric | Business meaning | Formula / rule | Grain / population | Primary Gold object | Important note |
|---|---|---|---|---|---|
| **Total Leads** | Number of CRM leads entering the funnel | `COUNT(*)` at one-lead grain | All eligible leads | `mart_lead_funnel` | Do not count activities, quotes, or order lines as leads. |
| **Qualified Lead Rate** | Share of leads that reached qualification | `Qualified Leads / Total Leads` | Lead | `mart_lead_funnel` | Use cleaned qualification logic, not dirty raw status text. |
| **Lead-to-Quote Rate** | Share of leads with at least one quotation | `Quoted Leads / Total Leads` | Lead | `mart_lead_funnel` | Multiple quotation versions still represent one quoted lead. |
| **Lead-to-Order Rate** | Share of leads that became Sales Orders | `Ordered Leads / Total Leads` | Lead | `mart_lead_funnel` | New-order conversion should be separated from repeat orders. |
| **Quote-to-Order Rate** | Share of quoted opportunities that became orders | `Ordered Leads / Quoted Leads` | Lead/opportunity | `mart_lead_funnel` | Do not calculate at quotation-line grain. |
| **Funnel Drop-off Count** | Number of leads lost between two stages | `Previous Stage Count - Next Stage Count` | Funnel stage | Derived from `mart_lead_funnel` | Count and rate answer different questions. |
| **Funnel Drop-off Rate** | Share lost relative to the prior stage | `(Previous - Next) / Previous` | Funnel stage | Derived from `mart_lead_funnel` | Use stage evidence before lost-reason analysis. |
| **Median First Response Hours** | Typical time from lead creation to first recorded Sales activity | median of `first_response_hours` | Leads with recorded Sales activity | `mart_lead_funnel`, `mart_sales_response` | Median is preferred because response time is skewed. |
| **CPL** | Marketing spend required to create one CRM lead | `Marketing Spend / CRM Leads` | Channel / Campaign | `mart_channel_quality` | Lower CPL is not automatically better. Read with quality and conversion. |
| **Order Value per Lead** | Sales Order value generated per acquired lead | `Net Order Value / Total Leads` | Channel / Campaign | `mart_channel_quality` | Denominator includes leads that did not order. This is an order-value proxy, not collected revenue. |

## Response-Time Buckets

The analysis uses these diagnostic groups:

- `< 4h`
- `4–12h`
- `12–24h`
- `> 24h`
- `No Sales Activity`

Conversion is compared across buckets using Lead-to-Quote and Lead-to-Order rates.

## First Response vs First Successful Contact

`First Response` means the earliest recorded Sales activity after lead creation. It does **not** require a successful outcome.

A separate `First Successful Contact` KPI is not calculated unless the business explicitly defines which activity outcomes count as successful contact.

## Channel Quality

There is intentionally no single composite channel score. Channel quality is evaluated by reading several metrics together:

```text
CPL
+ Qualified Lead Rate
+ Lead-to-Order Rate
+ Order Value per Lead
```

This makes the cost-versus-quality trade-off visible instead of hiding it inside arbitrary weights.
