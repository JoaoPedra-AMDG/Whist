import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import 'game_screen.dart';
import 'game_setup_screen.dart';
import 'leaderboard_screen.dart';
import 'rules_screen.dart';
import '../theme/whist_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final GameController controller;

  Future<void> _newGame(BuildContext context) async {
    if (controller.game != null && !controller.game!.isFinished) {
      final replace = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Start a new game?'),
              content: const Text('Your current game will be replaced.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep game'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('New game'),
                ),
              ],
            ),
      );
      if (replace != true || !context.mounted) return;
    }
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GameSetupScreen(controller: controller),
      ),
    );
    if (created == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GameScreen(controller: controller)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final game = controller.game;
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.style_rounded,
                          size: 22,
                          color: WhistPalette.accent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AMDG',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(letterSpacing: 1.5),
                        ),
                        const Spacer(),
                        Text(
                          'SCOREKEEPER',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Flexible(
                      fit: FlexFit.loose,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight:
                              MediaQuery.sizeOf(context).height < 700
                                  ? 130
                                  : 220,
                        ),
                        child: Card(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Whist - The Card Game',
                                    style:
                                        Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'The Pedra\'s Edition',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (controller.loading)
                      const Center(child: CircularProgressIndicator()),
                    if (controller.loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          controller.loadError!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (!controller.loading &&
                        game != null &&
                        !game.isFinished) ...[
                      FilledButton.icon(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => GameScreen(controller: controller),
                              ),
                            ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'Continue · Round ${game.currentRoundIndex + 1}',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!controller.loading &&
                        game != null &&
                        game.isFinished) ...[
                      FilledButton.icon(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => GameScreen(controller: controller),
                              ),
                            ),
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('View final results'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (game == null)
                      FilledButton.icon(
                        onPressed:
                            controller.loading ? null : () => _newGame(context),
                        icon: const Icon(Icons.add),
                        label: const Text('New game'),
                      ),
                    if (game == null) const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          if (game != null) ...[
                            _MenuRow(
                              icon: Icons.add_circle_outline,
                              label: 'New game',
                              onTap:
                                  controller.loading
                                      ? null
                                      : () => _newGame(context),
                            ),
                            const Divider(height: 1),
                          ],
                          _MenuRow(
                            icon: Icons.leaderboard_outlined,
                            label: 'Leaderboard & past games',
                            onTap:
                                controller.loading
                                    ? null
                                    : () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => LeaderboardScreen(
                                              controller: controller,
                                            ),
                                      ),
                                    ),
                          ),
                          const Divider(height: 1),
                          _MenuRow(
                            icon: Icons.menu_book_outlined,
                            label: 'How to play',
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RulesScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: WhistPalette.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          const Icon(Icons.chevron_right, color: WhistPalette.textMuted),
        ],
      ),
    ),
  );
}
