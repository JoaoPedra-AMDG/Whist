import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/seating.dart';
import '../theme/whist_theme.dart';

class SeatingScreen extends StatefulWidget {
  const SeatingScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<SeatingScreen> createState() => _SeatingScreenState();
}

class _SeatingScreenState extends State<SeatingScreen> {
  late List<int> _seats;
  late int _dealer;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final game = widget.controller.game!;
    _seats = List.of(game.seatOrder);
    _dealer = game.dealerForRound(game.currentRoundIndex);
  }

  void _move(int index, int direction) {
    final target = index + direction;
    if (target < 0 || target >= _seats.length) return;
    setState(() {
      final player = _seats.removeAt(index);
      _seats.insert(target, player);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.updateSeating(_seats, _dealer);
      if (mounted) Navigator.pop(context);
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
    final game = widget.controller.game!;
    final order = callingOrder(_seats, _dealer);
    return Scaffold(
      appBar: AppBar(title: const Text('Seating and dealer')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Round ${game.currentRoundIndex + 1} dealer: ${game.players[_dealer]}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Seats run to the left. Move players with the arrows, then tap the cards beside the dealer.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Call and result order: ${order.map((player) => game.players[player]).join(' → ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _seats.length,
                      itemBuilder: (context, index) {
                        final player = _seats[index];
                        final isDealer = player == _dealer;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: WhistPalette.accentMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    game.players[player],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  tooltip:
                                      'Set ${game.players[player]} as dealer',
                                  onPressed:
                                      _saving
                                          ? null
                                          : () =>
                                              setState(() => _dealer = player),
                                  icon: Icon(
                                    isDealer
                                        ? Icons.style_rounded
                                        : Icons.style_outlined,
                                    color: isDealer ? WhistPalette.gold : null,
                                  ),
                                ),
                                IconButton(
                                  tooltip:
                                      'Move ${game.players[player]} earlier',
                                  onPressed:
                                      _saving || index == 0
                                          ? null
                                          : () => _move(index, -1),
                                  icon: const Icon(Icons.arrow_upward),
                                ),
                                IconButton(
                                  tooltip: 'Move ${game.players[player]} later',
                                  onPressed:
                                      _saving || index == _seats.length - 1
                                          ? null
                                          : () => _move(index, 1),
                                  icon: const Icon(Icons.arrow_downward),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _error!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save seating'),
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
