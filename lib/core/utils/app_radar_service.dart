import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // IMPORT NOVO: Para forçar a vibração!
import 'notification_service.dart';

class AppRadarService {
  // Padrão Singleton para garantir que o Radar não seja ligado duas vezes
  static final AppRadarService _instance = AppRadarService._internal();
  factory AppRadarService() => _instance;
  AppRadarService._internal();

  bool _isParentRadarOn = false;
  bool _isFirstLoad = true;

  bool _isChildRadarOn = false;
  bool _isFirstChildLoad = true;

  // =================================================================
  // RADAR DOS PAIS: Escuta se as crianças mandaram missões!
  // =================================================================
  void startParentRadar(List<String> childIds) {
    if (_isParentRadarOn || childIds.isEmpty) return;
    _isParentRadarOn = true;

    FirebaseFirestore.instance
        .collection('task_logs')
        .where('childId', whereIn: childIds)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          // Ignora o histórico antigo ao abrir o aplicativo
          if (_isFirstLoad) {
            _isFirstLoad = false;
            return;
          }

          for (var change in snapshot.docChanges) {
            // Só dispara se for uma tarefa NOVA (Adicionada agora)
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                NotificationService().showNotification(
                  id: data['taskId']
                      .hashCode, // Cria um ID único baseado na tarefa
                  title: 'Nova Missão Concluída! 🌟',
                  body:
                      'A missão "${data['taskTitle']}" foi enviada e está a aguardar a sua aprovação.',
                );
              }
            }
          }
        });
  }

  // =================================================================
  // RADAR DA CRIANÇA: Escuta os "Cutucões" (Lembretes) dos Pais!
  // =================================================================
  void startChildRadar(String childId) {
    if (_isChildRadarOn || childId.isEmpty) return;
    _isChildRadarOn = true;

    FirebaseFirestore.instance
        .collection('nudges')
        .where('childId', isEqualTo: childId)
        .snapshots()
        .listen((snapshot) {
          // Ignora os avisos antigos para não apitar tudo de uma vez ao abrir o tablet
          if (_isFirstChildLoad) {
            _isFirstChildLoad = false;
            return;
          }

          for (var change in snapshot.docChanges) {
            // Dispara APENAS quando o Pai aperta o botão agora!
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                // Força o tablet a vibrar duas vezes forte!
                HapticFeedback.heavyImpact();
                Future.delayed(
                  const Duration(milliseconds: 300),
                  () => HapticFeedback.heavyImpact(),
                );

                // Solta a notificação no topo do ecrã
                NotificationService().showNotification(
                  id: DateTime.now().millisecond,
                  title: '🔔 Lembrete dos Pais!',
                  body: 'Não te esqueças de: ${data['title']}!',
                );
              }
            }
          }
        });
  }
}
