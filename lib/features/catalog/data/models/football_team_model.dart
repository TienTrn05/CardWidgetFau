class FootballTeamModel {
  const FootballTeamModel({required this.id, required this.name});

  final String id;
  final String name;
}

const footballTeamModels = <FootballTeamModel>[
  FootballTeamModel(id: 'algeria', name: 'Algeria'),
  FootballTeamModel(id: 'lafc', name: 'LAFC'),
  FootballTeamModel(id: 'arsenal', name: 'Arsenal'),
];
