import 'package:flutter/material.dart';
import 'package:frontend/common/app_route.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:frontend/data/models/chat_message.dart'; 
import 'package:frontend/data/models/attachment_file.dart';
import 'package:frontend/data/models/discussion.dart';
import 'package:frontend/common/enums.dart'; 

// Time formatter 
class TimeFormatter {
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 30) {
      return 'baru saja';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} detik lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      final weeksDiff = (difference.inDays / 7).floor();
      return '$weeksDiff minggu lalu';
    }
  }

  static String formatTimeDetailed(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Data Service untuk mengelola data chat (memakai model yang sudah dipindahkan)
class ChatDataService {
  static final ChatDataService _instance = ChatDataService._internal();
  factory ChatDataService() => _instance;
  ChatDataService._internal();

  // Data dari kode original Anda, tapi sekarang menggunakan model Discussion
  final Discussion _currentDiscussion = Discussion(
    id: "disc_001",
    title: "Susah Bangun Pagi dan Merasa Tidak Semangat, Ada yang Punya Tips?",
    content: "Akhir-akhir ini sering ngalamin lesu pagi-pagi, padahal udah tidur awal tapi tetep aja susah bangun. Kadang sampe alarm udah bunyi berkali-kali baru bisa bangun, terus pas bangun badan tu lemes dan ga semangat buat mulai hari. Ada yang punya pengalaman serupa? Gimana cara ngatasinnya ya? Mungkin ada tips?",
    authorName: "Saya",
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  // Menggunakan model ChatMessage yang sudah dimodifikasi (figma)
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: "msg_001",
      chatSessionId: "session_001",
      senderType: "ai_bot", 
      messageContent: "Aku banget ini! Kadang sampe telat kerja karena susah bangun. Coba deh sleep hygiene-nya diperbaiki dulu, kayak matiin gadget 1 jam sebelum tidur. Terus juga coba atur jadwal tidur yang konsisten setiap hari.",
      senderId: "user_001",
      senderName: "Sarah",
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      isOwner: false,
    ),
    ChatMessage(
      id: "msg_002",
      chatSessionId: "session_001",
      senderType: "user",
      messageContent: "Setuju sama yang di atas! Plus coba rutin olahraga ringan sore hari, ngaruh banget ke kualitas tidur. Terus jangan lupa sarapan yang bergizi. Aku dulu juga gitu, tapi setelah rutin olahraga dan makan teratur, sekarang udah lebih gampang bangun pagi.",
      senderId: "user_002",
      senderName: "Ahmad",
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isOwner: false,
    ),
    ChatMessage(
      id: "msg_003",
      chatSessionId: "session_001",
      senderType: "user",
      messageContent: "Aku pake teknik 5 detik rule pas alarm bunyi langsung berdiri. Awalnya susah tapi lama-lama jadi kebiasaan. Sama lamp yang simulasi sunrise juga membantu! Oh iya, coba juga taruh alarm jauh dari tempat tidur biar terpaksa bangun.",
      senderId: "user_003",
      senderName: "Dina",
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isOwner: false,
    ),
    ChatMessage(
      id: "msg_004",
      chatSessionId: "session_001",
      senderType: "user",
      messageContent: "Wah makasih semuanya! Aku coba deh step by step. Semoga bisa konsisten ngjalanin tipsnya 🙏 Bakal aku update lagi nanti gimana hasilnya.",
      senderId: "user_main",
      senderName: "Saya",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isOwner: true,
    ),
  ];

  Discussion get currentDiscussion => _currentDiscussion;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  String generateMessageId() {
    return "msg_${DateTime.now().millisecondsSinceEpoch}";
  }
}

class ForumDiscussionPostScreen extends StatefulWidget {
  const ForumDiscussionPostScreen({super.key});

  @override
  State<ForumDiscussionPostScreen> createState() => _ForumDiscussionPostScreenState();
}

class _ForumDiscussionPostScreenState extends State<ForumDiscussionPostScreen> {
  // Controllers - tetap sama seperti original
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Data service - sistem baru untuk data management
  final ChatDataService _dataService = ChatDataService();

  // State variables
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  String _currentMessage = '';
  List<ChatMessage> _messages = [];
  final List<AttachmentFile> _pendingAttachments = [];

  // File picker instances
  final ImagePicker _imagePicker = ImagePicker();

  // Emoji list dari kode original Anda
  final List<String> _emojiList = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩',
    '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣',
    '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬',
    '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗',
    '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯',
    '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐',
    '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '👍',
    '👎', '👌', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _messageController.addListener(() {
      setState(() {
        _currentMessage = _messageController.text;
        _isTyping = _currentMessage.isNotEmpty;
      });
    });
  }

  void _initializeData() {
    setState(() {
      _messages = _dataService.messages;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: _buildMainContent(context, screenWidth, screenHeight),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double screenWidth, double screenHeight) {
    return Stack(
      children: [
        // Background blur
        _buildBlurBackground(),

        // Scroll content area
        _buildScrollableContent(context),

        // Bottom message input
        _buildBottomMessageArea(),

        // Simple emoji picker
        if (_showEmojiPicker) _buildSimpleEmojiPicker(),

        // Arrow button
        _buildArrowButton(context),

        // Loading overlay untuk file upload
        if (_pendingAttachments.isNotEmpty) _buildUploadingIndicator(),
      ],
    );
  }

  Widget _buildBlurBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/blur_background.png',
        width: 430,
        height: 931,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildScrollableContent(BuildContext context) {
    return Positioned(
      top: 111,
      left: 41,
      right: 41,
      bottom: _showEmojiPicker ? 250 : 74,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            _buildMainDiscussionCard(),
            const SizedBox(height: 10),
            ..._buildDiscussionMessages(),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildMainDiscussionCard() {
    final discussion = _dataService.currentDiscussion;

    return Container(
      width: 348,
      decoration: const BoxDecoration( 
        image: DecorationImage(
          image: AssetImage('assets/images/kotak_hijau_tosca.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 19),

          // Title 
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 16),
            child: _buildTitleSection(discussion.title),
          ),

          const SizedBox(height: 29),

          // Question 
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 16),
            child: _buildQuestionSection(discussion.content),
          ),

          const SizedBox(height: 8),

          // Timestamp 
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 16, bottom: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'oleh ${discussion.authorName}',
                  style: GoogleFonts.fredoka(
                    fontSize: 9,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF001F3F).withOpacity(0.6),
                  ),
                ),
                Text(
                  TimeFormatter.formatTime(discussion.createdAt),
                  style: GoogleFonts.fredoka(
                    fontSize: 9,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF001F3F).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(String title) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration( 
        image: DecorationImage(
          image: AssetImage('assets/images/title_box.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF001F3F),
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildQuestionSection(String content) {
    return Container(
      width: 317,
      decoration: const BoxDecoration( 
        image: DecorationImage(
          image: AssetImage('assets/images/question_box.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              left: 10,
              right: 40,
              top: 10,
              bottom: 10,
            ),
            child: Text(
              content,
              style: GoogleFonts.fredoka(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF001F3F),
              ),
              textAlign: TextAlign.left,
            ),
          ),

          // Ellips
          Positioned(
            right: 14,
            bottom: 6,
            child: Image.asset(
              'assets/images/ellips.png',
              width: 22,
              height: 6,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDiscussionMessages() {
    return _messages.asMap().entries.map((entry) {
      final index = entry.key;
      final message = entry.value;

      return Container(
        margin: EdgeInsets.only(
          bottom: index == _messages.length - 1 ? 0 : 20,
        ),
        child: Column(
          crossAxisAlignment: message.isOwner
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender name dan timestamp
            if (!message.isOwner || _shouldShowSenderInfo(index))
              Padding(
                padding: EdgeInsets.only(
                  left: message.isOwner ? 50 : 0,
                  right: message.isOwner ? 0 : 50,
                  bottom: 4,
                ),
                child: Row(
                  mainAxisAlignment: message.isOwner
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    if (!message.isOwner) ...[
                      Text(
                        message.senderName,
                        style: GoogleFonts.fredoka(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF001F3F).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      TimeFormatter.formatTime(message.timestamp),
                      style: GoogleFonts.fredoka(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF001F3F).withOpacity(0.5),
                      ),
                    ),
                    if (message.isOwner) ...[
                      const SizedBox(width: 8),
                      Text(
                        message.senderName,
                        style: GoogleFonts.fredoka(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF001F3F).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Message bubble
            _buildDiscussionMessage(message),

            // Attachments
            if (message.attachments.isNotEmpty)
              _buildAttachmentsDisplay(message.attachments, message.isOwner),
          ],
        ),
      );
    }).toList();
  }

  bool _shouldShowSenderInfo(int index) {
    if (index == 0) return true;

    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];

    return currentMessage.senderId != previousMessage.senderId ||
        currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes > 5;
  }

  Widget _buildDiscussionMessage(ChatMessage message) {
    return Align(
      alignment: message.isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints( 
          maxWidth: 250,
          minWidth: 100,
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              message.isOwner
                  ? 'assets/images/yellow_discussion_box.png'
                  : 'assets/images/green_discussion_box.png',
            ),
            fit: BoxFit.fill,
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Text(
          message.messageContent, 
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF001F3F),
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }

  Widget _buildAttachmentsDisplay(List<AttachmentFile> attachments, bool isOwner) {
    return Align(
      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: attachments.map((attachment) => _buildAttachmentItem(attachment)).toList(),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(AttachmentFile attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF001F3F).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            attachment.type == AttachmentType.image
                ? Icons.image
                : Icons.attach_file,
            size: 16,
            color: const Color(0xFF001F3F).withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              attachment.name,
              style: GoogleFonts.fredoka(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF001F3F).withOpacity(0.8),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (attachment.size != null) ...[
            const SizedBox(width: 4),
            Text(
              _formatFileSize(attachment.size!),
              style: GoogleFonts.fredoka(
                fontSize: 8,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF001F3F).withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomMessageArea() {
    double dynamicHeight = _calculateMessageBoxHeight();

    return Positioned(
      bottom: 16,
      left: 10,
      right: 10,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(_messageFocusNode);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              width: 417,
              height: dynamicHeight,
              child: Image.asset(
                'assets/images/message_box.png',
                width: 300,
                height: dynamicHeight,
                fit: BoxFit.fill,
              ),
            ),

            // Pending attachments preview
            if (_pendingAttachments.isNotEmpty)
              Positioned(
                left: 140,
                right: 70,
                bottom: dynamicHeight - 25,
                child: _buildPendingAttachmentsPreview(),
              ),

            // Text inputan
            if (_isTyping || _messageFocusNode.hasFocus)
              Positioned(
                left: 140, 
                right: 70, 
                bottom: 10,
                top: _pendingAttachments.isNotEmpty ? 35 : 0,
                child: TextField( 
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF001F3F),
                  ),
                  textAlign: TextAlign.left,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Ketik pesan...',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

            // happy_emoji.png
            Positioned(
              left: 14,
              bottom: 8,
              child: GestureDetector(
                onTap: _toggleEmojiPicker,
                child: Image.asset(
                  'assets/images/happy_emoji.png',
                  width: 34,
                  height: 34,
                ),
              ),
            ),

            // paper_clip.png
            Positioned(
              left: 87,
              bottom: 9,
              child: GestureDetector(
                onTap: _showAttachmentDialog,
                child: Image.asset( 
                  'assets/images/paper_clip.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),

            // polygon_button.png (send button)
            Positioned(
              right: 24,
              bottom: 8,
              child: GestureDetector(
                onTap: _sendMessage,
                child: Image.asset( 
                  'assets/images/polygon_button.png',
                  width: 34,
                  height: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingAttachmentsPreview() {
    return SizedBox( 
      height: 30,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        itemBuilder: (context, index) {
          final attachment = _pendingAttachments[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  attachment.type == AttachmentType.image
                      ? Icons.image
                      : Icons.attach_file,
                  size: 12,
                  color: const Color(0xFF4CAF50),
                ),
                const SizedBox(width: 4),
                Text(
                  attachment.name.length > 10
                      ? '${attachment.name.substring(0, 10)}...'
                      : attachment.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF001F3F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removePendingAttachment(index),
                  child: Icon(
                    Icons.close,
                    size: 12,
                    color: const Color(0xFF001F3F).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculateMessageBoxHeight() {
    double baseHeight = 50;

    if (!_isTyping && !_messageFocusNode.hasFocus && _pendingAttachments.isEmpty) {
      return baseHeight;
    }

    double attachmentHeight = _pendingAttachments.isNotEmpty ? 35 : 0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: _currentMessage.isEmpty ? 'Ketik pesan...' : _currentMessage,
        style: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    double availableWidth = 417 - 140 - 70; 
    if (availableWidth <= 0) availableWidth = 100; 

    textPainter.layout(maxWidth: availableWidth);

    double textHeight = textPainter.height;
    if (_currentMessage.isNotEmpty) {
      textHeight += 20; 
    }

    double calculatedHeight = baseHeight + attachmentHeight + textHeight;

    return calculatedHeight.clamp(50, 200);
  }


  Widget _buildSimpleEmojiPicker() {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Container(
        height: 180,
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Emoji',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF001F3F),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showEmojiPicker = false),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  childAspectRatio: 1,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: _emojiList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _messageController.text += _emojiList[index];
                      setState(() => _showEmojiPicker = false);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[100],
                      ),
                      child: Center(
                        child: Text(
                          _emojiList[index],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton(BuildContext context) {
    return Positioned(
      top: 16,
      left: 8,
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacementNamed(context, AppRoute.dashboard); 
        },
        child: Image.asset(
          'assets/images/arrow.png',
          width: 66,
          height: 66,
        ),
      ),
    );
  }

  Widget _buildUploadingIndicator() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mengunggah file...',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF001F3F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HELPER METHODS

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _messageFocusNode.unfocus();
      }
    });
  }

  void _sendMessage() async {
    if (_currentMessage.trim().isEmpty && _pendingAttachments.isEmpty) return;

    final messageText = _currentMessage.trim();

    // message baru dengan attachments
    final newMessage = ChatMessage(
      id: _dataService.generateMessageId(),
      chatSessionId: _dataService.currentDiscussion.id, 
      senderType: "user", 
      messageContent: messageText,
      senderId: "user_main", 
      senderName: "Saya", 
      timestamp: DateTime.now(),
      isOwner: true,
      attachments: List.from(_pendingAttachments),
    );

    setState(() {
      _dataService.addMessage(newMessage);
      _messages = _dataService.messages;
      _messageController.clear();
      _currentMessage = '';
      _isTyping = false;
      _showEmojiPicker = false;
      _pendingAttachments.clear();
    });

    _messageFocusNode.unfocus();
    _scrollToBottom();
  }

  // ATTACHMENT HANDLING

  void _showAttachmentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Pilih Attachment',
            style: GoogleFonts.fredoka(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF001F3F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF001F3F),
                  ),
                ),
                subtitle: Text(
                  'Ambil foto langsung',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF001F3F).withOpacity(0.7),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),

              // Gallery option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF2196F3),
                  ),
                ),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF001F3F),
                  ),
                ),
                subtitle: Text(
                  'Pilih dari galeri',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF001F3F).withOpacity(0.7),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),

              // File option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.attach_file,
                    color: Color(0xFFFF9800),
                  ),
                ),
                title: Text(
                  'File',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF001F3F),
                  ),
                ),
                subtitle: Text(
                  'Dokumen dan file lainnya',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF001F3F).withOpacity(0.7),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF001F3F).withOpacity(0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        await _processSelectedFile(image.path, AttachmentType.image);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal mengambil foto: $e');
    }
  }

  // Image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        await _processSelectedFile(image.path, AttachmentType.image);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memilih gambar: $e');
    }
  }

  // File picker
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        AttachmentType type = AttachmentType.document;

        // file type
        if (file.extension != null) {
          final ext = file.extension!.toLowerCase();
          if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext)) {
            type = AttachmentType.image;
          }
        }

        await _processSelectedFile(file.path!, type, fileSize: file.size);
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memilih file: $e');
    }
  }

  Future<void> _processSelectedFile(String filePath, AttachmentType type, {int? fileSize}) async {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final size = fileSize ?? await file.length();

    // Check batas size filenya (max 10MB)
    if (size > 10 * 1024 * 1024) {
      _showErrorSnackbar('File terlalu besar. Maksimal 10MB.');
      return;
    }

    final attachment = AttachmentFile(
      name: fileName,
      path: filePath,
      type: type,
      size: size,
    );

    setState(() {
      _pendingAttachments.add(attachment);
      _isTyping = true;
    });

    // kalo success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'File berhasil ditambahkan: $fileName',
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _removePendingAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
      if (_pendingAttachments.isEmpty && _currentMessage.isEmpty) {
        _isTyping = false;
      }
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.fredoka(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE57373),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

// Extension untuk responsive design
extension ScreenUtils on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  double scaleWidth(double figmaWidth) {
    return (screenWidth / 430.25) * figmaWidth;
  }

  double scaleHeight(double figmaHeight) {
    return (screenHeight / 932) * figmaHeight;
  }
}