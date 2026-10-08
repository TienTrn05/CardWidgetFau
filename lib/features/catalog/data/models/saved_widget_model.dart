import 'dart:typed_data';

class SavedWidgetModel {
  const SavedWidgetModel({
    required this.id,
    required this.label,
    this.imageBytes,
    this.layoutId,
  });

  final String id;
  final String label;
  final Uint8List? imageBytes;
  final String? layoutId;
}

enum BrandCarElement { greeting, brand, car, location }

class WidgetElementPosition {
  const WidgetElementPosition(this.x, this.y);

  final double x;
  final double y;

  WidgetElementPosition movedBy(
    double dx,
    double dy, {
    required double maxAbsX,
    required double maxAbsY,
  }) => WidgetElementPosition(
    (x + dx).clamp(-maxAbsX, maxAbsX).toDouble(),
    (y + dy).clamp(-maxAbsY, maxAbsY).toDouble(),
  );
}

class BrandCarLayout {
  const BrandCarLayout({
    this.greeting = const WidgetElementPosition(-0.6, -0.62),
    this.brand = const WidgetElementPosition(0, 0.12),
    this.car = const WidgetElementPosition(0, 0.52),
    this.location = const WidgetElementPosition(0.3, 0.78),
    this.brandScale = 1,
    this.carScale = 1,
    this.carImageIndex = 0,
    this.carImageBytes,
    this.greetingNickname = 'Speed',
    this.greetingFontIndex = 0,
    this.greetingColorValue = 0xFFFFFFFF,
    this.borderColorValue,
    this.borderOpacity = 1,
    this.borderWidth = 2,
  });

  final WidgetElementPosition greeting;
  final WidgetElementPosition brand;
  final WidgetElementPosition car;
  final WidgetElementPosition location;
  final double brandScale;
  final double carScale;
  final int carImageIndex;
  final Uint8List? carImageBytes;
  final String greetingNickname;
  final int greetingFontIndex;
  final int greetingColorValue;
  final int? borderColorValue;
  final double borderOpacity;
  final double borderWidth;

  WidgetElementPosition positionFor(BrandCarElement element) =>
      switch (element) {
        BrandCarElement.greeting => greeting,
        BrandCarElement.brand => brand,
        BrandCarElement.car => car,
        BrandCarElement.location => location,
      };

  BrandCarLayout withPosition(
    BrandCarElement element,
    WidgetElementPosition position,
  ) => switch (element) {
    BrandCarElement.greeting => BrandCarLayout(
      greeting: position,
      brand: brand,
      car: car,
      location: location,
      brandScale: brandScale,
      carScale: carScale,
      carImageIndex: carImageIndex,
      carImageBytes: carImageBytes,
      greetingNickname: greetingNickname,
      greetingFontIndex: greetingFontIndex,
      greetingColorValue: greetingColorValue,
      borderColorValue: borderColorValue,
      borderOpacity: borderOpacity,
      borderWidth: borderWidth,
    ),
    BrandCarElement.brand => BrandCarLayout(
      greeting: greeting,
      brand: position,
      car: car,
      location: location,
      brandScale: brandScale,
      carScale: carScale,
      carImageIndex: carImageIndex,
      carImageBytes: carImageBytes,
      greetingNickname: greetingNickname,
      greetingFontIndex: greetingFontIndex,
      greetingColorValue: greetingColorValue,
      borderColorValue: borderColorValue,
      borderOpacity: borderOpacity,
      borderWidth: borderWidth,
    ),
    BrandCarElement.car => BrandCarLayout(
      greeting: greeting,
      brand: brand,
      car: position,
      location: location,
      brandScale: brandScale,
      carScale: carScale,
      carImageIndex: carImageIndex,
      carImageBytes: carImageBytes,
      greetingNickname: greetingNickname,
      greetingFontIndex: greetingFontIndex,
      greetingColorValue: greetingColorValue,
      borderColorValue: borderColorValue,
      borderOpacity: borderOpacity,
      borderWidth: borderWidth,
    ),
    BrandCarElement.location => BrandCarLayout(
      greeting: greeting,
      brand: brand,
      car: car,
      location: position,
      brandScale: brandScale,
      carScale: carScale,
      carImageIndex: carImageIndex,
      carImageBytes: carImageBytes,
      greetingNickname: greetingNickname,
      greetingFontIndex: greetingFontIndex,
      greetingColorValue: greetingColorValue,
      borderColorValue: borderColorValue,
      borderOpacity: borderOpacity,
      borderWidth: borderWidth,
    ),
  };

  BrandCarLayout withBrandScale(double scale) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: scale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: borderColorValue,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withCarScale(double scale) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: scale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: borderColorValue,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withCarImageIndex(int index) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: index,
    carImageBytes: null,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: borderColorValue,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withCarImageBytes(Uint8List bytes) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: bytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: borderColorValue,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withGreetingNickname(String nickname) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: nickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: borderColorValue,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withGreetingFontIndex(int index) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: index,
    greetingColorValue: greetingColorValue,
  );

  BrandCarLayout withGreetingColorValue(int value) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: value,
    borderColorValue: borderColorValue,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withBorderColor(int? value) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: value,
    borderOpacity: borderOpacity,
    borderWidth: borderWidth,
  );

  BrandCarLayout withBorderOpacity(double value) => BrandCarLayout(
    greeting: greeting,
    brand: brand,
    car: car,
    location: location,
    brandScale: brandScale,
    carScale: carScale,
    carImageIndex: carImageIndex,
    carImageBytes: carImageBytes,
    greetingNickname: greetingNickname,
    greetingFontIndex: greetingFontIndex,
    greetingColorValue: greetingColorValue,
    borderColorValue: borderColorValue,
    borderOpacity: value,
    borderWidth: borderWidth,
  );
}

const initialSavedWidgetModels = <SavedWidgetModel>[
  SavedWidgetModel(id: 'abarth', label: 'ABARTH'),
  SavedWidgetModel(id: 'car_widget', label: 'CAR WIDGET'),
  SavedWidgetModel(id: 'turbo', label: 'TURBO'),
  SavedWidgetModel(id: 'turbo_2', label: 'TURBO'),
  SavedWidgetModel(id: 'turbo_3', label: 'TURBO'),
];

const brandCarWidgetModels = <SavedWidgetModel>[
  SavedWidgetModel(id: 'brand_car_fiat', label: 'FIAT'),
  SavedWidgetModel(id: 'brand_car_acura', label: 'ACURA'),
  SavedWidgetModel(id: 'brand_car_porsche', label: 'PORSCHE'),
  SavedWidgetModel(id: 'brand_car_bmw', label: 'BMW'),
  SavedWidgetModel(id: 'brand_car_mercedes', label: 'MERCEDES'),
];
