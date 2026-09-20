# SEPRO Power BI Portfolio — 3 Projects

Bộ này là **implementation pack cho Power BI Desktop**, được thiết kế từ database `SEPRO_Master_prod(3).sql` và ba Business Analysis Guide đã đối chiếu.

Mỗi project có đúng **3 trang**, mỗi trang trả lời một câu hỏi business cốt lõi. Ba project dùng chung nguyên tắc trình bày chuyên nghiệp nhưng **không dùng chung một khuôn visual**:

- **Project 1 — Lead-to-Order:** Executive Commercial Storytelling.
- **Project 2 — Inventory & Fulfillment:** Operations Control Tower.
- **Project 3 — Lead-to-Cash:** Process & Finance Narrative.

## Cấu trúc mỗi project

1. `00_Data_Model.md` — table cần load, grain, relationship và model rules.
2. `01_Source_Queries.sql` — helper datasets chỉ dùng khi Gold mart chưa đủ chi tiết cho diagnostic.
3. `02_Measures.dax` — measures + calculated helper tables/columns.
4. `03_Page_1_*.md` — cấu hình visual chi tiết Page 1.
5. `04_Page_2_*.md` — cấu hình visual chi tiết Page 2.
6. `05_Page_3_*.md` — cấu hình visual chi tiết Page 3.
7. `06_Interactions_Navigation.md` — slicer, cross-filter, tooltip, drill-through, bookmarks.
8. `07_Build_Guide.md` — thứ tự dựng từ đầu trong Power BI Desktop.
9. `08_Validation_Checklist.md` — cách đối chiếu Power BI với SQL.
10. `Theme.json` — theme riêng của project.

## Nguyên tắc model

- Dùng **Import mode** cho portfolio để trải nghiệm visual mượt và DAX rõ ràng.
- Dimension lọc Fact/Mart theo hướng **single direction**.
- Không nối Fact ↔ Fact trực tiếp.
- Không dùng `DISTINCT` để che fan-out.
- KPI tỷ lệ luôn tính lại từ numerator/denominator thay vì `AVERAGE(rate)` khi aggregation có thể thay đổi.
- Diagnostic helper query chỉ bổ sung chiều sâu phân tích; KPI chính vẫn dựa trên Gold mart đã validate.

## Thứ tự triển khai

1. Dựng Project 1 và validate số hiện tại.
2. Dựng Project 2 và reconcile với SQL Conclusion của Project 2.
3. Dựng Project 3 và reconcile với SQL Conclusion của Project 3.
4. Sau khi số đúng mới tinh chỉnh typography, spacing, tooltip và bookmarks.

> File này không phải `.pbix`. Môi trường hiện tại không có Power BI Desktop để xuất PBIX. Pack này chứa toàn bộ model/DAX/visual mapping cần thiết để dựng 3 PBIX chính xác trong Power BI Desktop.
