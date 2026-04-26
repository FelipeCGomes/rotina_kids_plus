import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/models/community_models.dart';
import '../../../data/services/community_providers.dart';
import '../../../data/services/auth_provider.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages(
      'pt_BR',
      timeago.PtBrMessages(),
    ); // Formata datas para "há 5 min"
  }

  void _showCreatePostModal() {
    final contentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nova Publicação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Compartilhe uma dica ou faça uma pergunta...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final content = contentController.text.trim();
                if (content.isEmpty) return;

                final user = ref.read(authStateProvider).value;
                if (user != null) {
                  final post = PostModel(
                    id: '',
                    authorId: user.uid,
                    authorName: user.displayName ?? 'Pai/Mãe',
                    content: content,
                    createdAt: DateTime.now(),
                  );
                  await ref.read(communityServiceProvider).addPost(post);
                }
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Publicar'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsStreamProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Comunidade de Pais')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePostModal,
        child: const Icon(Icons.edit),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text('Nenhuma publicação ainda. Seja o primeiro!'),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final isLiked = user != null && post.likedBy.contains(user.uid);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  timeago.format(
                                    post.createdAt,
                                    locale: 'pt_BR',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(post.content, style: const TextStyle(fontSize: 15)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              if (user != null) {
                                ref
                                    .read(communityServiceProvider)
                                    .toggleLike(post.id, user.uid, isLiked);
                              }
                            },
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            label: Text('${post.likedBy.length}'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                context.push('/post-details', extra: post),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text('${post.commentCount} Comentários'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
