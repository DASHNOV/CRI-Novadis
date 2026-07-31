import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// Champ de saisie « éditeur riche » basé sur Markdown.
///
/// - Conserve un [FormBuilderTextField] (nommé [name]) pour rester compatible
///   avec la validation par étape existante.
/// - Ajoute une barre d'outils (gras / italique / liste à puces / titre) qui
///   insère la syntaxe Markdown correspondante.
/// - Bouton « plein écran » ouvrant un éditeur confortable avec onglets
///   Édition / Aperçu.
///
/// Le contenu stocké reste une simple chaîne (Markdown), 100 % rétrocompatible
/// avec le texte brut déjà enregistré.
class RichMarkdownField extends StatefulWidget {
  final String name;
  final String label;
  final String initialValue;
  final String hintText;
  final IconData? prefixIcon;
  final int minLines;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  /// Contrôleur fourni par le parent (ex. pour insérer un modèle de texte).
  /// Si non fourni, le champ en crée un en interne. Quand il est fourni, son
  /// cycle de vie (création / dispose) est à la charge du parent.
  final TextEditingController? controller;

  const RichMarkdownField({
    super.key,
    required this.name,
    required this.label,
    required this.initialValue,
    this.hintText = '',
    this.prefixIcon,
    this.minLines = 6,
    this.onChanged,
    this.validator,
    this.controller,
  });

  @override
  State<RichMarkdownField> createState() => _RichMarkdownFieldState();
}

class _RichMarkdownFieldState extends State<RichMarkdownField> {
  late final TextEditingController _controller;

  /// true si le contrôleur appartient au widget (donc à disposer ici).
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    if (_controller.text.isEmpty && widget.initialValue.isNotEmpty) {
      _controller.text = widget.initialValue;
    }
    _controller.addListener(_notify);
  }

  @override
  void didUpdateWidget(RichMarkdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cas édition : le contenu peut arriver après le premier build (chargement
    // async du CRI). On ne resynchronise que si l'utilisateur n'a pas encore
    // saisi (le contrôleur correspond encore à l'ancienne valeur initiale).
    if (widget.initialValue != oldWidget.initialValue &&
        _controller.text == oldWidget.initialValue) {
      _controller.value = TextEditingValue(
        text: widget.initialValue,
        selection: TextSelection.collapsed(offset: widget.initialValue.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_notify);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged?.call(_controller.text);

  /// Entoure la sélection courante de [left]/[right] (gras, italique…).
  /// Si rien n'est sélectionné, insère les marqueurs et place le curseur entre.
  void _wrapSelection(String left, String right) {
    final text = _controller.text;
    final sel = _controller.selection;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final selected = text.substring(start, end);
    final replacement = '$left$selected$right';
    final newText = text.replaceRange(start, end, replacement);
    final caret = selected.isEmpty
        ? start + left.length
        : start + replacement.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  /// Préfixe le début de la ligne courante (listes, titres).
  void _prefixLine(String prefix) {
    final text = _controller.text;
    final sel = _controller.selection;
    final caret = sel.isValid ? sel.start : text.length;
    final lineStart = caret == 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
    final newText = text.replaceRange(lineStart, lineStart, prefix);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret + prefix.length),
    );
  }

  Future<void> _openFullscreen() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FullscreenMarkdownEditor(
        title: widget.label,
        controller: _controller,
        hintText: widget.hintText,
        onWrap: _wrapSelection,
        onPrefix: _prefixLine,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MarkdownToolbar(
          onWrap: _wrapSelection,
          onPrefix: _prefixLine,
          onExpand: _openFullscreen,
        ),
        const SizedBox(height: 4),
        FormBuilderTextField(
          name: widget.name,
          controller: _controller,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon)
                : null,
            alignLabelWithHint: true,
          ),
          minLines: widget.minLines,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          validator: widget.validator,
        ),
      ],
    );
  }
}

/// Barre d'outils de mise en forme Markdown.
class _MarkdownToolbar extends StatelessWidget {
  final void Function(String left, String right) onWrap;
  final void Function(String prefix) onPrefix;
  final VoidCallback onExpand;

  const _MarkdownToolbar({
    required this.onWrap,
    required this.onPrefix,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget btn(IconData icon, String tooltip, VoidCallback onTap) {
      return IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        onPressed: onTap,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          btn(Icons.format_bold, 'Gras', () => onWrap('**', '**')),
          btn(Icons.format_italic, 'Italique', () => onWrap('*', '*')),
          btn(Icons.format_list_bulleted, 'Liste à puces',
              () => onPrefix('- ')),
          btn(Icons.title, 'Titre', () => onPrefix('## ')),
          const Spacer(),
          btn(Icons.open_in_full, 'Plein écran', onExpand),
        ],
      ),
    );
  }
}

/// Éditeur plein écran avec onglets Édition / Aperçu.
class _FullscreenMarkdownEditor extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final String hintText;
  final void Function(String left, String right) onWrap;
  final void Function(String prefix) onPrefix;

  const _FullscreenMarkdownEditor({
    required this.title,
    required this.controller,
    required this.hintText,
    required this.onWrap,
    required this.onPrefix,
  });

  @override
  State<_FullscreenMarkdownEditor> createState() =>
      _FullscreenMarkdownEditorState();
}

class _FullscreenMarkdownEditorState extends State<_FullscreenMarkdownEditor> {
  bool _preview = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      child: SizedBox(
        width: size.width,
        height: size.height * 0.9,
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    tooltip: 'Terminer',
                  ),
                ],
              ),
            ),
            // Bascule Édition / Aperçu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Édition'),
                      icon: Icon(Icons.edit)),
                  ButtonSegment(value: true, label: Text('Aperçu'),
                      icon: Icon(Icons.visibility)),
                ],
                selected: {_preview},
                onSelectionChanged: (s) => setState(() => _preview = s.first),
              ),
            ),
            const SizedBox(height: 8),
            if (!_preview)
              _MarkdownToolbar(
                onWrap: (l, r) {
                  widget.onWrap(l, r);
                  setState(() {});
                },
                onPrefix: (p) {
                  widget.onPrefix(p);
                  setState(() {});
                },
                onExpand: () {},
              ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _preview
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          child: MarkdownBody(
                            data: widget.controller.text.isEmpty
                                ? '_Aucun contenu_'
                                : widget.controller.text,
                          ),
                        ),
                      )
                    : TextField(
                        controller: widget.controller,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
