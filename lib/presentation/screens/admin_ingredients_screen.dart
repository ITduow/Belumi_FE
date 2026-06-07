import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class AdminIngredientsScreen extends StatefulWidget {
  const AdminIngredientsScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<AdminIngredientsScreen> createState() => _AdminIngredientsScreenState();
}

class _AdminIngredientsScreenState extends State<AdminIngredientsScreen> {
  final _searchController = TextEditingController();
  int _refresh = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _refresh++);

  Future<void> _openForm([Ingredient? ingredient]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _IngredientFormDialog(
        repository: widget.repository,
        ingredient: ingredient,
      ),
    );
    if (saved == true) _reload();
  }

  Future<void> _delete(Ingredient ingredient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: Text(
          'Remove ${ingredient.nameInc} from the ingredient database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.deleteIngredient(ingredient);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.t('Quản lý thành phần', 'Ingredient management')),
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: LuxuryPage(
        children: [
          LuxuryHero(
            title: copy.t('Dữ liệu thành phần', 'Ingredient Database'),
            subtitle: copy.t(
              'Tạo, chỉnh sửa và tìm kiếm dữ liệu INCI dùng trong app.',
              'Create, edit, and search INCI data used by the app.',
            ),
            imageUrl:
                'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=1200&q=80',
            actions: [
              LuxuryButton(
                label: copy.t('Thêm thành phần', 'New ingredient'),
                icon: Icons.add,
                onPressed: () => _openForm(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LuxuryPanel(
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: copy.t(
                  'Tìm theo INCI, tên, danh mục',
                  'Search by INCI, name, category',
                ),
                suffixIcon: IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<IngredientListResult>(
            key: ValueKey('admin-ingredients-$_refresh'),
            future: widget.repository.searchIngredients(
              search: _searchController.text,
              pageSize: 100,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LuxuryPanel(child: LinearProgressIndicator());
              }
              if (snapshot.hasError) {
                return LuxuryPanel(
                  child: Text(
                    copy.t(
                      'Không tải được dữ liệu ingredient. Kiểm tra quyền admin và backend.',
                      'Could not load ingredients. Check admin permission and backend.',
                    ),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              final result = snapshot.data;
              final ingredients = result?.items ?? const <Ingredient>[];
              if (ingredients.isEmpty) {
                return LuxuryPanel(
                  child: Text(
                    copy.t('Chưa có thành phần.', 'No ingredients yet.'),
                  ),
                );
              }

              return Column(
                children: ingredients
                    .map(
                      (ingredient) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AdminIngredientTile(
                          ingredient: ingredient,
                          onEdit: () => _openForm(ingredient),
                          onDelete: () => _delete(ingredient),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IngredientFormDialog extends StatefulWidget {
  const _IngredientFormDialog({required this.repository, this.ingredient});

  final BelumiRepository repository;
  final Ingredient? ingredient;

  @override
  State<_IngredientFormDialog> createState() => _IngredientFormDialogState();
}

class _IngredientFormDialogState extends State<_IngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameInc;
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _links;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ingredient = widget.ingredient;
    _nameInc = TextEditingController(text: ingredient?.nameInc ?? '');
    _name = TextEditingController(text: ingredient?.name ?? '');
    _category = TextEditingController(text: ingredient?.category ?? '');
    _description = TextEditingController(text: ingredient?.description ?? '');
    _links = TextEditingController(text: ingredient?.links ?? '');
  }

  @override
  void dispose() {
    _nameInc.dispose();
    _name.dispose();
    _category.dispose();
    _description.dispose();
    _links.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final ingredient = Ingredient(
      id: widget.ingredient?.id ?? '',
      nameInc: _nameInc.text.trim(),
      name: _name.text.trim(),
      category: _category.text.trim(),
      description: _description.text.trim(),
      links: _links.text.trim(),
    );

    try {
      if (widget.ingredient == null) {
        await widget.repository.createIngredient(ingredient);
      } else {
        await widget.repository.updateIngredient(ingredient);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ingredient == null
                      ? copy.t('Thêm thành phần', 'New ingredient')
                      : copy.t('Sửa thành phần', 'Edit ingredient'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                _RequiredField(controller: _nameInc, label: 'INCI name'),
                const SizedBox(height: 10),
                _RequiredField(controller: _name, label: 'Display name'),
                const SizedBox(height: 10),
                _RequiredField(controller: _category, label: 'Category'),
                const SizedBox(height: 10),
                _RequiredField(
                  controller: _description,
                  label: 'Description',
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                _RequiredField(
                  controller: _links,
                  label: 'Links, separated by |',
                  maxLines: 3,
                  validator: _validateLinks,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(copy.t('Hủy', 'Cancel')),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(copy.t('Lưu', 'Save')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateLinks(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return 'Required';
    for (final link in raw.split('|').map((item) => item.trim())) {
      final uri = Uri.tryParse(link);
      if (uri == null || uri.host.isEmpty) {
        return 'Links must be valid HTTP/HTTPS URLs separated by |';
      }
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return 'Links must be valid HTTP/HTTPS URLs separated by |';
      }
    }
    return null;
  }
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }
}

class _AdminIngredientTile extends StatelessWidget {
  const _AdminIngredientTile({
    required this.ingredient,
    required this.onEdit,
    required this.onDelete,
  });

  final Ingredient ingredient;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return LuxuryPanel(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.science_outlined)),
        title: Text(
          ingredient.nameInc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${ingredient.name} - ${ingredient.category}\n${ingredient.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
