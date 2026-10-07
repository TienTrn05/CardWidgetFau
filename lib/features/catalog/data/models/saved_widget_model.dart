import 'dart:typed_data';

class SavedWidgetModel {
  const SavedWidgetModel({
    required this.id,
    required this.label,
    this.imageBytes,
  });

  final String id;
  final String label;
  final Uint8List? imageBytes;
}

const initialSavedWidgetModels = <SavedWidgetModel>[
  SavedWidgetModel(id: 'abarth', label: 'ABARTH'),
  SavedWidgetModel(id: 'car_widget', label: 'CAR WIDGET'),
  SavedWidgetModel(id: 'turbo', label: 'TURBO'),
  SavedWidgetModel(id: 'turbo_2', label: 'TURBO'),
  SavedWidgetModel(id: 'turbo_3', label: 'TURBO'),
];
