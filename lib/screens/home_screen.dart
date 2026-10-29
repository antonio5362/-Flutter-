import 'package:flutter/material.dart';
import '../data/content.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'topic_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final total = Content.flat.length;
        final done = appState.doneCount;
        final pct = total == 0 ? 0.0 : done / total;
        Topic? next;
        for (final t in Content.flat) {
          if (!appState.isDone(t.key)) {
            next = t;
            break;
          }
        }
        final goalPct = (appState.xpToday / appState.goal).clamp(0.0, 1.0).toDouble();

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [C.primary, C.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 74,
                          height: 74,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: goalPct),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, v, _) => CircularProgressIndicator(
                              value: v,
                              strokeWidth: 8,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        Text(
                          goalPct >= 1 ? '✅' : '${appState.xpToday}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goalPct >= 1 ? 'Цель на сегодня выполнена!' : 'Цель на сегодня',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appState.xpToday} из ${appState.goal} XP',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🔥 Серия: ${appState.streak} дн.   •   Уровень ${appState.level}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
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
                  const SectionTitle('📚 Общий прогресс'),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, v, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 12,
                        backgroundColor: C.primaryLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(C.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$done из $total тем', style: const TextStyle(color: C.textLight, fontSize: 13)),
                      Text('${(pct * 100).round()}%', style: const TextStyle(color: C.textLight, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            if (next != null)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('▶ Продолжить'),
                    Text(next.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(Content.sectionOf(next).label, style: const TextStyle(color: C.textLight, fontSize: 12)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => openTopic(context, next!),
                      child: const Text('Открыть тему'),
                    ),
                  ],
                ),
              )
            else
              const AppCard(
                child: Text('🎉 Все темы изучены! Закрепляй их в разделе «Практика».',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 6, 4, 10),
              child: Text('🗂 Разделы программы',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.primary)),
            ),
            for (final s in Content.sections) _SectionTile(section: s),
          ],
        );
      },
    );
  }
}

void openTopic(BuildContext context, Topic t, {bool replace = false}) {
  final route = MaterialPageRoute<void>(builder: (_) => TopicScreen(topic: t));
  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

class _SectionTile extends StatelessWidget {
  final Section section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    final done = section.topics.where((t) => appState.isDone(t.key)).length;
    final n = section.topics.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cardDecoration(),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>(section.id),
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          title: Text(section.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: n == 0 ? 0 : done / n,
                    minHeight: 6,
                    backgroundColor: C.primaryLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(C.success),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$done/$n тем  •  ${section.weight}', style: const TextStyle(fontSize: 11.5, color: C.textLight)),
              ],
            ),
          ),
          children: [for (final t in section.topics) _TopicRow(topic: t)],
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  const _TopicRow({required this.topic});

  @override
  Widget build(BuildContext context) {
    final done = appState.isDone(topic.key);
    final date = appState.done[topic.key];
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => openTopic(context, topic),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => appState.toggleTopic(topic),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? C.success : Colors.transparent,
                    border: Border.all(color: done ? C.success : C.border, width: 2),
                  ),
                  child: done ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title, style: const TextStyle(fontSize: 14, height: 1.3)),
                  if (date != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text('📅 ${formatRu(date)}', style: const TextStyle(fontSize: 11.5, color: C.textLight)),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: C.textLight),
          ],
        ),
      ),
    );
  }
}
