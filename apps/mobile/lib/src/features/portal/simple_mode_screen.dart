import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class SimpleModeScreen extends StatelessWidget {
  const SimpleModeScreen(
      {super.key,
      required this.title,
      required this.message,
      this.teen = false});
  final String title;
  final String message;
  final bool teen;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            EmptyState(
                icon: teen ? Icons.lock_person_outlined : Icons.star_rounded,
                title: title,
                message: message),
            const Spacer(),
            FilledButton(
                onPressed: () => context.pop(), child: const Text('Volver'))
          ])));
}
