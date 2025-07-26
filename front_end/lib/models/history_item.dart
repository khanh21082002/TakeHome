class HistoryItem {
  final String id;
  final String problem;
  final String date;

  HistoryItem({required this.id, required this.problem, required this.date});

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      problem: json['problem'] ?? '',
      date: json['date'] ?? '',
    );
  }
} 