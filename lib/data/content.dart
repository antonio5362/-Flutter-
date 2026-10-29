import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Topic {
  final String sectionId;
  final int index;
  final String title;
  final String html;
  final List<List<String>> dates;
  final List<List<String>> terms;

  Topic({
    required this.sectionId,
    required this.index,
    required this.title,
    required this.html,
    required this.dates,
    required this.terms,
  });

  String get key => '${sectionId}_t$index';
}

class Section {
  final String id;
  final String title;
  final String weight;
  final List<Topic> topics;

  Section({required this.id, required this.title, required this.weight, required this.topics});

  String get label {
    final m = RegExp(r'^Раздел (\d+)').firstMatch(title);
    return m != null ? 'Раздел ${m.group(1)}' : 'Обобщение';
  }
}

class Content {
  static List<Section> sections = [];
  static List<Topic> flat = [];

  static List<List<String>> _pairs(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map<List<String>>((e) => (e as List).map((x) => x.toString()).toList())
        .where((e) => e.length >= 2)
        .toList();
  }

  static Future<void> load() async {
    final raw = await rootBundle.loadString('assets/sections.json');
    final list = jsonDecode(raw) as List<dynamic>;
    final result = <Section>[];
    for (final s in list) {
      final m = s as Map<String, dynamic>;
      final sid = m['id'] as String;
      final topics = <Topic>[];
      final rawTopics = m['topics'] as List<dynamic>;
      for (var i = 0; i < rawTopics.length; i++) {
        final t = rawTopics[i] as Map<String, dynamic>;
        topics.add(Topic(
          sectionId: sid,
          index: i,
          title: t['title'] as String,
          html: t['content'] as String,
          dates: _pairs(t['dates']),
          terms: _pairs(t['terms']),
        ));
      }
      result.add(Section(
        id: sid,
        title: m['title'] as String,
        weight: (m['weight'] ?? '') as String,
        topics: topics,
      ));
    }
    sections = result;
    flat = [for (final s in result) ...s.topics];
  }

  static Section sectionOf(Topic t) => sections.firstWhere((s) => s.id == t.sectionId);

  static Topic? byKey(String key) {
    for (final t in flat) {
      if (t.key == key) return t;
    }
    return null;
  }
}
