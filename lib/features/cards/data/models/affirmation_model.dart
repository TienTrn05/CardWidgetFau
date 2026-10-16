class AffirmationModel {
  const AffirmationModel({
    required this.text,
    required this.date,
    this.textColorValue = 0xFF211917,
    this.backgroundColorValue = 0xFFF5D9CF,
    this.eyebrow,
    this.styleIndex = 0,
  });

  final String text;
  final DateTime date;
  final int textColorValue;
  final int backgroundColorValue;
  final String? eyebrow;
  final int styleIndex;

  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  AffirmationModel copyWith({
    String? text,
    DateTime? date,
    int? textColorValue,
    int? backgroundColorValue,
    int? styleIndex,
  }) => AffirmationModel(
    text: text ?? this.text,
    date: date ?? this.date,
    textColorValue: textColorValue ?? this.textColorValue,
    backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
    eyebrow: eyebrow,
    styleIndex: styleIndex ?? this.styleIndex,
  );
}

List<AffirmationModel> buildDailyAffirmations() {
  final today = DateTime.now();
  return [
    AffirmationModel(
      text: 'I am worthy, capable and deserving of happiness and success.',
      date: today,
      textColorValue: 0xFF211917,
      backgroundColorValue: 0xFFF5D9CF,
    ),
    AffirmationModel(
      text: 'People are going to love what you create.',
      date: today,
      textColorValue: 0xFF164B43,
      backgroundColorValue: 0xFFD6D8D8,
    ),
    AffirmationModel(
      text: 'I release what I cannot control.',
      date: today,
      textColorValue: 0xFFFFFFFF,
      backgroundColorValue: 0xFF62B8DD,
      eyebrow: 'LET IT GO',
    ),
    AffirmationModel(
      text: 'I am becoming stronger with every step.',
      date: today,
      textColorValue: 0xFFF8F2FF,
      backgroundColorValue: 0xFF51407F,
      eyebrow: 'GROW THROUGH IT',
      styleIndex: 1,
    ),
    AffirmationModel(
      text: 'Small steps every day lead to big changes.',
      date: today,
      textColorValue: 0xFF103C32,
      backgroundColorValue: 0xFFE1F1CB,
      eyebrow: 'KEEP GOING',
      styleIndex: 2,
    ),
    AffirmationModel(
      text: 'I trust myself to find the way forward.',
      date: today,
      textColorValue: 0xFF29264D,
      backgroundColorValue: 0xFFDCD7F2,
      eyebrow: 'TRUST YOURSELF',
      styleIndex: 3,
    ),
    AffirmationModel(
      text: 'I can begin again as many times as I need.',
      date: today,
      textColorValue: 0xFFF6F4FF,
      backgroundColorValue: 0xFF263A63,
      eyebrow: 'BEGIN AGAIN',
      styleIndex: 4,
    ),
    AffirmationModel(
      text: 'My pace is still progress.',
      date: today,
      textColorValue: 0xFF5A2347,
      backgroundColorValue: 0xFFF3C9DC,
      eyebrow: 'ONE DAY AT A TIME',
      styleIndex: 5,
    ),
    AffirmationModel(
      text: 'I make room for good things to find me.',
      date: today,
      textColorValue: 0xFF5A4318,
      backgroundColorValue: 0xFFF3E5B5,
      eyebrow: 'OPEN TO GOOD',
      styleIndex: 6,
    ),
    AffirmationModel(
      text: 'I am proud of how far I have come.',
      date: today,
      textColorValue: 0xFF164B43,
      backgroundColorValue: 0xFFBFE1D4,
      eyebrow: 'LOOK HOW FAR',
      styleIndex: 7,
    ),
  ];
}
