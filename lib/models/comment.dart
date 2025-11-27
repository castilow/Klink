import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_messenger/models/user.dart';

class Comment {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final User? user; // For display purposes

  Comment({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.user,
  });

  factory Comment.fromMap(Map<String, dynamic> data, String docId) {
    return Comment(
      id: docId,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Comment copyWith({
    String? id,
    String? userId,
    String? text,
    DateTime? createdAt,
    User? user,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }
}
