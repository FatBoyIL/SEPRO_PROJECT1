# Project 1 — Review Guide

File này dùng để ngày mai kiểm tra lại Project 1 theo đúng thứ tự. Không cần đọc toàn bộ SQL ngay từ đầu; hãy chạy từng file, xem result set và tự trả lời các câu hỏi bên dưới.

## 1. Trước khi chạy analysis

Điều kiện đầu tiên là KPI validation của Project 1 đã PASS. Nếu validation chưa PASS thì chưa nên diễn giải business vì funnel hoặc conversion có thể đang sai từ layer trước.

Bảng chính của project là `gold.mart_lead_funnel`, grain **1 row = 1 lead**. Đây là điểm cần nhớ nhất vì mọi KPI Lead-to-Quote và Lead-to-Order đều dựa trên denominator là lead, không phải quotation line hay sales order line.

## 2. `00_Readiness_Profile.sql`

Mục tiêu của file này là trả lời “dataset tôi sắp phân tích có đủ và có đúng grain không?”.

Kiểm tra lần lượt:

- `total_rows` có bằng `unique_leads` không.
- `duplicate_leads` phải bằng 0.
- khoảng thời gian của lead là từ ngày nào đến ngày nào.
- bao nhiêu lead không có campaign, channel, customer hoặc assigned employee.
- bao nhiêu lead không có Sales activity.
- lifecycle, channel và response bucket có phân bố hợp lý hay có nhóm quá nhỏ.

Nếu duplicate lead khác 0, dừng lại vì funnel sẽ bị double count. Nếu channel NULL nhiều, Channel Quality phải ghi rõ coverage limitation.

## 3. `01_Funnel_Analysis.sql`

File này trả lời **WHERE khách rơi**.

Các stage phải đọc theo thứ tự:

`Lead → Qualified → Quote → Order`

Cần ghi lại hai loại leakage:

- **Drop-off count:** mất bao nhiêu lead.
- **Drop-off rate:** mất bao nhiêu phần trăm so với stage trước.

Hai kết quả này có thể chỉ ra hai vấn đề khác nhau. Một stage có thể mất nhiều lead nhất về số lượng nhưng không phải stage có tỷ lệ mất cao nhất.

Kiểm tra thêm:

- `quote_without_qualified = 0`
- `order_without_quote = 0`

Nếu hai số này khác 0, funnel logic không còn tuần tự và cần quay lại mart logic.

Với dataset hiện tại bạn đã chạy, funnel là **845 → 516 → 319 → 144**. Lead → Qualified mất nhiều nhất về số lượng, còn Quote → Order là leakage lớn nhất về tỷ lệ. Ngày mai hãy chạy lại để xác nhận database vẫn cho đúng kết quả này.

## 4. `02_Funnel_Loss_Reason.sql`

Sau khi biết WHERE, file này mới trả lời **WHY**.

Logic là:

- Lead chưa Qualified → `Lead -> Qualified`
- Qualified nhưng chưa có Quote → `Qualified -> Quote`
- Có Quote nhưng chưa có Order → `Quote -> Order`
- Có Order → Converted, không nằm trong lost-reason analysis

`lost_reason` lấy từ `silver.leads` vì Gold fact không giữ field này. Đây là diagnostic attribute, không dùng để xác định stage.

Khi đọc kết quả, hãy hỏi:

- lý do nào chiếm tỷ trọng lớn nhất ở từng stage;
- cùng một lý do có tập trung ở channel nào không;
- có quá nhiều `Not recorded` hay không;
- nếu `Not recorded` cao thì đây là vấn đề data capture, không phải business conclusion.

## 5. `03_Response_Time_Distribution_Outliers.sql`

Không đọc Average trước. Hãy nhìn theo thứ tự:

`P25 → Median → P75 → P90 → Max`

Nếu Average lớn hơn Median nhiều và Max rất lớn, distribution đang right-skewed. Khi đó Median đại diện cho “typical response” tốt hơn Average.

IQR được dùng để flag potential outlier:

`Upper Bound = Q3 + 1.5 × IQR`

Outlier không đồng nghĩa với lỗi. Với từng lead outlier cần hỏi:

- timestamp có sai không;
- activity được nhập muộn không;
- hay lead thực sự chờ Sales rất lâu.

Kết quả bạn đã chạy trước đó cho Median khoảng **13.9 giờ**, P90 khoảng **36.64 giờ** và Max hơn **5,600 giờ**. Hãy chạy lại để xác nhận.

## 6. `04_Response_vs_Conversion.sql`

So sánh các bucket:

- `< 4h`
- `4–12h`
- `12–24h`
- `> 24h`
- `No Sales Activity`

Với mỗi bucket, đọc:

- số lead;
- Median First Response Hours;
- Lead-to-Quote Rate;
- Lead-to-Order Rate.

Nếu conversion giảm khi response time tăng, cách nói đúng là:

> Lead được phản hồi sớm có conversion cao hơn trong dữ liệu quan sát.

Không được nói:

> Phản hồi chậm gây ra conversion thấp.

Đó là khác biệt giữa association và causality.

## 7. `05_Sales_Channel_Diagnostic.sql`

File này dùng để kiểm tra Sales trong đúng context, không phải làm leaderboard.

Hãy đọc Salesperson cùng:

- lead volume;
- channel mix;
- median / P90 response time;
- Lead-to-Quote;
- Lead-to-Order;
- số lead không có Sales Activity.

Nếu một người có conversion thấp nhưng nhận nhiều lead từ channel khó hơn, không thể kết luận nhân viên đó làm kém chỉ từ KPI tổng.

Phần activity outcome chỉ dùng để xem source hiện có những giá trị gì. Chưa tính First Successful Contact vì business rule cho `outcome` chưa được xác nhận.

## 8. `06_Channel_Quality.sql`

Không chọn channel tốt nhất chỉ từ CPL.

Với từng channel hãy nhìn đồng thời:

- Marketing Spend
- Total Leads
- CPL
- Qualified Lead Rate
- Lead-to-Quote Rate
- Lead-to-Order Rate
- Order Value per Lead

Cách đọc ví dụ:

- CPL thấp + conversion thấp → lead rẻ nhưng chưa chắc tốt.
- CPL cao + conversion và value cao → có thể vẫn đáng đầu tư.
- Lead volume rất thấp → chưa nên kết luận mạnh dù KPI đẹp.

Campaign-level result set dùng để tìm campaign nào kéo performance của channel lên hoặc xuống.

## 9. `99_Project1_Conclusion.sql`

Đây là file dùng khi review hoặc phỏng vấn. Nó gom lại bốn phần:

1. Funnel leakage.
2. Lost reason theo stage.
3. Response time vs conversion.
4. Channel quality trade-off.

Khi trình bày, đừng đọc số theo kiểu báo cáo. Hãy nói theo flow:

> Tôi xác định leakage trước, sau đó drill-down lost reason. Song song, tôi kiểm tra response-time distribution và so conversion theo bucket. Cuối cùng tôi đánh giá channel bằng cả cost, quality, conversion và value thay vì chỉ CPL.

## 10. Checklist hoàn thành

- [ ] KPI validation PASS.
- [ ] Grain 1 lead được xác nhận.
- [ ] Funnel count và rate được tính đúng.
- [ ] WHERE được xác định trước WHY.
- [ ] Lost reason có coverage check.
- [ ] Median/P90/IQR response time đã xem.
- [ ] Outlier không bị xóa tự động.
- [ ] Response vs conversion chỉ diễn giải association.
- [ ] Salesperson được đọc cùng channel mix và volume.
- [ ] Channel Quality dùng nhiều KPI, không dùng CPL một mình.
- [ ] Conclusion SQL chạy được và các result set nhất quán.
