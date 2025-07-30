import 'package:flutter/material.dart';
import 'gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart'; // <-- Import the new package

// ChatMessage class remains the same
class ChatMessage {
  final String text;
  final bool isUserMessage;
  final bool isTyping;

  ChatMessage({
    required this.text,
    required this.isUserMessage,
    this.isTyping = false,
  });
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // --- Part 1: State Variables ---
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessage> _messages = [
    ChatMessage(text: "Hello! I'm a Gemini-powered AI. How can I assist you today?", isUserMessage: false),
  ];
  
  bool _isDarkMode = false;
  
  // --- NEW: State variables for speech-to-text ---
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _initSpeech(); // Initialize speech recognition when the screen loads
  }

  // --- NEW: Initialize the speech-to-text service ---
  void _initSpeech() async {
    await _speechToText.initialize();
  }

  // --- NEW: Start listening for speech ---
  void _startListening() async {
    await _speechToText.listen(onResult: (result) {
      setState(() {
        // Update the text field with the recognized words as the user speaks
        _controller.text = result.recognizedWords;
      });
    });
    setState(() {
      _isListening = true;
    });
  }

  // --- NEW: Stop listening for speech ---
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _sendMessage() async {
    // ... sendMessage logic remains the same ...
    if (_controller.text.trim().isEmpty) return;
    final userMessageText = _controller.text.trim();
    final userMessage = ChatMessage(text: userMessageText, isUserMessage: true);

    setState(() {
      _messages.add(userMessage);
      _messages.add(ChatMessage(text: "Typing...", isUserMessage: false, isTyping: true));
    });
    
    _controller.clear();
    _scrollToBottom();

    try {
      final aiResponseText = await _geminiService.sendMessage(userMessageText);
      final aiMessage = ChatMessage(text: aiResponseText, isUserMessage: false);
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(aiMessage);
        });
        _scrollToBottom();
      }
    } catch (e) {
      final errorMessage = ChatMessage(text: "Sorry, an error occurred.", isUserMessage: false);
      if (mounted) {
        setState(() {
          _messages.removeLast();
          _messages.add(errorMessage);
        });
        _scrollToBottom();
      }
    }
  }
  
  void _scrollToBottom() {
    // ... scrollToBottom logic remains the same ...
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ... build method and color definitions remain the same ...
    final Color scaffoldBgColor = _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final Color appBarColor = _isDarkMode ? const Color(0xFF1F1F1F) : Colors.blue;
    final Color inputAreaColor = _isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: const Text("Gemini AI Chatbot"),
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: "Toggle Theme",
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isDarkMode
                ? [const Color(0xFF121212), const Color(0xFF181818)]
                : [Colors.white, const Color(0xFFE3F2FD)],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message, _isDarkMode);
                },
              ),
            ),
            _buildInputArea(inputAreaColor),
          ],
        ),
      ),
    );
  }

  // ... _buildMessageBubble remains the same ...
  Widget _buildMessageBubble(ChatMessage message, bool isDarkMode) {
    final Color userBubbleColor = isDarkMode ? Colors.blue.shade700 : Colors.blue;
    final Color botBubbleColor = isDarkMode ? const Color(0xFF333333) : Colors.white;
    final Color userTextColor = Colors.white;
    final Color botTextColor = isDarkMode ? Colors.white : Colors.black87;

    if (message.isTyping) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: botBubbleColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomRight: Radius.circular(20),
            ),
          ),
          child: SizedBox(width: 50, height: 25, child: Text("...", style: TextStyle(fontSize: 25, color: botTextColor, letterSpacing: 5))),
        ),
      );
    }
    
    return Align(
      alignment: message.isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0),
        padding: const EdgeInsets.all(14.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUserMessage ? userBubbleColor : botBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
            bottomLeft: message.isUserMessage ? const Radius.circular(20) : Radius.zero,
            bottomRight: message.isUserMessage ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2))],
        ),
        child: Text(
          message.text, style: TextStyle(color: message.isUserMessage ? userTextColor : botTextColor, fontSize: 16),
        ),
      ),
    );
  }

  // --- MODIFIED: Input Area Widget now includes the microphone button ---
  Widget _buildInputArea(Color inputAreaColor) {
    final Color iconColor = _isDarkMode ? Colors.blue.shade700 : Colors.blue;
    final Color textFieldBgColor = _isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);
    final Color hintColor = _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: inputAreaColor,
        boxShadow: const [BoxShadow(offset: Offset(0, -1), blurRadius: 4, color: Colors.black12)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // --- NEW: Microphone Button ---
            IconButton(
              icon: Icon(_isListening ? Icons.stop_circle_outlined : Icons.mic_none_outlined),
              color: _isListening ? Colors.redAccent : iconColor,
              onPressed: _isListening ? _stopListening : _startListening,
              tooltip: "Voice Input",
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: textFieldBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: _isListening ? "Listening..." : "Ask the AI anything...",
                    hintStyle: TextStyle(color: hintColor),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: iconColor),
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}