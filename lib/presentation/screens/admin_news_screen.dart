import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  final _searchController = TextEditingController();
  String? _status;
  int _refresh = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _refresh++);

  Future<void> _openForm([BlogPost? post]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _NewsFormDialog(repository: widget.repository, post: post),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.t('Quản lý tin tức', 'News management')),
        leading: IconButton(
          onPressed: () => context.go('/admin'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: LuxuryPage(
        children: [
          LuxuryHero(
            title: copy.t('Tin tức Belumi', 'Belumi News'),
            subtitle: copy.t(
              'Tạo, chỉnh sửa, ẩn bài viết và theo dõi hiệu quả nội dung.',
              'Create, edit, hide articles and track content performance.',
            ),
            imageUrl:
                'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1200&q=80',
            actions: [
              LuxuryButton(
                label: copy.t('Thêm bài viết', 'New article'),
                icon: Icons.add,
                onPressed: () => _openForm(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, dynamic>>(
            future: widget.repository.adminNewsStatistics(),
            builder: (context, snapshot) {
              final data = snapshot.data ?? const <String, dynamic>{};
              return LuxuryPanel(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatTile(label: 'Total', value: data['total']),
                    _StatTile(label: 'Published', value: data['published']),
                    _StatTile(label: 'Draft', value: data['draft']),
                    _StatTile(label: 'Hidden', value: data['hidden']),
                    _StatTile(label: 'Views', value: data['totalViews']),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          LuxuryPanel(
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _reload(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: copy.t('Tìm bài viết admin', 'Search admin news'),
                    suffixIcon: IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(copy.t('Tất cả', 'All')),
                      selected: _status == null,
                      onSelected: (_) => setState(() => _status = null),
                    ),
                    ...const ['Draft', 'Published', 'Hidden'].map(
                      (status) => ChoiceChip(
                        label: Text(status),
                        selected: _status == status,
                        onSelected: (_) => setState(() => _status = status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _CategoryManager(repository: widget.repository),
          const SizedBox(height: 14),
          FutureBuilder<List<BlogPost>>(
            key: ValueKey('admin-news-$_refresh-$_status'),
            future: widget.repository.adminNews(
              status: _status,
              search: _searchController.text,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LuxuryPanel(child: LinearProgressIndicator());
              }
              if (snapshot.hasError) {
                return LuxuryPanel(
                  child: Text(
                    copy.t(
                      'Không tải được tin tức admin. Kiểm tra quyền admin.',
                      'Could not load admin news. Check admin permission.',
                    ),
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              final posts = snapshot.data ?? const <BlogPost>[];
              if (posts.isEmpty) {
                return LuxuryPanel(
                  child: Text(copy.t('Chưa có bài viết.', 'No articles yet.')),
                );
              }

              return Column(
                children: posts
                    .map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AdminNewsTile(
                          post: post,
                          onEdit: () => _openForm(post),
                          onHide: () async {
                            await widget.repository.deleteNews(post);
                            _reload();
                          },
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

class _CategoryManager extends StatefulWidget {
  const _CategoryManager({required this.repository});

  final BelumiRepository repository;

  @override
  State<_CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends State<_CategoryManager> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _refresh = 0;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.repository.createNewsCategory(
        name,
        _descriptionController.text.trim(),
      );
      _nameController.clear();
      _descriptionController.clear();
      setState(() => _refresh++);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = belumiCopy(context);
    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('Danh mục tin tức', 'News categories'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final fields = [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: copy.t('Tên danh mục', 'Category name'),
                  ),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: copy.t('Mô tả', 'Description'),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filled(
                    onPressed: _saving ? null : _addCategory,
                    icon: const Icon(Icons.add),
                  ),
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    fields[0],
                    const SizedBox(height: 10),
                    fields[1],
                    const SizedBox(height: 10),
                    fields[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 10),
                  Expanded(child: fields[1]),
                  const SizedBox(width: 10),
                  fields[2],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('categories-$_refresh'),
            future: widget.repository.adminNewsCategories(),
            builder: (context, snapshot) {
              final categories =
                  snapshot.data ?? const <Map<String, dynamic>>[];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final id = category['id']?.toString() ?? '';
                  final active = category['isActive'] as bool? ?? true;
                  return InputChip(
                    label: Text(category['name']?.toString() ?? 'Category'),
                    avatar: Icon(
                      active ? Icons.check_circle_outline : Icons.hide_source,
                      size: 17,
                    ),
                    onDeleted: id.isEmpty
                        ? null
                        : () async {
                            await widget.repository.deleteNewsCategory(id);
                            if (mounted) setState(() => _refresh++);
                          },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NewsFormDialog extends StatefulWidget {
  const _NewsFormDialog({required this.repository, this.post});

  final BelumiRepository repository;
  final BlogPost? post;

  @override
  State<_NewsFormDialog> createState() => _NewsFormDialogState();
}

class _NewsFormDialogState extends State<_NewsFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _summary;
  late final TextEditingController _content;
  late final TextEditingController _thumbnail;
  late final TextEditingController _category;
  late final TextEditingController _tags;
  late final TextEditingController _author;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    _title = TextEditingController(text: post?.title ?? '');
    _slug = TextEditingController(text: post?.slug ?? '');
    _summary = TextEditingController(text: post?.summary ?? '');
    _content = TextEditingController(text: post?.content ?? '');
    _thumbnail = TextEditingController(text: post?.coverImageUrl ?? '');
    _category = TextEditingController(text: post?.category ?? 'Skincare');
    _tags = TextEditingController(text: post?.tags.join(', ') ?? '');
    _author = TextEditingController(text: post?.author ?? 'Belumi Team');
    _status = post?.status ?? 'Published';
  }

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _summary.dispose();
    _content.dispose();
    _thumbnail.dispose();
    _category.dispose();
    _tags.dispose();
    _author.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final post = BlogPost(
      id: widget.post?.id ?? '',
      slug: _slug.text.trim(),
      title: _title.text.trim(),
      summary: _summary.text.trim(),
      content: _content.text.trim(),
      coverImageUrl: _thumbnail.text.trim().isEmpty
          ? null
          : _thumbnail.text.trim(),
      category: _category.text.trim(),
      tags: _tags.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      author: _author.text.trim(),
      status: _status,
      viewCount: widget.post?.viewCount ?? 0,
      likeCount: widget.post?.likeCount ?? 0,
      publishedAt: widget.post?.publishedAt ?? DateTime.now(),
      isActive: _status != 'Hidden',
    );

    try {
      if (widget.post == null) {
        await widget.repository.createNews(post);
      } else {
        await widget.repository.updateNews(post);
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
                  widget.post == null
                      ? copy.t('Thêm bài viết', 'New article')
                      : copy.t('Sửa bài viết', 'Edit article'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                _RequiredField(controller: _title, label: 'Title'),
                const SizedBox(height: 10),
                TextField(
                  controller: _slug,
                  decoration: const InputDecoration(labelText: 'Slug'),
                ),
                const SizedBox(height: 10),
                _RequiredField(
                  controller: _summary,
                  label: 'Summary',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _RequiredField(
                  controller: _content,
                  label: 'Content',
                  maxLines: 7,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _thumbnail,
                  decoration: const InputDecoration(labelText: 'Thumbnail URL'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RequiredField(
                        controller: _category,
                        label: 'Category',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RequiredField(
                        controller: _author,
                        label: 'Author',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _tags,
                  decoration: const InputDecoration(labelText: 'Tags'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const ['Draft', 'Published', 'Hidden']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
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
}

class _RequiredField extends StatelessWidget {
  const _RequiredField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }
}

class _AdminNewsTile extends StatelessWidget {
  const _AdminNewsTile({
    required this.post,
    required this.onEdit,
    required this.onHide,
  });

  final BlogPost post;
  final VoidCallback onEdit;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return LuxuryPanel(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 58,
            height: 58,
            child: Image.network(
              post.coverImageUrl ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  ColoredBox(color: Colors.grey.shade100),
            ),
          ),
        ),
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${post.category} · ${post.status} · ${post.viewCount} views',
          maxLines: 2,
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
              tooltip: 'Hide',
              onPressed: onHide,
              icon: const Icon(Icons.visibility_off_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BelumiLuxury.peach,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${value ?? 0}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
