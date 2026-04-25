import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.checklist_rtl_rounded,
      'title': 'Rotina Organizada',
      'desc':
          'Crie tarefas diárias, separe por turnos e acompanhe o progresso de forma simples.',
    },
    {
      'icon': Icons.star_rounded,
      'title': 'Sistema de XP',
      'desc':
          'Ganhe pontos ao cumprir tarefas. O esforço se transforma em conquistas!',
    },
    {
      'icon': Icons.timer_rounded,
      'title': 'Controle de Tela',
      'desc':
          'Veja o tempo de uso, os apps favoritos e crie limites saudáveis.',
    },
    {
      'icon': Icons.security_rounded,
      'title': 'Modo Monitoramento',
      'desc': 'Instale no aparelho da criança de forma transparente e segura.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.chooseMode,
                ),
                child: const Text('Pular', style: TextStyle(fontSize: 16)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _slides[index]['icon'],
                          size: 120,
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _slides[index]['title'],
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _slides[index]['desc'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_currentPage == _slides.length - 1) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.chooseMode,
                        );
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _slides.length - 1
                          ? 'Começar'
                          : 'Próximo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
