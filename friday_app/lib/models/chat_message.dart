/// Represents a single message in the conversation log.
class ChatMessage {
  final int? id;
  final String role;       // 'user' | 'assistant'
  final String content;
  final DateTime timestamp;
  final int promptTokens;
  final int completionTokens;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.promptTokens = 0,
    this.completionTokens = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  int get totalTokens => promptTokens + completionTokens;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
      };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] as int?,
        role: map['role'] as String,
        content: map['content'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        promptTokens: map['prompt_tokens'] as int? ?? 0,
        completionTokens: map['completion_tokens'] as int? ?? 0,
      );

  ChatMessage copyWith({
    int? id,
    String? role,
    String? content,
    DateTime? timestamp,
    int? promptTokens,
    int? completionTokens,
  }) =>
      ChatMessage(
        id: id ?? this.id,
        role: role ?? this.role,
        content: content ?? this.content,
        timestamp: timestamp ?? this.timestamp,
        promptTokens: promptTokens ?? this.promptTokens,
        completionTokens: completionTokens ?? this.completionTokens,
      );
}
