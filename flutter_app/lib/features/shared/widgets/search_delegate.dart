import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';

class AppSearchDelegate extends SearchDelegate<String?> {
  final WidgetRef ref;
  final List<String> searchableTitles;
  final ValueChanged<String> onSelected;

  AppSearchDelegate({
    required this.ref,
    required this.searchableTitles,
    required this.onSelected,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            ref.read(searchProvider.notifier).onQueryChanged('', pool: searchableTitles);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    ref.read(searchProvider.notifier).addRecent(query);
    onSelected(query);
    return Center(
      child: Text('Showing results for: "$query"'),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    if (query.isEmpty) {
      return ListView.builder(
        itemCount: searchState.recentSearches.length,
        itemBuilder: (context, index) {
          final item = searchState.recentSearches[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(item),
            onTap: () {
              query = item;
              showResults(context);
            },
          );
        },
      );
    }

    ref.read(searchProvider.notifier).onQueryChanged(query, pool: searchableTitles);

    return ListView.builder(
      itemCount: searchState.suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = searchState.suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }
}
