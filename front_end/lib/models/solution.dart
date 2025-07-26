class Solution {
  final String problem;
  final String solution;
  final List<String>? steps;

  Solution({required this.problem, required this.solution, this.steps});

  factory Solution.fromJson(Map<String, dynamic> json) {
    return Solution(
      problem: json['problem'] ?? '',
      solution: json['solution'] ?? '',
      steps: (json['steps'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
} 