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
