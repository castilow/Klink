import 'package:chat_messenger/config/theme_config.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/material.dart';

class RichTexMessage extends StatelessWidget {
  const RichTexMessage({
    super.key,
    required this.text,
    this.defaultStyle,
    this.maxLines,
  });

  final String text;
  final TextStyle? defaultStyle;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return EasyRichText(
      text,
      maxLines: maxLines,
      overflow: defaultStyle?.overflow ?? TextOverflow.clip,
      defaultStyle: defaultStyle ?? DefaultTextStyle.of(context).style,
      patternList: [
        EasyRichTextPattern(
          targetString: EasyRegexPattern.emailPattern,
          urlType: 'email',
          style: TextStyle(
            color: secondaryColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
        EasyRichTextPattern(
          targetString:
              r'\b(?:(?:(?:https?|ftp):\/\/)|(?:www\.))(?:(?![@\s])[\w-]+(?:\.[\w-]+)+)(?:\/[^\s]*)?\b',
          urlType: 'web',
          style: TextStyle(
            color: primaryColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
        EasyRichTextPattern(
          targetString: EasyRegexPattern.telPattern,
          urlType: 'tel',
          style: TextStyle(
            color: secondaryColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Bold font - más suave
        EasyRichTextPattern(
          targetString: '(\\*)(.*?)(\\*)',
          matchBuilder: (_, match) {
            return TextSpan(
              text: match?[0]?.replaceAll('*', ''),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: defaultStyle?.color,
              ),
            );
          },
        ),

        // Italic font - más natural
        EasyRichTextPattern(
          targetString: '(_)(.*?)(_)',
          matchBuilder: (_, match) {
            return TextSpan(
              text: match?[0]?.replaceAll('_', ''),
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: defaultStyle?.color,
              ),
            );
          },
        ),

        // Strikethrough - más sutil
        EasyRichTextPattern(
          targetString: '(~)(.*?)(~)',
          matchBuilder: (_, match) {
            return TextSpan(
              text: match?[0]?.replaceAll('~', ''),
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                decorationColor: defaultStyle?.color?.withOpacity(0.6),
                color: defaultStyle?.color?.withOpacity(0.7),
              ),
            );
          },
        ),
      ],
    );
  }
}
