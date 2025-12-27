import 'dart:io';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chat_messenger/config/theme_config.dart';
import 'package:chat_messenger/models/sticker.dart';
import 'package:chat_messenger/screens/messages/controllers/sticker_controller.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class StickerPickerScreen extends StatefulWidget {
  const StickerPickerScreen({super.key, this.onStickerSent});

  final VoidCallback? onStickerSent;

  @override
  State<StickerPickerScreen> createState() => _StickerPickerScreenState();
}

class _StickerPickerScreenState extends State<StickerPickerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StickerController stickerController = Get.put(StickerController());
  final TextEditingController _searchController = TextEditingController();
  final RxInt _selectedCategoryIndex = 0.obs;
  
  // Premium Colors
  final Color _glassColorLight = Colors.white.withOpacity(0.85);
  final Color _glassColorDark = const Color(0xFF1E1E1E).withOpacity(0.85);
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      stickerController.searchStickers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? _glassColorDark : _glassColorLight;
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), // More rounded
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Heavy blur for premium glass feel
        child: Container(
          // height: MediaQuery.of(context).size.height * 0.4, // Removed to fit parent container
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header & Search
              _buildHeader(isDark),
              
              // Custom Tabs
              _buildCustomTabs(isDark),
              
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildStickersTab(isDark),
                    _buildCreateStickerTab(isDark),
                    _buildMyStickersTab(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), // Reduced bottom padding
      child: Container(
        height: 40, // Height 50 -> 40
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12), // Radius 16 -> 12
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              IconlyLight.search,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 18, // Size 20 -> 18
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search stickers...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                    fontSize: 14, // Font 16 -> 14
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero, // Keep zero
                  isDense: true,
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14, // Font 16 -> 14
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                  stickerController.searchStickers('');
                },
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabs(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), // Vertical 8 -> 4
      height: 36, // Height 44 -> 36
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10), // Radius 14 -> 10
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF3A3A3C) : Colors.white,
          borderRadius: BorderRadius.circular(8), // Radius 12 -> 8
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(3), // Padding 4 -> 3
        labelColor: isDark ? Colors.white : Colors.black,
        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), // Font 13 -> 12
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12), // Font 13 -> 12
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Stickers'),
          Tab(text: 'Create'),
          Tab(text: 'My Pack'),
        ],
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildStickersTab(bool isDark) {
    return Obx(() {
      if (stickerController.searchQuery.value.isNotEmpty) {
        return _buildSearchResults(isDark);
      }
      
      return Column(
        children: [
          // Horizontal Categories
          SizedBox(
            height: 40, // Height 48 -> 40
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCategoryChip('Recent', 0, isDark),
                // Agregar categoría "Mis Stickers" si hay stickers personalizados
                if (stickerController.customStickers.isNotEmpty)
                  Obx(() => _buildCategoryChip('Mis Stickers', 999, isDark)), // Usar 999 como ID especial
                ...stickerController.stickerPacks.asMap().entries.map((entry) {
                  return _buildCategoryChip(entry.value.name, entry.key + 1, isDark);
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 4), // Space 8 -> 4

          // Grid
          Expanded(
            child: Obx(() {
              if (_selectedCategoryIndex.value == 0) {
                return _buildRecentStickers(isDark);
              }
              
              // Categoría "Mis Stickers" (índice 999)
              if (_selectedCategoryIndex.value == 999) {
                return _buildMyStickersTab(isDark);
              }
              
              // Ajustar el índice para los packs normales
              // Si hay "Mis Stickers", el índice se desplaza por 2 (Recent + Mis Stickers), sino por 1 (solo Recent)
              final hasMyStickers = stickerController.customStickers.isNotEmpty;
              final packIndex = _selectedCategoryIndex.value - (hasMyStickers ? 2 : 1);
              
              if (packIndex >= 0 && packIndex < stickerController.stickerPacks.length) {
                final pack = stickerController.stickerPacks[packIndex];
                if (pack.stickers.isEmpty) {
                  return _buildEmptyState('No stickers in this pack', isDark);
                }
                return _buildStickerPack(pack, isDark);
              }
              
              return _buildEmptyState('No stickers available', isDark);
            }),
          ),
        ],
      );
    });
  }

  Widget _buildCategoryChip(String label, int index, bool isDark) {
    return Obx(() {
      final isSelected = _selectedCategoryIndex.value == index;
      final selectedColor = primaryColor;
      
      return GestureDetector(
        onTap: () => _selectedCategoryIndex.value = index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6), // Vertical 8 -> 6
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // Padding 16/6 -> 12/4
          decoration: BoxDecoration(
            color: isSelected 
                ? selectedColor 
                : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(16), // Radius 20 -> 16
            border: Border.all(
              color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : Colors.black12),
              width: 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: selectedColor.withOpacity(0.4),
                blurRadius: 6, // 8 -> 6
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12, // Font 13 -> 12
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildRecentStickers(bool isDark) {
    return Obx(() {
      if (stickerController.recentStickers.isEmpty) {
        return _buildEmptyState('No recent stickers', isDark);
      }
      
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16), // Padding 20 -> 16
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5, // 5 columns (Standard size)
          crossAxisSpacing: 12, // 16 -> 12
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: stickerController.recentStickers.length,
        itemBuilder: (context, index) {
          final sticker = stickerController.recentStickers[index];
          return _buildStickerItem(sticker, isDark);
        },
      );
    });
  }

  Widget _buildStickerPack(StickerPack pack, bool isDark) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16), // 20 -> 16
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // 5 columns
        crossAxisSpacing: 12, // 16 -> 12
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: pack.stickers.length,
      itemBuilder: (context, index) {
        final sticker = pack.stickers[index];
        return _buildStickerItem(sticker, isDark);
      },
    );
  }

  Widget _buildStickerItem(Sticker sticker, bool isDark) {
    return GestureDetector(
      onTap: () => _sendSticker(sticker),
      child: HoverScaleEffect( // Assuming we can make a simple scale effect or just use container
        child: Container(
          decoration: const BoxDecoration(), // Clean container
          child: _buildStickerImage(sticker),
        ),
      ),
    );
  }

  Widget _buildStickerImage(Sticker sticker) {
    // Emoji
    if (sticker.emoji != null && sticker.url == sticker.emoji) {
      return Center(
        child: Text(
          sticker.emoji!,
          style: const TextStyle(fontSize: 48), // Larger font (38 -> 48)
        ),
      );
    }
    
    // Local File
    if (sticker.url.startsWith('/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(sticker.url),
          fit: BoxFit.contain,
          errorBuilder: (_,__,___) => const Icon(Icons.error_outline, size: 20),
        ),
      );
    }
    
    // SVG Remote (OpenMoji) - usar PNG para mejor compatibilidad
    if (sticker.url.toLowerCase().endsWith('.svg')) {
      // Convertir URL SVG a PNG para mejor visualización
      final String hexcode = sticker.url.split('/').last.replaceAll('.svg', '');
      final String pngUrl = 'https://openmoji.org/data/color/618x618/$hexcode.png';
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.transparent,
          padding: const EdgeInsets.all(4),
          child: CachedNetworkImage(
            imageUrl: pngUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.withOpacity(0.5))
              ),
            ),
            errorWidget: (context, url, error) {
              // Fallback a SVG si PNG falla
              return Container(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.network(
                  sticker.url,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => Center(
                    child: SizedBox(
                      width: 16, 
                      height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.withOpacity(0.5))
                    ),
                  ),
                ),
              );
            },
            memCacheWidth: 200,
          ),
        ),
      );
    }

    // Standard Remote Image (PNG/GIF)
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(4),
        child: CachedNetworkImage(
          imageUrl: sticker.url,
          fit: BoxFit.contain,
          placeholder: (context, url) => Center(
            child: SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.withOpacity(0.5))
            ),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 20, color: Colors.grey),
          memCacheWidth: 200,
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    return Obx(() {
      if (stickerController.searchResults.isEmpty) {
        return _buildEmptyState('No stickers found', isDark);
      }
      
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: stickerController.searchResults.length,
        itemBuilder: (context, index) {
          final sticker = stickerController.searchResults[index];
          return _buildStickerItem(sticker, isDark);
        },
      );
    });
  }

  Widget _buildEmptyState(String text, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(IconlyLight.paper, size: 48, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: isDark ? Colors.grey[500] : Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateStickerTab(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16), // Reduced padding 24->16
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(IconlyBold.image, size: 32, color: primaryColor), // Reduced size 40->32
            ),
            const SizedBox(height: 16), // Reduced space 24->16
            Text(
              'Create your own stickers',
              style: TextStyle(
                fontSize: 18, // Reduced font 20->18
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4), // Reduced space 8->4
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Turn your photos into expressive stickers instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, // Reduced font 14->13
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24), // Reduced space 32->24
            
            _buildActionButton(
              icon: IconlyBold.image,
              label: 'Choose from Gallery',
              isPrimary: true,
              onTap: _createStickerFromGallery,
              isDark: isDark,
            ),
            const SizedBox(height: 12), // Reduced space 16->12
             _buildActionButton(
              icon: IconlyBold.camera,
              label: 'Take a Photo',
              isPrimary: false,
              onTap: _createStickerFromCamera,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: isPrimary ? null : Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyStickersTab(bool isDark) {
    return Obx(() {
      if (stickerController.customStickers.isEmpty) {
        return _buildEmptyState('You haven\'t created any stickers yet', isDark);
      }
      
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: stickerController.customStickers.length,
        itemBuilder: (context, index) {
          final sticker = stickerController.customStickers[index];
          return _buildStickerItem(sticker, isDark);
        },
      );
    });
  }

  // --- Logic Methods (Kept largely the same but cleaned up) ---

  Future<void> _createStickerFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) await _processStickerFile(File(image.path));
    } catch (e) {
      Get.snackbar('Error', 'Could not select image', backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
    }
  }

  Future<void> _createStickerFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) await _processStickerFile(File(image.path));
    } catch (e) {
      Get.snackbar('Error', 'Could not take photo', backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
    }
  }

  Future<void> _processStickerFile(File file) async {
    try {
      // Show loading with a nice dialog
      Get.dialog(
        Center(child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
          child: const CircularProgressIndicator(color: Colors.white),
        )),
        barrierDismissible: false,
      );
      
      await stickerController.addCustomSticker(file);
      
      Get.back(); // Close loading
      
      Get.snackbar(
        'Success',
        'Sticker created!',
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      
      // Switch to "My Pack" tab
      _tabController.animateTo(2);
      
    } catch (e) {
      Get.back(); // Close loading
      Get.snackbar('Error', 'Could not create sticker', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _sendSticker(Sticker sticker) async {
    try {
      await stickerController.addToRecent(sticker);
      
      final MessageController? messageController = Get.find<MessageController>();
      if (messageController == null) return;
      
      // Local File
      if (sticker.url.startsWith('/')) {
        final File stickerFile = File(sticker.url);
        if (await stickerFile.exists()) {
          await messageController.sendMessage(MessageType.image, file: stickerFile);
          // Cerrar picker y notificar al callback si existe
          if (widget.onStickerSent != null) {
            widget.onStickerSent!();
          } else {
            Get.back(); // Cerrar el picker (si se abrió como modal)
          }
          return;
        }
      }
      
      // Emoji
      if (sticker.emoji != null && sticker.url == sticker.emoji) {
        await messageController.sendMessage(MessageType.text, text: sticker.emoji!);
        // Cerrar picker y notificar al callback si existe
        if (widget.onStickerSent != null) {
          widget.onStickerSent!();
        } else {
          Get.back(); // Cerrar el picker (si se abrió como modal)
        }
        return;
      }
      
      // Remote URL
      if (sticker.url.startsWith('http')) {
        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
        
        try {
          // Si es SVG, convertir a PNG usando OpenMoji PNG CDN (mayor resolución)
          String downloadUrl = sticker.url;
          if (sticker.url.toLowerCase().endsWith('.svg')) {
            // Convertir URL de SVG a PNG usando OpenMoji PNG CDN
            // Usar 1024x1024 para mejor calidad en lugar de 618x618
            // Ejemplo: https://openmoji.org/data/color/svg/1F600.svg -> https://openmoji.org/data/color/1024x1024/1F600.png
            final String hexcode = sticker.url.split('/').last.replaceAll('.svg', '');
            downloadUrl = 'https://openmoji.org/data/color/1024x1024/$hexcode.png';
          }
          
          final response = await http.get(Uri.parse(downloadUrl)).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            // Validar que los bytes sean una imagen válida
            final bytes = response.bodyBytes;
            if (bytes.isEmpty) {
              Get.back();
              Get.snackbar('Error', 'Imagen vacía');
              return;
            }
            
            final Directory tempDir = await getTemporaryDirectory();
            final String extension = downloadUrl.contains('.gif') ? 'gif' : 'png';
            final String fileName = '${DateTime.now().millisecondsSinceEpoch}_sticker.$extension';
            final File stickerFile = File('${tempDir.path}/$fileName');
            await stickerFile.writeAsBytes(bytes);
            
            // Verificar que el archivo se creó correctamente
            if (!await stickerFile.exists() || await stickerFile.length() == 0) {
              Get.back();
              Get.snackbar('Error', 'No se pudo guardar el sticker');
              return;
            }
            
            Get.back(); // Close loading
            await messageController.sendMessage(MessageType.image, file: stickerFile);
            // Cerrar picker y notificar al callback si existe
            if (widget.onStickerSent != null) {
              widget.onStickerSent!();
            } else {
              Get.back(); // Close picker (si se abrió como modal)
            }
          } else {
             Get.back();
             Get.snackbar('Error', 'No se pudo descargar el sticker');
          }
        } catch (e) {
          Get.back();
          debugPrint('Error downloading sticker: $e');
          Get.snackbar('Error', 'Error de red al descargar sticker');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not send sticker');
    }
  }
}

// Simple helper for hover effect (Flutter web mainly, but good structure)
class HoverScaleEffect extends StatefulWidget {
  final Widget child;
  const HoverScaleEffect({super.key, required this.child});

  @override
  State<HoverScaleEffect> createState() => _HoverScaleEffectState();
}

class _HoverScaleEffectState extends State<HoverScaleEffect> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
