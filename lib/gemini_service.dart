import 'package:google_generative_ai/google_generative_ai.dart';
import 'constants.dart'; // Your file with the API key

class GeminiService {
  final GenerativeModel _model;
  
  // Keep a chat history
  final List<Content> _history = [];

  GeminiService()
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash', // Use a fast and capable model
          apiKey: geminiApiKey,
        );
        
  // A stream of responses
  Future<String> sendMessage(String userMessage) async {
    try {
      // Add the user's message to the history
      _history.add(Content.text(userMessage));

      // Start a chat session with the existing history
      final chat = _model.startChat(history: _history);
      
      // Send the message and wait for the response
      var response = await chat.sendMessage(Content.text(userMessage));
      var text = response.text;

      if (text == null) {
        return 'No response from API.';
      }

      // Add the model's response to the history
      _history.add(Content.model([TextPart(text)]));
      
      return text;

    } catch (e) {
      // Handle potential errors, like API key issues or network problems
      print("Error sending message: $e");
      return "Sorry, I'm having trouble connecting right now.";
    }
  }
}