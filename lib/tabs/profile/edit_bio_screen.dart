import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/api/user_api.dart';
import 'package:chat_messenger/components/custom_appbar.dart';
import 'package:chat_messenger/components/default_button.dart';
import 'package:chat_messenger/helpers/dialog_helper.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/routes/app_routes.dart';
import 'package:chat_messenger/helpers/routes_helper.dart';

class EditBioController extends GetxController {
  final RxBool isLoading = RxBool(false);
  final bioController = TextEditingController();
  final thoughtController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  final RxBool bioVisibleToAll = RxBool(true);
  final RxList<String> bioHiddenFromUsers = RxList<String>([]);
  final RxString currentThought = RxString('');
  final Rx<DateTime?> thoughtExpiresAt = Rx<DateTime?>(null);
  final Rx<Map<String, dynamic>?> currentMusic = Rx<Map<String, dynamic>?>(null);
  final Rx<DateTime?> musicExpiresAt = Rx<DateTime?>(null);

  @override
  void onInit() {
    super.onInit();
    final currentUser = AuthController.instance.currentUser;
    bioController.text = currentUser.bio;
    bioVisibleToAll.value = currentUser.bioVisibleToAll;
    bioHiddenFromUsers.value = List<String>.from(currentUser.bioHiddenFromUsers);
    
    // Verificar si el pensamiento aún es válido (no expirado)
    if (currentUser.thought.isNotEmpty && 
        currentUser.thoughtExpiresAt != null &&
        currentUser.thoughtExpiresAt!.isAfter(DateTime.now())) {
      currentThought.value = currentUser.thought;
      thoughtExpiresAt.value = currentUser.thoughtExpiresAt;
      thoughtController.text = currentUser.thought;
    }
    
    // Verificar si la música aún es válida (no expirada)
    if (currentUser.musicTrack != null && 
        currentUser.musicExpiresAt != null &&
        currentUser.musicExpiresAt!.isAfter(DateTime.now())) {
      currentMusic.value = Map<String, dynamic>.from(currentUser.musicTrack!);
      musicExpiresAt.value = currentUser.musicExpiresAt;
    }
    
    // Limitar el pensamiento a 80 caracteres
    thoughtController.addListener(() {
      if (thoughtController.text.length > 80) {
        thoughtController.text = thoughtController.text.substring(0, 80);
        thoughtController.selection = TextSelection.fromPosition(
          TextPosition(offset: thoughtController.text.length),
        );
      }
    });
  }

  @override
  void onClose() {
    bioController.dispose();
    thoughtController.dispose();
    super.onClose();
  }

  Future<void> selectContactsToHideBio() async {
    final List? selectedContacts = await RoutesHelper.toSelectContacts(
      title: 'Ocultar bio a'.tr,
      isBroadcast: false,
      showGroups: false,
    );
    
    if (selectedContacts != null && selectedContacts.isNotEmpty) {
      bioHiddenFromUsers.value = selectedContacts
          .whereType<User>()
          .map((user) => user.userId)
          .toList();
    }
  }

  Future<void> setThought() async {
    if (thoughtController.text.trim().isEmpty) {
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'El pensamiento no puede estar vacío'.tr,
      );
      return;
    }
    
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    currentThought.value = thoughtController.text.trim();
    thoughtExpiresAt.value = expiresAt;
    
    await _saveData();
  }

  Future<void> clearThought() async {
    currentThought.value = '';
    thoughtExpiresAt.value = null;
    thoughtController.clear();
    await _saveData();
  }

  Future<void> setMusicTrack({
    required String platform,
    required String trackId,
    required String trackName,
    required String artist,
    required String previewUrl,
  }) async {
    final expiresAt = DateTime.now().add(const Duration(hours: 24));
    currentMusic.value = {
      'platform': platform,
      'trackId': trackId,
      'trackName': trackName,
      'artist': artist,
      'previewUrl': previewUrl,
    };
    musicExpiresAt.value = expiresAt;
    
    await _saveData();
  }

  Future<void> clearMusic() async {
    currentMusic.value = null;
    musicExpiresAt.value = null;
    await _saveData();
  }

  Future<void> updateBio() async {
    if (!formKey.currentState!.validate()) return;
    await _saveData();
  }

  Future<void> _saveData() async {
    isLoading.value = true;

    try {
      final currentUser = AuthController.instance.currentUser;
      
      final data = {
        'bio': bioController.text.trim(),
        'bioVisibleToAll': bioVisibleToAll.value,
        'bioHiddenFromUsers': bioHiddenFromUsers.toList(),
        'thought': currentThought.value,
        'thoughtExpiresAt': thoughtExpiresAt.value?.millisecondsSinceEpoch,
        'musicTrack': currentMusic.value,
        'musicExpiresAt': musicExpiresAt.value?.millisecondsSinceEpoch,
      };
      
      await UserApi.updateUserData(
        userId: currentUser.userId,
        data: data,
      );

      // Actualizar el usuario local
      currentUser.bio = bioController.text.trim();
      currentUser.bioVisibleToAll = bioVisibleToAll.value;
      currentUser.bioHiddenFromUsers = bioHiddenFromUsers.toList();
      currentUser.thought = currentThought.value;
      currentUser.thoughtExpiresAt = thoughtExpiresAt.value;
      currentUser.musicTrack = currentMusic.value;
      currentUser.musicExpiresAt = musicExpiresAt.value;

      isLoading.value = false;

      Get.back();
      DialogHelper.showSnackbarMessage(
        SnackMsgType.success,
        'account_updated_successfully'.tr,
      );
    } catch (e) {
      isLoading.value = false;
      DialogHelper.showSnackbarMessage(
        SnackMsgType.error,
        'Error al actualizar: $e',
      );
    }
  }
}

class EditBioScreen extends StatelessWidget {
  const EditBioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EditBioController controller = Get.put(EditBioController());
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: CustomAppBar(
        title: Text('Bio'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
            onPressed: () => _showPrivacyBottomSheet(context, controller, isDarkMode),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Bio text field
                TextFormField(
                  maxLines: 5,
                  controller: controller.bioController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'about_you'.tr,
                    hintStyle: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.info_outline,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    filled: isDarkMode,
                    fillColor: isDarkMode ? const Color(0xFF1E1E1E) : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDarkMode ? Colors.blue[400]! : primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Thoughts Section
                _buildSectionTitle('Pensamientos', isDarkMode),
                const SizedBox(height: 12),
                _buildThoughtSection(controller, isDarkMode),
                
                const SizedBox(height: 32),
                
                // Music Section
                _buildSectionTitle('Música', isDarkMode),
                const SizedBox(height: 12),
                _buildMusicSection(controller, isDarkMode),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: defaultPadding,
              vertical: 16,
            ),
            child: DefaultButton(
              height: 50,
              isLoading: controller.isLoading.value,
              width: double.maxFinite,
              text: 'UPDATE',
              onPress: () => controller.updateBio(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildThoughtSection(EditBioController controller, bool isDarkMode) {
    return Obx(() {
      final hasActiveThought = controller.currentThought.value.isNotEmpty &&
          controller.thoughtExpiresAt.value != null &&
          controller.thoughtExpiresAt.value!.isAfter(DateTime.now());
      
      return Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: isDarkMode ? Colors.blue[400] : primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pensamiento (24 horas)',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.thoughtController,
              maxLines: 2,
              maxLength: 80,
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Comparte un pensamiento...',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? Colors.blue[400]! : primaryColor,
                    width: 2,
                  ),
                ),
                counterStyle: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (hasActiveThought) ...[
              Text(
                'Expira: ${_formatExpirationTime(controller.thoughtExpiresAt.value!)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasActiveThought)
                  TextButton(
                    onPressed: () => controller.clearThought(),
                    child: Text(
                      'Eliminar',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: controller.thoughtController.text.trim().isEmpty
                      ? null
                      : () => controller.setThought(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Publicar'),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMusicSection(EditBioController controller, bool isDarkMode) {
    return Obx(() {
      final hasActiveMusic = controller.currentMusic.value != null &&
          controller.musicExpiresAt.value != null &&
          controller.musicExpiresAt.value!.isAfter(DateTime.now());
      
      return Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: isDarkMode ? Colors.blue[400] : primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Música (24 horas)',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasActiveMusic) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.currentMusic.value!['platform'] == 'spotify'
                          ? Icons.music_note
                          : Icons.library_music,
                      color: controller.currentMusic.value!['platform'] == 'spotify'
                          ? Colors.green[400]
                          : Colors.pink[400],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.currentMusic.value!['trackName'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            controller.currentMusic.value!['artist'] ?? '',
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red[400]),
                      onPressed: () => controller.clearMusic(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Expira: ${_formatExpirationTime(controller.musicExpiresAt.value!)}',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementar integración con Spotify
                        DialogHelper.showSnackbarMessage(
                          SnackMsgType.info,
                          'Integración con Spotify próximamente',
                        );
                      },
                      icon: Icon(Icons.music_note, size: 18),
                      label: Text('Spotify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementar integración con Apple Music
                        DialogHelper.showSnackbarMessage(
                          SnackMsgType.info,
                          'Integración con Apple Music próximamente',
                        );
                      },
                      icon: Icon(Icons.library_music, size: 18),
                      label: Text('Apple Music'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  String _formatExpirationTime(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  void _showPrivacyBottomSheet(
    BuildContext context,
    EditBioController controller,
    bool isDarkMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PrivacyBottomSheet(
        controller: controller,
        isDarkMode: isDarkMode,
      ),
    );
  }
}

class _PrivacyBottomSheet extends StatelessWidget {
  final EditBioController controller;
  final bool isDarkMode;

  const _PrivacyBottomSheet({
    required this.controller,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: isDarkMode ? Colors.blue[400] : primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Privacidad de Bio',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bio visibility toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => _buildSwitchTile(
              context: context,
              title: 'Mostrar bio a todos',
              subtitle: 'Permite que todos vean tu biografía',
              value: controller.bioVisibleToAll.value,
              onChanged: (value) {
                controller.bioVisibleToAll.value = value;
              },
              isDarkMode: isDarkMode,
            )),
          ),
          
          const SizedBox(height: 12),
          
          // Hide bio from specific contacts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => _buildListTile(
              context: context,
              title: 'Ocultar bio a contactos específicos',
              subtitle: controller.bioHiddenFromUsers.isEmpty
                  ? 'Ningún contacto seleccionado'
                  : '${controller.bioHiddenFromUsers.length} contacto(s) seleccionado(s)',
              icon: Icons.people_outline,
              onTap: () {
                Navigator.pop(context);
                controller.selectContactsToHideBio();
              },
              isDarkMode: isDarkMode,
            )),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: primaryColor,
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDarkMode ? Colors.blue[400] : primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: onTap,
      ),
    );
  }
}

