import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/notifications.dart';
import '../state/app_state.dart';
import '../theme.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  bool _work = true;
  int _remaining = 25 * 60;
  bool _running = false;
  DateTime? _endAt;
  Timer? _timer;

  int get _total => (_work ? 25 : 5) * 60;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    _endAt = DateTime.now().add(Duration(seconds: _remaining));
    setState(() => _running = true);
    Notifications.scheduleTimerEnd(
      _endAt!,
      _work ? 'Время вышло — пора отдохнуть 5 минут ☕' : 'Перерыв закончился — за дело! 📚',
    );
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final end = _endAt;
    if (end == null) return;
    final left = (end.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    if (left <= 0) {
      _finish();
    } else {
      setState(() => _remaining = left);
    }
  }

  void _pause() {
    if (!_running) return;
    _timer?.cancel();
    final end = _endAt;
    if (end != null) {
      final left = (end.difference(DateTime.now()).inMilliseconds / 1000).ceil();
      _remaining = left.clamp(1, _total).toInt();
    }
    Notifications.cancelTimerEnd();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    Notifications.cancelTimerEnd();
    setState(() {
      _running = false;
      _remaining = _total;
    });
  }

  void _setMode(bool work) {
    _timer?.cancel();
    Notifications.cancelTimerEnd();
    setState(() {
      _work = work;
      _running = false;
      _remaining = _total;
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final wasWork = _work;
    HapticFeedback.vibrate();
    setState(() {
      _running = false;
      _work = !wasWork;
      _remaining = _total;
    });
    if (wasWork) appState.completePomodoro();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Время вышло!'),
        content: Text(wasWork
            ? 'Отлично поработал! +10 XP. Теперь отдохни 5 минут.'
            : 'Перерыв окончен. Пора учиться!'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - _remaining / _total;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        AppCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Учёба 25'),
                    selected: _work,
                    onSelected: (_) => _setMode(true),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Отдых 5'),
                    selected: !_work,
                    onSelected: (_) => _setMode(false),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: C.primaryLight,
                        valueColor: AlwaysStoppedAnimation<Color>(_work ? C.primary : C.success),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_label,
                            style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: C.primary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            )),
                        Text(_work ? 'Фокус' : 'Перерыв', style: const TextStyle(color: C.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _running ? _pause : _start,
                    child: Text(_running ? 'Пауза' : 'Старт'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: _reset, child: const Text('Сброс')),
                ],
              ),
            ],
          ),
        ),
        const AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitle('💡 Как это работает'),
              Text(
                '• Учись 25 минут без отвлечений, потом отдыхай 5.\n'
                '• За каждый завершённый сеанс — +10 XP.\n'
                '• Когда время выйдет, телефон напомнит уведомлением.',
                style: TextStyle(fontSize: 14, height: 1.6, color: C.textLight),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
