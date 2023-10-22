import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sc_meme/models/meme.dart';

class ApiService {
  static const baseUrl = 'https://api.imgflip.com';

  static Future<List<Meme>> getMemes() async {
    final response = await http.get(Uri.parse('$baseUrl/get_memes'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<dynamic> memeList = data['data']['memes'];
      return memeList.map((meme) => Meme.fromJson(meme)).toList();
    } else {
      throw Exception('Failed to load memes');
    }
  }
}
