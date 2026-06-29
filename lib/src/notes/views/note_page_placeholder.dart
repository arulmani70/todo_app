import 'package:flutter/material.dart';

class NotePagePlaceholder extends StatelessWidget {
  const NotePagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes'), backgroundColor: Theme.of(context).colorScheme.primary, foregroundColor: Theme.of(context).colorScheme.surface),
      body: const Center(child: Text('Desktop/Tablet view coming soon', style: TextStyle(color: Colors.grey))),
    );
  }
}
