import 'package:flutter/material.dart';
import 'package:chat_messenger/config/theme_config.dart';

class NoData extends StatefulWidget {
  const NoData({
    super.key,
    required this.text,
    this.textColor,
    this.iconData,
    this.iconSize = 80,
    this.customIcon,
    this.subtitle,
  });

  // Variables
  final String text;
  final String? subtitle;
  final Color? textColor;
  final IconData? iconData;
  final double iconSize;
  final Widget? customIcon;

  @override
  State<NoData> createState() => _NoDataState();
}

class _NoDataState extends State<NoData>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Modern icon container with gradient background
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor.withOpacity(0.1),
                            primaryLight.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: widget.customIcon ?? 
                        Icon(
                          widget.iconData,
                          color: primaryColor.withOpacity(0.7),
                          size: widget.iconSize,
                        ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Main text with better typography
                    Text(
                      widget.text,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: widget.textColor ?? 
                          (isDarkMode ? darkThemeTextColor : lightThemeTextColor),
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    // Subtitle if provided
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDarkMode 
                            ? darkThemeTextColor.withOpacity(0.7)
                            : lightThemeSecondaryText,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
