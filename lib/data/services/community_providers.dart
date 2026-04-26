import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> addPost(PostModel post) async {
    DocumentReference docRef = _db.collection('community_posts').doc();
    await docRef.set(post.toMap()..['id'] = docRef.id);
  }

  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    final docRef = _db.collection('community_posts').doc(postId);
    if (isLiked) {
      // Remove o like
      await docRef.update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      // Adiciona o like
      await docRef.update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  Future<void> addComment(CommentModel comment) async {
    final batch = _db.batch();

    // 1. Cria o comentário
    DocumentReference commentRef = _db.collection('community_comments').doc();
    batch.set(commentRef, comment.toMap()..['id'] = commentRef.id);

    // 2. Atualiza a contagem de comentários no Post original
    DocumentReference postRef = _db
        .collection('community_posts')
        .doc(comment.postId);
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});

    await batch.commit();
  }
}

final communityServiceProvider = Provider<CommunityService>(
  (ref) => CommunityService(),
);

// Traz os posts ordenados do mais recente para o mais antigo
final postsStreamProvider = StreamProvider<List<PostModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('community_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList(),
      );
});

// Traz os comentários de um post específico
final commentsStreamProvider =
    StreamProvider.family<List<CommentModel>, String>((ref, postId) {
      return FirebaseFirestore.instance
          .collection('community_comments')
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((doc) => CommentModel.fromMap(doc.data(), doc.id))
                .toList(),
          );
    });
