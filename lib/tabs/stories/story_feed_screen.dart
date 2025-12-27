import 'package:chat_messenger/models/story/story.dart';
import 'package:chat_messenger/tabs/stories/story_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StoryFeedScreen extends StatefulWidget {
  final List<Story> stories;
  final int initialIndex;

  const StoryFeedScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  @override
  State<StoryFeedScreen> createState() => _StoryFeedScreenState();
}

class _StoryFeedScreenState extends State<StoryFeedScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStoryComplete() {
    if (_currentIndex < widget.stories.length - 1) {
      // Move to next user's story
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      // Last story, close feed
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics: const ClampingScrollPhysics(), // Important for "Cube" feel
        itemCount: widget.stories.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          // Add a cube-like transition effect here if desired, 
          // essentially passing the StoryViewScreen as the child.
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              // Basic transform logic for visual flair (swipe effect)
              // If not needed, just return child.
              return child!;
            },
            child: StoryViewScreen(
              story: widget.stories[index],
              onStoryComplete: _onStoryComplete,
            ),
          );
        },
      ),
    );
  }
}
