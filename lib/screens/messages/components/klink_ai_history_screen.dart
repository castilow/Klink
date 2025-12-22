import 'package:flutter/material.dart';
import 'package:chat_messenger/models/message.dart';
import 'package:chat_messenger/models/user.dart';
import 'package:chat_messenger/api/chat_api.dart'; // Assuming we can fetch messages
import 'package:chat_messenger/helpers/date_helper.dart';
import 'package:chat_messenger/controllers/auth_controller.dart';
import 'package:chat_messenger/controllers/klink_ai_chat_controller.dart';
import 'package:chat_messenger/screens/messages/controllers/message_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KlinkAIHistoryScreen extends StatefulWidget {
  final User user; // The AI User
  const KlinkAIHistoryScreen({super.key, required this.user});

  @override
  State<KlinkAIHistoryScreen> createState() => _KlinkAIHistoryScreenState();
}

class _KlinkAIHistoryScreenState extends State<KlinkAIHistoryScreen> {
  // Mock sessions for now, or processed from real messages
  // Since we don't have a direct API to get "sessions", we'll verify what we can do.
  // For this task, I'll create the UI and load the actual messages, then group them.
  
  bool isLoading = true;
  List<Map<String, dynamic>> conversations = []; // Lista de conversaciones con chatId y título

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Obtener todas las conversaciones de Klink AI (chats que empiezan con "klink_ai_")
    final currentUserId = AuthController.instance.currentUser.userId;
    
    try {
      // Obtener todos los chats del usuario
      final chatsSnapshot = await ChatApi.firestore
          .collection('Users/$currentUserId/Chats')
          .get();

      // Filtrar solo los chats de Klink AI (que empiezan con "klink_ai_")
      final klinkAIChats = chatsSnapshot.docs.where((doc) {
        return doc.id.startsWith('klink_ai_');
      }).toList();

      // Para cada chat, obtener el primer mensaje para el título
      List<Map<String, dynamic>> conversationsList = [];
      
      for (var chatDoc in klinkAIChats) {
        final chatId = chatDoc.id;
        final chatData = chatDoc.data();
        
        // Obtener el primer mensaje de esta conversación para el título
        final messagesSnapshot = await ChatApi.firestore
            .collection('Users/$currentUserId/Chats/$chatId/Messages')
            .orderBy('sentAt', descending: true)
            .limit(1)
            .get();
        
        String title = 'Nueva conversación';
        DateTime? lastMessageDate;
        
        if (messagesSnapshot.docs.isNotEmpty) {
          final firstMessage = Message.fromMap(
            isGroup: false,
            data: messagesSnapshot.docs.first.data(),
            docRef: messagesSnapshot.docs.first.reference,
          );
          
          if (firstMessage.textMsg.isNotEmpty) {
            title = firstMessage.textMsg.replaceAll('\n', ' ').trim();
            if (title.length > 35) {
              title = "${title.substring(0, 35)}...";
            }
          }
          
          lastMessageDate = firstMessage.sentAt;
        } else if (chatData['lastMsg'] != null) {
          title = chatData['lastMsg'].toString();
          if (title.length > 35) {
            title = "${title.substring(0, 35)}...";
          }
          if (chatData['sentAt'] != null) {
            lastMessageDate = (chatData['sentAt'] as Timestamp).toDate();
          }
        }
        
        conversationsList.add({
          'chatId': chatId,
          'title': title,
          'lastMessageDate': lastMessageDate,
        });
      }
      
      // Ordenar por fecha del último mensaje (más reciente primero)
      conversationsList.sort((a, b) {
        final dateA = a['lastMessageDate'] as DateTime?;
        final dateB = b['lastMessageDate'] as DateTime?;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        conversations = conversationsList;
        isLoading = false;
      });

    } catch (e) {
      debugPrint('Error loading AI history: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Historial de Chats", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : conversations.isEmpty 
              ? Center(child: Text("No hay historial disponible", style: TextStyle(color: Colors.white.withOpacity(0.5))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final chatId = conversation['chatId'] as String;
                    final title = conversation['title'] as String;
                    final lastMessageDate = conversation['lastMessageDate'] as DateTime?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Minimalist
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            // Establecer el chatId en el controlador
                            final klinkAIController = Get.find<KlinkAIChatController>();
                            klinkAIController.setChatId(chatId);
                            
                            // Recargar mensajes con el nuevo chatId
                            try {
                              final messageController = Get.find<MessageController>();
                              messageController.reloadMessages();
                            } catch (e) {
                              debugPrint('Error recargando mensajes: $e');
                            }
                            
                            // Volver a la pantalla de chat
                            Get.back(result: true);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            child: Row(
                              children: [
                                // Icon (ChatGPT style usually has a bubble icon)
                                Center(
                                  child: Icon(
                                    IconlyLight.chat, 
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Text Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      // Date / Meta
                                      Text(
                                        lastMessageDate != null
                                            ? DateFormat.yMMMd().format(lastMessageDate)
                                            : 'Sin fecha',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Arrow
                                Icon(
                                  Icons.arrow_forward_ios, 
                                  color: Colors.white.withOpacity(0.2), 
                                  size: 12
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
