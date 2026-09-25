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
  int _selected = 0;
  int _cards = 10;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final name in _names) {
      name.dispose();
    }
    super.dispose();
  }

  void _select(int index) {
    FocusScope.of(context).unfocus();
    setState(() => _selected = index);
  }

  void _add() {
    if (_names.length >= 52) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _names.add(TextEditingController());
      _selected = _names.length - 1;
      _cards = _cards.clamp(1, maxStartingCards(_names.length));
    });
  }

  void _remove() {
    if (_names.length <= 2) return;
    FocusScope.of(context).unfocus();
    late final TextEditingController removed;
    setState(() {
      removed = _names.removeAt(_selected);
      _selected = _selected.clamp(0, _names.length - 1);
      _cards = _cards.clamp(1, maxStartingCards(_names.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _move(int direction) {
    final target = _selected + direction;
    if (target < 0 || target >= _names.length) return;
    FocusScope.of(context).unfocus();
    setState(() {
      final current = _names.removeAt(_selected);
      _names.insert(target, current);
      _selected = target;
    });
  }

  Future<void> _start() async {
    FocusScope.of(context).unfocus();
    final players = _names.map((name) => name.text.trim()).toList();
    if (players.any((name) => name.isEmpty)) {
      setState(() {
        _error =
            'Give every player a name. Use the arrows to find empty names.';
      });
      return;
    }
    if (players.map((name) => name.toLowerCase()).toSet().length !=
        players.length) {
      setState(() => _error = 'Player names must be different.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.start(players, _cards);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = maxStartingCards(_names.length);
    return Scaffold(
      appBar: AppBar(title: const Text('New game')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Players',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text('Enter names in calling order.'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Previous player',
                        onPressed:
                            _selected > 0 ? () => _select(_selected - 1) : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        'Player ${_selected + 1} of ${_names.length}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        tooltip: 'Next player',
                        onPressed:
                            _selected < _names.length - 1
                                ? () => _select(_selected + 1)
                                : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  TextField(
                    key: ValueKey(_names[_selected]),
                    controller: _names[_selected],
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Player ${_selected + 1} name',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _names.length < 52 ? _add : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                      IconButton(
                        tooltip: 'Move earlier',
                        onPressed: _selected > 0 ? () => _move(-1) : null,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Move later',
                        onPressed:
                            _selected < _names.length - 1
                                ? () => _move(1)
                                : null,
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: 'Remove player',
                        onPressed: _names.length > 2 ? _remove : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Text(
                    'Starting cards',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('$_cards per player · maximum $max'),
                  Slider(
                    value: _cards.toDouble(),
                    min: 1,
                    max: max.toDouble(),
                    divisions: max > 1 ? max - 1 : null,
                    label: '$_cards',
                    onChanged:
                        (value) => setState(() => _cards = value.round()),
                  ),
                  const Spacer(),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _error!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () => showDialog<void>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Save details'),
                                        content: Text(_error!),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                ),
                            child: const Text('Details'),
                          ),
                        ],
                      ),
                    ),
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
      ),
    );
  }
}
