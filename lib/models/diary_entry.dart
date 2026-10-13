enum Mood {
  happy('开心', '😄'),
  calm('平静', '😌'),
  tired('疲惫', '😴'),
  sad('低落', '😔'),
  anxious('焦虑', '😟');

  const Mood(this.label, this.emoji);
  final String label;
  final String emoji;
}

String dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
    required this.updatedAt,
  });

  final String id;
  final DateTime date;
  final String title;
  final String content;
  final Mood mood;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': dateKey(date),
    'title': title,
    'content': content,
    'mood': mood.name,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    title: json['title'] as String,
    content: json['content'] as String,
    mood: Mood.values.byName(json['mood'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}
