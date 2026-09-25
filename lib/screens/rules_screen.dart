import 'package:flutter/material.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  int _page = 0;
  static const _rules = <(String, String)>[
    (
      'The rounds',
      'Start at your chosen card count. Deal one fewer card each round down to one, play a one-card Blind round, then increase back to the starting count.',
    ),
    (
      'The Blind round',
      'Do not look at your own card. Hold it against your forehead so the other players can see it, then make your call.',
    ),
    (
      'Before each round',
      'In order, each player calls how many tricks they expect to win. The final caller may not make the total calls equal the number of tricks available.',
    ),
    (
      'Playing a trick',
      'The first card sets the lead suit. Follow that suit if you can. If you cannot, play trump if you have it. Otherwise play any card. Trump beats non-trump cards. Without trump, the highest lead-suit card wins. Aces are high.',
    ),
    (
      'Scoring',
      'Each trick won scores one point. Match your call exactly to earn 10 bonus points. All players’ tricks won must add up to the number of cards in the round.',
    ),
    (
      'Corrections',
      'Open the score sheet and tap a completed round to correct its calls or results. Totals update automatically.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('How to play')),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.style_outlined,
                          size: 42,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _rules[_page].$1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _rules[_page].$2,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous rule',
                      onPressed:
                          _page == 0 ? null : () => setState(() => _page--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('${_page + 1} / ${_rules.length}'),
                    IconButton(
                      tooltip: 'Next rule',
                      onPressed:
                          _page >= _rules.length - 1
                              ? null
                              : () => setState(() => _page++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
