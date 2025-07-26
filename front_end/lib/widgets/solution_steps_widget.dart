import 'package:flutter/material.dart';

class SolutionStepsWidget extends StatelessWidget {
  final List<String> steps;
  const SolutionStepsWidget({Key? key, required this.steps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (context, index) => ListTile(
        leading: Text('${index + 1}'),
        title: Text(steps[index]),
      ),
    );
  }
} 