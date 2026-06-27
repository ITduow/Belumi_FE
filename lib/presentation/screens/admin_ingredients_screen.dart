import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class AdminIngredientsScreen extends StatefulWidget {
  const AdminIngredientsScreen({super.key, required this.repository, this.embedMode = false});

  final BelumiRepository repository;
  final bool embedMode;

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
    final copy = belumiCopy(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(copy.t('Xóa thành phần?', 'Delete ingredient?')),
        content: Text(
          copy.t('Xóa ${ingredient.nameInc} khỏi cơ sở dữ liệu thành phần.', 'Remove ${ingredient.nameInc} from the ingredient database.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(copy.t('Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(copy.t('Xóa', 'Delete')),
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
    
    final headerAction = LuxuryButton(
      label: copy.t('Thêm thành phần', 'New ingredient'),
      icon: Icons.add,
      onPressed: () => _openForm(),
    );

    final body = LuxuryPage(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.t('Dữ liệu thành phần', 'Ingredient Database'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: BelumiLuxury.black,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.t(
                      'Tạo, chỉnh sửa và tìm kiếm dữ liệu INCI dùng trong app.',
                      'Create, edit, and search INCI data used by the app.',
                    ),
                    style: const TextStyle(color: BelumiLuxury.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            headerAction,
          ],
        ),
        const SizedBox(height: 18),
        LuxuryPanel(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _reload(),
              decoration: InputDecoration(
                hintText: copy.t(
                  'Tìm theo INCI, tên, danh mục...',
                  'Search by INCI, name, category...',
                ),
                prefixIcon: const Icon(Icons.search, color: BelumiLuxury.muted),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF1DFD8)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFF1DFD8)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BelumiLuxury.ink, width: 1.5),
                ),
                suffixIcon: IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.arrow_forward, color: BelumiLuxury.ink),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
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
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }

            final result = snapshot.data;
            final ingredients = result?.items ?? const <Ingredient>[];
            if (ingredients.isEmpty) {
              return LuxuryPanel(
                child: Center(
                  child: Text(
                    copy.t('Chưa có thành phần nào.', 'No ingredients yet.'),
                    style: const TextStyle(color: BelumiLuxury.muted),
                  ),
                ),
              );
            }

            return LuxuryPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FixedColumnWidth(180), // INCI name
                        1: FixedColumnWidth(180), // Display name
                        2: FixedColumnWidth(120), // Category
                        3: FixedColumnWidth(300), // Description
                        4: FixedColumnWidth(125), // Actions
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.shade200,
                          width: 0.5,
                        ),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          children: [
                            _tHead(copy.t('Tên INCI', 'INCI Name')),
                            _tHead(copy.t('Tên hiển thị', 'Display Name')),
                            _tHead(copy.t('Danh mục', 'Category')),
                            _tHead(copy.t('Mô tả', 'Description')),
                            _tHead(copy.t('Hành động', 'Actions')),
                          ],
                        ),
                        ...ingredients.map((ingredient) {
                          return TableRow(
                            children: [
                              _tCell(ingredient.nameInc, bold: true),
                              _tCell(ingredient.name),
                              _tCell(ingredient.category),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Text(
                                  ingredient.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, height: 1.3, color: BelumiLuxury.black),
                                ),
                              ),
                              _tCellWidget(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: BelumiLuxury.ink),
                                      onPressed: () => _openForm(ingredient),
                                      tooltip: copy.t('Sửa', 'Edit'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _delete(ingredient),
                                      tooltip: copy.t('Xóa', 'Delete'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  _buildPaginationRow(
                    currentPage: 1,
                    totalPages: 1,
                    totalItems: ingredients.length,
                    onPrevious: null,
                    onNext: null,
                    t: copy.t,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );

    if (widget.embedMode) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.t('Dữ liệu thành phần', 'Ingredient Database')),
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: body,
    );
  }

  Padding _tHead(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(s,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1F1F2C))),
      );

  Padding _tCell(String s, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Text(s,
            style: TextStyle(
                fontSize: 12,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: color ?? const Color(0xFF1F1F2C))),
      );

  Padding _tCellWidget(Widget child) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: child,
      );

  Widget _buildPaginationRow({
    required int currentPage,
    required int totalPages,
    required int totalItems,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
    required String Function(String, String) t,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            t('Tổng số: $totalItems bản ghi', 'Total: $totalItems records'),
            style: const TextStyle(fontSize: 12, color: BelumiLuxury.muted),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left),
                tooltip: t('Trang trước', 'Previous Page'),
              ),
              Text(
                t('Trang $currentPage / $totalPages', 'Page $currentPage of $totalPages'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
                tooltip: t('Trang sau', 'Next Page'),
              ),
            ],
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

  String? _validateLinks(String? value) {
    final copy = belumiCopy(context);
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split('|');
    for (final p in parts) {
      final t = p.trim();
      if (t.isEmpty) continue;
      if (!t.startsWith('http://') && !t.startsWith('https://')) {
        return copy.t('Các liên kết phải bắt đầu bằng http:// hoặc https://', 'Links must start with http:// or https://');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F1F2C)),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: BelumiLuxury.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: BelumiLuxury.muted, fontSize: 13),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF1DFD8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF1DFD8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BelumiLuxury.ink, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label),
      validator: validator ?? (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }
}
