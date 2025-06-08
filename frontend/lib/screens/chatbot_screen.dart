import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

// Import dari common
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/common/enums.dart';
import 'package:frontend/common/time_formatter.dart'; // Import TimeFormatter

// Import dari models
import 'package:frontend/data/models/chat_message.dart';
import 'package:frontend/data/models/attachment_file.dart';
import 'package:frontend/data/models/discussion.dart'; // Import Discussion dari models

// Data Service yang akan direfactor ke Cubit/Bloc di masa depan
class ChatDataService {
  static final ChatDataService _instance = ChatDataService._internal();
  factory ChatDataService() => _instance;
  ChatDataService._internal();

  final Map<String, List<ChatMessage>> _allMessages = {};
  final List<Discussion> _allDiscussions = [];

  String _currentChatSessionId = "";
  Discussion? _currentChatDiscussion;

  List<Discussion> get allDiscussions => List.unmodifiable(_allDiscussions);
  List<ChatMessage> get currentMessages {
    if (_currentChatSessionId.isEmpty || !_allMessages.containsKey(_currentChatSessionId)) {
      return [];
    }
    return List.unmodifiable(_allMessages[_currentChatSessionId]!);
  }
  Discussion? get currentDiscussion => _currentChatDiscussion;

  void initialize() {
    if (_allMessages.isEmpty) {
      _startNewChatSession();
      addMessage(
        ChatMessage(
          id: "bot_msg_001",
          chatSessionId: _currentChatSessionId,
          senderType: "ai_bot",
          messageContent: "Hai! 👋 Ada yang bisa saya bantu hari ini?",
          senderId: "ai_bot_001",
          senderName: "Tenang.in Bot",
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isOwner: false,
        ),
      );
      addMessage(
        ChatMessage(
          id: "user_msg_001",
          chatSessionId: _currentChatSessionId,
          senderType: "user",
          messageContent: "Lagi kerasa agak overthinking nih... 🤔",
          senderId: "user_main",
          senderName: "Saya",
          timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
          isOwner: true,
        ),
      );
      addMessage(
        ChatMessage(
          id: "bot_msg_002",
          chatSessionId: _currentChatSessionId,
          senderType: "ai_bot",
          messageContent: "Hmm, wajar kok kalau merasa terbebani dan punya pekerjaan. Tapi coba kita lihat dari sisi lain yuk! 😊 Bayangkan perasaan lega ketika semua tugas itu selesai. ✨ Kita bisa coba pecah jadi bagian-bagian kecil. Kekuatan apa yang kamu cari? 💪 Atau mungkin ada hal lain yang bisa bantu kamu merasa lebih tenang? Misalnya, mendengarkan musik yang rileks? 🎶",
          senderId: "ai_bot_001",
          senderName: "Tenang.in Bot",
          timestamp: DateTime.parse('2025-06-06T10:06:00Z'),
          isOwner: false,
        ),
      );

      _allDiscussions.add(Discussion(
        id: "chatbot_session_001",
        title: "Overthinking Session",
        content: "Diskusi tentang overthinking.",
        authorName: "User",
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ));
      _allDiscussions.add(Discussion(
        id: "chatbot_session_002",
        title: "Wound Healing",
        content: "Diskusi tentang penyembuhan luka batin.",
        authorName: "User",
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ));
      _allDiscussions.add(Discussion(
        id: "chatbot_session_003",
        title: "Feeling Lonely",
        content: "Diskusi tentang rasa kesepian.",
        authorName: "User",
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ));
    }
  }

  void addMessage(ChatMessage message) {
    if (!_allMessages.containsKey(message.chatSessionId)) {
      _allMessages[message.chatSessionId] = [];
    }
    _allMessages[message.chatSessionId]!.add(message);
    
    final discussionIndex = _allDiscussions.indexWhere(
      (disc) => disc.id == message.chatSessionId,
    );

    if (discussionIndex != -1) {
      if (message.messageContent.isNotEmpty) {
        _allDiscussions[discussionIndex] = _allDiscussions[discussionIndex].copyWith(
          content: message.messageContent,
        );
        _currentChatDiscussion = _allDiscussions[discussionIndex];
      }
    } else {
      final newDisc = Discussion(
        id: message.chatSessionId,
        title: message.messageContent.isNotEmpty ? message.messageContent : "New Chat Session",
        content: message.messageContent,
        authorName: message.senderName,
        createdAt: message.timestamp,
      );
      _allDiscussions.add(newDisc);
      _currentChatDiscussion = newDisc;
    }
  }

  void _startNewChatSession() {
    _currentChatSessionId = "chatbot_session_${DateTime.now().millisecondsSinceEpoch}";
    _allMessages[_currentChatSessionId] = [];
    _currentChatDiscussion = Discussion(
      id: _currentChatSessionId,
      title: "New Chat Session",
      content: "Mulai percakapan baru.",
      authorName: "User",
      createdAt: DateTime.now(),
    );
    _allDiscussions.insert(0, _currentChatDiscussion!);
  }

  void loadChatSession(String sessionId) {
    if (_allMessages.containsKey(sessionId)) {
      _currentChatSessionId = sessionId;
      _currentChatDiscussion = _allDiscussions.firstWhere((disc) => disc.id == sessionId);
    } else {
      _startNewChatSession();
    }
  }

  void startNewChat() {
    _startNewChatSession();
    addMessage(
      ChatMessage(
        id: "bot_msg_${DateTime.now().millisecondsSinceEpoch}",
        chatSessionId: _currentChatSessionId,
        senderType: "ai_bot",
        messageContent: "Halo! 👋 Ada yang bisa saya bantu untuk memulai percakapan baru?",
        senderId: "ai_bot_001",
        senderName: "Tenang.in Bot",
        timestamp: DateTime.now(),
        isOwner: false,
      ),
    );
  }

  String generateMessageId() {
    return "msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";
  }

  void updateDiscussionTitle(String sessionId, String newTitle) {
    final index = _allDiscussions.indexWhere((disc) => disc.id == sessionId);
    if (index != -1) {
      _allDiscussions[index] = _allDiscussions[index].copyWith(title: newTitle);
      if (_currentChatDiscussion?.id == sessionId) {
        _currentChatDiscussion = _allDiscussions[index];
      }
    }
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final ChatDataService _dataService = ChatDataService();

  bool _isTyping = false;
  bool _showEmojiPicker = false;
  String _currentMessage = '';
  List<ChatMessage> _messages = [];
  final List<AttachmentFile> _pendingAttachments = [];

  final ImagePicker _imagePicker = ImagePicker();

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
    _dataService.initialize();
    _initializeData();
    _messageController.addListener(() {
      setState(() {
        _currentMessage = _messageController.text;
        _isTyping = _currentMessage.isNotEmpty || _pendingAttachments.isNotEmpty;
      });
    });
    _messageFocusNode.addListener(() {
      setState(() {});
    });
  }

  void _initializeData() {
    setState(() {
      _messages = _dataService.currentMessages;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.removeListener(() {});
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColor.putihNormal,
      resizeToAvoidBottomInset: true,
      endDrawer: _buildHistoryDrawer(context),
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          child: Stack(
            children: [
              _buildBackground(),
              _buildHeader(context),
              _buildChatMessagesArea(context),
              _buildBottomSection(context),
              if (_showEmojiPicker) _buildSimpleEmojiPicker(context),
              if (_pendingAttachments.isNotEmpty && !_showEmojiPicker) _buildUploadingIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/wave_history_voice.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Stack(
        children: [
          Image.asset(
            'assets/images/blur_top_history.png',
            width: context.screenWidth,
            height: context.scaleHeight(88),
            fit: BoxFit.fill,
          ),
          Positioned(
            top: context.scaleHeight(16),
            left: context.scaleWidth(8),
            right: context.scaleWidth(8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: context.scaleWidth(66),
                    height: context.scaleHeight(66),
                  ),
                ),
                SizedBox(width: context.scaleWidth(10)),
                Expanded(
                  child: Text(
                    _dataService.currentDiscussion?.title ?? 'Chatbot',
                    style: GoogleFonts.fredoka(
                      fontSize: 24,
                      color: AppColor.navyText,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: context.scaleWidth(10)),
                GestureDetector(
                  onTap: () {
                    _scaffoldKey.currentState?.openEndDrawer();
                  },
                  child: Image.asset(
                    'assets/images/history_button.png',
                    width: context.scaleWidth(34),
                    height: context.scaleHeight(34),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessagesArea(BuildContext context) {
    return Positioned(
      top: context.scaleHeight(88),
      left: 0,
      right: 0,
      bottom: context.scaleHeight(80),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(15), vertical: context.scaleHeight(10)),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return _buildChatMessageBubbleItem(message, context); // Pass context
        },
      ),
    );
  }

  Widget _buildBottomSection(BuildContext currentContext) {
    return Positioned(
      bottom: currentContext.scaleHeight(25), // Mengatur bottom agar tepat di atas keyboard
      left: 0,
      right: 0,
      child: Column(
        children: [
          _buildBottomMessageArea(currentContext),
          // Emoji picker dan indicator upload sekarang di handle di root Stack
          // if (_showEmojiPicker) _buildSimpleEmojiPicker(currentContext),
        ],
      ),
    );
  }

  Widget _buildUploadingIndicator(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(context.scaleWidth(20)),
            decoration: BoxDecoration(
              color: AppColor.putihNormal,
              borderRadius: BorderRadius.circular(context.scaleWidth(12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijauTosca),
                ),
                SizedBox(height: context.scaleHeight(12)),
                Text(
                  'Mengunggah file...',
                  style: GoogleFonts.fredoka(
                    fontSize: context.scaleWidth(14),
                    fontWeight: FontWeight.w500,
                    color: AppColor.navyText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomMessageArea(BuildContext areaContext) {
    double dynamicHeight = _calculateMessageBoxHeight(areaContext);

    return Container(
      height: dynamicHeight,
      margin: EdgeInsets.symmetric(horizontal: areaContext.scaleWidth(15)),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: areaContext.scaleWidth(417),
            height: dynamicHeight,
            child: Image.asset(
              'assets/images/message_box.png',
              fit: BoxFit.fill,
            ),
          ),
          if (_pendingAttachments.isNotEmpty)
            Positioned(
              left: areaContext.scaleWidth(60),
              right: areaContext.scaleWidth(60),
              bottom: dynamicHeight - areaContext.scaleHeight(40),
              child: _buildPendingAttachmentsPreview(areaContext),
            ),
          Positioned(
            left: areaContext.scaleWidth(100),
            right: areaContext.scaleWidth(60),
            bottom: areaContext.scaleHeight(10),
            top: _pendingAttachments.isNotEmpty
                ? areaContext.scaleHeight(20)
                : areaContext.scaleHeight(10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(areaContext.scaleWidth(20)),
                border: Border.all(
                  color: _messageFocusNode.hasFocus
                      ? Colors.grey.withOpacity(0.4)
                      : Colors.transparent,
                  width: _messageFocusNode.hasFocus ? 1.5 : 0,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: GoogleFonts.fredoka(
                  fontSize: areaContext.scaleWidth(12),
                  fontWeight: FontWeight.w400,
                  color: AppColor.navyText,
                ),
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ketik pesan...',
                  hintStyle: GoogleFonts.fredoka(
                    fontSize: areaContext.scaleWidth(12),
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText.withOpacity(0.6),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: areaContext.scaleHeight(5),
                    horizontal: areaContext.scaleWidth(10),
                  ),
                  isDense: true,
                ),
                cursorColor: AppColor.navyText,
              ),
            ),
          ),
          Positioned(
            left: areaContext.scaleWidth(14),
            bottom: areaContext.scaleHeight(8),
            child: GestureDetector(
              onTap: () => _toggleEmojiPicker(areaContext),
              child: Image.asset(
                'assets/images/happy_emoji.png',
                width: areaContext.scaleWidth(34),
                height: areaContext.scaleHeight(34),
              ),
            ),
          ),
          Positioned(
            left: areaContext.scaleWidth(60),
            bottom: areaContext.scaleHeight(9),
            child: GestureDetector(
              onTap: () => _showAttachmentDialog(areaContext),
              child: Image.asset(
                'assets/images/paper_clip.png',
                width: areaContext.scaleWidth(30),
                height: areaContext.scaleHeight(30),
              ),
            ),
          ),
          Positioned(
            right: areaContext.scaleWidth(24),
            bottom: areaContext.scaleHeight(8),
            child: GestureDetector(
              onTap: _sendMessage,
              child: Image.asset(
                'assets/images/polygon_button.png',
                width: areaContext.scaleWidth(34),
                height: areaContext.scaleHeight(32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAttachmentsPreview(BuildContext previewContext) {
    return SizedBox(
      height: previewContext.scaleHeight(30),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        itemBuilder: (context, index) {
          final attachment = _pendingAttachments[index];
          return Container(
            margin: EdgeInsets.only(right: previewContext.scaleWidth(8)),
            padding: EdgeInsets.symmetric(horizontal: previewContext.scaleWidth(8), vertical: previewContext.scaleHeight(4)),
            decoration: BoxDecoration(
              color: AppColor.hijauTosca.withOpacity(0.1),
              borderRadius: BorderRadius.circular(previewContext.scaleWidth(15)),
              border: Border.all(
                color: AppColor.hijauTosca.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  attachment.type == AttachmentType.image ? Icons.image : Icons.attach_file,
                  size: previewContext.scaleWidth(12),
                  color: AppColor.hijauTosca,
                ),
                SizedBox(width: previewContext.scaleWidth(4)),
                Text(
                  attachment.name.length > 10 ? '${attachment.name.substring(0, 10)}...' : attachment.name,
                  style: GoogleFonts.fredoka(
                    fontSize: previewContext.scaleWidth(9),
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: previewContext.scaleWidth(4)),
                GestureDetector(
                  onTap: () => _removePendingAttachment(index),
                  child: Icon(
                    Icons.close,
                    size: previewContext.scaleWidth(12),
                    color: AppColor.navyText.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  double _calculateMessageBoxHeight(BuildContext calcContext) {
    double baseImageHeight = calcContext.scaleHeight(50);

    final textPainter = TextPainter(
      text: TextSpan(
        text: _currentMessage.isEmpty ? 'Ketik pesan...' : _currentMessage,
        style: GoogleFonts.fredoka(
          fontSize: calcContext.scaleWidth(12), // Use scaled font size
          fontWeight: FontWeight.w400,
        ),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    double availableWidthForText = calcContext.scaleWidth(417 - 100 - 60 - 20); // (full image width - left offset - right offset - internal padding)
    if (availableWidthForText <= 0) availableWidthForText = calcContext.scaleWidth(100);

    textPainter.layout(maxWidth: availableWidthForText);

    double textContentHeight = textPainter.height;

    final double minTextHeight = calcContext.scaleHeight(16);
    textContentHeight = max(minTextHeight, textContentHeight);

    double textFieldPaddingTop = _pendingAttachments.isNotEmpty ? calcContext.scaleHeight(35) : calcContext.scaleHeight(10);
    double textFieldPaddingBottom = calcContext.scaleHeight(10);
    double requiredContentHeight = textContentHeight + textFieldPaddingTop + textFieldPaddingBottom;

    double maxMessageBoxHeight = calcContext.scaleHeight(200);

    return max(baseImageHeight, requiredContentHeight).clamp(baseImageHeight, maxMessageBoxHeight);
  }

  Widget _buildSimpleEmojiPicker(BuildContext emojiContext) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: emojiContext.scaleHeight(180),
        color: AppColor.putihNormal,
        padding: EdgeInsets.all(emojiContext.scaleWidth(16)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pilih Emoji',
                  style: GoogleFonts.fredoka(
                    fontSize: emojiContext.scaleWidth(16),
                    fontWeight: FontWeight.w600,
                    color: AppColor.navyText,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showEmojiPicker = false),
                  child: Icon(Icons.close, size: emojiContext.scaleWidth(24)),
                ),
              ],
            ),
            SizedBox(height: emojiContext.scaleHeight(8)),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  childAspectRatio: 1,
                  crossAxisSpacing: emojiContext.scaleWidth(2),
                  mainAxisSpacing: emojiContext.scaleHeight(2),
                ),
                itemCount: _emojiList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _messageController.text += _emojiList[index];
                      setState(() => _showEmojiPicker = false);
                      _messageFocusNode.requestFocus();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(emojiContext.scaleWidth(4)),
                        color: Colors.grey[100],
                      ),
                      child: Center(
                        child: Text(
                          _emojiList[index],
                          style: TextStyle(fontSize: emojiContext.scaleHeight(20)),
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

  void _toggleEmojiPicker(BuildContext toggleContext) {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _messageFocusNode.unfocus();
      } else {
        _messageFocusNode.requestFocus();
      }
    });
  }

  void _showAttachmentDialog(BuildContext dialogContext) {
    _messageFocusNode.unfocus();

    showDialog(
      context: dialogContext,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogContext.scaleWidth(16)),
          ),
          title: Text(
            'Pilih Attachment',
            style: GoogleFonts.fredoka(
              fontSize: dialogContext.scaleWidth(18),
              fontWeight: FontWeight.w600,
              color: AppColor.navyText,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(dialogContext.scaleWidth(8)),
                  decoration: BoxDecoration(
                    color: AppColor.hijauTosca.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(dialogContext.scaleWidth(8)),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColor.hijauTosca,
                    size: dialogContext.scaleWidth(24),
                  ),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.fredoka(
                    fontSize: dialogContext.scaleWidth(16),
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                ),
                subtitle: Text(
                  'Ambil foto langsung',
                  style: GoogleFonts.fredoka(
                    fontSize: dialogContext.scaleWidth(12),
                    fontWeight: FontWeight.w300,
                    color: AppColor.navyText.withOpacity(0.7),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(dialogContext.scaleWidth(8)),
                  decoration: BoxDecoration(
                    color: AppColor.biruNormal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(dialogContext.scaleWidth(8)),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: AppColor.biruNormal,
                    size: dialogContext.scaleWidth(24),
                  ),
                ),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.fredoka(
                    fontSize: dialogContext.scaleWidth(16),
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                ),
                subtitle: Text(
                  'Pilih dari galeri',
                  style: GoogleFonts.fredoka(
                    fontSize: dialogContext.scaleWidth(12),
                    fontWeight: FontWeight.w300,
                    color: AppColor.navyText.withOpacity(0.7),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(dialogContext.scaleWidth(8)),
                  decoration: BoxDecoration(
                    color: AppColor.kuning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(dialogContext.scaleWidth(8)),
                  ),
                  child: Icon(
                    Icons.attach_file,
                    color: AppColor.kuning,
                    size: dialogContext.scaleWidth(24),
                  ),
                ),
                title: Text(
                  'File',
                  style: GoogleFonts.fredoka(
                    fontSize: dialogContext.scaleWidth(16),
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                ),
                subtitle: Text(
                  'Dokumen dan file lainnya',
                  style: GoogleFonts.fredoka(
                    fontSize: dialogContext.scaleWidth(12),
                    fontWeight: FontWeight.w300,
                    color: AppColor.navyText.withOpacity(0.7),
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
              onPressed: () {
                Navigator.pop(context);
                _messageFocusNode.requestFocus();
              },
              child: Text(
                'Batal',
                style: GoogleFonts.fredoka(
                  fontSize: dialogContext.scaleWidth(14),
                  fontWeight: FontWeight.w400,
                  color: AppColor.navyText.withOpacity(0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
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
    } finally {
      _messageFocusNode.requestFocus();
    }
  }

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
    } finally {
      _messageFocusNode.requestFocus();
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        AttachmentType type = AttachmentType.document;
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
    } finally {
      _messageFocusNode.requestFocus();
    }
  }

  Future<void> _processSelectedFile(String filePath, AttachmentType type, {int? fileSize}) async {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final size = fileSize ?? await file.length();

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'File berhasil ditambahkan: $fileName',
          style: GoogleFonts.roboto(color: AppColor.putihNormal, fontSize: context.scaleWidth(12)),
        ),
        backgroundColor: AppColor.hijauTosca,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.scaleWidth(8)),
        ),
      ),
    );
  }

  void _removePendingAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
      _isTyping = _currentMessage.isNotEmpty || _pendingAttachments.isNotEmpty;
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(color: AppColor.putihNormal, fontSize: context.scaleWidth(12)),
        ),
        backgroundColor: AppColor.merahError,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.scaleWidth(8)),
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

  void _sendMessage() async {
    if (_currentMessage.trim().isEmpty && _pendingAttachments.isEmpty) {
      _showErrorSnackbar('Pesan tidak boleh kosong!');
      return;
    }

    final messageText = _currentMessage.trim();
    final currentSessionId = _dataService._currentChatSessionId;

    final firstBotMsg = _dataService.currentMessages.isNotEmpty
        ? _dataService.currentMessages.firstWhere(
            (msg) => msg.senderType == 'ai_bot',
            orElse: () => ChatMessage(
              id: 'dummy',
              chatSessionId: '',
              senderType: 'user',
              messageContent: '',
              senderId: '',
              senderName: '',
              timestamp: DateTime.now(),
              isOwner: true,
            ),
          )
        : null;
    if (_dataService.currentMessages.length == 1 &&
        firstBotMsg != null &&
        firstBotMsg.id == _dataService.currentMessages.first.id) {
      if (messageText.isNotEmpty) {
        _dataService.updateDiscussionTitle(currentSessionId, messageText);
      }
    }

    final newMessage = ChatMessage(
      id: _dataService.generateMessageId(),
      chatSessionId: currentSessionId,
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
      _messages = _dataService.currentMessages;
      _messageController.clear();
      _currentMessage = '';
      _isTyping = false;
      _showEmojiPicker = false;
      _pendingAttachments.clear();
    });

    _messageFocusNode.unfocus();
    _scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      final botReplyMessage = ChatMessage(
        id: _dataService.generateMessageId(),
        chatSessionId: currentSessionId,
        senderType: "ai_bot",
        messageContent: "Terima kasih atas pesannya! Saya sedang memproses itu. Ada hal lain yang bisa saya bantu?",
        senderId: "ai_bot_001",
        senderName: "Tenang.in Bot",
        timestamp: DateTime.now(),
        isOwner: false,
      );
      setState(() {
        _dataService.addMessage(botReplyMessage);
        _messages = _dataService.currentMessages;
      });
      _scrollToBottom();
    });
  }

  Widget _buildChatMessageBubbleItem(ChatMessage message, BuildContext itemContext) {
    final double messageMaxWidth = itemContext.screenWidth * 0.7;

    String bubbleImage;
    if (message.isOwner) {
      bubbleImage = 'assets/images/yellow_discussion_box.png';
    } else {
      bubbleImage = 'assets/images/green_discussion_box.png';
    }

    return Align(
      alignment: message.isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: itemContext.scaleHeight(8),
          bottom: itemContext.scaleHeight(8),
          left: message.isOwner ? itemContext.screenWidth * 0.15 : 0,
          right: message.isOwner ? 0 : itemContext.screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: itemContext.scaleWidth(25),
          vertical: itemContext.scaleHeight(25),
        ),
        constraints: BoxConstraints(
          maxWidth: messageMaxWidth,
          minWidth: itemContext.scaleWidth(100),
        ),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bubbleImage),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isOwner ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.messageContent,
              style: GoogleFonts.fredoka(
                fontSize: itemContext.scaleWidth(12),
                color: AppColor.navyText,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
            if (message.attachments.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: itemContext.scaleHeight(5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: message.attachments.map((attachment) {
                    return Container(
                      margin: EdgeInsets.only(right: itemContext.scaleWidth(5)),
                      child: Icon(
                        attachment.type == AttachmentType.image ? Icons.image : Icons.attach_file,
                        color: AppColor.navyText,
                        size: itemContext.scaleWidth(16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: itemContext.scaleHeight(4)),
            Text(
              '${message.senderName} - ${TimeFormatter.formatTimeDetailed(message.timestamp)}',
              style: GoogleFonts.fredoka(
                fontSize: itemContext.scaleWidth(9),
                color: AppColor.navyText.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext drawerContext) {
    return Drawer(
      width: drawerContext.screenWidth * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: Container(
        color: AppColor.putihNormal,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: drawerContext.scaleHeight(88),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/blur_top_history.png'),
                  fit: BoxFit.fill,
                ),
              ),
              padding: EdgeInsets.only(
                top: drawerContext.scaleHeight(16),
                left: drawerContext.scaleWidth(8),
                right: drawerContext.scaleWidth(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/history_button.png',
                        width: drawerContext.scaleWidth(34),
                        height: drawerContext.scaleHeight(34),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: drawerContext.scaleWidth(80)),
                      Text(
                        'History',
                        style: GoogleFonts.fredoka(
                          fontSize: drawerContext.scaleWidth(24),
                          color: AppColor.navyText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(drawerContext).pop(),
                    child: Icon(
                      Icons.close,
                      color: AppColor.navyText,
                      size: drawerContext.scaleWidth(24),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: drawerContext.scaleHeight(20)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: drawerContext.scaleWidth(16)),
                itemCount: _dataService.allDiscussions.length + 1,
                itemBuilder: (context, index) {
                  if (index < _dataService.allDiscussions.length) {
                    final discussion = _dataService.allDiscussions[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: drawerContext.scaleHeight(12)),
                      child: _buildHistoryChipItem(drawerContext, discussion),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: drawerContext.scaleHeight(10),
                        bottom: drawerContext.scaleHeight(20),
                      ),
                      child: _buildNewChatButton(drawerContext),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryChipItem(BuildContext context, Discussion discussion) {
    return GestureDetector(
      onTap: () {
        print('History chip tapped: ${discussion.title} (ID: ${discussion.id})');
        Navigator.of(context).pop();
        setState(() {
          _dataService.loadChatSession(discussion.id);
          _messages = _dataService.currentMessages;
          _messageController.clear();
          _pendingAttachments.clear();
          _isTyping = false;
          _showEmojiPicker = false;
        });
        _scrollToBottom();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.scaleWidth(20),
          vertical: context.scaleHeight(15),
        ),
        decoration: BoxDecoration(
          color: _dataService.currentDiscussion?.id == discussion.id ? AppColor.hijauTosca.withOpacity(0.3) : AppColor.hijauTosca,
          borderRadius: BorderRadius.circular(context.scaleWidth(12)),
          border: Border.all(color: AppColor.navyElement, width: 1),
        ),
        child: Text(
          discussion.title,
          style: GoogleFonts.fredoka(
            fontSize: context.scaleWidth(16),
            color: AppColor.navyText,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNewChatButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('New chat button tapped');
        Navigator.of(context).pop();
        _dataService.startNewChat();
        setState(() {
          _messages = _dataService.currentMessages;
          _messageController.clear();
          _pendingAttachments.clear();
          _isTyping = false;
          _showEmojiPicker = false;
        });
        _scrollToBottom();
      },
      child: Container(
        width: double.infinity,
        height: context.scaleHeight(50),
        decoration: BoxDecoration(
          color: AppColor.putihNormal,
          borderRadius: BorderRadius.circular(context.scaleWidth(12)),
          border: Border.all(color: AppColor.navyElement, width: 1),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: AppColor.navyText,
            size: context.scaleWidth(30),
          ),
        ),
      ),
    );
  }
}