import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Liste avec recherche, tri et affichage par tranches (« Afficher plus »).
/// Les listes du dashboard peuvent compter des centaines de sites : on n'en
/// construit que [pageSize] à la fois.
class SearchableSortedList<T> extends StatefulWidget {
  final List<T> items;
  final String searchHint;

  /// Texte sur lequel porte la recherche (insensible à la casse et aux accents).
  final String Function(T item) searchText;

  /// Tris proposés, dans l'ordre du menu ; le premier est celui par défaut.
  final Map<String, Comparator<T>> sorts;
  final Widget Function(T item) itemBuilder;
  final String emptyMessage;
  final int pageSize;

  const SearchableSortedList({
    super.key,
    required this.items,
    required this.searchHint,
    required this.searchText,
    required this.sorts,
    required this.itemBuilder,
    this.emptyMessage = 'Aucun résultat',
    this.pageSize = 20,
  });

  @override
  State<SearchableSortedList<T>> createState() => _SearchableSortedListState<T>();
}

/// Minuscules sans accents, pour une recherche tolérante (« evry » trouve « Évry »).
String normalizeForSearch(String text) {
  const from = 'àâäáãåçéèêëíìîïñóòôöõúùûüýÿ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final i = from.indexOf(char);
    buffer.write(switch (char) {
      'œ' => 'oe',
      'æ' => 'ae',
      _ => i >= 0 ? to[i] : char,
    });
  }
  return buffer.toString();
}

class _SearchableSortedListState<T> extends State<SearchableSortedList<T>> {
  String _search = '';
  late String _sort = widget.sorts.keys.first;
  late int _visible = widget.pageSize;

  List<T> get _filtered {
    final needle = normalizeForSearch(_search.trim());
    final result = needle.isEmpty
        ? List<T>.of(widget.items)
        : widget.items
            .where((item) => normalizeForSearch(widget.searchText(item)).contains(needle))
            .toList();
    return result..sort(widget.sorts[_sort]);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final shown = filtered.take(_visible).toList();
    final remaining = filtered.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: TextField(
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                onChanged: (value) => setState(() {
                  _search = value;
                  _visible = widget.pageSize;
                }),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sort_rounded, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: AppTheme.space4),
                DropdownButton<String>(
                  value: _sort,
                  underline: const SizedBox.shrink(),
                  items: widget.sorts.keys
                      .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _sort = value);
                  },
                ),
              ],
            ),
            Text(
              '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Center(
              child: Text(
                widget.emptyMessage,
                style: TextStyle(color: AppTheme.textTertiary),
              ),
            ),
          )
        else
          ...shown.map(widget.itemBuilder),
        if (remaining > 0)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _visible += widget.pageSize),
              icon: const Icon(Icons.expand_more_rounded),
              label: Text('Afficher plus ($remaining restant${remaining > 1 ? 's' : ''})'),
            ),
          ),
      ],
    );
  }
}
