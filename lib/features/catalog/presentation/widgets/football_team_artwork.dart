import 'package:flutter/material.dart';

import '../../data/models/football_team_model.dart';

class FootballTeamArtwork extends StatelessWidget {
  const FootballTeamArtwork({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context) {
    final team = footballTeamArtworkById[teamId];
    if (team == null) return const SizedBox.expand();
    return SizedBox.expand(
      child: FractionallySizedBox(
        widthFactor: .88,
        heightFactor: .88,
        child: Image.asset(team.imageAsset, fit: BoxFit.contain),
      ),
    );
  }
}
