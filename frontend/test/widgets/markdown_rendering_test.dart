import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Étape 4.3 : `flutter_markdown` (abandonné) remplacé par son fork
/// `flutter_markdown_plus`. Les champs riches des CRI (travaux, préconisations,
/// modèles préventifs) doivent s'afficher comme avant : gras, italique,
/// listes, titres.
void main() {
  Future<void> render(WidgetTester tester, String data) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MarkdownBody(data: data))),
      );

  /// Tous les fragments de texte rendus, avec leur style effectif.
  List<TextSpan> spans(WidgetTester tester) {
    final result = <TextSpan>[];
    for (final text in tester.widgetList<RichText>(find.byType(RichText))) {
      text.text.visitChildren((span) {
        if (span is TextSpan && (span.text ?? '').isNotEmpty) result.add(span);
        return true;
      });
      final root = text.text;
      if (root is TextSpan && (root.text ?? '').isNotEmpty) result.add(root);
    }
    return result;
  }

  TextSpan spanOf(WidgetTester tester, String text) =>
      spans(tester).firstWhere((s) => s.text == text);

  testWidgets('gras et italique', (tester) async {
    await render(tester, 'Remplacement **carte mère** et *test* final');

    expect(spanOf(tester, 'carte mère').style?.fontWeight, FontWeight.bold);
    expect(spanOf(tester, 'test').style?.fontStyle, FontStyle.italic);
  });

  testWidgets('liste à puces : un élément par ligne', (tester) async {
    await render(tester, '- Contrôle alimentation\n- Mise à jour firmware');

    expect(find.text('•'), findsNWidgets(2));
    expect(spans(tester).map((s) => s.text),
        containsAll(['Contrôle alimentation', 'Mise à jour firmware']));
  });

  testWidgets('titre plus grand que le corps', (tester) async {
    await render(tester, '## Préconisations\n\nTexte courant');

    final title = spanOf(tester, 'Préconisations').style!.fontSize!;
    final body = spanOf(tester, 'Texte courant').style!.fontSize!;
    expect(title, greaterThan(body));
  });
}
