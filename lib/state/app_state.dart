import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/content.dart';

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseIso(String s) {
  final p = s.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

DateTime dayBefore(DateTime d) => DateTime(d.year, d.month, d.day - 1);

int dayNum(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(2020)).inDays;

const _months = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
];

String formatRu(String iso) {
  final d = parseIso(iso);
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String desc;
  final bool Function(AppState) test;
  Achievement(this.id, this.emoji, this.title, this.desc, this.test);
}

class LessonResult {
  final int xp;
  final int total;
  final int firstTry;
  final bool perfect;
  LessonResult(this.xp, this.total, this.firstTry, this.perfect);
}

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;
  static const _key = 'ct_state_v2';

  Map<String, String> done = {}; // ключ темы -> дата изучения
  Set<String> rewardedTopics = {};
  Map<String, int> xpByDay = {};
  Set<String> days = {};
  int xp = 0;
  Map<String, List<int>> qstats = {}; // id -> [коробка, день повторения]
  Set<String> achievements = {};
  List<Map<String, String>> log = [];
  int goal = 50;
  bool reminder = false;
  int reminderMinutes = 19 * 60;
  int correctTotal = 0;
  int lessonsDone = 0;
  int perfectLessons = 0;
  int pomodoros = 0;

  void Function(String message)? onToast;
  void Function()? onActivityToday;

  static final List<Achievement> allAchievements = [
    Achievement('first_topic', '📗', 'Первый шаг', 'Изучи первую тему', (s) => s.doneCount >= 1),
    Achievement('topics5', '📚', 'Пятёрка', 'Изучи 5 тем', (s) => s.doneCount >= 5),
    Achievement('topics20', '🎓', 'Знаток', 'Изучи 20 тем', (s) => s.doneCount >= 20),
    Achievement('topics_all', '👑', 'Весь курс', 'Изучи все темы', (s) => s.doneCount >= Content.flat.length && Content.flat.isNotEmpty),
    Achievement('section', '🏁', 'Раздел закрыт', 'Изучи все темы одного раздела', (s) => s.anySectionComplete),
    Achievement('streak3', '🔥', '3 дня подряд', 'Занимайся 3 дня подряд', (s) => s.bestStreak >= 3),
    Achievement('streak7', '🔥', 'Неделя огня', 'Занимайся 7 дней подряд', (s) => s.bestStreak >= 7),
    Achievement('streak30', '🌋', 'Месяц силы', 'Занимайся 30 дней подряд', (s) => s.bestStreak >= 30),
    Achievement('first_lesson', '🎯', 'Первый тест', 'Пройди первый урок', (s) => s.lessonsDone >= 1),
    Achievement('perfect', '💯', 'Без ошибок', 'Пройди урок без единой ошибки', (s) => s.perfectLessons >= 1),
    Achievement('correct100', '✅', 'Сотня', '100 верных ответов с первой попытки', (s) => s.correctTotal >= 100),
    Achievement('xp500', '⚡', '500 XP', 'Набери 500 очков опыта', (s) => s.xp >= 500),
    Achievement('level5', '⭐', 'Уровень 5', 'Достигни 5 уровня', (s) => s.level >= 5),
    Achievement('pomodoro', '⏱', 'Фокус', 'Заверши один сеанс таймера', (s) => s.pomodoros >= 1),
  ];

  // ---------- вычисляемые ----------
  String get today => isoDate(DateTime.now());
  int get doneCount => done.length;
  bool isDone(String key) => done.containsKey(key);
  int get xpToday => xpByDay[today] ?? 0;
  bool get studiedToday => days.contains(today);

  bool get anySectionComplete =>
      Content.sections.any((s) => s.topics.isNotEmpty && s.topics.every((t) => done.containsKey(t.key)));

  int get level => 1 + sqrt(xp / 50).floor();
  int get levelStartXp => 50 * (level - 1) * (level - 1);
  int get levelEndXp => 50 * level * level;
  double get levelProgress => (xp - levelStartXp) / (levelEndXp - levelStartXp);

  int get streak {
    var d = DateTime.now();
    if (!days.contains(isoDate(d))) d = dayBefore(d);
    var n = 0;
    while (days.contains(isoDate(d))) {
      n++;
      d = dayBefore(d);
    }
    return n;
  }

  int get bestStreak {
    if (days.isEmpty) return 0;
    final nums = days.map((s) => dayNum(parseIso(s))).toList()..sort();
    var best = 1;
    var cur = 1;
    for (var i = 1; i < nums.length; i++) {
      if (nums[i] == nums[i - 1] + 1) {
        cur++;
      } else if (nums[i] != nums[i - 1]) {
        cur = 1;
      }
      if (cur > best) best = cur;
    }
    return best;
  }

  List<String> dueItemIds() {
    final t = dayNum(DateTime.now());
    final due = qstats.entries.where((e) => e.value[1] <= t).toList()
      ..sort((a, b) => a.value[0].compareTo(b.value[0]));
    return due.map((e) => e.key).toList();
  }

  // ---------- загрузка / сохранение ----------
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      done = Map<String, String>.from(m['done'] ?? {});
      rewardedTopics = Set<String>.from(m['rewarded'] ?? []);
      xpByDay = Map<String, int>.from(m['xpByDay'] ?? {});
      days = Set<String>.from(m['days'] ?? []);
      xp = (m['xp'] ?? 0) as int;
      final q = (m['qstats'] ?? {}) as Map<String, dynamic>;
      qstats = q.map((k, v) => MapEntry(k, List<int>.from(v as List)));
      achievements = Set<String>.from(m['ach'] ?? []);
      log = ((m['log'] ?? []) as List).map((e) => Map<String, String>.from(e as Map)).toList();
      goal = (m['goal'] ?? 50) as int;
      reminder = (m['reminder'] ?? false) as bool;
      reminderMinutes = (m['reminderMin'] ?? 19 * 60) as int;
      correctTotal = (m['correct'] ?? 0) as int;
      lessonsDone = (m['lessons'] ?? 0) as int;
      perfectLessons = (m['perfect'] ?? 0) as int;
      pomodoros = (m['pomodoros'] ?? 0) as int;
    } catch (e) {
      debugPrint('Не удалось прочитать сохранение: $e');
    }
  }

  void _save() {
    final m = {
      'done': done,
      'rewarded': rewardedTopics.toList(),
      'xpByDay': xpByDay,
      'days': days.toList(),
      'xp': xp,
      'qstats': qstats,
      'ach': achievements.toList(),
      'log': log,
      'goal': goal,
      'reminder': reminder,
      'reminderMin': reminderMinutes,
      'correct': correctTotal,
      'lessons': lessonsDone,
      'perfect': perfectLessons,
      'pomodoros': pomodoros,
    };
    _prefs?.setString(_key, jsonEncode(m));
  }

  // ---------- действия ----------
  void _markActive() {
    final wasActive = days.contains(today);
    days.add(today);
    if (!wasActive) onActivityToday?.call();
  }

  void _checkAchievements() {
    for (final a in allAchievements) {
      if (!achievements.contains(a.id) && a.test(this)) {
        achievements.add(a.id);
        onToast?.call('🏆 Достижение: ${a.title}');
      }
    }
  }

  void addXp(int amount) {
    final before = level;
    xp += amount;
    xpByDay[today] = xpToday + amount;
    _markActive();
    if (level > before) onToast?.call('⭐ Новый уровень: $level!');
  }

  void toggleTopic(Topic t) {
    if (done.containsKey(t.key)) {
      done.remove(t.key);
    } else {
      done[t.key] = today;
      _markActive();
      if (!rewardedTopics.contains(t.key)) {
        rewardedTopics.add(t.key);
        addXp(10);
      }
    }
    _checkAchievements();
    _save();
    notifyListeners();
  }

  void recordAnswer(String itemId, bool correct) {
    final cur = qstats[itemId] ?? [0, 0];
    var box = cur[0];
    box = correct ? min(box + 1, 5) : 0;
    const gaps = [0, 1, 2, 4, 8, 16];
    qstats[itemId] = [box, dayNum(DateTime.now()) + gaps[box]];
    _save();
  }

  LessonResult finishLesson(String title, int total, int firstTry) {
    final perfect = total > 0 && firstTry == total;
    final gained = firstTry * 2 + 5 + (perfect ? 10 : 0);
    correctTotal += firstTry;
    lessonsDone += 1;
    if (perfect) perfectLessons += 1;
    log.add({'d': today, 't': 'lesson', 's': '$title: $firstTry из $total с первой попытки'});
    if (log.length > 300) log = log.sublist(log.length - 300);
    addXp(gained);
    _checkAchievements();
    _save();
    notifyListeners();
    return LessonResult(gained, total, firstTry, perfect);
  }

  void completePomodoro() {
    pomodoros += 1;
    log.add({'d': today, 't': 'pomodoro', 's': 'Сеанс фокуса 25 минут'});
    addXp(10);
    _checkAchievements();
    _save();
    notifyListeners();
  }

  void setGoal(int v) {
    goal = v;
    _save();
    notifyListeners();
  }

  void setReminder(bool on, {int? minutes}) {
    reminder = on;
    if (minutes != null) reminderMinutes = minutes;
    _save();
    notifyListeners();
  }

  void resetAll() {
    done = {};
    rewardedTopics = {};
    xpByDay = {};
    days = {};
    xp = 0;
    qstats = {};
    achievements = {};
    log = [];
    correctTotal = 0;
    lessonsDone = 0;
    perfectLessons = 0;
    pomodoros = 0;
    _save();
    notifyListeners();
  }
}

final AppState appState = AppState();
