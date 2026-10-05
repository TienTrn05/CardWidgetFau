# CarWidget

Dự án Flutter cho màn hình thiết kế widget, kết hợp Swift và WidgetKit để hiển thị widget trên iOS/CarPlay.

- [Cấu trúc thư mục, danh sách chức năng và ranh giới Flutter/Swift](docs/architecture.md)
- Ứng dụng hiện vẫn là Flutter starter. Các thư mục mới là khung để triển khai theo từng tính năng; chưa có BLoC, native bridge hay WidgetKit target hoạt động.

## Bắt đầu

```sh
flutter pub get
flutter run
```

WidgetKit extension cần được thêm vào `ios/Runner.xcodeproj` bằng Xcode trên macOS. Xem các bước trong tài liệu kiến trúc.
