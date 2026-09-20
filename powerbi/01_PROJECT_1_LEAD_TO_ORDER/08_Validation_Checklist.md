# Project 1 — Validation Checklist

With no report filters, current SSMS results supplied in the project are:

| KPI | Expected |
|---|---:|
| Total Leads | 845 |
| Qualified Leads | 516 |
| Quoted Leads | 319 |
| Ordered Leads | 144 |
| Qualified Rate | ~61.07% |
| Lead-to-Quote | ~37.75% |
| Lead-to-Order | ~17.04% |
| Lead→Qualified Drop | 329 |
| Qualified→Quote Drop | 197 |
| Quote→Order Drop | 175 |
| Quote→Order Drop Rate | ~54.86% |
| Median First Response | 13.9h |
| P25 | 8.45h |
| P75 | 23.25h |
| P90 | ~36.64h |

If Power BI does not match:
1. Check relationship direction.
2. Check Date filter is cleared.
3. Check channel/campaign slicers.
4. Verify funnel measures use `DISTINCTCOUNT(lead_id)`.
5. Verify channel economics come from `mart_channel_quality`, not a spend join at lead grain.
