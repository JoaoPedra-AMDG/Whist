import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/game_rules.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  final List<TextEditingController> _names = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _cards = 10;
  bool _saving = false;

  @override
  void dispose() {
    for (final name in _names) {
      name.dispose();
    }
    super.dispose();
  }

  void _add() {
    if (_names.length >= 52) return;
    setState(() {
      _names.add(TextEditingController());
      _cards = _cards.clamp(1, maxStartingCards(_names.length));
    });
  }

  Future<void> _start() async {
    final players = _names.map((name) => name.text.trim()).toList();
    if (players.any((name) => name.isEmpty)) {
      _message('Give every player a name.');
      return;
    }
    if (players.map((name) => name.toLowerCase()).toSet().length !=
        players.length) {
      _message('Player names must be different.');
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.controller.start(players, _cards);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _message('Could not save the game. Please try again.');
      }
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final max = maxStartingCards(_names.length);
    return Scaffold(
      appBar: AppBar(title: const Text('New game')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Players',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                const Text('Enter names in calling order. Drag to reorder.'),
                const SizedBox(height: 16),
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _names.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      _names.insert(newIndex, _names.removeAt(oldIndex));
                    });
                  },
                  itemBuilder:
                      (context, index) => Padding(
                        key: ObjectKey(_names[index]),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ReorderableDragStartListener(
                              index: index,
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(Icons.drag_handle),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _names[index],
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                  labelText: 'Player ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove player',
                              onPressed:
                                  _names.length <= 2
                                      ? null
                                      : () => setState(() {
                                        _names.removeAt(index).dispose();
                                        _cards = _cards.clamp(
                                          1,
                                          maxStartingCards(_names.length),
                                        );
                                      }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                ),
                TextButton.icon(
                  onPressed: _names.length < 52 ? _add : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Add player'),
                ),
                const SizedBox(height: 28),
                Text(
                  'Starting cards',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  '$_cards cards per player · maximum $max with ${_names.length} players',
                ),
                Slider(
                  value: _cards.toDouble(),
                  min: 1,
                  max: max.toDouble(),
                  divisions: max > 1 ? max - 1 : null,
                  label: '$_cards',
                  onChanged: (value) => setState(() => _cards = value.round()),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saving ? null : _start,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_saving ? 'Saving…' : 'Start game'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
