import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class AppRadarService {
  // Padrão Singleton para garantir que o Radar não seja ligado duas vezes
  static final AppRadarService _instance = AppRadarService._internal();
  factory AppRadarService() => _instance;
  AppRadarService._internal();

  bool _isParentRadarOn = false;
  bool _isFirstLoad = true;

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
          // A grande sacada: No primeiro milissegundo que a tela abre, o Firebase
          // cospe todo o histórico antigo. Nós ignoramos isso para não apitar coisas do passado!
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
                      'A missão "${data['taskTitle']}" foi enviada e está aguardando a sua aprovação.',
                );
              }
            }
          }
        });
  }
}
