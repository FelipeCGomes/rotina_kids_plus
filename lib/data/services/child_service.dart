import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

class ChildService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cria ou Atualiza um perfil
  Future<void> saveChild(ChildModel child) async {
    try {
      if (child.id.isEmpty) {
        // CRIAÇÃO: Gera novo ID
        DocumentReference docRef = _db.collection('children').doc();
        await docRef.set(child.toMap()..['id'] = docRef.id);
      } else {
        // EDIÇÃO: Usa o ID existente para sobrescrever
        await _db.collection('children').doc(child.id).update(child.toMap());
      }
    } catch (e) {
      print("Erro ao salvar criança: $e");
      rethrow;
    }
  }

  // Excluir Perfil
  Future<void> deleteChild(String childId) async {
    try {
      await _db.collection('children').doc(childId).delete();
      // Opcional: Deletar tarefas e prêmios vinculados a esse ID
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ChildModel>> getChildrenByParent(String parentId) {
    return _db
        .collection('children')
        .where('parentId', isEqualTo: parentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChildModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
