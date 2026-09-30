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
  final List<GlobalKey> _rowKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  late TextEditingController _firstDealer;
  int _cards = 10;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstDealer = _names.last;
  }

  @override
  void dispose() {
    for (final name in _names) {
      name.dispose();
    }
    super.dispose();
  }

  void _showRow(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _rowKeys.length) return;
      final row = _rowKeys[index].currentContext;
      if (row != null) {
        Scrollable.ensureVisible(
          row,
          duration: const Duration(milliseconds: 250),
          alignment: 0.25,
        );
      }
    });
  }

  void _add() {
    if (_names.length >= 52) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _names.add(TextEditingController());
      _rowKeys.add(GlobalKey());
      _cards = _cards.clamp(1, maxStartingCards(_names.length));
      _error = null;
    });
    _showRow(_names.length - 1);
  }

  void _remove(int index) {
    if (_names.length <= 2) return;
    FocusScope.of(context).unfocus();
    late final TextEditingController removed;
    setState(() {
      removed = _names.removeAt(index);
      _rowKeys.removeAt(index);
      if (removed == _firstDealer) _firstDealer = _names.last;
      _cards = _cards.clamp(1, maxStartingCards(_names.length));
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  void _move(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _names.length) return;
    FocusScope.of(context).unfocus();
    setState(() {
      final name = _names.removeAt(index);
      final key = _rowKeys.removeAt(index);
      _names.insert(target, name);
      _rowKeys.insert(target, key);
    });
    _showRow(target);
  }

  Future<void> _start() async {
    FocusScope.of(context).unfocus();
    final players = _names.map((name) => name.text.trim()).toList();
    final empty = players.indexWhere((name) => name.isEmpty);
    if (empty != -1) {
      setState(() => _error = 'Give player ${empty + 1} a name.');
      _showRow(empty);
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
      await widget.controller.start(
        players,
        _cards,
        firstDealer: _names.indexOf(_firstDealer),
      );
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
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                    const Text(
                      'Enter seats in order to the left. Use the arrows to change their order.',
                    ),
                    const SizedBox(height: 16),
                    for (var index = 0; index < _names.length; index++)
                      Padding(
                        key: _rowKeys[index],
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: ValueKey('player-name-${index + 1}'),
                                controller: _names[index],
                                onChanged: (_) => setState(() {}),
                                textCapitalization: TextCapitalization.words,
                                textInputAction:
                                    index == _names.length - 1
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                onSubmitted: (_) {
                                  if (index == _names.length - 1) {
                                    FocusScope.of(context).unfocus();
                                  } else {
                                    FocusScope.of(context).nextFocus();
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Player ${index + 1} name',
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Move player ${index + 1} earlier',
                              onPressed:
                                  index > 0 ? () => _move(index, -1) : null,
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Move player ${index + 1} later',
                              onPressed:
                                  index < _names.length - 1
                                      ? () => _move(index, 1)
                                      : null,
                              icon: const Icon(Icons.arrow_downward),
                            ),
                            IconButton(
                              tooltip: 'Remove player ${index + 1}',
                              onPressed:
                                  _names.length > 2
                                      ? () => _remove(index)
                                      : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _names.length < 52 ? _add : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Add player'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TextEditingController>(
                      key: ValueKey(_firstDealer),
                      value: _firstDealer,
                      decoration: const InputDecoration(
                        labelText: 'First dealer',
                      ),
                      items: [
                        for (var index = 0; index < _names.length; index++)
                          DropdownMenuItem(
                            value: _names[index],
                            child: Text(
                              _names[index].text.trim().isEmpty
                                  ? 'Player ${index + 1}'
                                  : _names[index].text.trim(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (dealer) {
                        if (dealer != null) {
                          setState(() => _firstDealer = dealer);
                        }
                      },
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
                    const SizedBox(height: 12),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
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
      ),
    );
  }
}
