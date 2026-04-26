import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- Nova importação obrigatória
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  // Garante que os bindings do Flutter estejam prontos antes do Firebase
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // <-- Carrega o dicionário de datas (meses, dias) para Português antes de desenhar o app
  await initializeDateFormatting('pt_BR', null);

  runApp(const ProviderScope(child: RotinaKidsApp()));
}
