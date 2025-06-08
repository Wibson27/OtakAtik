import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
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

class ChatDataService {
  static final ChatDataService _instance = ChatDataService._internal();
  factory ChatDataService() => _instance;
  ChatDataService._internal();

  String _currentChatSessionId = "chatbot_session_001";

  String get currentChatSessionId => _currentChatSessionId; 

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: "bot_msg_001",
      chatSessionId: "chatbot_session_001",
      senderType: "ai_bot",
      messageContent: "Hai! 👋 Ada yang bisa saya bantu hari ini?",
      senderId: "ai_bot_001",
      senderName: "Tenang.in Bot",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isOwner: false,
    ),
    ChatMessage(
      id: "user_msg_001",
      chatSessionId: "chatbot_session_001",
      senderType: "user",
      messageContent: "Lagi kerasa agak overthinking nih... 🤔",
      senderId: "user_main",
      senderName: "Hai OtakAtik",
      timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
      isOwner: true,
    ),
    ChatMessage(
      id: "bot_msg_002",
      chatSessionId: "chatbot_session_001",
      senderType: "ai_bot",
      messageContent: "Hmm, wajar kok kalau merasa terbebani dan punya pekerjaan. Tapi coba kita lihat dari sisi lain yuk! 😊 Bayangkan perasaan lega ketika semua tugas itu selesai. ✨ Kita bisa coba pecah jadi bagian-bagian kecil. Kekuatan apa yang kamu cari? 💪 Atau mungkin ada hal lain yang bisa bantu kamu merasa lebih tenang? Misalnya, mendengarkan musik yang rileks? 🎶",
      senderId: "ai_bot_001",
      senderName: "Tenang.in Bot",
      timestamp: DateTime.parse('2025-06-06T10:06:00Z'),
      isOwner: false,
    ),
  ];

  final Discussion _currentChatDiscussion = Discussion(
    id: "chat_001",
    title: "Chatbot Session",
    content: "Sesi obrolan dengan chatbot.",
    authorName: "Chatbot",
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
  );

  Discussion get currentDiscussion => _currentChatDiscussion;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addMessage(ChatMessage message) {
    _messages.add(message);
  }

  String generateMessageId() {
    return "msg_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}";
  }
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Data service
  final ChatDataService _dataService = ChatDataService();

  // State variables
  bool _isTyping = false;
  bool _showEmojiPicker = false;
  String _currentMessage = '';
  List<ChatMessage> _messages = [];
  final List<AttachmentFile> _pendingAttachments = [];

  // File picker 
  final ImagePicker _imagePicker = ImagePicker();

  // Emoji 
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
        _isTyping = _currentMessage.isNotEmpty || _pendingAttachments.isNotEmpty;
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
    final screenWidth = context.screenWidth;
    final screenHeight = context.screenHeight;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 244, 240, 240), 
      resizeToAvoidBottomInset: true, 
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
              if (_pendingAttachments.isNotEmpty) _buildUploadingIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  // Background
  Widget _buildBackground() {
    return Positioned.fill(
      child: Image.asset(
        'assets/images/wave_history_voice.png', 
        fit: BoxFit.cover,
      ),
    );
  }

  // _buildHeader
  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Stack( 
        children: [
          // blur_top_history.png
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
                // arrow.png
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/images/arrow.png',
                    width: context.scaleWidth(66),
                    height: context.scaleHeight(66),
                  ),
                ),
                SizedBox(width: context.scaleWidth(300)),
               
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoute.chatbotHistory);
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

  //  _buildChatMessagesArea
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
          return _buildChatMessageBubbleItem(message);
        },
      ),
    );
  }

  Widget _buildBottomSection(BuildContext currentContext) {
    return Positioned(
      bottom: currentContext.scaleHeight(10), 
      left: 0,
      right: 0,
      child: Column(
        children: [
          _buildBottomMessageArea(currentContext),
          if (_showEmojiPicker) _buildSimpleEmojiPicker(currentContext),
        ],
      ),
    );
  }

  // Upload indicator
  Widget _buildUploadingIndicator() {
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijauSuccess),
                ),
                SizedBox(height: context.scaleHeight(12)),
                Text(
                  'Mengunggah file...',
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
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

  // _buildBottomMessageArea
  Widget _buildBottomMessageArea(BuildContext areaContext) {
    double dynamicHeight = _calculateMessageBoxHeight(areaContext);

    return Container(
      height: dynamicHeight,
      margin: EdgeInsets.symmetric(horizontal: areaContext.scaleWidth(10)),
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
              left: areaContext.scaleWidth(140),
              right: areaContext.scaleWidth(70),
              bottom: dynamicHeight - areaContext.scaleHeight(25), 
              child: _buildPendingAttachmentsPreview(areaContext),
            ),

          // Text inputan 
          Positioned(
            left: areaContext.scaleWidth(140),
            right: areaContext.scaleWidth(70),
            bottom: areaContext.scaleHeight(10), 
            top: _pendingAttachments.isNotEmpty
                ? areaContext.scaleHeight(35) 
                : areaContext.scaleHeight(10), 
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              maxLines: null, 
              style: GoogleFonts.fredoka(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColor.navyText,
              ),
              textAlign: TextAlign.left, 
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Ketik pesan...',
                hintStyle: GoogleFonts.fredoka(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColor.navyText.withOpacity(0.6),
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: areaContext.scaleHeight(0), 
                  horizontal: areaContext.scaleWidth(0),
                ),
                isDense: true,
              ),
              cursorColor: AppColor.navyText,
            ),
          ),

          // happy_emoji.png
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

          // paper_clip.png 
          Positioned(
            left: areaContext.scaleWidth(87),
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

          // polygon_button.png 
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

  // _buildPendingAttachmentsPreview
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
              color: AppColor.hijauSuccess.withOpacity(0.1),
              borderRadius: BorderRadius.circular(previewContext.scaleWidth(15)),
              border: Border.all(
                color: AppColor.hijauSuccess.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  attachment.type == AttachmentType.image ? Icons.image : Icons.attach_file,
                  size: previewContext.scaleWidth(12),
                  color: AppColor.hijauSuccess,
                ),
                SizedBox(width: previewContext.scaleWidth(4)),
                Text(
                  attachment.name.length > 10 ? '${attachment.name.substring(0, 10)}...' : attachment.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 9,
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

  // _calculateMessageBoxHeight
  double _calculateMessageBoxHeight(BuildContext calcContext) {
    double baseImageHeight = calcContext.scaleHeight(50);
    double attachmentAreaHeight = _pendingAttachments.isNotEmpty ? calcContext.scaleHeight(35) : 0;

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

    double availableWidthForText = calcContext.scaleWidth(417 - 140 - 70);
    if (availableWidthForText <= 0) availableWidthForText = calcContext.scaleWidth(100);

    textPainter.layout(maxWidth: availableWidthForText);

    double textContentHeight = textPainter.height;
    double textFieldVerticalPadding = calcContext.scaleHeight(10) + calcContext.scaleHeight(10); 
    if (_pendingAttachments.isNotEmpty) {
      textFieldVerticalPadding = calcContext.scaleHeight(35) + calcContext.scaleHeight(10); 
    }

    double requiredContentHeight = textContentHeight;
    if (_currentMessage.isEmpty) {
        requiredContentHeight = max(requiredContentHeight, calcContext.scaleHeight(16)); 
    }


    double totalContentHeight = requiredContentHeight + textFieldVerticalPadding;
    double calculatedTotalHeight = max(baseImageHeight, totalContentHeight);
    return calculatedTotalHeight.clamp(baseImageHeight, calcContext.scaleHeight(200));
  }


  //  _buildSimpleEmojiPicker
  Widget _buildSimpleEmojiPicker(BuildContext emojiContext) {
    return Positioned(
      bottom: emojiContext.scaleHeight(10) + _calculateMessageBoxHeight(emojiContext),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.navyText,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showEmojiPicker = false),
                  child: const Icon(Icons.close),
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
                      _messageFocusNode.requestFocus(); // Kembalikan fokus ke TextField setelah memilih emoji
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

  //  _toggleEmojiPicker
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

  // _showAttachmentDialog
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
              fontSize: 18,
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
                    color: AppColor.hijauSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(dialogContext.scaleWidth(8)),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColor.hijauSuccess,
                  ),
                ),
                title: Text(
                  'Kamera',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                ),
                subtitle: Text(
                  'Ambil foto langsung',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
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
                  ),
                ),
                title: Text(
                  'Galeri',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                ),
                subtitle: Text(
                  'Pilih dari galeri',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
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
                  ),
                ),
                title: Text(
                  'File',
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                ),
                subtitle: Text(
                  'Dokumen dan file lainnya',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
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
                _messageFocusNode.requestFocus(); // Kembalikan fokus ke TextField setelah menutup dialog
              },
              child: Text(
                'Batal',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
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

    if (size > 10 * 1024 * 1024) { // Max 10MB
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
          style: GoogleFonts.roboto(color: AppColor.putihNormal, fontSize: 12),
        ),
        backgroundColor: AppColor.hijauSuccess,
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
          style: GoogleFonts.roboto(color: AppColor.putihNormal, fontSize: 12),
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

    final newMessage = ChatMessage(
      id: _dataService.generateMessageId(),
      chatSessionId: _dataService.currentChatSessionId,
      senderType: "user",
      messageContent: messageText,
      senderId: "user_main",
      senderName: "Hai OtakAtik",
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

    Future.delayed(const Duration(seconds: 1), () {
      final botReplyMessage = ChatMessage(
        id: _dataService.generateMessageId(),
        chatSessionId: _dataService.currentChatSessionId,
        senderType: "ai_bot",
        messageContent: "Terima kasih atas pesannya! Saya sedang memproses itu. Ada hal lain yang bisa saya bantu?",
        senderId: "ai_bot_001",
        senderName: "Tenang.in Bot",
        timestamp: DateTime.now(),
        isOwner: false,
      );
      setState(() {
        _dataService.addMessage(botReplyMessage);
        _messages = _dataService.messages;
      });
      _scrollToBottom();
    });
  }

  // _buildChatMessageBubbleItem 
  Widget _buildChatMessageBubbleItem(ChatMessage message) {
    final double messageMaxWidth = context.screenWidth * 0.7;

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
          top: context.scaleHeight(8),
          bottom: context.scaleHeight(8),
          left: message.isOwner ? context.screenWidth * 0.15 : 0,
          right: message.isOwner ? 0 : context.screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: context.scaleWidth(25),
          vertical: context.scaleHeight(25),
        ),
        constraints: BoxConstraints(
          maxWidth: messageMaxWidth,
          minWidth: context.scaleWidth(100),
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
                fontSize: 12,
                color: AppColor.navyText,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.left,
            ),
            if (message.attachments.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: context.scaleHeight(5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: message.attachments.map((attachment) {
                    return Container(
                      margin: EdgeInsets.only(right: context.scaleWidth(5)),
                      child: Icon(
                        attachment.type == AttachmentType.image ? Icons.image : Icons.attach_file,
                        color: AppColor.navyText,
                        size: context.scaleWidth(16),
                      ),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: context.scaleHeight(4)),
            Text(
              '${message.senderName} - ${TimeFormatter.formatTimeDetailed(message.timestamp)}',
              style: GoogleFonts.fredoka(
                fontSize: 9,
                color: AppColor.navyText.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}