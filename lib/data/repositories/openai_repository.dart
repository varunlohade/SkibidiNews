import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class OpenAIRepository {
  final String apiKey;
  static const String baseUrl = 'https://api.openai.com/v1';

  OpenAIRepository({required this.apiKey});

  Future<Map<String, String>> generatePodcastContent(String topic) async {
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
            'content':
                '''You are writing a script for a comedy podcast with two hosts.
            Host 1 (Alex) is energetic and funny, while Host 2 (Jamie) is more analytical but still humorous.
            Include natural reactions like laughter [😂] and expressions of surprise [😮].
            Format the conversation clearly with "Alex:" and "Jamie:" prefixes.
            Make it engaging, informative, and entertaining.
            Keep each host's lines under 4 sentences for better flow.''',
          },
          {
            'role': 'user',
            'content':
                'Create a funny but informative podcast script about $topic. Include reactions and make it natural.',
          }
        ],
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];

      // Split content into two separate scripts for each voice
      final lines = content.split('\n');
      String alexScript = '';
      String jamieScript = '';

      for (var line in lines) {
        if (line.trim().startsWith('Alex:')) {
          alexScript += line.replaceAll('Alex:', '').trim() + '\n';
        } else if (line.trim().startsWith('Jamie:')) {
          jamieScript += line.replaceAll('Jamie:', '').trim() + '\n';
        }
      }

      return {
        'content': content,
        'alexScript': alexScript,
        'jamieScript': jamieScript,
      };
    } else {
      print(response.body);
      throw Exception('Failed to generate content');
    }
  }

  Future<String> generateAudioForVoice(String text, String voice) async {
    final response = await http.post(
      Uri.parse('$baseUrl/audio/speech'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'tts-1',
        'input': text,
        'voice': voice, // 'alloy' for Alex, 'echo' for Jamie
      }),
    );

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${dir.absolute.path}/podcast_${voice}_$timestamp.mp3';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      print('Audio file generated at: $filePath');
      return filePath;
    } else {
      print('Failed to generate audio: ${response.body}');
      throw Exception('Failed to generate audio');
    }
  }

  Future<String> mergeAudioFiles(String firstAudioPath, String secondAudioPath) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${dir.absolute.path}/merged_podcast_$timestamp.mp3';

    // Create a complex filter to merge audio files with crossfade
    final command = '-i "$firstAudioPath" -i "$secondAudioPath" -filter_complex '
        '"[0:a][1:a]concat=n=2:v=0:a=1[out]" '
        '-map "[out]" "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      print('Audio files merged successfully at: $outputPath');
      return outputPath;
    } else {
      final logs = await session.getLogs();
      print('Failed to merge audio files: $logs');
      throw Exception('Failed to merge audio files');
    }
  }

  Future<String> generateDualVoicePodcast(String topic) async {
    // First generate the content
    final content = await generatePodcastContent(topic);

    // Generate audio for both voices
    final alexAudioPath = await generateAudioForVoice(
      content['alexScript']!,
      'alloy', // More energetic voice
    );

    final jamieAudioPath = await generateAudioForVoice(
      content['jamieScript']!,
      'echo', // More analytical voice
    );

    // Merge the audio files
    try {
      final mergedAudioPath = await mergeAudioFiles(alexAudioPath, jamieAudioPath);
      
      // Clean up individual audio files
      await File(alexAudioPath).delete();
      await File(jamieAudioPath).delete();
      
      return mergedAudioPath;
    } catch (e) {
      print('Error merging audio files: $e');
      // If merging fails, return the first voice's audio as fallback
      await File(jamieAudioPath).delete(); // Clean up second file
      return alexAudioPath;
    }
  }

  Future<String> downloadPodcast(String url, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(path.join(dir.path, filename));

    if (await file.exists()) {
      return file.path;
    }

    final response = await http.get(Uri.parse(url));
    await file.writeAsBytes(response.bodyBytes);
    return file.path;
  }
}
