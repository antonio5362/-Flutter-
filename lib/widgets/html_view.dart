import 'package:flutter/material.dart';
import '../theme.dart';

/// Простой показ учебного HTML (теги p, b, ul, li) без внешних библиотек.
class HtmlView extends StatelessWidget {
  final String html;
  const HtmlView(this.html, {super.key});

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 16, height: 1.55, color: C.text);
    const boldStyle = TextStyle(fontSize: 16, height: 1.55, color: C.primary, fontWeight: FontWeight.w700);

    final blocks = <Widget>[];
    final spans = <InlineSpan>[];
    var bold = 0;

    void flush(bool bullet) {
      final children = List<InlineSpan>.from(spans);
      spans.clear();
      final hasText = children.any((s) => s is TextSpan && (s.text ?? '').trim().isNotEmpty);
      if (!hasText) return;
      final text = Text.rich(TextSpan(style: base, children: children));
      if (bullet) {
        blocks.add(Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text('•', style: TextStyle(fontSize: 16, height: 1.55, color: C.accent, fontWeight: FontWeight.w700)),
              ),
              Expanded(child: text),
            ],
          ),
        ));
      } else {
        blocks.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: text));
      }
    }

    final re = RegExp(r'<(/?)(p|b|ul|li)>|([^<]+)');
    for (final m in re.allMatches(html)) {
      final textPart = m.group(3);
      if (textPart != null) {
        spans.add(TextSpan(text: textPart, style: bold > 0 ? boldStyle : null));
        continue;
      }
      final close = m.group(1) == '/';
      final tag = m.group(2);
      if (tag == 'b') {
        bold += close ? -1 : 1;
        if (bold < 0) bold = 0;
      } else if (tag == 'p' && close) {
        flush(false);
      } else if (tag == 'li' && close) {
        flush(true);
      }
    }
    flush(false);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }
}
