import 'package:flutter/material.dart';
import 'dart:math' as math;
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

class _ChatbotPageState extends State<ChatbotPage> with TickerProviderStateMixin {
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
  
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _initSpeech();
    _loadProperties();
    _addBotMessage(
      'Hi! I\'m your AI real estate assistant. 🏠\n\nI can help you find properties, compare listings, and answer questions. Tap the mic to use voice search!\n\nHow can I help you today?',
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
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isBot: false,
        timestamp: DateTime.now(),
      ));
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
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic_off, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Speech recognition not available'),
            ],
          ),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
                : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(isDark),
              // Quick Actions
              _buildQuickActionsBar(isDark),
              // Messages
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isLoading && index == _messages.length) {
                            return _buildTypingIndicator(isDark);
                          }
                          return _buildMessageBubble(_messages[index], isDark);
                        },
                      ),
              ),
              // Voice Listening Overlay
              if (_isListening) _buildVoiceListeningOverlay(isDark),
              // Input Area
              _buildInputArea(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // AI Avatar with animation
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.6),
                ],
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ).createShader(bounds),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.5 * _pulseController.value),
                                blurRadius: 4,
                                spreadRadius: _pulseController.value * 2,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online • Ready to help',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Clear Chat Button
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Clear Chat'),
                  content: const Text('Are you sure you want to clear all messages?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.clear();
                          _conversationHistory.clear();
                        });
                        _addBotMessage(
                          'Chat cleared! 🔄\n\nHow can I help you find your perfect property?',
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(bool isDark) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildQuickActionChip('🏠 All properties', 'Show all properties', isDark),
          _buildQuickActionChip('💰 Under 500k', 'Properties under 500k', isDark),
          _buildQuickActionChip('🛏️ 3 bedrooms', '3 bedroom homes', isDark),
          _buildQuickActionChip('🏊 With pool', 'Properties with pool', isDark),
          _buildQuickActionChip('🌆 Downtown', 'Downtown properties', isDark),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, String query, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _controller.text = query;
            _sendMessage();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                    : [Colors.white, Colors.grey.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask about properties or use voice search',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 80),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ).createShader(bounds),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Row(
              children: List.generate(3, (index) => _buildAnimatedDot(index, isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedDot(int index, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return AnimatedBuilder(
          animation: _waveController,
          builder: (context, child) {
            final offset = math.sin((_waveController.value * 2 * math.pi) + (index * 0.5));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              transform: Matrix4.translationValues(0, offset * 4, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isBot = message.isBot;
    
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            margin: EdgeInsets.only(
              bottom: 4,
              left: isBot ? 0 : 60,
              right: isBot ? 60 : 0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isBot
                  ? null
                  : LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isBot
                  ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white)
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isBot ? 4 : 20),
                bottomRight: Radius.circular(isBot ? 20 : 4),
              ),
              boxShadow: [
                BoxShadow(
                  color: isBot
                      ? Colors.black.withOpacity(0.05)
                      : Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isBot)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ],
                          ).createShader(bounds),
                          child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Assistant',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  message.text,
                  style: TextStyle(
                    color: isBot
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Timestamp
          Padding(
            padding: EdgeInsets.only(
              bottom: 12,
              left: isBot ? 8 : 0,
              right: isBot ? 0 : 8,
            ),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            ),
          ),
          // Property Cards
          if (message.properties != null && message.properties!.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.properties!.length,
                itemBuilder: (context, index) {
                  return _buildPropertyCard(message.properties![index], isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPropertyCard(Property property, bool isDark) {
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
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    property.imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.3),
                            Theme.of(context).primaryColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: const Icon(Icons.home, size: 40, color: Colors.white),
                    ),
                  ),
                ),
                // Price tag
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.formattedPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPropertyStat(Icons.bed, '${property.bedrooms}', isDark),
                      const SizedBox(width: 12),
                      _buildPropertyStat(Icons.bathtub, '${property.bathrooms}', isDark),
                      const SizedBox(width: 12),
                      _buildPropertyStat(Icons.square_foot, '${property.sqft}', isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyStat(IconData icon, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Theme.of(context).primaryColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceListeningOverlay(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.15),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Animated mic icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withOpacity(0.1 + (_pulseController.value * 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3 * _pulseController.value),
                      blurRadius: 12,
                      spreadRadius: 4 * _pulseController.value,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.red, size: 24),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listening...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _controller.text.isEmpty
                      ? 'Speak now to search properties'
                      : _controller.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _stopListening,
            icon: const Icon(Icons.stop_circle, color: Colors.red),
            label: const Text('Stop', style: TextStyle(color: Colors.red)),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Voice Button
          GestureDetector(
            onTap: _isListening ? _stopListening : _startListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isListening
                      ? [Colors.red, Colors.red.shade700]
                      : [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? Colors.red.withOpacity(0.4)
                        : Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text Input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Ask about properties...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                enabled: !_isLoading,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Send Button
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey, Colors.grey.shade600]
                      : [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                ),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final List<Property>? properties;
  final DateTime? timestamp;

  ChatMessage({
    required this.text,
    required this.isBot,
    this.properties,
    this.timestamp,
  });
}
