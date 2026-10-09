# Kiến trúc CarWidget

## Nguồn và phạm vi

Danh sách dưới đây được rút ra từ [mô tả và lịch sử phiên bản CarWidgetGo trên App Store](https://apps.apple.com/us/app/car-widgets-carwidgetgo/id6754965592). [Figma Car widget](https://www.figma.com/design/fgE6beTQxWVIy8LcQ4ryHF/Car-widget?node-id=14-93) không truy cập được trong môi trường hiện tại, nên tên màn hình, thứ tự luồng và chi tiết UI của thiết kế **chưa được xác nhận**. Không coi danh sách này là bản sao chính xác của Figma.

App tham khảo tập trung vào widget, không phải ứng dụng thay thế toàn bộ dashboard CarPlay. Apple đặt widget iPhone cỡ `systemSmall` trên màn hình Widgets của CarPlay; hình nền của widget được hệ thống loại bỏ trong ngữ cảnh này. CarPlay widgets là tính năng của iOS 26; app có thể hỗ trợ iOS cũ hơn cho giao diện và widget trên iPhone, nhưng cần điều kiện phiên bản khi hướng dẫn dùng CarPlay. Xem [tài liệu WidgetKit/CarPlay](https://developer.apple.com/documentation/widgetkit/adding-standby-and-carplay-support-to-your-widget) và [WWDC25 của Apple](https://developer.apple.com/videos/play/wwdc2025/216/).

## Danh sách chức năng để lập kế hoạch

| Nhóm | Chức năng được App Store nêu | Vị trí Flutter | Phần iOS liên quan |
| --- | --- | --- | --- |
| Khám phá | Danh sách mẫu, chủ đề car/clock/photo/anniversary/countdown/minimal/premium/dashboard, chọn mẫu | `features/catalog` | Không bắt buộc |
| Thiết kế | Tạo widget từ đầu hoặc từ mẫu; thêm/sửa chữ, font, cỡ, màu; bố cục, nền, màu fill, icon, sticker | `features/editor` | Kết xuất lại bằng SwiftUI trong extension |
| Ảnh | Chọn ảnh xe/ảnh cá nhân, cắt nền tự động | `features/media` | Lưu ảnh đã xử lý vào App Group để extension đọc |
| Widget cá nhân | Lưu, xem lại, sửa, xoá, chọn widget đang dùng | `features/my_widgets` | App Group + `WidgetCenter.reloadTimelines` |
| Nội dung thời gian | Clock, anniversary, countdown; cấu hình ngày và nội dung | `features/editor` | Timeline provider; cập nhật theo lịch phù hợp |
| Âm thanh | Chọn/nghe thử âm thanh kiểu khởi động/kết nối | `features/startup_sounds` | Swift service nếu cần API iOS; hành vi tự phát khi kết nối CarPlay cần xác minh riêng |
| Premium | Paywall, mua gói, khôi phục mua hàng, khoá nội dung premium | `features/premium` | StoreKit hoặc plugin mua hàng được chọn sau |
| Thiết lập | Hướng dẫn thêm widget, cài đặt, liên kết chính sách/hỗ trợ | `features/settings` | Hướng dẫn CarPlay/iOS theo phiên bản hỗ trợ |
| Bắt đầu | Giới thiệu và quyền truy cập ảnh khi cần | `features/onboarding` | Photo picker / quyền hệ thống khi cần |

Các thao tác **sửa/xoá/chọn widget**, onboarding và cài đặt là đề xuất cho sản phẩm này để hoàn chỉnh luồng; App Store không xác nhận từng màn hình tương ứng. Không triển khai chúng như tính năng đã chốt nếu Figma khác.

## Cây thư mục

```text
lib/
  main.dart                   # Entry point
  app/
    di/                       # Đăng ký repository, service, BLoC
    router/                   # Route và deep link
    theme/                    # Màu, typography, theme
  core/
    error/                    # Lỗi dùng chung
    platform/                 # Contract/channel Flutter <-> iOS
    storage/                  # Local storage dùng chung phía Flutter
    ui/                       # Component dùng lại giữa nhiều feature
  features/
    onboarding/presentation/bloc/
    catalog/{data,domain,presentation}/
    editor/{data,domain,presentation}/
    my_widgets/{data,domain,presentation}/
    media/{data,domain,presentation}/
    startup_sounds/{data,domain,presentation}/
    premium/{data,domain,presentation}/
    cards/presentation/       # UI bộ sưu tập card minh họa
    settings/{data,domain,presentation}/
assets/{images,stickers,sounds,templates}/
ios/
  Runner/
    AppDelegate.swift
    NativeBridge/
      Channels/              # Flutter MethodChannel/EventChannel
      Services/              # Ghi App Group, yêu cầu reload WidgetKit, audio
  Shared/
    Models/                  # Codable DTO/schema dùng chung app + extension
    Storage/                 # App Group container và version dữ liệu
  CarWidgetExtension/        # Nguồn dự kiến; CHƯA là Xcode target
    Widgets/                 # WidgetBundle + Widget definitions
    Providers/               # TimelineProvider/AppIntentTimelineProvider
    Views/                   # SwiftUI widget views
    Intents/                 # Tuỳ chọn cấu hình/tương tác
    Resources/               # Asset catalog riêng của extension
docs/architecture.md
test/{core,features}/
```

Trong mỗi feature đã có `presentation/bloc/`; thêm `pages/` và `widgets/` khi bắt đầu làm UI. `domain/` chứa entity, repository contract và use case; `data/` chứa model, data source và repository implementation. Tạo thư mục con khi bắt đầu code feature, tránh nhiều lớp rỗng. Một BLoC quản lý một luồng trạng thái rõ ràng (ví dụ `CatalogBloc`, `EditorBloc`, `MyWidgetsBloc`); state tạm của canvas và gesture có thể giữ cục bộ nếu không cần chia sẻ.

## Luồng dữ liệu đề xuất

```text
Flutter UI -> BLoC -> use case -> repository -> local data / MethodChannel
                                              -> Swift native bridge
                                              -> App Group snapshot + image files
                                              -> WidgetKit timeline -> SwiftUI view
```

Flutter lưu bản thiết kế có version (`schemaVersion`, `id`, `templateId`, danh sách layer, kích thước/màu/font, dữ liệu clock/countdown, đường dẫn ảnh tương đối). Native bridge ghi một snapshot nhỏ, ổn định vào App Group, sau đó gọi `WidgetCenter` reload. Extension đọc snapshot và render bằng SwiftUI; nó không chạy Flutter hoặc đọc trực tiếp trạng thái BLoC. Ảnh phải được lưu trong shared container, không lưu đường dẫn sandbox riêng của Runner. Repository Flutter xử lý migration/schema và kiểm tra dữ liệu trước khi gửi qua channel.

## Thứ tự triển khai

1. Đối chiếu Figma để chốt màn hình, navigation và phạm vi bản đầu.
2. Thêm `flutter_bloc` (và thư viện cần thiết) bằng `flutter pub add`; tạo `app/` bootstrap, router và một feature đầu tiên.
3. Chốt model widget và schema lưu trữ trước khi viết MethodChannel. Dùng tên channel/command có version, ví dụ `carwidget/widget_v1` với `saveSnapshot`, `deleteSnapshot`, `reloadWidgets`.
4. Trên macOS/Xcode, thêm **Widget Extension target** vào `Runner.xcodeproj`; bật cùng App Group cho Runner và extension; đặt source ở `ios/CarWidgetExtension` và khai báo Target Membership. Đừng chỉ tạo file Swift trong thư mục rồi xem như target đã hoạt động.
5. Tạo widget `systemSmall`, kiểm tra StandBy và CarPlay Simulator; xử lý background có thể tháo, chữ đủ lớn và thông tin đọc nhanh. Chỉ thêm App Intents/tương tác phù hợp sau khi kiểm tra trên xe/mô phỏng.
6. Kiểm thử lưu/sửa/xoá, ảnh trong App Group, reload và dữ liệu cũ. Kiểm tra mua hàng, quyền ảnh và âm thanh riêng theo hành vi thực tế được chốt.

## Ranh giới kỹ thuật

- WidgetKit render bằng SwiftUI và có vòng đời riêng; BLoC chỉ chạy trong app Flutter.
- CarPlay widget không cấp quyền thay thế màn hình chính hoặc dashboard của CarPlay. Một số thao tác widget phụ thuộc xe có màn hình cảm ứng và khả năng tích hợp CarPlay của app. [Apple: Adding StandBy and CarPlay support](https://developer.apple.com/documentation/widgetkit/adding-standby-and-carplay-support-to-your-widget).
- Phát âm thanh khi kết nối CarPlay không nên được coi là chức năng mặc định của WidgetKit; cần xác minh API, quyền và chính sách Apple trước khi cam kết.
- Repo hiện chưa có dependency BLoC, target WidgetKit, App Group entitlement hoặc native channel. Các folder này là khung triển khai, không phải chức năng đã chạy.
