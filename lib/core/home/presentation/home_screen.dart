import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('USB Camera Detection')),
      body: Center(
        child: Text(
          'USB Camera Detection',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
      ),
    );
  }
}
