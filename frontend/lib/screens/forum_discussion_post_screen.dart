import 'package:flutter/material.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/data/models/community_post_detail.dart';
import 'package:frontend/data/models/community_post_reply.dart';
import 'package:frontend/data/services/community_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ForumDiscussionPostScreen extends StatefulWidget {
  final String postId;
  const ForumDiscussionPostScreen({super.key, required this.postId});

  @override
  State<ForumDiscussionPostScreen> createState() => _ForumDiscussionPostScreenState();
}

class _ForumDiscussionPostScreenState extends State<ForumDiscussionPostScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Future<CommunityPostDetail> _postDetailFuture;
  List<CommunityPostReply> _replies = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadPostDetails();
  }

  void _loadPostDetails() {
    _postDetailFuture = _communityService.getPostDetail(widget.postId);
    _postDetailFuture.then((data) {
      if (mounted) {
        setState(() => _replies = data.replies);
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat detail: ${e.toString()}')));
      }
    });
  }

  void _sendReply() async {
    if (_replyController.text.trim().isEmpty || _isSending) return;

    final content = _replyController.text.trim();
    setState(() => _isSending = true);

    try {
      final newReply = await _communityService.createReply(
        postId: widget.postId,
        content: content,
      );

      if(mounted) {
        setState(() {
          _replies.add(newReply);
          _replyController.clear();
        });
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengirim balasan: $e")));
      }
    } finally {
      if(mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFA),
      appBar: AppBar(
        title: const Text("Diskusi"),
      ),
      body: FutureBuilder<CommunityPostDetail>(
        future: _postDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Gagal memuat data diskusi.\n${snapshot.error}"));
          }
          final post = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12.0),
                  itemCount: _replies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildMainPostCard(post);
                    }
                    final reply = _replies[index - 1];
                    return _buildReplyCard(reply);
                  },
                ),
              ),
              _buildReplyInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainPostCard(CommunityPostDetail post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.title, style: GoogleFonts.fredoka(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('oleh ${post.authorName} • ${DateFormat.yMMMd('id_ID').format(post.createdAt)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const Divider(height: 32),
            Text(post.content, style: GoogleFonts.roboto(fontSize: 15, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(CommunityPostReply reply) {
    const isOwner = false; // Placeholder
    return Align(
      alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isOwner ? AppColor.kuning.withOpacity(0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(16)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reply.authorName, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 14, color: AppColor.navyText)),
              const SizedBox(height: 4),
              Text(reply.content, style: GoogleFonts.roboto()),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(DateFormat.jm('id_ID').format(reply.createdAt), style: TextStyle(color: Colors.grey[600], fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: "Tulis balasan Anda...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20))
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: AppColor.hijauTosca),
            onPressed: _isSending ? null : _sendReply,
          ),
        ],
      ),
    );
  }
}