import 'package:hive/hive.dart';
import 'meme.dart';

class MemeAdapter extends TypeAdapter<Meme> {
  @override
  final typeId = 0;

  @override
  Meme read(BinaryReader reader) {
    return Meme(
      id: reader.readString(),
      name: reader.readString(),
      imageUrl: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Meme obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.imageUrl);
  }
}
