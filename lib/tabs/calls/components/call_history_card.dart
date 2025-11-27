import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:chat_messenger/components/cached_circle_avatar.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/helpers/date_helper.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';
import 'package:chat_messenger/models/call_history.dart';
import 'package:chat_messenger/screens/calling/helper/call_helper.dart';

import 'call_type_message.dart';

class CallHistoryCard extends StatelessWidget {
  const CallHistoryCard(this.call, {super.key});

  final CallHistory call;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => RoutesHelper.toMessages(
          isGroup: false,
          user: call.receiver,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPadding / 2,
          ),
          child: Row(
            children: [
              // Profile photo
              Stack(
                children: [
                  CachedCircleAvatar(
                    radius: 30,
                    imageUrl: call.receiver.photoUrl,
                  ),
                  // Indicador de llamada perdida
                  if (call.callStatus == CallStatus.missed && call.isNew)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: errorColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile name
                    Text(
                      call.receiver.fullname,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: call.callStatus == CallStatus.missed && call.isNew
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: call.callStatus == CallStatus.missed && call.isNew
                            ? errorColor
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Other info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Call type message
                        CallTypeMessage(call.callStatus),
                        const Text(' | '),
                        Expanded(
                          child: Text(
                            call.createdAt.formatDateTime,
                            style: Theme.of(context).textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Call back button
              IconButton(
                onPressed: () => CallHelper.makeCall(
                  isVideo: call.callType == CallType.video,
                  user: call.receiver,
                ),
                icon: Icon(
                  call.callType == CallType.video ? IconlyBold.video : IconlyBold.call,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
