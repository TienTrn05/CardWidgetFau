class CountryFlagModel {
  const CountryFlagModel({required this.code, required this.name});

  final String code;
  final String name;
}

const countryFlagModels = <CountryFlagModel>[
  CountryFlagModel(code: 'pt', name: 'Portugal'),
  CountryFlagModel(code: 'al', name: 'Albania'),
  CountryFlagModel(code: 'dz', name: 'Algeria'),
];
