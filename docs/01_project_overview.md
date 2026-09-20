# Project 1 — B2B Lead-to-Order Analytics

Project này theo dõi hành trình từ lúc một lead xuất hiện cho đến khi phát sinh Sales Order. Điểm quan trọng không phải là “kênh nào có nhiều lead nhất”, mà là hiểu **lead có chất lượng hay không, khách rơi ở đâu trong funnel và tốc độ phản hồi của Sales có liên hệ thế nào với khả năng chuyển đổi**.

Flow chính của project là:

`Lead → Qualified → Quotation → Sales Order`

Tôi tập trung vào ba câu hỏi. Thứ nhất, channel nào tạo lead tốt khi nhìn đồng thời chi phí, chất lượng và giá trị kinh doanh. Thứ hai, funnel đang mất lead nhiều nhất ở bước nào. Thứ ba, lead được Sales phản hồi nhanh hay chậm có khác nhau về tỷ lệ đi tới Quote và Order hay không.

Để tránh đếm sai, phần funnel dùng `gold.mart_lead_funnel` ở grain **1 dòng = 1 lead**. Quote được xác nhận bằng quotation record, còn Order conversion dựa trên Sales Order thực tế. Vì một lead có thể có nhiều activity, quotation hoặc order, việc đưa dữ liệu về lead grain trước khi tính conversion là bắt buộc để tránh fan-out và double counting.

Ở phần funnel, tôi tách rõ **WHERE trước, WHY sau**. Trước tiên xác định lead rơi ở `Lead → Qualified`, `Qualified → Quote` hay `Quote → Order`. Sau đó mới lấy `lost_reason` từ Silver để giải thích nguyên nhân. Cách này tránh việc dùng lý do mất lead để suy ngược stage mà khách đã dừng.

Response time được đo từ thời điểm lead được tạo đến Sales activity đầu tiên. Tôi ưu tiên Median, P25, P75, P90 và IQR vì response time thường có long tail. Outlier không bị xóa tự động; nó được đưa vào danh sách điều tra để phân biệt delay thật với timestamp hoặc data-entry issue.

Channel Quality không có một KPI duy nhất. Tôi nhìn cùng lúc **CPL, Qualified Lead Rate, Lead-to-Order Rate và Order Value per Lead**. Một channel có CPL thấp chưa chắc tốt nếu conversion thấp hoặc giá trị đơn hàng trên mỗi lead thấp. Ngược lại, channel đắt hơn vẫn có thể hợp lý nếu mang về lead chất lượng và giá trị cao hơn.

Phần Sales diagnostic cũng không dùng để gắn nhãn nhân viên tốt/xấu. Tôi kiểm tra Salesperson cùng với lead volume, channel mix, response time và conversion. Source hiện chưa định nghĩa chính xác outcome nào được coi là “successful contact”, nên tôi không tự tạo KPI First Successful Contact; thay vào đó tôi profile các outcome để business chốt rule trước.

Kết quả cuối cùng của Project 1 phải giúp trả lời được: funnel đang rò ở đâu, các lý do mất lead tập trung ở đâu, response bucket nào có conversion khác biệt và channel nào đang tạo trade-off tốt giữa cost, quality và value. Các kết luận về response time chỉ được diễn giải là **association**, không phải causal proof.
