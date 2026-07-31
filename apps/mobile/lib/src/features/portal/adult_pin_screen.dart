import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:habitar_design_system/design_system.dart';

class AdultPinScreen extends StatelessWidget {
  const AdultPinScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Espacio adulto')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const EmptyState(
                    icon: Icons.lock_outline,
                    title: 'Confirma el PIN adulto',
                    message:
                        'Las rutinas, hábitos y cambios familiares quedan protegidos.',
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => showAdultPin(context),
                    child: const Text('Ingresar PIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

void showAdultPin(BuildContext context) {
  final controller = TextEditingController();
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Ingresa el PIN adulto'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        decoration: const InputDecoration(labelText: 'PIN demo: 1234'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text != '1234') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN incorrecto')),
              );
              return;
            }
            Navigator.pop(dialogContext);
            context.go('/dashboard');
          },
          child: const Text('Entrar'),
        ),
      ],
    ),
  );
}
