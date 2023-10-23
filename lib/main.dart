import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/meme_provider.dart';
import 'models/meme_adapter.dart';
import 'models/meme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDirectory = await getApplicationDocumentsDirectory();

  Hive.init(appDocumentDirectory.path);
  Hive.registerAdapter(MemeAdapter());
  await Hive.openBox<Meme>('bookmarks');

  runApp(const ProviderScope(child: SCMemeApp()));
}

class SCMemeApp extends StatefulWidget {
  const SCMemeApp({Key? key}) : super(key: key);

  @override
  SCMemeAppState createState() => SCMemeAppState();
}

class SCMemeAppState extends State<SCMemeApp> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    MemeListing(),
    FavoriteMemes(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('SC Memes')),
        body: _tabs[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'Meme Listing',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
          ],
        ),
      ),
    );
  }
}

class MemeListing extends StatefulWidget {
  const MemeListing({Key? key}) : super(key: key);

  @override
  MemeListingState createState() => MemeListingState();
}

class MemeListingState extends State<MemeListing> {
  List<Meme> allMemes = [];
  List<Meme> currentMemes = [];
  ScrollController _scrollController = ScrollController();
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

      Future.delayed(Duration(seconds: 2), () {
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
                    return Center(child: CircularProgressIndicator());
                  }
                  final meme = currentMemes[index];

                  return Dismissible(
                    key: ValueKey(meme.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      color: Colors.red,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.favorite, color: Colors.white),
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      final bookmarksBox = Hive.box<Meme>('bookmarks');
                      if (bookmarksBox.containsKey(meme.id)) {
                        bookmarksBox.delete(meme.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Removed from favorites!')),
                        );
                      } else {
                        bookmarksBox.put(meme.id, meme);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to favorites!')),
                        );
                      }

                      // Notify the UI to rebuild
                      setState(() {});

                      // By returning false, the Dismissible won't remove the item
                      return false;
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Image.network(meme.imageUrl),
                        title: Text(meme.name),
                        trailing: Icon(
                          Hive.box<Meme>('bookmarks').containsKey(meme.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        onTap: () {
                          // Optional: Do something when the meme is tapped
                        },
                      ),
                    ),
                  );
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

class FavoriteMemes extends StatefulWidget {
  const FavoriteMemes({Key? key}) : super(key: key);

  @override
  _FavoriteMemesState createState() => _FavoriteMemesState();
}

class _FavoriteMemesState extends State<FavoriteMemes> {
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

      Future.delayed(Duration(seconds: 2), () {
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
                      decoration: InputDecoration(
                        hintText: 'Search...',
                      ),
                    ),
                  )
                else
                  const Text('Search'),
                SizedBox(width: 10),
                if (isSearching)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        isSearching = false;
                        _searchController.clear();
                        filteredMemes = currentMemes;
                      });
                    },
                    child: Text('Cancel'),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.search),
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
                    return Center(child: CircularProgressIndicator());
                  }
                  final meme = filteredMemes[index];
                  return Dismissible(
                    key: ValueKey(meme.id),
                    background: Container(
                      alignment: Alignment.centerRight,
                      color: Colors.red,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      Hive.box<Meme>('bookmarks').delete(meme.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Removed from favorites!')),
                      );
                      setState(() {
                        filteredMemes.removeAt(index);
                        currentMemes.removeWhere((m) => m.id == meme.id);
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: Image.network(meme.imageUrl),
                        title: Text(meme.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite),
                          onPressed: () {
                            Hive.box<Meme>('bookmarks').delete(meme.id);
                            setState(() {
                              filteredMemes.removeAt(index);
                              currentMemes.removeWhere((m) => m.id == meme.id);
                            });
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
