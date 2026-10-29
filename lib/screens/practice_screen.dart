import 'dart:math';
import 'package:flutter/material.dart';
import '../data/content.dart';
import '../quiz/quiz.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'lesson_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  void _start(BuildContext context, String title, List<QuizItem> items) {
    if (items.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => LessonScreen(title: title, items: items),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final rng = Random();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final dueIds = appState.dueItemIds();
        final dueItems = <QuizItem>[];
        for (final id in dueIds) {
          final it = QuizBank.byId(id);
          if (it != null) dueItems.add(it);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            _tile(
              emoji: '⚡',
              title: 'Быстрый урок',
              subtitle: '10 случайных вопросов по всему курсу',
              color: C.accent,
              onTap: () => _start(context, 'Быстрый урок', QuizBank.pick(QuizBank.items, 10, rng)),
            ),
            _tile(
              emoji: '🔁',
              title: 'Повторение',
              subtitle: dueItems.isEmpty
                  ? 'Пока нечего повторять — пройди несколько уроков'
                  : 'Пора повторить: ${dueItems.length} карточек (интервальное повторение)',
              color: C.success,
              enabled: dueItems.isNotEmpty,
              onTap: () => _start(context, 'Повторение', dueItems.take(10).toList()),
            ),
            _tile(
              emoji: '📅',
              title: 'Только даты',
              subtitle: 'Даты и события',
              color: C.primary,
              onTap: () => _start(context, 'Даты', QuizBank.pick(QuizBank.dates(), 10, rng)),
            ),
            _tile(
              emoji: '📖',
              title: 'Только термины',
              subtitle: 'Понятия и их определения',
              color: C.primary,
              onTap: () => _start(context, 'Термины', QuizBank.pick(QuizBank.terms(), 10, rng)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 14, 4, 10),
              child: Text('🗂 Тест по разделу',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.primary)),
            ),
            for (final s in Content.sections)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: cardDecoration(),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(s.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text('${QuizBank.forSection(s).length} карточек', style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.play_circle_fill, color: C.accent, size: 30),
                  onTap: () => _start(context, s.label, QuizBank.pick(QuizBank.forSection(s), 10, rng)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _tile({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: cardDecoration(),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(14)),
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12.5, color: C.textLight, height: 1.3)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
