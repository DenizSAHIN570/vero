import 'package:equatable/equatable.dart';

/// Represents a single message in the conversation history.
class Message extends Equatable {
  final String role;    // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;

  const Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory Message.user(String content) => Message(
        role: 'user',
        content: content,
        timestamp: DateTime.now(),
      );

  factory Message.assistant(String content) => Message(
        role: 'assistant',
        content: content,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };

  @override
  List<Object?> get props => [role, content, timestamp];
}
