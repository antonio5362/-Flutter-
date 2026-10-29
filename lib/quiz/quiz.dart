import 'dart:math';
import '../data/content.dart';

/// Одна «карточка» для запоминания: дата↔событие или термин↔определение.
class QuizItem {
  final String id;
  final String sectionId;
  final String topicKey;
  final bool isDate;
  final String a; // дата или термин
  final String b; // событие или определение

  QuizItem({
    required this.id,
    required this.sectionId,
    required this.topicKey,
    required this.isDate,
    required this.a,
    required this.b,
  });
}

class Question {
  final QuizItem item;
  final String prompt;
  final List<String> options;
  final int correct;
  final String explanation;

  Question({
    required this.item,
    required this.prompt,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  String get id => item.id;
}

class QuizBank {
  static List<QuizItem> items = [];

  static void build() {
    final result = <QuizItem>[];
    for (final t in Content.flat) {
      for (var i = 0; i < t.dates.length; i++) {
        result.add(QuizItem(
          id: '${t.key}_d$i',
          sectionId: t.sectionId,
          topicKey: t.key,
          isDate: true,
          a: t.dates[i][0],
          b: t.dates[i][1],
        ));
      }
      for (var i = 0; i < t.terms.length; i++) {
        result.add(QuizItem(
          id: '${t.key}_m$i',
          sectionId: t.sectionId,
          topicKey: t.key,
          isDate: false,
          a: t.terms[i][0],
          b: t.terms[i][1],
        ));
      }
    }
    items = result;
  }

  static List<QuizItem> forTopic(Topic t) => items.where((e) => e.topicKey == t.key).toList();
  static List<QuizItem> forSection(Section s) => items.where((e) => e.sectionId == s.id).toList();
  static List<QuizItem> dates() => items.where((e) => e.isDate).toList();
  static List<QuizItem> terms() => items.where((e) => !e.isDate).toList();

  static QuizItem? byId(String id) {
    for (final e in items) {
      if (e.id == id) return e;
    }
    return null;
  }

  static List<QuizItem> pick(List<QuizItem> pool, int n, Random rng) {
    final copy = List<QuizItem>.from(pool)..shuffle(rng);
    return copy.take(n).toList();
  }

  static Question make(QuizItem it, Random rng) {
    final rev = rng.nextBool();
    final answer = rev ? it.a : it.b;

    final String prompt;
    if (it.isDate) {
      prompt = rev
          ? 'К какой дате или периоду относится:\n«${it.b}»?'
          : 'С каким событием связана дата\n«${it.a}»?';
    } else {
      prompt = rev
          ? 'Какой термин соответствует определению:\n«${it.b}»?'
          : 'Что означает термин\n«${it.a}»?';
    }

    final same = <String>{};
    final other = <String>{};
    for (final o in items) {
      if (o.isDate != it.isDate || o.id == it.id) continue;
      final v = rev ? o.a : o.b;
      if (v == answer) continue;
      if (o.sectionId == it.sectionId) {
        same.add(v);
      } else {
        other.add(v);
      }
    }
    final s = same.toList()..shuffle(rng);
    final ot = other.toList()..shuffle(rng);
    final distractors = <String>[...s, ...ot].take(3).toList();
    final options = <String>[answer, ...distractors]..shuffle(rng);

    return Question(
      item: it,
      prompt: prompt,
      options: options,
      correct: options.indexOf(answer),
      explanation: '${it.a} — ${it.b}',
    );
  }
}
