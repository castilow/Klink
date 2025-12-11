import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/theme/app_theme.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyAndSecurityScreen extends StatefulWidget {
  const PrivacyAndSecurityScreen({super.key});

  @override
  State<PrivacyAndSecurityScreen> createState() => _PrivacyAndSecurityScreenState();
}

class _PrivacyAndSecurityScreenState extends State<PrivacyAndSecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = AppTheme.of(context).isDarkMode;
    final AuthController authController = Get.find<AuthController>();
    final String userId = authController.currentUser.userId;

    return Scaffold(
      backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
      appBar: AppBar(
        backgroundColor: isDarkMode ? darkThemeBgColor : lightThemeBgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDarkMode ? Colors.white : Colors.black87,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Privacy and Security',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Privacy Section
              _buildPrivacySection(
                context,
                isDarkMode,
                'Profile Photo',
                'Control who can see your profile photo',
                Icons.account_circle,
                'showProfilePhoto',
                userId,
              ),
              
              const SizedBox(height: 20),
              
              // Bio Privacy Section
              _buildBioPrivacySection(
                context,
                isDarkMode,
                userId,
              ),
              
              const SizedBox(height: 20),
              
              // Calls Section
              _buildCallsSection(
                context,
                isDarkMode,
                userId,
              ),
              
              const SizedBox(height: 20),
              
              // Blocked Users Section
              _buildBlockedUsersSection(
                context,
                isDarkMode,
              ),
              
              const SizedBox(height: 20),
              
              // Two-Factor Authentication Section
              _buildTwoFactorSection(
                context,
                isDarkMode,
                userId,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection(
    BuildContext context,
    bool isDarkMode,
    String title,
    String description,
    IconData icon,
    String privacyKey,
    String userId,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // Toggle Switch
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final Map<String, dynamic>? data = snapshot.hasData 
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;
              final bool isEnabled = data?[privacyKey] ?? false;
              
              return SwitchListTile(
              value: isEnabled,
              onChanged: (value) async {
                await _updatePrivacySetting(
                  userId,
                  privacyKey,
                  value,
                );
              },
              title: Text(
                'Allow everyone to see',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                isEnabled 
                  ? 'Everyone can see your $title'
                  : 'Only your contacts can see your $title',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              activeColor: isDarkMode ? Colors.blue[400] : Colors.blue[600],
            );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBioPrivacySection(
    BuildContext context,
    bool isDarkMode,
    String userId,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.description,
                  color: isDarkMode ? Colors.green[400] : Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control who can see your bio',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // Bio Privacy Options
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final Map<String, dynamic>? data = snapshot.hasData 
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;
              final String bioPrivacy = data?['bioPrivacy'] ?? 'everyone';
              
              return Column(
              children: [
                RadioListTile<String>(
                  value: 'everyone',
                  groupValue: bioPrivacy,
                  onChanged: (value) async {
                    await _updatePrivacySetting(
                      userId,
                      'bioPrivacy',
                      value,
                    );
                  },
                  title: Text(
                    'Everyone',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Anyone can see your bio',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  activeColor: isDarkMode ? Colors.green[400] : Colors.green[600],
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  indent: 56,
                ),
                RadioListTile<String>(
                  value: 'contacts',
                  groupValue: bioPrivacy,
                  onChanged: (value) async {
                    await _updatePrivacySetting(
                      userId,
                      'bioPrivacy',
                      value,
                    );
                  },
                  title: Text(
                    'My Contacts',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Only your contacts can see your bio',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  activeColor: isDarkMode ? Colors.green[400] : Colors.green[600],
                ),
                Divider(
                  height: 1,
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  indent: 56,
                ),
                RadioListTile<String>(
                  value: 'nobody',
                  groupValue: bioPrivacy,
                  onChanged: (value) async {
                    await _updatePrivacySetting(
                      userId,
                      'bioPrivacy',
                      value,
                    );
                  },
                  title: Text(
                    'Nobody',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'No one can see your bio',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  activeColor: isDarkMode ? Colors.green[400] : Colors.green[600],
                ),
              ],
            );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCallsSection(
    BuildContext context,
    bool isDarkMode,
    String userId,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.phone,
                  color: isDarkMode ? Colors.blue[400] : Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calls',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Control who can call you',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // Toggle Switch para activar/desactivar llamadas
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final Map<String, dynamic>? data = snapshot.hasData 
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;
              final bool allowCalls = data?['allowCalls'] ?? true;
              
              return SwitchListTile(
                value: allowCalls,
                onChanged: (value) async {
                  await _updatePrivacySetting(
                    userId,
                    'allowCalls',
                    value,
                  );
                },
                title: Text(
                  'Allow incoming calls',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  allowCalls 
                    ? 'You can receive calls'
                    : 'Calls are disabled',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                activeColor: isDarkMode ? Colors.blue[400] : Colors.blue[600],
              );
            },
          ),
          
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // Opción para seleccionar contactos específicos
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final Map<String, dynamic>? data = snapshot.hasData 
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;
              final List<dynamic> allowedContacts = data?['allowedCallContacts'] ?? [];
              final int contactCount = allowedContacts.length;
              
              return ListTile(
                leading: Icon(
                  Icons.people,
                  color: isDarkMode ? Colors.green[400] : Colors.green[600],
                  size: 24,
                ),
                title: Text(
                  'Specific contacts',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  contactCount > 0
                    ? '$contactCount contact${contactCount > 1 ? 's' : ''} selected'
                    : 'Select specific contacts who can call you',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  size: 16,
                ),
                onTap: () async {
                  // Navegar a la pantalla de selección de contactos
                  final selectedContacts = await Get.toNamed(
                    AppRoutes.selectContacts,
                    arguments: {
                      'title': 'Select contacts for calls',
                      'showGroups': false,
                    },
                  ) as List<dynamic>?;
                  
                  if (selectedContacts != null) {
                    // Guardar los IDs de los contactos seleccionados
                    final List<String> contactIds = selectedContacts
                        .whereType<User>()
                        .map((user) => user.userId)
                        .toList();
                    
                    await _updatePrivacySetting(
                      userId,
                      'allowedCallContacts',
                      contactIds,
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersSection(
    BuildContext context,
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.block,
          color: isDarkMode ? Colors.red[400] : Colors.red[600],
          size: 24,
        ),
        title: Text(
          'Blocked Users',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Manage blocked users',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          size: 16,
        ),
        onTap: () {
          Get.toNamed(AppRoutes.blockedAccount);
        },
      ),
    );
  }

  Widget _buildTwoFactorSection(
    BuildContext context,
    bool isDarkMode,
    String userId,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.security,
                  color: isDarkMode ? Colors.orange[400] : Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add an extra layer of security to your account',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
          ),
          
          // Toggle Switch
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(userId)
                .snapshots(),
            builder: (context, snapshot) {
              final Map<String, dynamic>? data = snapshot.hasData 
                  ? snapshot.data!.data() as Map<String, dynamic>?
                  : null;
              final bool isEnabled = data?['twoFactorEnabled'] ?? false;
              
              return SwitchListTile(
              value: isEnabled,
              onChanged: (value) async {
                if (value) {
                  // Mostrar diálogo de confirmación
                  final confirmed = await Get.dialog<bool>(
                    AlertDialog(
                      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      title: Text(
                        'Enable Two-Factor Authentication',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      content: Text(
                        'This will add an extra layer of security to your account. You will need to verify your identity with a code when logging in.',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.back(result: true),
                          child: Text(
                            'Enable',
                            style: TextStyle(
                              color: isDarkMode ? Colors.orange[400] : Colors.orange[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await _updatePrivacySetting(
                      userId,
                      'twoFactorEnabled',
                      true,
                    );
                    Get.snackbar(
                      'Two-Factor Authentication',
                      'Two-factor authentication has been enabled',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      colorText: isDarkMode ? Colors.white : Colors.black87,
                    );
                  }
                } else {
                  await _updatePrivacySetting(
                    userId,
                    'twoFactorEnabled',
                    false,
                  );
                }
              },
              title: Text(
                'Enable Two-Factor Authentication',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                isEnabled 
                  ? 'Two-factor authentication is active'
                  : 'Two-factor authentication is disabled',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              activeColor: isDarkMode ? Colors.orange[400] : Colors.orange[600],
            );
            },
          ),
        ],
      ),
    );
  }


  Future<void> _updatePrivacySetting(
    String userId,
    String key,
    dynamic value,
  ) async {
    try {
      await UserApi.updateUserData(
        userId: userId,
        data: {key: value},
        isSet: true,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update privacy setting: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[800],
        colorText: Colors.white,
      );
    }
  }
}

