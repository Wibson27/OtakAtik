// PERBAIKAN UTAMA untuk ChatbotScreen
// File: screens/chatbot_screen.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:intl/date_symbol_data_local.dart';

import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_info.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/chat_message.dart';
import 'package:frontend/data/models/chat_session.dart';
import 'package:frontend/data/models/attachment_file.dart';
import 'package:frontend/common/enums.dart';
import 'package:frontend/data/services/chat_service.dart';
import 'package:frontend/data/services/secure_storage_service.dart';
import 'package:frontend/common/app_route.dart';

class ChatbotScreen extends StatefulWidget {
  final String? initialSessionId; // ← UBAH jadi nullable

  const ChatbotScreen({super.key, this.initialSessionId}); // ← HAPUS required

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Controllers and Keys
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // Services
  final ChatService _chatService = ChatService();

  // State variables
  bool _isLoading = true;
  bool _isSending = false;
  String? _currentSessionId;
  List<ChatMessage> _messages = [];
  List<ChatSession> _sessionHistory = [];
  Timer? _pollingTimer;

  // 🔧 PERBAIKAN: Tambah flag untuk tracking
  bool _hasInitialLoad = false;
  int _lastMessageCount = 0;

  // UI State
  bool _showEmojiPicker = false;
  final List<AttachmentFile> _pendingAttachments = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Computed properties
  String get _currentMessage => _messageController.text;
  bool get _isTyping => _currentMessage.isNotEmpty || _pendingAttachments.isNotEmpty;

  // Emoji list
  final List<String> _emojiList = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉',
    '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨',
    '🧐', '🤓', '😎', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️',
    '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳',
    '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥', '😶',
    '😐', '😑', '😬', '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪',
    '😵', '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '👍', '👎',
    '👌', '✊', '👊', '🤛', '🤜', '👏', '🙌', '👐', '🤲',
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

 Future<void> _initializeScreen() async {
    try {
      await initializeDateFormatting('id_ID', null);

      // 🔧 PERBAIKAN: Handle null/empty initialSessionId
      if (widget.initialSessionId != null && widget.initialSessionId!.isNotEmpty) {
        _currentSessionId = widget.initialSessionId;
        print('🔍 Using existing session: $_currentSessionId');
      } else {
        print('🔍 No session provided, creating new session...');
        await _createNewChatSession();
      }

      _messageController.addListener(() => setState(() {}));
      _messageFocusNode.addListener(() => setState(() {}));

      // Load data secara berurutan
      await _loadInitialMessages();
      await _loadHistory();

      // Tunggu sebentar sebelum mulai polling
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _startPolling();
      }
    } catch (e) {
      print("Error in initialization: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        AppInfo.error(context, "Gagal memulai chat: ${e.toString().replaceFirst("Exception: ", "")}");
      }
    }
  }

    Future<void> _createNewChatSession() async {
    try {
      print('🔍 Creating new chat session...');
      final newSession = await _chatService.createChatSession();

      if (mounted) {
        setState(() {
          _currentSessionId = newSession.id;
        });
        print('✅ New session created: ${_currentSessionId}');
      }
    } catch (e) {
      print('❌ Failed to create new session: $e');
      rethrow;
    }
  }


  // ==================== DATA MANAGEMENT ====================

   Future<void> _loadInitialMessages() async {
    if (_currentSessionId == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final messages = await _chatService.getMessagesForSession(_currentSessionId!);
      if (mounted) {
        setState(() {
          _messages = messages.where((msg) =>
            msg.messageContent.isNotEmpty &&
            msg.messageContent.trim() != ''
          ).toList();
          _lastMessageCount = _messages.length;
          _hasInitialLoad = true;
          _isLoading = false;
        });

        // Scroll hanya jika ada pesan
        if (_messages.isNotEmpty) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      print("Error loading messages: $e");
      if (mounted) {
        // Jangan tampilkan error untuk session kosong/baru
        if (!e.toString().contains('tidak ditemukan') &&
            !e.toString().contains('empty') &&
            !e.toString().contains('404')) {
          AppInfo.error(context, "Gagal memuat pesan: ${e.toString().replaceFirst("Exception: ", "")}");
        }
        setState(() {
          _messages = [];
          _hasInitialLoad = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _chatService.getChatSessions();
      if (mounted) setState(() => _sessionHistory = history);
    } catch (e) {
      print("Error loading history: $e");
    }
  }

  void _startPolling() {
    if (!_hasInitialLoad || _currentSessionId == null) return;

    _pollingTimer?.cancel();

    // 🔧 PERBAIKAN: Polling yang lebih konservatif
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted || _currentSessionId == null || _isSending) {
        timer.cancel();
        return;
      }

      try {
        final newMessages = await _chatService.getMessagesForSession(_currentSessionId!);

        // 🔧 PERBAIKAN: Filter dan cek perubahan yang valid
        final validMessages = newMessages.where((msg) =>
          msg.messageContent.isNotEmpty &&
          msg.messageContent.trim() != ''
        ).toList();

        if (validMessages.length > _lastMessageCount && mounted) {
          setState(() {
            _messages = validMessages;
            _lastMessageCount = validMessages.length;
          });
          _scrollToBottom();
          print("📩 New messages detected: ${validMessages.length}");
        }
      } catch (e) {
        print("Polling error (continuing): $e");
        // 🔧 PERBAIKAN: Jangan stop polling untuk error minor
      }
    });
  }

  // ==================== SESSION MANAGEMENT ====================

  Future<void> _createNewSession() async {
    Navigator.of(context).pop();
    setState(() => _isLoading = true);

    try {
      final newSession = await _chatService.createChatSession();
      if (mounted) {
        // 🔧 PERBAIKAN: Gunakan pushReplacement dengan arguments yang benar
        Navigator.pushReplacementNamed(
          context,
          AppRoute.chatbot,
          arguments: newSession.id,
        );
      }
    } catch (e) {
      if (mounted) {
        AppInfo.error(context, "Gagal memulai sesi baru.");
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchSession(String newSessionId) {
     if (newSessionId == _currentSessionId) {
        Navigator.of(context).pop();
        return;
     }

     if(mounted){
        // 🔧 PERBAIKAN: Pass sessionId sebagai arguments
        Navigator.pushReplacementNamed(
          context,
          AppRoute.chatbot,
          arguments: newSessionId,
        );
     }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    print("📤 Sending message: $content");

    // 🔧 PERBAIKAN: Buat temporary message dengan data yang valid
    final tempMessage = ChatMessage.fromUser(
      content: content,
      sessionId: _currentSessionId!
    );

    setState(() {
      _isSending = true;
      _messages.add(tempMessage);
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        sessionId: _currentSessionId!,
        content: content,
      );

      print("📨 Message sent successfully");

      if (mounted) {
        setState(() {
          // 🔧 PERBAIKAN: Remove temp message properly
          _messages.removeWhere((msg) => msg.id == tempMessage.id);

          // 🔧 PERBAIKAN: Add user message manually jika tidak ada di response
          final userMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            chatSessionId: _currentSessionId!,
            senderType: 'user',
            messageContent: content,
            timestamp: DateTime.now(),
            senderName: 'You',
            isOwner: true,
          );

          _messages.add(userMessage);

          // Add AI response jika ada
          if (response.messageContent.isNotEmpty) {
            _messages.add(response);
          }

          _lastMessageCount = _messages.length;
        });
        _scrollToBottom();
      }
    } catch (e) {
      print("❌ Send message error: $e");
      if (mounted) {
        AppInfo.error(context, "Gagal mengirim pesan: ${e.toString().replaceFirst("Exception: ", "")}");
        setState(() {
          _messages.removeWhere((msg) => msg.id == tempMessage.id);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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

  // ==================== FILE HANDLING ====================
  // [File handling methods tetap sama...]

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

    setState(() => _pendingAttachments.add(attachment));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'File berhasil ditambahkan: $fileName',
          style: GoogleFonts.roboto(color: AppColor.putihNormal, fontSize: 12),
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
    setState(() => _pendingAttachments.removeAt(index));
  }

  // ==================== UI HELPERS ====================

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        _messageFocusNode.unfocus();
      } else {
        _messageFocusNode.requestFocus();
      }
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  double _calculateMessageBoxHeight() {
    double baseImageHeight = context.scaleHeight(50);

    final textPainter = TextPainter(
      text: TextSpan(
        text: _currentMessage.isEmpty ? 'Ketik pesan...' : _currentMessage,
        style: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    );

    double availableWidthForText = context.scaleWidth(277);
    if (availableWidthForText <= 0) availableWidthForText = context.scaleWidth(100);

    textPainter.layout(maxWidth: availableWidthForText);
    double textContentHeight = max(context.scaleHeight(16), textPainter.height);

    double textFieldPaddingTop = _pendingAttachments.isNotEmpty ? context.scaleHeight(35) : context.scaleHeight(10);
    double textFieldPaddingBottom = context.scaleHeight(10);
    double requiredContentHeight = textContentHeight + textFieldPaddingTop + textFieldPaddingBottom;

    double maxMessageBoxHeight = context.scaleHeight(200);

    return max(baseImageHeight, requiredContentHeight).clamp(baseImageHeight, maxMessageBoxHeight);
  }

  // ==================== UI BUILD METHODS ====================
  // [UI methods tetap sama - hanya ubah chat area]

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColor.putihNormal,
      resizeToAvoidBottomInset: true,
      endDrawer: _buildHistoryDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            _buildHeader(),
            _buildChatArea(),
            _buildBottomSection(),
            if (_showEmojiPicker) _buildSimpleEmojiPicker(),
            if (_pendingAttachments.isNotEmpty && !_showEmojiPicker) _buildUploadingIndicator(),
          ],
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

  Widget _buildHeader() {
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
                    'Chatbot',
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
                    _loadHistory();
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

  Widget _buildChatArea() {
    return Positioned(
      top: context.scaleHeight(88),
      left: 0,
      right: 0,
      bottom: context.scaleHeight(80),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Mulai percakapan Anda!",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Ketik pesan untuk memulai chat",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: context.scaleWidth(15),
                    vertical: context.scaleHeight(10),
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    // 🔧 PERBAIKAN: Skip pesan kosong saat rendering
                    if (message.messageContent.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildChatMessageBubble(message);
                  },
                ),
    );
  }

  Widget _buildChatMessageBubble(ChatMessage message) {
    final double messageMaxWidth = context.screenWidth * 0.7;
    final String bubbleImage = message.isOwner
        ? 'assets/images/yellow_discussion_box.png'
        : 'assets/images/green_discussion_box.png';

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
            if (message.attachments?.isNotEmpty == true)
              Padding(
                padding: EdgeInsets.only(top: context.scaleHeight(5)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: message.attachments!.map((attachment) {
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
              '${message.senderName} - ${_formatTimestamp(message.timestamp)}',
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

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('HH:mm - dd/MM/yyyy', 'id_ID').format(timestamp);
  }

  Widget _buildBottomSection() {
    return Positioned(
      bottom: 25,
      left: 0,
      right: 0,
      child: _buildBottomMessageArea(),
    );
  }

  Widget _buildBottomMessageArea() {
    double dynamicHeight = _calculateMessageBoxHeight();

    return Container(
      height: dynamicHeight,
      margin: EdgeInsets.symmetric(horizontal: context.scaleWidth(15)),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: context.scaleWidth(417),
            height: dynamicHeight,
            child: Image.asset(
              'assets/images/message_box.png',
              fit: BoxFit.fill,
            ),
          ),
          if (_pendingAttachments.isNotEmpty)
            Positioned(
              left: context.scaleWidth(60),
              right: context.scaleWidth(60),
              bottom: dynamicHeight - context.scaleHeight(40),
              child: _buildPendingAttachmentsPreview(),
            ),
          Positioned(
            left: context.scaleWidth(100),
            right: context.scaleWidth(60),
            bottom: context.scaleHeight(10),
            top: _pendingAttachments.isNotEmpty
                ? context.scaleHeight(20)
                : context.scaleHeight(10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColor.putihNormal,
                borderRadius: BorderRadius.circular(context.scaleWidth(20)),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColor.navyText,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ketik pesan...',
                  hintStyle: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText.withOpacity(0.6),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: context.scaleHeight(5),
                    horizontal: context.scaleWidth(10),
                  ),
                  isDense: true,
                ),
                cursorColor: AppColor.navyText,
              ),
            ),
          ),
          _buildMessageInputButtons(dynamicHeight),
        ],
      ),
    );
  }

  Widget _buildMessageInputButtons(double dynamicHeight) {
    return Stack(
      children: [
        // Emoji button
        Positioned(
          left: context.scaleWidth(14),
          bottom: context.scaleHeight(8),
          child: GestureDetector(
            onTap: _toggleEmojiPicker,
            child: Image.asset(
              'assets/images/happy_emoji.png',
              width: context.scaleWidth(34),
              height: context.scaleHeight(34),
            ),
          ),
        ),
        // Attachment button
        Positioned(
          left: context.scaleWidth(60),
          bottom: context.scaleHeight(9),
          child: GestureDetector(
            onTap: _showAttachmentDialog,
            child: Image.asset(
              'assets/images/paper_clip.png',
              width: context.scaleWidth(30),
              height: context.scaleHeight(30),
            ),
          ),
        ),
        // Send button
        Positioned(
          right: context.scaleWidth(24),
          bottom: context.scaleHeight(8),
          child: GestureDetector(
            onTap: _isSending ? null : _sendMessage, // 🔧 PERBAIKAN: Disable saat sending
            child: Opacity(
              opacity: _isSending ? 0.5 : 1.0,
              child: Image.asset(
                'assets/images/polygon_button.png',
                width: context.scaleWidth(34),
                height: context.scaleHeight(32),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingAttachmentsPreview() {
    return SizedBox(
      height: context.scaleHeight(30),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pendingAttachments.length,
        itemBuilder: (context, index) {
          final attachment = _pendingAttachments[index];
          return Container(
            margin: EdgeInsets.only(right: context.scaleWidth(8)),
            padding: EdgeInsets.symmetric(
              horizontal: context.scaleWidth(8),
              vertical: context.scaleHeight(4),
            ),
            decoration: BoxDecoration(
              color: AppColor.hijauTosca.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.scaleWidth(15)),
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
                  size: context.scaleWidth(12),
                  color: AppColor.hijauTosca,
                ),
                SizedBox(width: context.scaleWidth(4)),
                Text(
                  attachment.name.length > 10
                      ? '${attachment.name.substring(0, 10)}...'
                      : attachment.name,
                  style: GoogleFonts.fredoka(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppColor.navyText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(width: context.scaleWidth(4)),
                GestureDetector(
                  onTap: () => _removePendingAttachment(index),
                  child: Icon(
                    Icons.close,
                    size: context.scaleWidth(12),
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

  Widget _buildSimpleEmojiPicker() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: context.scaleHeight(180),
        color: AppColor.putihNormal,
        padding: EdgeInsets.all(context.scaleWidth(16)),
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
            SizedBox(height: context.scaleHeight(8)),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  childAspectRatio: 1,
                  crossAxisSpacing: context.scaleWidth(2),
                  mainAxisSpacing: context.scaleHeight(2),
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
                        borderRadius: BorderRadius.circular(context.scaleWidth(4)),
                        color: Colors.grey[100],
                      ),
                      child: Center(
                        child: Text(
                          _emojiList[index],
                          style: TextStyle(fontSize: context.scaleHeight(20)),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.hijauTosca),
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

  void _showAttachmentDialog() {
    _messageFocusNode.unfocus();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.scaleWidth(16)),
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
              _buildAttachmentOption(
                icon: Icons.camera_alt,
                title: 'Kamera',
                subtitle: 'Ambil foto langsung',
                color: AppColor.hijauTosca,
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.photo_library,
                title: 'Galeri',
                subtitle: 'Pilih dari galeri',
                color: AppColor.biruNormal,
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              _buildAttachmentOption(
                icon: Icons.attach_file,
                title: 'File',
                subtitle: 'Dokumen dan file lainnya',
                color: AppColor.kuning,
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

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(context.scaleWidth(8)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(context.scaleWidth(8)),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: GoogleFonts.fredoka(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColor.navyText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.fredoka(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: AppColor.navyText.withOpacity(0.7),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHistoryDrawer() {
    return Drawer(
      width: context.screenWidth * 0.75,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        color: AppColor.putihNormal,
        child: Column(
          children: [
            _buildHistoryHeader(),
            SizedBox(height: context.scaleHeight(20)),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(16)),
                itemCount: _sessionHistory.length + 1,
                itemBuilder: (context, index) {
                  if (index == _sessionHistory.length) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: context.scaleHeight(10),
                        bottom: context.scaleHeight(20),
                      ),
                      child: _buildNewChatButton(),
                    );
                  }
                  final session = _sessionHistory[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: context.scaleHeight(12)),
                    child: _buildHistoryChipItem(session),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Container(
      width: double.infinity,
      height: context.scaleHeight(88),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/blur_top_history.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: EdgeInsets.only(
        top: context.scaleHeight(16),
        left: context.scaleWidth(8),
        right: context.scaleWidth(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/history_button.png',
                width: context.scaleWidth(34),
                height: context.scaleHeight(34),
                fit: BoxFit.contain,
              ),
              SizedBox(width: context.scaleWidth(80)),
              Text(
                'History',
                style: GoogleFonts.fredoka(
                  fontSize: 24,
                  color: AppColor.navyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close,
              color: AppColor.navyText,
              size: context.scaleWidth(24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChipItem(ChatSession session) {
    final bool isSelected = session.id == _currentSessionId;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _switchSession(session.id);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.scaleWidth(20),
          vertical: context.scaleHeight(15),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColor.hijauTosca.withOpacity(0.3)
              : AppColor.hijauTosca,
          borderRadius: BorderRadius.circular(context.scaleWidth(12)),
          border: Border.all(color: AppColor.navyElement, width: 1),
        ),
        child: Text(
          session.sessionTitle ?? 'Percakapan Tanpa Judul',
          style: GoogleFonts.fredoka(
            fontSize: 16,
            color: AppColor.navyText,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildNewChatButton() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _createNewSession();
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