import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static const String apiUrl = 'https://api.openai.com/v1/chat/completions';

  Future<String> askOpenAI(String question, String formattedData) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null) {
      throw Exception('API key not found');
    }

    final prompt = '''
Com base nos seguintes dados de compras:

$formattedData

Por favor, responda à seguinte pergunta:
$question
''';

    print('Enviando prompt para OpenAI: $prompt');

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant that answers questions about shopping data.'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final answer = data['choices'][0]['message']['content'];
      print('Resposta recebida da OpenAI: $answer');
      return answer;
    } else {
      print('Erro na resposta da OpenAI. Status code: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
      throw Exception('Failed to get response from OpenAI');
    }
  }
}