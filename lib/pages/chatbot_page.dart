import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';
import '../services/voice_search_service.dart';
import '../providers/property_provider.dart';
import '../models/property.dart';
import 'property_details_page.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = AIService();
  final _speechToText = SpeechToText();

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechEnabled = false;
  List<Property> _allProperties = [];
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadProperties();
    _addBotMessage(
      'Hi! I\'m your AI real estate assistant. I can help you find properties, compare listings, and answer questions. You can also use voice search! How can I help you today?',
    );
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _loadProperties() {
    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    _allProperties = propertyProvider.properties;
  }

  void _addBotMessage(String text, {List<Property>? properties}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: true,
        properties: properties,
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isBot: false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
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

  Future<void> _sendMessage([String? voiceText]) async {
    final text = voiceText ?? _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addUserMessage(text);

    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': text});

    setState(() => _isLoading = true);

    try {
      // Refresh properties
      _loadProperties();

      // Search for matching properties
      final matchingProperties = _aiService.searchProperties(text, _allProperties);

      // Get AI response
      final response = await _aiService.generateResponse(
        text,
        _allProperties,
        conversationHistory: _conversationHistory.length > 10
            ? _conversationHistory.sublist(_conversationHistory.length - 10)
            : _conversationHistory,
      );

      // Add to conversation history
      _conversationHistory.add({'role': 'assistant', 'content': response});

      _addBotMessage(
        response,
        properties: matchingProperties.isNotEmpty ? matchingProperties : null,
      );
    } catch (e) {
      _addBotMessage('Sorry, I encountered an error. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });
        if (result.finalResult) {
          _stopListening();
          if (_controller.text.isNotEmpty) {
            _sendMessage();
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() => _isListening = true);
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: TextStyle(fontSize: 16)),
                Text(
                  'Powered by Mistral AI',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages.clear();
                _conversationHistory.clear();
              });
              _addBotMessage(
                'Chat cleared! How can I help you find your perfect property?',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('Show all properties', Icons.home),
                  _buildQuickAction('Properties under 500k', Icons.attach_money),
                  _buildQuickAction('3 bedroom homes', Icons.bed),
                  _buildQuickAction('Properties with pool', Icons.pool),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          // Voice Indicator
          if (_isListening)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Listening...',
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: _stopListening,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice Button
                IconButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening
                        ? Colors.red
                        : Theme.of(context).primaryColor,
                  ),
                ),
                // Text Input
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about properties...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                IconButton.filled(
                  onPressed: _isLoading ? null : () => _sendMessage(),
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _controller.text = text;
          _sendMessage();
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            _buildDot(1),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment:
            message.isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            decoration: BoxDecoration(
              color: message.isBot
                  ? Colors.grey.shade200
                  : Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isBot ? Colors.black87 : Colors.white,
              ),
            ),
          ),
          // Property Cards
          if (message.properties != null && message.properties!.isNotEmpty)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.properties!.length,
                itemBuilder: (context, index) {
                  return _buildPropertyCard(message.properties![index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Property property) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: property),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                property.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.home, size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.formattedPrice,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${property.bedrooms} bed • ${property.bathrooms} bath',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final List<Property>? properties;

  ChatMessage({
    required this.text,
    required this.isBot,
    this.properties,
  });
}
