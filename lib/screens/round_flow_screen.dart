import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/game_rules.dart';
import '../logic/scoring.dart';

enum RoundStage { calls, callsReady, results, summary }

class RoundFlowScreen extends StatefulWidget {
  const RoundFlowScreen({
    super.key,
    required this.controller,
    required this.roundIndex,
    this.initialStage = RoundStage.calls,
    this.editing = false,
  });

  final GameController controller;
  final int roundIndex;
  final RoundStage initialStage;
  final bool editing;

  @override
  State<RoundFlowScreen> createState() => _RoundFlowScreenState();
}

class _RoundFlowScreenState extends State<RoundFlowScreen> {
  late Map<int, int> _calls;
  late Map<int, int> _wins;
  late RoundStage _stage;
  int _person = 0;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final round = widget.controller.game!.rounds[widget.roundIndex];
    _calls = Map.of(round.calls);
    _wins = Map.of(round.wins);
    _stage = widget.initialStage;
    if (_stage == RoundStage.calls && !widget.editing) {
      _person = _firstMissing(_calls);
    } else if (_stage == RoundStage.results) {
      _person = _firstMissing(_wins);
    }
  }

  int _firstMissing(Map<int, int> values) {
    final count = widget.controller.game!.players.length;
    for (var index = 0; index < count; index++) {
      if (!values.containsKey(index)) return index;
    }
    return 0;
  }

  Future<void> _persistDraft() async {
    if (widget.editing) return;
    try {
      await widget.controller.saveDraft(widget.roundIndex, _calls, _wins);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Save failed. Tap a number to try again.');
      }
    }
  }

  Future<void> _chooseCall(int value) async {
    if (_busy) return;
    final game = widget.controller.game!;
    final last = game.players.length - 1;
    setState(() {
      _busy = true;
      _error = null;
      _calls[_person] = value;
      // An earlier correction may make the final call forbidden.
      if (_person != last &&
          _calls.length == game.players.length &&
          !validCalls(game.rounds[widget.roundIndex].cards, [
            for (var i = 0; i < game.players.length; i++) _calls[i]!,
          ])) {
        _calls.remove(last);
      }
      if (_calls.length == game.players.length) {
        _stage = RoundStage.callsReady;
      } else {
        _person = _firstMissing(_calls);
      }
    });
    await _persistDraft();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _chooseWin(int value) async {
    if (_busy) return;
    final game = widget.controller.game!;
    final round = game.rounds[widget.roundIndex];
    setState(() {
      _busy = true;
      _error = null;
      _wins[_person] = value;
      if (_wins.length == game.players.length) {
        final entered = _wins.values.fold<int>(0, (sum, won) => sum + won);
        if (validResults(round.cards, [
          for (var i = 0; i < game.players.length; i++) _wins[i]!,
        ])) {
          _stage = RoundStage.summary;
        } else {
          _error =
              '${round.cards} tricks must be accounted for. Currently entered: $entered.';
        }
      } else {
        _person = _firstMissing(_wins);
      }
    });
    await _persistDraft();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirm() async {
    final game = widget.controller.game!;
    final round = game.rounds[widget.roundIndex];
    if (_calls.length != game.players.length ||
        _wins.length != game.players.length ||
        !validCalls(round.cards, [
          for (var i = 0; i < game.players.length; i++) _calls[i]!,
        ]) ||
        !validResults(round.cards, [
          for (var i = 0; i < game.players.length; i++) _wins[i]!,
        ])) {
      setState(() => _error = 'Check the calls and tricks before confirming.');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.commit(widget.roundIndex, _calls, _wins);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not save the round. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.controller.game!;
    final round = game.rounds[widget.roundIndex];
    final isCalls = _stage == RoundStage.calls;
    final isResults = _stage == RoundStage.results;
    final last = game.players.length - 1;
    final forbidden =
        isCalls &&
                _person == last &&
                List.generate(
                  last,
                  (index) => _calls[index],
                ).every((call) => call != null)
            ? forbiddenFinalCall(round.cards, [
              for (var i = 0; i < last; i++) _calls[i]!,
            ])
            : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editing
              ? 'Edit round ${widget.roundIndex + 1}'
              : 'Round ${widget.roundIndex + 1}',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${round.cards} ${round.cards == 1 ? 'card' : 'cards'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    if (round.blind) const Chip(label: Text('BLIND')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(switch (_stage) {
                  RoundStage.calls =>
                    'PREDICTIONS · ${_person + 1} OF ${game.players.length}',
                  RoundStage.callsReady => 'CALLS ARE IN',
                  RoundStage.results =>
                    'RESULTS · ${_person + 1} OF ${game.players.length}',
                  RoundStage.summary => 'ROUND SUMMARY',
                }, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 24),
                if (isCalls || isResults) ...[
                  Text(
                    game.players[_person],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isCalls
                        ? 'How many tricks will they win?'
                        : 'Called ${_calls[_person]}. How many tricks did they win?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var value = 0; value <= round.cards; value++)
                        SizedBox(
                          width: 66,
                          height: 60,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor:
                                  (isCalls
                                              ? _calls[_person]
                                              : _wins[_person]) ==
                                          value
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                      : null,
                            ),
                            onPressed:
                                _busy || (isCalls && value == forbidden)
                                    ? null
                                    : () =>
                                        isCalls
                                            ? _chooseCall(value)
                                            : _chooseWin(value),
                            child: Text(
                              '$value',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (forbidden != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '$forbidden is unavailable: total calls cannot equal ${round.cards}.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Tap a name to correct an entry',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < game.players.length; i++)
                    ListTile(
                      dense: true,
                      selected: i == _person,
                      title: Text(game.players[i]),
                      trailing: Text(
                        isCalls ? '${_calls[i] ?? '—'}' : '${_wins[i] ?? '—'}',
                      ),
                      onTap:
                          _busy ||
                                  (isCalls &&
                                      i > 0 &&
                                      List.generate(
                                        i,
                                        (n) => _calls[n],
                                      ).any((v) => v == null))
                              ? null
                              : () => setState(() {
                                _person = i;
                                _error = null;
                              }),
                    ),
                  if (_person > 0)
                    TextButton.icon(
                      onPressed:
                          _busy
                              ? null
                              : () => setState(() {
                                _person--;
                                _error = null;
                              }),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous player'),
                    ),
                  if (isResults &&
                      _wins.length == game.players.length &&
                      _error == null)
                    FilledButton(
                      onPressed:
                          () => setState(() => _stage = RoundStage.summary),
                      child: const Text('Review round'),
                    ),
                ],
                if (_stage == RoundStage.callsReady) ...[
                  for (var i = 0; i < game.players.length; i++)
                    ListTile(
                      title: Text(game.players[i]),
                      trailing: Text('Called ${_calls[i]}'),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed:
                        widget.editing
                            ? () => setState(() {
                              _stage = RoundStage.results;
                              _person = _firstMissing(_wins);
                            })
                            : () => Navigator.pop(context),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.editing ? 'Edit results' : 'Play round',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        () => setState(() {
                          _stage = RoundStage.calls;
                          _person = 0;
                        }),
                    child: const Text('Edit calls'),
                  ),
                ],
                if (_stage == RoundStage.summary) ...[
                  for (var i = 0; i < game.players.length; i++)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game.players[i],
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text('Called ${_calls[i]} · Won ${_wins[i]}'),
                                  if (_calls[i] == _wins[i])
                                    const Text('✓ Exact call'),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${roundScore(_calls[i]!, _wins[i]!)}',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  'New total ${totalScore(game, i, throughRound: widget.roundIndex - 1) + roundScore(_calls[i]!, _wins[i]!)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _confirm,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        widget.editing ? 'Save correction' : 'Confirm round',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed:
                        _busy
                            ? null
                            : () => setState(() {
                              _stage = RoundStage.results;
                              _person = 0;
                            }),
                    child: const Text('Edit results'),
                  ),
                  TextButton(
                    onPressed:
                        _busy
                            ? null
                            : () => setState(() {
                              _stage = RoundStage.calls;
                              _person = 0;
                            }),
                    child: const Text('Edit calls'),
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
