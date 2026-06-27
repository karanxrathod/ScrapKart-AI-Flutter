import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final ScrollController _scrollController = ScrollController();

  final String _backendUrl = 'http://10.213.229.69:3000/api/chat';

  // Core Neumorphic/Soft-UI Design Palette constraints
  final Color _baseColor = const Color(0xFFE0E5EC);
  final Color _accentColor = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    // Default system introduction gracefully initializing state
    _messages.add(ChatMessage(
      text: "Hi! I'm the ScrapKart AI. How can I help you with recycling today?", 
      isUser: false
    ));
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add(ChatMessage(text: data['reply'], isUser: false));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(text: 'Apologies, I encountered a backend processing error.', isUser: false));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'I cannot reach the network right now. Please test your data.', isUser: false));
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _baseColor,
      appBar: AppBar(
        title: const Text('ScrapKart Support AI', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: _baseColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                       const SizedBox(
                         width: 15, height: 15,
                         child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)
                       ),
                       const SizedBox(width: 10),
                       Text('AI is typing...', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8, 
          bottom: 8, 
          // Adjust message bounding avoiding long lines stretching full width
          left: message.isUser ? 60 : 0, 
          right: message.isUser ? 0 : 60
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: message.isUser ? _accentColor.withValues(alpha: 0.1) : _baseColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(0),
            bottomRight: message.isUser ? const Radius.circular(0) : const Radius.circular(20),
          ),
          // Deep Neumorphic popping exclusively pushing AI replies off-card
          boxShadow: [
            if (!message.isUser)
             const BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
            if (!message.isUser)
             BoxShadow(color: Colors.grey.withValues(alpha: 0.4), offset: const Offset(5, 5), blurRadius: 10),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 16,
            color: message.isUser ? Colors.black87 : Colors.black54,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 5),
      decoration: BoxDecoration(
        color: _baseColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          // Render inputs distinctly indented utilizing reverse-shadow logic
          const BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 8),
          BoxShadow(color: Colors.grey.withValues(alpha: 0.5), offset: const Offset(3, 3), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Type a natural message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          GestureDetector(
             onTap: _sendMessage,
             child: Container(
              margin: const EdgeInsets.all(6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(2, 2)),
                ]
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
