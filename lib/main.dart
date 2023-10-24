import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/meme_adapter.dart';
import 'models/meme.dart';
import 'meme_listing.dart';
import 'favorite_memes.dart';

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
        appBar: AppBar(
          title: _currentIndex == 0
              ? const Text('Meme Listing')
              : const Text('Favorites'),
        ),
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
