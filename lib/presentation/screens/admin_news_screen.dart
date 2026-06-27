import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key, required this.repository, this.embedMode = false});

  final BelumiRepository repository;
  final bool embedMode;

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

  Future<void> _openForm([NewsArticle? post]) async {
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
    
    final headerAction = LuxuryButton(
      label: copy.t('Thêm bài viết', 'New article'),
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
                    copy.t('Quản lý tin tức', 'News Management'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: BelumiLuxury.black,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.t(
                      'Tạo, chỉnh sửa, ẩn bài viết và theo dõi hiệu quả nội dung.',
                      'Create, edit, hide articles and track content performance.',
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
        FutureBuilder<Map<String, dynamic>>(
          future: widget.repository.adminNewsStatistics(),
          builder: (context, snapshot) {
            final data = snapshot.data ?? const <String, dynamic>{};
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatTile(label: copy.t('Tổng số', 'Total'), value: data['total'], icon: Icons.collections_bookmark_outlined),
                _StatTile(label: copy.t('Đã đăng', 'Published'), value: data['published'], icon: Icons.public_outlined, color: Colors.teal),
                _StatTile(label: copy.t('Bản nháp', 'Draft'), value: data['draft'], icon: Icons.edit_note_outlined, color: Colors.orange),
                _StatTile(label: copy.t('Đã ẩn', 'Hidden'), value: data['hidden'], icon: Icons.visibility_off_outlined, color: Colors.red),
                _StatTile(label: copy.t('Lượt xem', 'Views'), value: data['totalViews'], icon: Icons.remove_red_eye_outlined, color: Colors.blue),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onSubmitted: (_) => _reload(),
                decoration: InputDecoration(
                  hintText: copy.t('Tìm bài viết...', 'Search articles...'),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(copy.t('Tất cả', 'All')),
                    selected: _status == null,
                    selectedColor: const Color(0xFFFFE8E0),
                    labelStyle: TextStyle(
                      color: _status == null ? BelumiLuxury.ink : Colors.black87,
                      fontWeight: _status == null ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  ...['Draft', 'Published', 'Hidden'].map(
                    (status) {
                      final isSel = _status == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSel,
                        selectedColor: const Color(0xFFFFE8E0),
                        labelStyle: TextStyle(
                          color: isSel ? BelumiLuxury.ink : Colors.black87,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _status = status),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _CategoryManager(repository: widget.repository),
        const SizedBox(height: 18),
        FutureBuilder<List<NewsArticle>>(
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
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
            }
            final posts = snapshot.data ?? const <NewsArticle>[];
            if (posts.isEmpty) {
              return LuxuryPanel(
                child: Center(
                  child: Text(
                    copy.t('Chưa có bài viết nào.', 'No articles yet.'),
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
                        0: FixedColumnWidth(80),  // Ảnh bìa
                        1: FixedColumnWidth(280), // Tiêu đề
                        2: FixedColumnWidth(120), // Danh mục
                        3: FixedColumnWidth(100), // Trạng thái
                        4: FixedColumnWidth(100), // Lượt xem
                        5: FixedColumnWidth(125), // Hành động
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
                            _tHead(copy.t('Hình ảnh', 'Cover')),
                            _tHead(copy.t('Tiêu đề', 'Title')),
                            _tHead(copy.t('Danh mục', 'Category')),
                            _tHead(copy.t('Trạng thái', 'Status')),
                            _tHead(copy.t('Lượt xem', 'Views')),
                            _tHead(copy.t('Hành động', 'Actions')),
                          ],
                        ),
                        ...posts.map((post) {
                          return TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Image.network(
                                      post.coverImageUrl ?? '',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: Colors.grey.shade100,
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                child: Text(
                                  post.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: BelumiLuxury.black,
                                  ),
                                ),
                              ),
                              _tCell(post.category),
                              _tCellWidget(
                                _buildStatusBadge(post.status),
                              ),
                              _tCell('${post.viewCount}'),
                              _tCellWidget(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: BelumiLuxury.ink),
                                      onPressed: () => _openForm(post),
                                      tooltip: copy.t('Sửa', 'Edit'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility_off_outlined, color: Colors.red),
                                      onPressed: () async {
                                        await widget.repository.deleteNews(post);
                                        _reload();
                                      },
                                      tooltip: copy.t('Ẩn', 'Hide'),
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
                    totalItems: posts.length,
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
        title: Text(copy.t('Quản lý tin tức', 'News Management')),
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

  Widget _buildStatusBadge(String status) {
    final t = belumiCopy(context).t;
    Color bg = Colors.grey.shade50;
    Color fg = Colors.grey.shade800;
    String label = status;

    final s = status.toLowerCase();

    if (s == 'paid' || s == 'mockpaid' || s == 'active' || s == 'resolved' || s == 'true') {
      bg = Colors.teal.shade50;
      fg = Colors.teal.shade800;
      label = s == 'true' || s == 'active'
          ? t('Hoạt động', 'Active')
          : (s == 'resolved' ? t('Đã xử lý', 'Resolved') : t('Thành công', 'Success'));
    } else if (s == 'pending' || s == 'inprogress' || s == 'draft') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      label = s == 'pending'
          ? t('Chờ xử lý', 'Pending')
          : (s == 'inprogress' ? t('Đang xử lý', 'In Progress') : t('Bản nháp', 'Draft'));
    } else if (s == 'new' || s == 'false' || s == 'blocked' || s == 'hidden') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade800;
      label = s == 'new'
          ? t('Yêu cầu mới', 'New')
          : (s == 'false' || s == 'blocked'
              ? t('Đã khóa', 'Blocked')
              : t('Bị ẩn', 'Hidden'));
    } else if (s == 'published') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
      label = t('Xuất bản', 'Published');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

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
    );
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
            copy.t('Danh mục tin tức', 'News Categories'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F1F2C)),
          ),
          const SizedBox(height: 14),
          Builder(
            builder: (context) {
              final compact = MediaQuery.sizeOf(context).width < 800;
              final fields = [
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration(copy.t('Tên danh mục', 'Category name')),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: _inputDecoration(copy.t('Mô tả', 'Description')),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton.filled(
                    onPressed: _saving ? null : _addCategory,
                    style: IconButton.styleFrom(
                      backgroundColor: BelumiLuxury.black,
                      foregroundColor: Colors.white,
                    ),
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
          const SizedBox(height: 14),
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
  final NewsArticle? post;

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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final post = NewsArticle(
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
                  widget.post == null
                      ? copy.t('Thêm bài viết', 'New article')
                      : copy.t('Sửa bài viết', 'Edit article'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F1F2C)),
                ),
                const SizedBox(height: 14),
                _RequiredField(controller: _title, label: 'Title'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _slug,
                  decoration: _inputDecoration('Slug'),
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
                TextFormField(
                  controller: _thumbnail,
                  decoration: _inputDecoration('Thumbnail URL'),
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
                TextFormField(
                  controller: _tags,
                  decoration: _inputDecoration('Tags'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: _inputDecoration('Status'),
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
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;

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
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, this.color});

  final String label;
  final Object? value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1DFD8)),
        boxShadow: [
          BoxShadow(
            color: BelumiLuxury.rose.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: BelumiLuxury.muted,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Icon(icon, size: 16, color: color ?? BelumiLuxury.ink),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${value ?? 0}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: BelumiLuxury.black,
            ),
          ),
        ],
      ),
    );
  }
}
