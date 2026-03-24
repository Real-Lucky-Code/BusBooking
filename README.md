# BusBooking

## Overview
BusBooking là hệ thống đặt vé xe buýt với kiến trúc hai tầng: backend API bằng ASP.NET Core 8 và ứng dụng di động đa nền tảng bằng Flutter, hỗ trợ người dùng tìm kiếm, đặt vé, quản lý chuyến đi và đánh giá công ty xe buýt.

## Features
- **Xác thực & quản lý người dùng**: Đăng ký, đăng nhập với JWT, quản lý hồ sơ hành khách (CCCD)
- **Tìm kiếm chuyến đi**: Lọc theo địa điểm, ngày, giá, loại xe, công ty
- **Đặt vé**: Đặt chỗ với giao dịch nguyên tử, quản lý ghế ngồi, áp dụng khuyến mãi
- **Quản lý công ty xe buýt**: Đăng ký công ty (chờ phê duyệt), quản lý xe và tuyến
- **Đánh giá**: Đánh giá công ty (1-5 sao), xem đánh giá trung bình
- **Trang quản trị**: Phê duyệt công ty, quản lý người dùng, thống kê hệ thống
- **Upload**: Tải lên hình ảnh xe buýt
- **Hủy vé**: Yêu cầu hủy, xử lý hoàn tiền

## Tech Stack
- **Backend**: ASP.NET Core 8.0, Entity Framework Core 8.0, SQL Server
- **Frontend**: Flutter (Dart), HTTP client, SharedPreferences
- **Authentication**: JWT với bcrypt hashing
- **Database**: SQL Server với migrations và seeding dữ liệu mẫu
- **API Documentation**: Swagger/OpenAPI

## Highlights
- Áp dụng MVC Pattern với layered architecture
- Xử lý giao dịch nguyên tử cho đặt vé
- Eager loading để tối ưu truy vấn N+1
- Hỗ trợ đa vai trò: User, Provider, Admin
- Quy trình phê duyệt công ty xe buýt
- Giao diện tiếng Việt, định dạng ngày Việt Nam
- API RESTful stateless với JWT

## Prerequisites
- .NET 8.0
- SQL Server (local hoặc Docker)
- Flutter SDK
- Visual Studio 2022 / VS Code
- Android Studio / Xcode (cho phát triển mobile)

## Local Setup

### Backend
1. Clone repository:
   ```
   git clone https://github.com/your-repo/BusBooking.git
   cd BusBooking/backend
   ```

2. Cập nhật connection string trong `appsettings.json`

3. Chạy migrations:
   ```
   dotnet ef database update
   ```

4. Chạy ứng dụng:
   ```
   dotnet run
   ```
   API sẽ chạy tại: http://localhost:5000 (hoặc port được cấu hình)

### Frontend
1. Chuyển đến thư mục frontend:
   ```
   cd ../frontend
   ```

2. Cài đặt dependencies:
   ```
   flutter pub get
   ```

3. Chạy ứng dụng:
   ```
   flutter run
   ```

## Author
Trần Bảo Thiệt - Frontend Developer
