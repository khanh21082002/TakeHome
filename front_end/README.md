import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _CounterDisplay(),
            _IncrementButton(),
          ],
        ),
      ),
    );
  }
}

class _CounterDisplay extends StatelessWidget {
  const _CounterDisplay();

  @override
  Widget build(BuildContext context) {
    return Text(
      'You have pushed the button this many times:',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}

class _IncrementButton extends StatelessWidget {
  const _IncrementButton({super.key});

  @override
  Widget build(BuildContext context) {
    final counter = context.findAncestorStateOfType<_MyHomePageState>()?._counter;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          context.findAncestorStateOfType<_MyHomePageState>()?._incrementCounter();
        },
        child: Text(
          'Increment',
          style: Theme.of(context).textTheme.button,
        ),
      ),
    );
  }
}