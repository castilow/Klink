import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:get/get.dart';

class ReactionPanel extends StatefulWidget {
  const ReactionPanel({
    super.key,
    required this.message,
    required this.onReactionTap,
    required this.onReactionLongPress,
  });

  final Message message;
  final Function(String emoji) onReactionTap;
  final Function() onReactionLongPress;

  @override
  State<ReactionPanel> createState() => _ReactionPanelState();
}

class _ReactionPanelState extends State<ReactionPanel>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<String> quickReactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...quickReactions.map((emoji) => _buildReactionButton(emoji)),
                  _buildMoreButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionButton(String emoji) {
    final bool isReacted = widget.message.reactions?.containsKey(emoji) ?? false;
    final int count = widget.message.reactions?[emoji]?.length ?? 0;
    
    return GestureDetector(
      onTap: () => widget.onReactionTap(emoji),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isReacted ? primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isReacted ? Border.all(color: primaryColor, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isReacted ? primaryColor : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: widget.onReactionLongPress,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.add,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
} 