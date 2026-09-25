import 'package:flutter/material.dart';
import '../logic/game_controller.dart';
import 'game_screen.dart';
import 'game_setup_screen.dart';
import 'rules_screen.dart';

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
        appBar: AppBar(title: const Text('Whist')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.style_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Keep the cards on the table.',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Calls, tricks, and scores in one quiet place.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    if (controller.loading)
                      const Center(child: CircularProgressIndicator()),
                    if (controller.loadError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(controller.loadError!),
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
                      OutlinedButton(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => GameScreen(controller: controller),
                              ),
                            ),
                        child: const Text('View final results'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FilledButton.tonalIcon(
                      onPressed:
                          controller.loading ? null : () => _newGame(context),
                      icon: const Icon(Icons.add),
                      label: const Text('New game'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RulesScreen(),
                            ),
                          ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('How to play'),
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
