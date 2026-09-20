# Assumptions & Limitations — Project 01: B2B Lead-to-Order Analytics

## 1. Synthetic Portfolio Data

All transaction-level records used in this case study are synthetic. They do not represent actual SEPRO customer identities, supplier identities, prices, revenue, payments, or confidential operating records.

The process logic and analytical questions are designed to reflect a B2B workflow I understand from practice while protecting company information.

## 2. Gold Depends on the Silver Layer

This repository assumes the upstream Silver tables have already been:

- cleaned and standardized;
- typed correctly;
- checked for duplicate business keys;
- validated for important relationships;
- reconciled against the Bronze/source layer.

Silver implementation is documented separately at:

https://github.com/FatBoyIL/SEPRO_Cleaning_Data

## 3. Channel Attribution

Channel analysis uses the standardized campaign/channel mapping. Raw source-channel text can contain naming variants and should not be treated as the canonical attribution field.

## 4. Funnel Evidence

Funnel stages use event/business evidence rather than relying only on CRM lifecycle text:

- Quote stage requires quotation evidence.
- Order stage requires Sales Order evidence.
- `lost_reason` is used only **after** the leakage stage has been identified.

## 5. Order Value Is Not Collected Revenue

Project 01 ends at Sales Order. Therefore `Order Value per Lead` is an order-value proxy. It should not be described as actual recognized revenue, invoiced revenue, or collected cash.

## 6. First Response Definition

First Response Time measures time to the earliest recorded Sales activity. A `No Answer` outcome can still represent a legitimate response attempt.

A First Successful Contact metric is not produced because the source/business rules do not formally define which outcome codes count as successful contact.

## 7. Outliers

Extreme response-time values are flagged for investigation but are not automatically removed. A long response may reflect:

- a legitimate delay;
- late CRM data entry;
- incorrect timestamps;
- another data-quality issue.

## 8. Association, Not Causation

If faster-response buckets show higher conversion, the correct interpretation is an **association**. This analysis alone does not prove that response time is the sole cause of conversion differences.

The same caution applies to pre/post intervention analysis unless a stronger causal design is available.

## 9. Salesperson Comparisons

Salesperson performance should not be ranked from response/conversion metrics alone because lead volume, channel mix, product mix, and customer mix can differ across employees.

## 10. Sample Size and Coverage

Small channel/campaign groups and missing attribution should be reviewed before drawing strong conclusions. KPI values without adequate population size can be unstable.
