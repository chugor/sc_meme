import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/meme_provider.dart';
import 'models/meme.dart';
import 'meme_dismissible.dart';

class MemeListing extends StatefulWidget {
  const MemeListing({Key? key}) : super(key: key);

  @override
  MemeListingState createState() => MemeListingState();
}

class MemeListingState extends State<MemeListing> {
  List<Meme> allMemes = [];
  List<Meme> currentMemes = [];
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  final int itemsPerPage = 10;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        _loadMoreMemes();
      }
    });
  }

  _loadMoreMemes() {
    if (!isLoading && (currentPage + 1) * itemsPerPage < allMemes.length) {
      setState(() {
        isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          currentMemes.addAll(allMemes
              .skip(currentPage * itemsPerPage)
              .take(itemsPerPage)
              .toList());
          currentPage++;
          isLoading = false;
        });
      });
    }
  }

  _changeFavorite(Meme meme) {
    final bookmarksBox = Hive.box<Meme>('bookmarks');
    if (bookmarksBox.containsKey(meme.id)) {
      bookmarksBox.delete(meme.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites!')),
      );
    } else {
      bookmarksBox.put(meme.id, meme);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to favorites!')),
      );
    }
  }

  Future<void> _refreshMemeList() async {
    // Logic to refresh the memes, probably calling the memeProvider again
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final memesAsyncValue = ref.watch(memeProvider);

        return memesAsyncValue.when(
          data: (memes) {
            if (allMemes.isEmpty) {
              allMemes = memes;
              if (currentMemes.isEmpty) {
                Future.microtask(() => _loadMoreMemes());
              }
            }

            return RefreshIndicator(
              onRefresh: _refreshMemeList,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: currentMemes.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == currentMemes.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final meme = currentMemes[index];

                  return MemeDismissible(
                      meme: meme,
                      isFavorite:
                          Hive.box<Meme>('bookmarks').containsKey(meme.id),
                      onDismiss: (direction) async {
                        _changeFavorite(meme);

                        // Notify the UI to rebuild
                        setState(() {});

                        // By returning false, the Dismissible won't remove the item
                        return false;
                      },
                      onTap: (meme) {
                        // Optional: Do something when the meme is tapped
                        _changeFavorite(meme);

                        // Notify the UI to rebuild
                        setState(() {});
                      });
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Error loading memes: $error')),
        );
      },
    );
  }
}
