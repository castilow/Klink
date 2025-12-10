import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_messenger/api/best_friends_api.dart';
import 'package:chat_messenger/api/contact_api.dart';
import 'package:chat_messenger/models/user.dart';

class StorySettingsBottomSheet extends StatefulWidget {
  final Function(List<String> bestFriends, bool isVipOnly) onSave;
  final List<String> initialBestFriends;
  final bool initialIsVipOnly;

  const StorySettingsBottomSheet({
    super.key,
    required this.onSave,
    this.initialBestFriends = const [],
    this.initialIsVipOnly = false,
  });

  @override
  State<StorySettingsBottomSheet> createState() => _StorySettingsBottomSheetState();
}

class _StorySettingsBottomSheetState extends State<StorySettingsBottomSheet> {
  late List<String> selectedBestFriends;
  late bool isVipOnly;
  List<User> contacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    selectedBestFriends = List.from(widget.initialBestFriends);
    isVipOnly = widget.initialIsVipOnly;
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contactsList = await ContactApi.getContacts().first;
      setState(() {
        contacts = contactsList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _toggleBestFriend(String userId) {
    setState(() {
      if (selectedBestFriends.contains(userId)) {
        selectedBestFriends.remove(userId);
      } else {
        selectedBestFriends.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Configuración de Historia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // VIP Toggle
          SwitchListTile(
            title: const Text('Solo mejores amigos'),
            subtitle: const Text('Solo visible para personas seleccionadas'),
            value: isVipOnly,
            onChanged: (value) {
              setState(() {
                isVipOnly = value;
              });
            },
          ),
          
          // Best Friends Selection
          if (isVipOnly) ...[
            const SizedBox(height: 10),
            const Text(
              'Seleccionar mejores amigos:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No tienes contactos'),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected = selectedBestFriends.contains(contact.userId);
                    
                    return CheckboxListTile(
                      title: Text(contact.fullname),
                      subtitle: Text('@${contact.username}'),
                      value: isSelected,
                      onChanged: (value) => _toggleBestFriend(contact.userId),
                    );
                  },
                ),
              ),
          ],
          
          const SizedBox(height: 20),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(selectedBestFriends, isVipOnly);
                Get.back();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
























