import 'package:flutter/material.dart';
import 'models/meme.dart';

class MemeDismissible extends StatelessWidget {
  final Meme meme;
  final bool isFavorite;
  final Function(Meme meme) onDismiss;
  final Function(Meme meme) onTap;

  const MemeDismissible({
    super.key,
    required this.meme,
    required this.isFavorite,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(meme.id),
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Icon(isFavorite ? Icons.delete : Icons.favorite,
              color: Colors.white),
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => onDismiss(meme),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: ListTile(
          visualDensity: const VisualDensity(vertical: 4.0),
          leading: AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                meme.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          title: Text(
            meme.name,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => onTap(meme),
          ),
        ),
      ),
    );
  }
}
