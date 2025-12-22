import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';

class KlinkAIButton extends StatefulWidget {
  const KlinkAIButton({super.key});

  @override
  State<KlinkAIButton> createState() => _KlinkAIButtonState();
}

class _KlinkAIButtonState extends State<KlinkAIButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _glowAnimation = ColorTween(
      begin: const Color(0xFF00E5FF).withOpacity(0.3),
      end: const Color(0xFF2979FF).withOpacity(0.6),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openAIChat() {
    HapticFeedback.mediumImpact();
    
    // Create a dummy user for Klink AI
    final aiUser = User(
      userId: 'klink_ai_assistant',
      fullname: 'Klink AI',
      email: 'ai@klink.com',
      photoUrl: 'assets/images/app_logo.png', // Use local asset as URL for now
      bio: 'Your personal AI assistant',
      isOnline: true,
      lastActive: DateTime.now(),
      deviceToken: '',
    );

    // Navigate to chat
    RoutesHelper.toMessages(user: aiUser);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: _openAIChat,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black, // Always black to ensure logo visibility
              border: Border.all(
                color: isDarkMode 
                    ? const Color(0xFF00E5FF).withOpacity(0.5) 
                    : Colors.black.withOpacity(0.1), // Subtle border in light mode
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _glowAnimation.value!,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
                if (!isDarkMode)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
