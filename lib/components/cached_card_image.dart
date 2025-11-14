import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/config/theme_config.dart';

class CachedCardImage extends StatelessWidget {
  const CachedCardImage(
    this.imageUrl, {
    super.key,
    this.placeholder = const SizedBox.shrink(),
    this.errorIconColor = primaryColor,
  });

  // Variables
  final String imageUrl;
  final Widget placeholder;
  final Color errorIconColor;

  @override
  Widget build(BuildContext context) {
    // Check local asset
    if (imageUrl.startsWith('assets')) {
      // Get asset image for debug purposes
      return Image.asset(imageUrl, fit: BoxFit.cover);
    } else {
      // Get network image
      return CachedNetworkImage(
        fit: BoxFit.cover,
        imageUrl: imageUrl,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: Center(
            child: Icon(
              IconlyLight.dangerCircle,
              color: errorIconColor,
              size: 50,
            ),
          ),
        ),
      );
    }
  }
}
