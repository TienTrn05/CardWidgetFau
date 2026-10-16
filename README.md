# CarWidget

A Flutter app for designing widgets, with Swift and WidgetKit support for the iPhone Home Screen.

- [Cấu trúc thư mục, danh sách chức năng và ranh giới Flutter/Swift](docs/architecture.md)
- Luồng UI hiện tại: **Loading → Buy → Widget / Sound / Card**, mở Settings từ nút bánh răng. Có thể bỏ qua Buy để khám phá giao diện.
- Giao diện là bản tạm theo phạm vi yêu cầu; chưa đối chiếu được frame Figma vì link không truy cập được trong môi trường triển khai. Mẫu widget/card và dữ liệu hiển thị là dữ liệu minh họa.
- My Widgets stays in memory in the Flutter app. iPhone Widget export is temporarily disabled while App Group signing is unavailable; the WidgetKit source remains in the project for later reactivation. Payments and BLoC are not implemented.

## Bắt đầu

```sh
flutter pub get
flutter run
```

## Add an iPhone widget

iPhone Widget export is temporarily disabled until the Apple Developer team can provision the App Group for Runner and the WidgetKit extension. The extension source and Flutter export code remain in the project for later reactivation. CarPlay preview selection remains available.
