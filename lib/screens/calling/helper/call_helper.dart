import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:get/get.dart';

abstract class CallHelper {
  /// Inicia una llamada (audio o video)
  static void makeCall({
    required bool isVideo,
    required User user,
  }) {
    Get.toNamed(
      AppRoutes.call,
      arguments: {
        'user': user,
        'isIncoming': false,
        'isVideo': isVideo,
      },
    );
  }
}




