class FootballTeamModel {
  const FootballTeamModel({required this.id, required this.name});

  final String id;
  final String name;

  String get imageAsset => 'assets/images/team_$id.png';
}

// UEFA Champions League and Europa League league-phase clubs, 2026/27.
const footballTeamModels = <FootballTeamModel>[
  // UEFA Champions League.
  FootballTeamModel(id: "133753", name: "AEK Athens"),
  FootballTeamModel(id: "arsenal", name: "Arsenal"),
  FootballTeamModel(id: "133601", name: "Aston Villa"),
  FootballTeamModel(id: "133729", name: "Atlético Madrid"),
  FootballTeamModel(id: "133739", name: "Barcelona"),
  FootballTeamModel(id: "133664", name: "Bayern Munich"),
  FootballTeamModel(id: "135497", name: "Bodø/Glimt"),
  FootballTeamModel(id: "133650", name: "Borussia Dortmund"),
  FootballTeamModel(id: "133789", name: "Club Brugge"),
  FootballTeamModel(id: "134243", name: "Como"),
  FootballTeamModel(id: "133758", name: "Feyenoord"),
  FootballTeamModel(id: "133804", name: "Galatasaray"),
  FootballTeamModel(id: "133681", name: "Inter Milan"),
  FootballTeamModel(id: "137261", name: "LASK"),
  FootballTeamModel(id: "133822", name: "Lens"),
  FootballTeamModel(id: "133711", name: "Lille"),
  FootballTeamModel(id: "133602", name: "Liverpool"),
  FootballTeamModel(id: "133613", name: "Manchester City"),
  FootballTeamModel(id: "133612", name: "Manchester United"),
  FootballTeamModel(id: "133670", name: "Napoli"),
  FootballTeamModel(id: "133714", name: "Paris Saint-Germain"),
  FootballTeamModel(id: "134114", name: "Porto"),
  FootballTeamModel(id: "133768", name: "PSV Eindhoven"),
  FootballTeamModel(id: "134695", name: "RB Leipzig"),
  FootballTeamModel(id: "133722", name: "Real Betis"),
  FootballTeamModel(id: "133738", name: "Real Madrid"),
  FootballTeamModel(id: "133682", name: "Roma"),
  FootballTeamModel(id: "138341", name: "Sabah Baku"),
  FootballTeamModel(id: "134126", name: "Shakhtar Donetsk"),
  FootballTeamModel(id: "136036", name: "Slavia Prague"),
  FootballTeamModel(id: "134090", name: "Slovan Bratislava"),
  FootballTeamModel(id: "135708", name: "Sporting CP"),
  FootballTeamModel(id: "133660", name: "Stuttgart"),
  FootballTeamModel(id: "134570", name: "Viking"),
  FootballTeamModel(id: "133740", name: "Villarreal"),
  // UEFA Europa League.
  FootballTeamModel(id: "133667", name: "AC Milan"),
  FootballTeamModel(id: "133776", name: "Anderlecht"),
  FootballTeamModel(id: "137892", name: "Ararat-Armenia"),
  FootballTeamModel(id: "133767", name: "AZ Alkmaar"),
  FootballTeamModel(id: "133666", name: "Bayer Leverkusen"),
  FootballTeamModel(id: "134108", name: "Benfica"),
  FootballTeamModel(id: "133794", name: "Beşiktaş"),
  FootballTeamModel(id: "134301", name: "Bournemouth"),
  FootballTeamModel(id: "134318", name: "Celje"),
  FootballTeamModel(id: "133937", name: "Celta Vigo"),
  FootballTeamModel(id: "133647", name: "Celtic"),
  FootballTeamModel(id: "133632", name: "Crystal Palace"),
  FootballTeamModel(id: "133961", name: "Dinamo Zagreb"),
  FootballTeamModel(id: "134620", name: "Ferencváros"),
  FootballTeamModel(id: "134799", name: "Hapoel Be'er Sheva"),
  FootballTeamModel(id: "133657", name: "Hoffenheim"),
  FootballTeamModel(id: "135297", name: "Jagiellonia Białystok"),
  FootballTeamModel(id: "133676", name: "Juventus"),
  FootballTeamModel(id: "134010", name: "Lech Poznań"),
  FootballTeamModel(id: "134085", name: "Levski Sofia"),
  FootballTeamModel(id: "134569", name: "Lillestrøm"),
  FootballTeamModel(id: "133713", name: "Lyon"),
  FootballTeamModel(id: "133707", name: "Marseille"),
  FootballTeamModel(id: "133760", name: "NEC Nijmegen"),
  FootballTeamModel(id: "133754", name: "Olympiacos"),
  FootballTeamModel(id: "133986", name: "Omonia Nicosia"),
  FootballTeamModel(id: "133970", name: "Red Bull Salzburg"),
  FootballTeamModel(id: "133719", name: "Rennes"),
  FootballTeamModel(id: "137743", name: "Sturm Graz"),
  FootballTeamModel(id: "133603", name: "Sunderland"),
  FootballTeamModel(id: "143720", name: "Torreense"),
  FootballTeamModel(id: "138141", name: "Union Saint-Gilloise"),
  FootballTeamModel(id: "134015", name: "Viktoria Plzeň"),
];

// Retired catalog entries stay readable in previously saved widgets only.
final footballTeamArtworkById = <String, FootballTeamModel>{
  for (final team in footballTeamModels) team.id: team,
  'algeria': const FootballTeamModel(id: 'algeria', name: 'Algeria'),
  'lafc': const FootballTeamModel(id: 'lafc', name: 'LAFC'),
};
