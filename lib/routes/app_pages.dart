// Application Routes Configuration

import 'package:get/get.dart';
import 'package:flutter/animation.dart';

// Screen Imports
import 'package:chat_messenger/screens/splash/splash_screen.dart';
import 'package:chat_messenger/screens/dashboard_screen.dart';
import 'package:chat_messenger/screens/investment_screen.dart';
import 'package:chat_messenger/screens/auth/signin-or-signup/signin_or_signup_screen.dart';
import 'package:chat_messenger/screens/auth/signin/signin_screen.dart';
import 'package:chat_messenger/screens/auth/signup/signup_screen.dart';
import 'package:chat_messenger/screens/auth/password/forgot_password_screen.dart';
import 'package:chat_messenger/screens/auth/signup/controllers/signup_controller.dart';
import 'package:chat_messenger/screens/auth/signin/controller/signin_controller.dart';
import 'package:chat_messenger/screens/auth/signup/signup_with_email_screen.dart';
import 'package:chat_messenger/screens/auth/signup/verify_email_screen.dart';
import 'package:chat_messenger/screens/home/home_screen.dart';
import 'package:chat_messenger/screens/record-video/record_video_screen.dart';
import 'package:chat_messenger/screens/messages/message_screen.dart';
import 'package:chat_messenger/screens/session/session_screen.dart';
import 'package:chat_messenger/screens/about/about_screen.dart';
import 'package:chat_messenger/screens/blocked/blocked_account_screen.dart';
import 'package:chat_messenger/screens/contacts/contacts_screen.dart';
import 'package:chat_messenger/screens/contacts/contact_search_screen.dart';
import 'package:chat_messenger/screens/contacts/select_contacts_screen.dart';
import 'package:chat_messenger/tabs/groups/screens/create_group_screen.dart';
import 'package:chat_messenger/tabs/groups/screens/group_details_screen.dart';
import 'package:chat_messenger/tabs/groups/screens/edit_group_screen.dart';
import 'package:chat_messenger/tabs/stories/write_story_screen.dart';
import 'package:chat_messenger/tabs/stories/story_view_screen.dart';
import 'package:chat_messenger/screens/edit_profile_screen.dart';
import 'package:chat_messenger/tabs/profile/profile_view_screen.dart';
import 'package:chat_messenger/tabs/profile/profile_screen.dart';
import 'package:chat_messenger/tabs/profile/edit_bio_screen.dart';
import 'package:chat_messenger/screens/wallet/wallet_screen.dart';
import 'package:chat_messenger/screens/appearance_screen.dart';
import 'package:chat_messenger/screens/bubble_color_picker_screen.dart';
import 'package:chat_messenger/screens/text_size_screen.dart';
import 'package:chat_messenger/screens/chat_settings_screen.dart';
import 'package:chat_messenger/screens/data_storage_screen.dart';
import 'package:chat_messenger/screens/privacy_and_security_screen.dart';
import 'package:chat_messenger/screens/help/help_screen.dart';

import 'package:chat_messenger/screens/price_screen.dart';
import 'package:chat_messenger/screens/woop_dashboard_screen.dart';
import 'package:chat_messenger/screens/eth_dashboard_screen.dart';
import 'package:chat_messenger/screens/global_search_screen.dart';
import 'package:chat_messenger/screens/send_eth_screen.dart';
import 'package:chat_messenger/screens/receive_eth_screen.dart';
import 'package:chat_messenger/screens/call/call_screen.dart';

// Model Imports
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/models/group.dart';
import 'package:chat_messenger/models/story/story.dart';

// Binding Imports
import 'package:chat_messenger/screens/auth/signin/binding/signin_binding.dart';
import 'package:chat_messenger/screens/auth/signup/bindings/signup_binding.dart';
import 'package:chat_messenger/screens/auth/signup/bindings/signup_with_email_binding.dart';
import 'package:chat_messenger/screens/auth/password/binding/forgot_pwd_binding.dart';
import 'package:chat_messenger/screens/home/binding/home_binding.dart';

import 'app_routes.dart';

abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
      name: AppRoutes.signInOrSignUp,
      page: () => const SigninOrSignupScreen(),
    ),
    GetPage(
      name: AppRoutes.signIn,
      page: () => const SignInScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SignInController>(() => SignInController());
      }),
    ),
    GetPage(
      name: AppRoutes.signUp,
      binding: SignUpBinding(),
      page: () => const SignUpScreen(),
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      binding: ForgotPasswordBinding(),
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.signUpWithEmail,
      page: () => const SignUpWithEmailScreen(),
      binding: SignUpWithEmailBinding(),
    ),
    GetPage(name: AppRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(
      name: AppRoutes.home,
      binding: HomeBinding(),
      page: () => const HomeScreen(),

    ),
    GetPage(
      name: AppRoutes.wallet,
      page: () => const WalletScreen(),

    ),
    GetPage(
      name: AppRoutes.price,
      page: () => const PriceScreen(),

    ),
    GetPage(
      name: AppRoutes.woopDashboard,
      page: () => const WoopDashboardScreen(),

    ),
    GetPage(
      name: AppRoutes.ethDashboard,
      page: () => const EthDashboardScreen(),

    ),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardScreen(),

    ),
    GetPage(
      name: AppRoutes.investment,
      page: () => const InvestmentScreen(),

    ),
    GetPage(
      name: AppRoutes.sendEth,
      page: () => const SendEthScreen(),

    ),
    GetPage(
      name: AppRoutes.receiveEth,
      page: () => const ReceiveEthScreen(),

    ),
    GetPage(name: AppRoutes.recordVideo, page: () => RecordVideoScreen()),
    GetPage(
      name: AppRoutes.messages,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return MessageScreen(
          isGroup: args['isGroup'] as bool,
          user: args['user'] as User?,
          groupId: args['groupId'] as String?,
        );
      },
      // Transición de apertura del chat deslizándose hacia la izquierda (entrada desde la derecha)


    ),
    GetPage(name: AppRoutes.session, page: () => const SesssionScreen()),
    GetPage(name: AppRoutes.about, page: () => const AboutScreen()),
    GetPage(
      name: AppRoutes.blockedAccount,
      page: () => const BlockedAccountScreen(),
    ),
    GetPage(name: AppRoutes.contacts, page: () => const ContactsScreen()),
    GetPage(
      name: AppRoutes.contactSearch,
      page: () => const ContactSearchScreen(),
    ),
    GetPage(
      name: AppRoutes.selectContacts,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return SelectContactsScreen(
          title: args['title'] as String,
          showGroups: args['showGroups'] as bool? ?? false,
        );
      },
    ),
    GetPage(
      name: AppRoutes.createGroup,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final isBroadcast = args?['isBroadcast'] as bool? ?? false;
        return CreateGroupScreen(isBroadcast: isBroadcast);
      },
    ),
    GetPage(
      name: AppRoutes.groupDetails,
      page: () => const GroupDetailsScreen(),
    ),
    GetPage(
      name: AppRoutes.editGroup,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final group = args['group'] as Group;
        return EditGroupScreen(group: group);
      },
    ),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(
      name: AppRoutes.editProfile, 
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final user = args['user'] as User;
        return EditProfileScreen(user: user);
      },
    ),
    GetPage(
      name: AppRoutes.editBio,
      page: () => const EditBioScreen(),
    ),
    GetPage(
      name: AppRoutes.profileView,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return ProfileViewScreen(
          user: args['user'] as User,
          isGroup: args['isGroup'] as bool,
        );
      },
    ),
    GetPage(name: AppRoutes.writeStory, page: () => const WriteStoryScreen()),
    GetPage(
      name: AppRoutes.storyView,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        final story = args['story'] as Story;
        return StoryViewScreen(story: story);
      },
    ),
    GetPage(
      name: AppRoutes.globalSearch,
      page: () => const GlobalSearchScreen(),

    ),
    GetPage(
      name: AppRoutes.call,
      page: () => const CallScreen(),

    ),
    GetPage(
      name: AppRoutes.appearance,
      page: () => const AppearanceScreen(),

    ),
    GetPage(
      name: AppRoutes.bubbleColorPicker,
      page: () => const BubbleColorPickerScreen(),

    ),
    GetPage(
      name: AppRoutes.textSize,
      page: () => const TextSizeScreen(),

    ),
    GetPage(
      name: AppRoutes.chatSettings,
      page: () => const ChatSettingsScreen(),

    ),
    GetPage(
      name: AppRoutes.dataStorage,
      page: () => const DataStorageScreen(),
    ),
    GetPage(
      name: AppRoutes.privacyAndSecurity,
      page: () => const PrivacyAndSecurityScreen(),
    ),
    GetPage(
      name: AppRoutes.help,
      page: () => const HelpScreen(),
    ),
  ];
}
