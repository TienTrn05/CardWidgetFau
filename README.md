# CarWidget

Dự án Flutter cho màn hình thiết kế widget, kết hợp Swift và WidgetKit để hiển thị widget trên iOS/CarPlay.

- [Cấu trúc thư mục, danh sách chức năng và ranh giới Flutter/Swift](docs/architecture.md)
- Luồng UI hiện tại: **Loading → Buy → Widget / Sound / Card**, mở Settings từ nút bánh răng. Có thể bỏ qua Buy để khám phá giao diện.
- Giao diện là bản tạm theo phạm vi yêu cầu; chưa đối chiếu được frame Figma vì link không truy cập được trong môi trường triển khai. Mẫu widget/card và dữ liệu hiển thị là dữ liệu minh họa.
- Các lựa chọn được giữ trong phiên sử dụng; chưa có lưu trữ, thanh toán, phát âm thanh, BLoC, native bridge hay WidgetKit target hoạt động.

## Bắt đầu

```sh
flutter pub get
flutter run
```

WidgetKit extension cần được thêm vào `ios/Runner.xcodeproj` bằng Xcode trên macOS. Xem các bước trong tài liệu kiến trúc.
