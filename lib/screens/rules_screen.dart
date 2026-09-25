import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('How to play')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        _RuleSection(
          'The rounds',
          'Start at your chosen card count. Deal one fewer card each round down to one, play a one-card Blind round, then increase back to the starting count.',
        ),
        _RuleSection(
          'The Blind round',
          'Do not look at your own card. Hold it against your forehead so the other players can see it, then make your call.',
        ),
        _RuleSection(
          'Before each round',
          'In order, each player calls how many tricks they expect to win. The final caller may not make the total calls equal the number of tricks available.',
        ),
        _RuleSection(
          'Playing a trick',
          'The first card sets the lead suit. Follow that suit if you can. If you cannot, play trump if you have it. Otherwise play any card. Trump beats non-trump cards. Without trump, the highest lead-suit card wins. Aces are high.',
        ),
        _RuleSection(
          'Scoring',
          'Each trick won scores one point. Match your call exactly to earn 10 bonus points. All players’ tricks won must add up to the number of cards in the round.',
        ),
        _RuleSection(
          'Corrections',
          'Open the score sheet and tap a completed round to correct its calls or results. Totals update automatically.',
        ),
      ],
    ),
  );
}

class _RuleSection extends StatelessWidget {
  const _RuleSection(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 7),
        Text(body, style: Theme.of(context).textTheme.bodyLarge),
      ],
    ),
  );
}
