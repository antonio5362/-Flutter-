import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../quiz/quiz.dart';
import '../state/app_state.dart';
import '../theme.dart';

class LessonScreen extends StatefulWidget {
  final String title;
  final List<QuizItem> items;
  const LessonScreen({super.key, required this.title, required this.items});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final Random _rng = Random();
  late List<Question> _queue;
  final Set<String> _attempted = {};
  int _i = 0;
  int? _sel;
  bool _checked = false;
  int _firstTry = 0;

  @override
  void initState() {
    super.initState();
    _queue = widget.items.map((e) => QuizBank.make(e, _rng)).toList();
  }

  Question get _q => _queue[_i];
  bool get _isCorrect => _sel == _q.correct;

  void _check() {
    if (_sel == null) return;
    final q = _q;
    final correct = _isCorrect;
    if (!_attempted.contains(q.id)) {
      _attempted.add(q.id);
      appState.recordAnswer(q.id, correct);
      if (correct) {
        _firstTry++;
      } else {
        // неверно — вернём вопрос в конец урока (как в Duolingo)
        _queue.add(QuizBank.make(q.item, _rng));
      }
    }
    if (correct) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
    setState(() => _checked = true);
  }

  void _next() {
    if (_i + 1 >= _queue.length) {
      final res = appState.finishLesson(widget.title, widget.items.length, _firstTry);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ResultScreen(result: res)),
      );
      return;
    }
    setState(() {
      _i++;
      _sel = null;
      _checked = false;
    });
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти из урока?'),
        content: const Text('Прогресс этого урока не сохранится.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Остаться')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Выйти')),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(onPressed: _confirmExit, icon: const Icon(Icons.close, color: C.textLight)),
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _i / _queue.length),
                        duration: const Duration(milliseconds: 350),
                        builder: (context, v, _) => ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 14,
                            backgroundColor: C.primaryLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(C.success),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: C.textLight)),
                      const SizedBox(height: 10),
                      Text(q.prompt,
                          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, height: 1.3, color: C.text)),
                      const SizedBox(height: 22),
                      for (var k = 0; k < q.options.length; k++) _option(k, q.options[k]),
                    ],
                  ),
                ),
              ),
              _bottomBar(q),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(int k, String text) {
    Color border = C.border;
    Color bg = Colors.white;
    Color fg = C.text;
    if (_checked) {
      if (k == _q.correct) {
        border = C.success;
        bg = C.successLight;
      } else if (k == _sel) {
        border = C.error;
        bg = C.errorLight;
      } else {
        fg = C.textLight;
      }
    } else if (_sel == k) {
      border = C.primary;
      bg = C.primaryLight;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _checked ? null : () => setState(() => _sel = k),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(text, style: TextStyle(fontSize: 15.5, height: 1.35, color: fg, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _bottomBar(Question q) {
    if (!_checked) {
      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.border))),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _sel == null ? null : _check,
            child: const Text('Проверить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }
    final ok = _isCorrect;
    final color = ok ? C.success : C.error;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      color: ok ? C.successLight : C.errorLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(ok ? Icons.check_circle : Icons.cancel, color: color, size: 26),
              const SizedBox(width: 8),
              Text(ok ? 'Верно!' : 'Неверно',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          if (!ok) ...[
            const SizedBox(height: 6),
            Text('Правильно: ${q.explanation}', style: TextStyle(fontSize: 14, color: color, height: 1.35)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _next,
              child: const Text('Продолжить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final LessonResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final acc = result.total == 0 ? 0 : (result.firstTry * 100 / result.total).round();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (context, v, child) => Transform.scale(scale: v, child: child),
                child: Text(result.perfect ? '🏆' : (acc >= 60 ? '🎉' : '💪'), style: const TextStyle(fontSize: 84)),
              ),
              const SizedBox(height: 12),
              Text(result.perfect ? 'Без единой ошибки!' : 'Урок пройден!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.primary)),
              const SizedBox(height: 28),
              Row(
                children: [
                  _stat('⚡', '+${result.xp}', 'XP', C.accent),
                  const SizedBox(width: 10),
                  _stat('✅', '${result.firstTry}/${result.total}', 'с 1-й попытки', C.success),
                  const SizedBox(width: 10),
                  _stat('🎯', '$acc%', 'точность', C.primary),
                ],
              ),
              const SizedBox(height: 18),
              Text('🔥 Серия: ${appState.streak} дн.   •   Уровень ${appState.level}',
                  style: const TextStyle(fontSize: 15, color: C.textLight)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Продолжить', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: C.textLight)),
          ],
        ),
      ),
    );
  }
}
