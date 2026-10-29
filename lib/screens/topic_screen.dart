import 'dart:math';
import 'package:flutter/material.dart';
import '../data/content.dart';
import '../quiz/quiz.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/html_view.dart';
import 'home_screen.dart';
import 'lesson_screen.dart';

class TopicScreen extends StatelessWidget {
  final Topic topic;
  const TopicScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final section = Content.sectionOf(topic);
    final idx = Content.flat.indexWhere((t) => t.key == topic.key);
    final prev = idx > 0 ? Content.flat[idx - 1] : null;
    final next = idx < Content.flat.length - 1 ? Content.flat[idx + 1] : null;
    final items = QuizBank.forTopic(topic);
    final quizCount = min(10, items.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(section.label),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('Тема ${topic.index + 1} из ${section.topics.length}',
                  style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final done = appState.isDone(topic.key);
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(topic.title,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: C.primary, height: 1.25)),
                    const SizedBox(height: 14),
                    HtmlView(topic.html),
                  ],
                ),
              ),
              if (topic.dates.isNotEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('📅 Ключевые даты'),
                      for (final d in topic.dates) _pair(d[0], d[1]),
                    ],
                  ),
                ),
              if (topic.terms.isNotEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle('📖 Ключевые термины'),
                      for (final t in topic.terms) _pair(t[0], t[1]),
                    ],
                  ),
                ),
              if (quizCount >= 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: C.accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => LessonScreen(
                          title: topic.title,
                          items: QuizBank.pick(items, 10, Random()),
                        ),
                      ));
                    },
                    icon: const Icon(Icons.bolt),
                    label: Text('Пройти тест по теме ($quizCount вопр.)', style: const TextStyle(fontSize: 15)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: done
                    ? OutlinedButton(
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: () => appState.toggleTopic(topic),
                        child: const Text('✅ Изучено (нажми, чтобы снять)', style: TextStyle(fontSize: 15)),
                      )
                    : FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: C.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => appState.toggleTopic(topic),
                        child: const Text('✓ Отметить как изученное (+10 XP)', style: TextStyle(fontSize: 15)),
                      ),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: prev == null ? null : () => openTopic(context, prev, replace: true),
                      child: const Text('← Предыдущая'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: next == null ? null : () => openTopic(context, next, replace: true),
                      child: const Text('Следующая →'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _pair(String a, String b) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(fontSize: 14.5, height: 1.4, color: C.text),
          children: [
            TextSpan(text: a, style: const TextStyle(fontWeight: FontWeight.w700, color: C.accent)),
            TextSpan(text: ' — $b'),
          ],
        ),
      ),
    );
  }
}
