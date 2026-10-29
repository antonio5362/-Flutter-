import 'package:flutter/material.dart';
import '../data/content.dart';
import '../state/app_state.dart';
import '../theme.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final byDate = <String, List<String>>{};
        for (final e in appState.done.entries) {
          final t = Content.byKey(e.key);
          if (t == null) continue;
          byDate.putIfAbsent(e.value, () => []).add('✅ Изучено: ${t.title}');
        }
        for (final l in appState.log) {
          final d = l['d'];
          final s = l['s'];
          if (d == null || s == null) continue;
          final icon = l['t'] == 'pomodoro' ? '⏱' : '🎯';
          byDate.putIfAbsent(d, () => []).add('$icon $s');
        }
        final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            AppCard(
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 44)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${appState.streak} дн. подряд',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.accent)),
                        const SizedBox(height: 2),
                        Text(
                          appState.studiedToday
                              ? 'Сегодня уже занимался — так держать!'
                              : 'Позанимайся сегодня, чтобы продолжить серию',
                          style: const TextStyle(fontSize: 12.5, color: C.textLight),
                        ),
                        Text('Лучшая серия: ${appState.bestStreak} дн.',
                            style: const TextStyle(fontSize: 12.5, color: C.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('📅 Дневник обучения'),
                  if (dates.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('Пока записей нет. Отметь тему или пройди тест.',
                            textAlign: TextAlign.center, style: TextStyle(color: C.textLight)),
                      ),
                    ),
                  for (final d in dates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatRu(d),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.primary)),
                          const SizedBox(height: 4),
                          for (final line in byDate[d]!)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Text(line, style: const TextStyle(fontSize: 14, height: 1.35)),
                            ),
                          const Divider(height: 16, color: C.border),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
