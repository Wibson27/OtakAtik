import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/common/app_color.dart';
import 'package:frontend/common/app_route.dart';
import 'package:frontend/common/screen_utils.dart';
import 'package:frontend/data/models/community_post.dart'; // Import model baru
import 'package:frontend/data/services/community_service.dart'; // Import service baru

class ForumDiscussionScreen extends StatefulWidget {
  const ForumDiscussionScreen({super.key});

  @override
  State<ForumDiscussionScreen> createState() => _ForumDiscussionScreenState();
}

class _ForumDiscussionScreenState extends State<ForumDiscussionScreen> {
  final CommunityService _communityService = CommunityService();
  late Future<List<CommunityPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _communityService.getPublicPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.putihNormal,
      body: SafeArea(
        child: _buildMainContent(context),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/yellow_background.png', fit: BoxFit.cover),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Image.asset('assets/images/blur_top.png', height: context.scaleHeight(88), fit: BoxFit.fill),
        ),
        Positioned(
          top: context.scaleHeight(16),
          left: context.scaleWidth(8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: context.scaleWidth(66),
              height: context.scaleHeight(66),
              child: Image.asset('assets/images/arrow.png', fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          top: context.scaleHeight(40), // Adjusted for better centering
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Forum Diskusi',
              style: GoogleFonts.fredoka(
                color: AppColor.navyText,
                fontSize: context.scaleWidth(24),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: context.scaleHeight(100), // Adjusted top position
          left: context.scaleWidth(20),  // Adjusted side padding
          right: context.scaleWidth(20),
          bottom: 0,
          child: FutureBuilder<List<CommunityPost>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Belum ada diskusi.'));
              }

              final posts = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.only(top: 10, bottom: context.scaleHeight(20)),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: context.scaleHeight(16)),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoute.forumDiscussPost,
                          arguments: post.id, // Mengirim ID post asli
                        );
                      },
                      child: _buildDiscussionCard(post),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionCard(CommunityPost post) {
    return Container(
      width: context.scaleWidth(348),
      decoration: BoxDecoration(
        color: AppColor.hijauTosca.withOpacity(0.85),
        borderRadius: BorderRadius.circular(context.scaleWidth(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: context.scaleWidth(8),
            offset: Offset(0, context.scaleHeight(4)),
          ),
        ],
      ),
      padding: EdgeInsets.all(context.scaleWidth(15.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.scaleWidth(10)),
            decoration: BoxDecoration(
              color: AppColor.putihNormal,
              borderRadius: BorderRadius.circular(context.scaleWidth(8)),
            ),
            child: Text(
              post.title, // Data asli
              style: GoogleFonts.fredoka(
                color: AppColor.navyText,
                fontSize: context.scaleWidth(18),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: context.scaleHeight(12)),
          // Description Box
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: context.scaleWidth(10), vertical: context.scaleHeight(8)),
            child: Text(
              post.contentSnippet, // Data asli
              style: GoogleFonts.roboto(
                color: AppColor.putihNormal,
                fontSize: context.scaleWidth(13),
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: context.scaleHeight(10)),
          // Footer (Author, Replies, etc.)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'oleh ${post.authorName}',
                style: GoogleFonts.roboto(
                  color: AppColor.putihNormal.withOpacity(0.8),
                  fontSize: context.scaleWidth(11),
                ),
              ),
              Row(
                children: [
                  Icon(Icons.comment, color: AppColor.putihNormal.withOpacity(0.8), size: context.scaleWidth(14)),
                  SizedBox(width: context.scaleWidth(4)),
                  Text(
                    post.replyCount.toString(),
                     style: GoogleFonts.roboto(color: AppColor.putihNormal.withOpacity(0.8), fontSize: context.scaleWidth(11)),
                  ),
                  SizedBox(width: context.scaleWidth(10)),
                  Icon(Icons.favorite_border, color: AppColor.putihNormal.withOpacity(0.8), size: context.scaleWidth(14)),
                   SizedBox(width: context.scaleWidth(4)),
                  Text(
                    post.reactionCount.toString(),
                     style: GoogleFonts.roboto(color: AppColor.putihNormal.withOpacity(0.8), fontSize: context.scaleWidth(11)),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}