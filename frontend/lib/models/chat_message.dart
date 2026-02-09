class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String role;
  final String content;
  final DateTime createdAt;

  factory ChatMessage.user(String content) => ChatMessage(
        role: 'user',
        content: content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        role: 'assistant',
        content: content,
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at']?.toString() ?? '';
    final createdAt = DateTime.tryParse(createdRaw) ?? DateTime.now();
    return ChatMessage(
      role: json['role']?.toString() ?? 'assistant',
      content: json['content']?.toString() ?? '',
      createdAt: createdAt,
    );
  }
}
