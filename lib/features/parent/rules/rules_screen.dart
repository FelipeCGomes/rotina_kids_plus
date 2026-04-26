import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/rule_model.dart';
import '../../../data/services/rule_providers.dart';
import '../../../data/services/auth_provider.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  // Abre o modal para criar ou editar uma regra
  void _showRuleForm(BuildContext context, {RuleModel? rule}) {
    final titleController = TextEditingController(text: rule?.title ?? '');
    final descController = TextEditingController(text: rule?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o modal suba junto com o teclado
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          // O padding bottom com viewInsets ajusta o espaço para o teclado não cobrir o botão
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  rule == null ? 'Nova Regra da Casa' : 'Editar Regra',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título da Regra (Ex: Sem telas na mesa)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição detalhada (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _saveRule(
                        rule?.id,
                        titleController.text,
                        descController.text,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Salvar Regra',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveRule(String? id, String title, String description) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final rule = RuleModel(
      id: id ?? '',
      parentId: user.uid,
      title: title.trim(),
      description: description.trim(),
    );

    if (id == null) {
      await ref.read(ruleServiceProvider).addRule(rule);
    } else {
      await ref.read(ruleServiceProvider).updateRule(rule);
    }
  }

  void _deleteRule(RuleModel rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover regra?'),
        content: Text('Deseja excluir "${rule.title}" dos combinados da casa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(ruleServiceProvider).deleteRule(rule.id);
              Navigator.pop(ctx);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(familyRulesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Regras da Casa')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRuleForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Regra'),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gavel, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum combinado cadastrado ainda.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    rule.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: rule.description.isNotEmpty
                      ? Text(rule.description)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showRuleForm(context, rule: rule),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _deleteRule(rule),
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
