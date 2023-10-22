import 'package:riverpod/riverpod.dart';
import 'package:sc_meme/services/api_service.dart';
import 'package:sc_meme/models/meme.dart';

final memeProvider = FutureProvider<List<Meme>>((ref) async {
  return ApiService.getMemes();
});
