import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import '../logic/game_rules.dart';
import '../logic/scoring.dart';
import '../models/game.dart';

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
  int _pickerValue = 0;
  bool _busy = false;
  bool _saveFailed = false;
  String? _error;

  int get _count => widget.controller.game!.players.length;
  int get _cards => widget.controller.game!.rounds[widget.roundIndex].cards;

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
    _pickerValue =
        (_stage == RoundStage.results ? _wins[_person] : _calls[_person]) ?? 0;
  }

  int _firstMissing(Map<int, int> values) {
    for (var index = 0; index < _count; index++) {
      if (!values.containsKey(index)) return index;
    }
    return 0;
  }

  void _selectPerson(int index) {
    setState(() {
      _person = index;
      _pickerValue =
          (_stage == RoundStage.results ? _wins[index] : _calls[index]) ?? 0;
      if (!_saveFailed) _error = null;
    });
  }

  Future<bool> _persistDraft() async {
    if (widget.editing) return true;
    try {
      await widget.controller.saveDraft(widget.roundIndex, _calls, _wins);
      if (mounted) {
        setState(() {
          _saveFailed = false;
          _error = null;
        });
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _saveFailed = true;
          _error = '$error';
        });
      }
      return false;
    }
  }

  Future<void> _retrySave() async {
    setState(() => _busy = true);
    await _persistDraft();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _chooseCall(int value) async {
    if (_busy) return;
    final last = _count - 1;
    setState(() {
      _busy = true;
      _error = null;
      _saveFailed = false;
      _calls[_person] = value;
      if (_person != last &&
          _calls.length == _count &&
          !validCalls(_cards, [for (var i = 0; i < _count; i++) _calls[i]!])) {
        _calls.remove(last);
      }
      if (_calls.length == _count) {
        _stage = RoundStage.callsReady;
        _person = 0;
      } else {
        _person = _firstMissing(_calls);
      }
      _pickerValue = _calls[_person] ?? 0;
    });
    await _persistDraft();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _chooseWin(int value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _saveFailed = false;
      _wins[_person] = value;
      if (_wins.length == _count) {
        if (validResults(_cards, [
          for (var i = 0; i < _count; i++) _wins[i]!,
        ])) {
          _stage = RoundStage.summary;
          _person = 0;
        } else {
          final entered = _wins.values.fold<int>(0, (sum, won) => sum + won);
          _error =
              '$_cards tricks are needed. You entered $entered. Use the arrows to correct a result.';
        }
      } else {
        _person = _firstMissing(_wins);
      }
      _pickerValue = _wins[_person] ?? 0;
    });
    final validationError = _error;
    await _persistDraft();
    if (mounted) {
      setState(() {
        _busy = false;
        if (!_saveFailed) _error = validationError;
      });
    }
  }

  Future<void> _confirm() async {
    if (_saveFailed) return;
    if (_calls.length != _count ||
        _wins.length != _count ||
        !validCalls(_cards, [for (var i = 0; i < _count; i++) _calls[i]!]) ||
        !validResults(_cards, [for (var i = 0; i < _count; i++) _wins[i]!])) {
      setState(
        () => _error = 'Check every call and trick total before confirming.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.commit(widget.roundIndex, _calls, _wins);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$error';
        });
      }
    }
  }

  void _details() => showDialog<void>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: const Text('Save details'),
          content: Text(_error ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
  );

  @override
  Widget build(BuildContext context) {
    final game = widget.controller.game!;
    final round = game.rounds[widget.roundIndex];
    final isEntry = _stage == RoundStage.calls || _stage == RoundStage.results;
    final isCalls = _stage == RoundStage.calls;
    final forbidden =
        isCalls &&
                _person == _count - 1 &&
                [
                  for (var i = 0; i < _count - 1; i++) _calls[i],
                ].every((call) => call != null)
            ? forbiddenFinalCall(_cards, [
              for (var i = 0; i < _count - 1; i++) _calls[i]!,
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
            constraints: const BoxConstraints(maxWidth: 620),
            child: LayoutBuilder(
              builder:
                  (context, constraints) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$_cards ${_cards == 1 ? 'card' : 'cards'}',
                                style:
                                    Theme.of(context).textTheme.headlineMedium,
                              ),
                            ),
                            if (round.blind) const Chip(label: Text('BLIND')),
                          ],
                        ),
                        Text(switch (_stage) {
                          RoundStage.calls => 'PREDICTIONS',
                          RoundStage.callsReady => 'CALLS ARE IN',
                          RoundStage.results => 'RESULTS',
                          RoundStage.summary => 'ROUND SUMMARY',
                        }, style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              isEntry
                                  ? _entryBody(context, game, forbidden)
                                  : _reviewBody(context, game),
                        ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Card(
                              color:
                                  Theme.of(context).colorScheme.errorContainer,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _details,
                                      child: const Text('Details'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_saveFailed)
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _retrySave,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry save'),
                          ),
                        const SizedBox(height: 6),
                        _actions(context, game),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _entryBody(BuildContext context, WhistGame game, int? forbidden) {
    final isCalls = _stage == RoundStage.calls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          game.players[_person],
          style: Theme.of(context).textTheme.headlineSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          isCalls
              ? 'How many tricks will they win?'
              : 'Called ${_calls[_person]} · How many did they win?',
        ),
        if (forbidden != null)
          Text(
            '$forbidden is unavailable for the last caller.',
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        const SizedBox(height: 10),
        Expanded(
          child:
              _cards <= 14
                  ? LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth < 330 ? 4 : 5;
                      final rows = ((_cards + 1) / columns).ceil();
                      final cellWidth =
                          (box.maxWidth - 6 * (columns - 1)) / columns;
                      final cellHeight =
                          (box.maxHeight - 6 * (rows - 1)) / rows;
                      final ratio = cellWidth / cellHeight;
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: ratio,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                        ),
                        itemCount: _cards + 1,
                        itemBuilder:
                            (context, value) => OutlinedButton(
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
                      );
                    },
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_pickerValue',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      Slider(
                        value: _pickerValue.toDouble(),
                        min: 0,
                        max: _cards.toDouble(),
                        divisions: _cards,
                        label: '$_pickerValue',
                        onChanged:
                            _busy
                                ? null
                                : (value) => setState(
                                  () => _pickerValue = value.round(),
                                ),
                      ),
                      FilledButton(
                        onPressed:
                            _busy || (isCalls && _pickerValue == forbidden)
                                ? null
                                : () =>
                                    isCalls
                                        ? _chooseCall(_pickerValue)
                                        : _chooseWin(_pickerValue),
                        child: const Text('Use this number'),
                      ),
                    ],
                  ),
        ),
      ],
    );
  }

  Widget _reviewBody(BuildContext context, WhistGame game) {
    final name = game.players[_person];
    final call = _calls[_person];
    final won = _wins[_person];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.headlineMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text('Called $call', style: Theme.of(context).textTheme.titleLarge),
          if (_stage == RoundStage.summary) ...[
            Text('Won $won', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '+${roundScore(call!, won!)}',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            if (call == won) const Text('Exact call · 10 bonus points'),
            Text(
              'New total ${totalScore(game, _person, throughRound: widget.roundIndex - 1) + roundScore(call, won)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WhistGame game) {
    final isEntry = _stage == RoundStage.calls || _stage == RoundStage.results;
    final values = _stage == RoundStage.results ? _wins : _calls;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Previous player',
              onPressed:
                  _busy || _person == 0
                      ? null
                      : () => _selectPerson(_person - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_person + 1} / $_count',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              tooltip: 'Next player',
              onPressed:
                  _busy ||
                          _person == _count - 1 ||
                          (isEntry && values[_person] == null)
                      ? null
                      : () => _selectPerson(_person + 1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (_stage == RoundStage.callsReady) ...[
          FilledButton(
            onPressed:
                _busy || _saveFailed
                    ? null
                    : widget.editing
                    ? () => setState(() {
                      _stage = RoundStage.results;
                      _person = _firstMissing(_wins);
                    })
                    : () => Navigator.pop(context),
            child: Text(widget.editing ? 'Edit results' : 'Play round'),
          ),
          TextButton(
            onPressed:
                _busy
                    ? null
                    : () => setState(() {
                      _stage = RoundStage.calls;
                      _person = 0;
                    }),
            child: const Text('Calls'),
          ),
        ],
        if (_stage == RoundStage.results &&
            _wins.length == _count &&
            validResults(_cards, [for (var i = 0; i < _count; i++) _wins[i]!]))
          FilledButton(
            onPressed:
                _busy || _saveFailed
                    ? null
                    : () => setState(() {
                      _stage = RoundStage.summary;
                      _person = 0;
                    }),
            child: const Text('Review round'),
          ),
        if (_stage == RoundStage.summary) ...[
          FilledButton(
            onPressed: _busy || _saveFailed ? null : _confirm,
            child: Text(widget.editing ? 'Save correction' : 'Confirm round'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () => setState(() {
                          _stage = RoundStage.calls;
                          _person = 0;
                        }),
                child: const Text('Calls'),
              ),
              TextButton(
                onPressed:
                    _busy
                        ? null
                        : () => setState(() {
                          _stage = RoundStage.results;
                          _person = 0;
                        }),
                child: const Text('Results'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
