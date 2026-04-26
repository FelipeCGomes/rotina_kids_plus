import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Como você quer usar o app?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Sou Pai/Responsável',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                onPressed: () => context.go('/parent-home'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                icon: const Icon(Icons.smart_toy),
                label: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Este é o dispositivo da Criança',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                onPressed: () => context.go('/child-home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
