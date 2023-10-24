import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'models/meme.dart';
import 'meme_dismissible.dart';

class FavoriteMemes extends StatefulWidget {
  const FavoriteMemes({Key? key}) : super(key: key);

  @override
  FavoriteMemesState createState() => FavoriteMemesState();
}

class FavoriteMemesState extends State<FavoriteMemes> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final int itemsPerPage = 10;
  int currentPage = 0;
  bool isLoading = false;
  bool isSearching = false;
  List<Meme> currentMemes = [];
  List<Meme> filteredMemes = [];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent &&
          !isLoading) {
        _loadMoreMemes();
      }
    });

    _loadMoreMemes();
  }

  _loadMoreMemes() {
    final bookmarksBox = Hive.box<Meme>('bookmarks');
    final totalMemes = bookmarksBox.values.toList();

    if (currentPage * itemsPerPage < totalMemes.length) {
      setState(() {
        isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        List<Meme> newMemes = totalMemes
            .skip(currentPage * itemsPerPage)
            .take(itemsPerPage)
            .toList();
        setState(() {
          currentMemes.addAll(newMemes);
          filteredMemes.addAll(newMemes);
          currentPage++;
          isLoading = false;
        });
      });
    }
  }

  Future<void> _refreshFavoriteMemes() async {
    setState(() {
      currentMemes.clear();
      currentPage = 0;
    });
    _loadMoreMemes();
  }

  _performSearch(String searchText) {
    if (searchText.isEmpty) {
      setState(() {
        filteredMemes = [];
      });
    } else {
      setState(() {
        filteredMemes = currentMemes.where((meme) {
          return meme.name.toLowerCase().contains(searchText.toLowerCase());
        }).toList();
      });
    }
  }

  _changeFavorite(Meme meme, int index) {
    Hive.box<Meme>('bookmarks').delete(meme.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from favorites!')),
    );
    setState(() {
      filteredMemes.removeAt(index);
      currentMemes.removeWhere((m) => m.id == meme.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                if (isSearching)
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _performSearch(value),
                      onSubmitted: (value) => _performSearch(value),
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                      ),
                    ),
                  )
                else
                  const Text('Search'),
                const SizedBox(width: 10),
                if (isSearching)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSearching = false;
                        _searchController.clear();
                        filteredMemes = currentMemes;
                      });
                    },
                    child: const Text('Cancel'),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      setState(() {
                        isSearching = true;
                        filteredMemes =
                            []; // Clear the filtered memes when starting a search
                      });
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshFavoriteMemes,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: filteredMemes.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filteredMemes.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final meme = filteredMemes[index];

                  return MemeDismissible(
                      meme: meme,
                      isFavorite:
                          Hive.box<Meme>('bookmarks').containsKey(meme.id),
                      onDismiss: (direction) async {
                        _changeFavorite(meme, index);
                      },
                      onTap: (meme) {
                        _changeFavorite(meme, index);
                      });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
