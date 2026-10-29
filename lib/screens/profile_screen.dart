import 'package:flutter/material.dart';
import '../data/content.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final total = Content.flat.length;
        final done = appState.doneCount;
        final pct = total == 0 ? 0 : (done * 100 / total).round();
        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
          children: [
            _levelCard(),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('📊 Статистика'),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.9,
                    children: [
                      _stat('$total', 'Всего тем'),
                      _stat('$done', 'Изучено'),
                      _stat('$pct%', 'Прогресс'),
                      _stat('${appState.days.length}', 'Дней занятий'),
                      _stat('${appState.lessonsDone}', 'Уроков пройдено'),
                      _stat('${appState.correctTotal}', 'Верных ответов'),
                    ],
                  ),
                ],
              ),
            ),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('📈 По разделам'),
                  for (final s in Content.sections) _sectionBar(s),
                ],
              ),
            ),
            AppCard(child: _heatmap()),
            AppCard(child: _achievements()),
            AppCard(child: _settings(context)),
          ],
        );
      },
    );
  }

  Widget _levelCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [C.accent, Color(0xFFB85F17)]),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('⭐ Уровень ${appState.level}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('⚡ ${appState.xp} XP',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: appState.levelProgress.clamp(0.0, 1.0).toDouble(),
              minHeight: 12,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 6),
          Text('До уровня ${appState.level + 1}: ${appState.levelEndXp - appState.xp} XP',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _stat(String num, String label) {
    return Container(
      decoration: BoxDecoration(color: C.primaryLight, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(num, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.primary)),
          Text(label, style: const TextStyle(fontSize: 11.5, color: C.textLight)),
        ],
      ),
    );
  }

  Widget _sectionBar(Section s) {
    final done = s.topics.where((t) => appState.isDone(t.key)).length;
    final n = s.topics.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              Text('$done/$n', style: const TextStyle(fontSize: 12, color: C.textLight)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: n == 0 ? 0 : done / n,
              minHeight: 8,
              backgroundColor: C.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(C.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heatmap() {
    final now = DateTime.now();
    final cells = <Widget>[];
    for (var i = 29; i >= 0; i--) {
      final d = DateTime(now.year, now.month, now.day - i);
      final xp = appState.xpByDay[isoDate(d)] ?? 0;
      Color c;
      if (xp == 0) {
        c = C.primaryLight;
      } else if (xp < 20) {
        c = const Color(0xFFB3CCE0);
      } else if (xp < 50) {
        c = const Color(0xFF6A9BC0);
      } else {
        c = C.primary;
      }
      cells.add(Tooltip(
        message: '${formatRu(isoDate(d))}: $xp XP',
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)),
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('🗓 Календарь активности'),
        const Text('Последние 30 дней: чем темнее — тем больше XP за день.',
            style: TextStyle(fontSize: 12.5, color: C.textLight)),
        const SizedBox(height: 12),
        Wrap(spacing: 5, runSpacing: 5, children: cells),
      ],
    );
  }

  Widget _achievements() {
    final all = AppState.allAchievements;
    final got = all.where((a) => appState.achievements.contains(a.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle('🏆 Достижения ($got/${all.length})'),
        for (final a in all)
          Builder(builder: (context) {
            final ok = appState.achievements.contains(a.id);
            return Opacity(
              opacity: ok ? 1 : 0.45,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: ok ? C.successLight : C.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(ok ? a.emoji : '🔒', style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                          Text(a.desc, style: const TextStyle(fontSize: 12.5, color: C.textLight)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _settings(BuildContext context) {
    final time = TimeOfDay(hour: appState.reminderMinutes ~/ 60, minute: appState.reminderMinutes % 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('⚙️ Настройки'),
        const Text('Ежедневная цель', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final g in const [20, 50, 100])
              ChoiceChip(
                label: Text('$g XP'),
                selected: appState.goal == g,
                onSelected: (_) => appState.setGoal(g),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Напоминать позаниматься', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: const Text('Каждый день в выбранное время', style: TextStyle(fontSize: 12)),
          value: appState.reminder,
          onChanged: (on) async {
            if (on) {
              final ok = await Notifications.requestPermission();
              if (!ok) {
                messengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Разрешите уведомления в настройках телефона')),
                );
                return;
              }
              appState.setReminder(true);
              await Notifications.scheduleDaily(appState.reminderMinutes, skipToday: appState.studiedToday);
            } else {
              appState.setReminder(false);
              await Notifications.cancelDaily();
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          enabled: appState.reminder,
          title: const Text('Время напоминания', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: Text(time.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.primary)),
          onTap: !appState.reminder
              ? null
              : () async {
                  final picked = await showTimePicker(context: context, initialTime: time);
                  if (picked == null) return;
                  final m = picked.hour * 60 + picked.minute;
                  appState.setReminder(true, minutes: m);
                  await Notifications.scheduleDaily(m, skipToday: appState.studiedToday);
                },
        ),
        const Divider(color: C.border),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: C.error),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Сбросить весь прогресс'),
          onPressed: () async {
            final yes = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Сбросить прогресс?'),
                content: const Text('Все отметки, XP, серия и достижения будут удалены. Это нельзя отменить.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сбросить')),
                ],
              ),
            );
            if (yes == true) appState.resetAll();
          },
        ),
      ],
    );
  }
}

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
