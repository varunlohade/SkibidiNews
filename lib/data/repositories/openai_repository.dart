import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OpenAIRepository {
  final String apiKey;
  static const String baseUrl = 'https://api.openai.com/v1';
  
  OpenAIRepository({required this.apiKey});

  Future<String> generatePodcastContent(String topic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4',
        'messages': [
          {
            'role': 'system',
            'content': 'You are a podcast host. Create a 2-minute engaging podcast script about the given topic. Be concise, informative, and engaging.',
          },
          {
            'role': 'user',
            'content': 'Create a podcast script about $topic',
          }
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to generate content');
    }
  }

  Future<String> generateAudio(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/audio/speech'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': 'alloy',
      }),
    );

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/podcast_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to generate audio');
    }
  }

  Future<String> generatePodcast(String topic) async {
    // First generate the content
    final content = await generatePodcastContent(topic);
    
    // Then convert it to audio
    final audioPath = await generateAudio(content);
    
    return audioPath;
  }
} 