import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform/picked_skin_image.dart';
import '../../core/services/ocr_service.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';
import 'ocr_camera_screen.dart';

class IngredientLookupScreen extends StatefulWidget {
  const IngredientLookupScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<IngredientLookupScreen> createState() => _IngredientLookupScreenState();
}

class _IngredientLookupScreenState extends State<IngredientLookupScreen> {
  final searchController = TextEditingController();
  final pasteController = TextEditingController(
    text:
        'Aqua, Niacinamide, Glycerin, Hyaluronic Acid, Ceramide NP, Fragrance',
  );
  int tab = 0;
  bool loading = false;
  String? error;
  PickedSkinImage? image;
  String? _ocrText; // Text extracted by OCR from image
  String? _imagePath; // File path of picked/captured image
  IngredientListResult? searchResult;
  IngredientScanResult? scan;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    searchController.dispose();
    pasteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        LuxuryHero(
          title: t('Tra cứu thành phần', 'Ingredient Lookup'),
          subtitle: t(
            'Tìm thành phần trong dữ liệu Belumi hoặc phân tích danh sách INCI bằng scan.',
            'Search Belumi ingredient data or analyze a full INCI list with scan.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&w=1200&q=80',
        ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: Text(t('Tìm kiếm', 'Search'))),
            ButtonSegment(value: 1, label: Text(t('Dán INCI', 'Paste INCI'))),
            ButtonSegment(value: 2, label: Text(t('Quét ảnh', 'Scan image'))),
          ],
          selected: {tab},
          onSelectionChanged: (value) => setState(() => tab = value.first),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (tab) {
            0 => _SearchPanel(
              controller: searchController,
              loading: loading,
              onSearch: _search,
            ),
            1 => _PastePanel(
              controller: pasteController,
              loading: loading,
              onAnalyze: () => _scan(pasteController.text),
            ),
            _ => _ScanPanel(
              image: image,
              ocrText: _ocrText,
              loading: loading,
              onCamera: _openOcrCamera,
              onUpload: () => _pickAndScan(false),
              onClear: () => setState(() {
                image = null;
                _ocrText = null;
                _imagePath = null;
                scan = null;
              }),
            ),
          },
        ),
        if (loading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          _ToolCard(
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        ],
        if (tab == 0 && searchResult != null) ...[
          const SizedBox(height: 18),
          _IngredientSearchResults(result: searchResult!),
        ],
        if (scan != null && tab != 0) ...[
          const SizedBox(height: 18),
          _ScanResultCard(result: scan!),
        ],
        const SizedBox(height: 22),
        const _HowToUseCard(),
      ],
    );
  }

  Future<void> _search() async {
    setState(() {
      loading = true;
      error = null;
      scan = null;
    });
    try {
      final data = await widget.repository.searchIngredients(
        search: searchController.text.trim(),
      );
      if (!mounted) return;
      setState(() => searchResult = data);
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _scan(String value) async {
    if (value.trim().isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await widget.repository.scanIngredientLabel(value.trim());
      if (!mounted) return;
      setState(() => scan = data);
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = exception.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Open the custom camera screen with flash toggle for OCR scanning.
  Future<void> _openOcrCamera() async {
    final imagePath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const OcrCameraScreen()),
    );
    if (imagePath == null || !mounted) return;
    await _processImageForOcr(imagePath);
  }

  /// Pick image from gallery and run OCR.
  Future<void> _pickAndScan(bool preferCamera) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1800,
    );
    if (file == null || !mounted) return;
    await _processImageForOcr(file.path);
  }

  /// Process image: show preview, run OCR, then send extracted text to backend.
  Future<void> _processImageForOcr(String imagePath) async {
    // Create preview image
    final bytes = await File(imagePath).readAsBytes();
    final mimeType = imagePath.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

    setState(() {
      image = PickedSkinImage(
        name: imagePath.split(Platform.pathSeparator).last,
        mimeType: mimeType,
        dataUrl: dataUrl,
      );
      _imagePath = imagePath;
      _ocrText = null;
      loading = true;
      error = null;
      scan = null;
    });

    try {
      // Step 1: Extract text from image using ML Kit OCR
      final extractedText = await OcrService.instance.extractTextFromFile(
        imagePath,
      );

      if (!mounted) return;
      setState(() => _ocrText = extractedText);

      // Step 2: Send extracted text to backend for ingredient analysis
      final data = await widget.repository.scanIngredientLabel(
        extractedText,
      );

      if (!mounted) return;
      setState(() => scan = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class IngredientDetailScreen extends StatelessWidget {
  const IngredientDetailScreen({
    super.key,
    required this.repository,
    required this.ingredientId,
  });

  final BelumiRepository repository;
  final String ingredientId;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('Chi tiết thành phần', 'Ingredient Details')),
        leading: IconButton(
          onPressed: () => context.go('/ingredient-lookup'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: FutureBuilder<Ingredient?>(
        future: repository.ingredientDetail(ingredientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LuxuryPage(
              children: [LuxuryPanel(child: LinearProgressIndicator())],
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return LuxuryPage(
              children: [
                LuxuryPanel(
                  child: Text(
                    t(
                      'Không tải được chi tiết thành phần.',
                      'Could not load ingredient details.',
                    ),
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          }

          final ingredient = snapshot.data!;
          return LuxuryPage(
            children: [
              LuxuryHero(
                title: ingredient.nameInc,
                subtitle: '${ingredient.name} - ${ingredient.category}',
                imageUrl:
                    'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&w=1200&q=80',
              ),
              const SizedBox(height: 16),
              LuxuryPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'INCI', value: ingredient.nameInc),
                    _DetailRow(
                      label: t('Tên hiển thị', 'Display name'),
                      value: ingredient.name,
                    ),
                    _DetailRow(
                      label: t('Danh mục', 'Category'),
                      value: ingredient.category,
                    ),
                    const SizedBox(height: 12),
                    Text(t('Mô tả', 'Description'), style: _titleStyle),
                    const SizedBox(height: 8),
                    Text(ingredient.description),
                    if (ingredient.linkList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _LinkSection(links: ingredient.linkList),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.loading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return _ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Tìm trong dữ liệu thành phần', 'Search ingredient data'),
            style: _titleStyle,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: t(
                'Tên thành phần, INCI, danh mục',
                'Ingredient name, INCI, category',
              ),
              hintText: 'Hyaluronic Acid, Retinol, Niacinamide...',
              suffixIcon: IconButton(
                onPressed: loading ? null : onSearch,
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ],
      ),
    );
  }
}

class _PastePanel extends StatelessWidget {
  const _PastePanel({
    required this.controller,
    required this.loading,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return _ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Dán danh sách thành phần', 'Paste full ingredient list'),
            style: _titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Sao chép danh sách INCI trên nhãn sản phẩm và dán vào đây.',
              'Copy the INCI list from the product label and paste it here.',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: t('Danh sách INCI đầy đủ', 'Full INCI list'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onAnalyze,
            icon: const Icon(Icons.analytics_outlined),
            label: Text(
              loading
                  ? t('Đang phân tích...', 'Analyzing...')
                  : t('Phân tích thành phần', 'Analyze ingredients'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPanel extends StatelessWidget {
  const _ScanPanel({
    required this.image,
    required this.ocrText,
    required this.loading,
    required this.onCamera,
    required this.onUpload,
    required this.onClear,
  });

  final PickedSkinImage? image;
  final String? ocrText;
  final bool loading;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return _ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Quét nhãn sản phẩm', 'Scan product label'),
            style: _titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Dùng camera hoặc tải ảnh rõ nét của bảng thành phần.',
              'Use camera or upload a clear photo of the ingredient list.',
            ),
          ),
          const SizedBox(height: 14),
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                image!.dataUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
          ],
          // Show extracted OCR text
          if (ocrText != null && ocrText!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.text_snippet_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        t('Chữ nhận diện được (OCR)', 'Detected text (OCR)'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ocrText!,
                    style: const TextStyle(fontSize: 13, height: 1.4),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(t('Camera', 'Camera')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: Text(t('Tải ảnh', 'Upload')),
                ),
              ),
            ],
          ),
          if (image != null)
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: Text(t('Xóa ảnh', 'Clear image')),
            ),
        ],
      ),
    );
  }
}

class _IngredientSearchResults extends StatelessWidget {
  const _IngredientSearchResults({required this.result});

  final IngredientListResult result;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    if (result.items.isEmpty) {
      return _ToolCard(
        child: Text(
          t(
            'Không tìm thấy thành phần phù hợp.',
            'No matching ingredients found.',
          ),
        ),
      );
    }

    return Column(
      children: [
        _ToolCard(
          child: Row(
            children: [
              const Icon(Icons.science_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t(
                    'Tìm thấy ${result.total} thành phần',
                    '${result.total} ingredients found',
                  ),
                  style: _titleStyle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...result.items.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IngredientCard(ingredient: ingredient),
          ),
        ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  const _IngredientCard({required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    return _ToolCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => context.go('/ingredient-lookup/${ingredient.id}'),
        leading: const CircleAvatar(child: Icon(Icons.science_outlined)),
        title: Text(
          ingredient.nameInc,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '${ingredient.name} - ${ingredient.category}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.result});

  final IngredientScanResult result;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    final color = switch (result.status) {
      'danger' => Colors.red,
      'warning' => Colors.orange,
      _ => Colors.green,
    };
    return _ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(Icons.verified_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t(
                    'Điểm an toàn ${result.safetyScore}/100',
                    'Safety score ${result.safetyScore}/100',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Chip(label: Text(result.status.toUpperCase())),
            ],
          ),
          const SizedBox(height: 10),
          Text(result.summary),
          _IngredientItems(
            title: t('Thành phần có lợi', 'Beneficial Ingredients'),
            items: result.beneficial,
          ),
          _IngredientItems(
            title: t('Thành phần trung tính', 'Neutral Ingredients'),
            items: result.neutral,
          ),
          _IngredientItems(
            title: t('Điểm cần chú ý', 'Potential Concerns'),
            items: result.harmful,
          ),
          _ListSection(
            title: t('Gợi ý', 'Recommendations'),
            items: result.recommendations,
          ),
        ],
      ),
    );
  }
}

class _IngredientItems extends StatelessWidget {
  const _IngredientItems({required this.title, required this.items});

  final String title;
  final List<IngredientScanItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _ListSection(
        title: title,
        items: [belumiCopy(context).t('Không phát hiện', 'None detected')],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          ...items.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle, size: 9),
              title: Text(item.name),
              subtitle: Text('${item.category} - ${item.reason}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          ...(items.isEmpty
                  ? [belumiCopy(context).t('Không có', 'None')]
                  : items)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('- $item'),
                ),
              ),
        ],
      ),
    );
  }
}

class _LinkSection extends StatelessWidget {
  const _LinkSection({required this.links});

  final List<String> links;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Links', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        ...links.map((link) => _LinkTile(link: link)),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.open_in_new, size: 20),
      title: Text(
        link,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () async {
        final uri = Uri.tryParse(link);
        if (uri == null) return;
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Could not open $link')));
        }
      },
    );
  }
}

class _HowToUseCard extends StatelessWidget {
  const _HowToUseCard();

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return _ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Cách dùng công cụ', 'How to use this tool'),
            style: _titleStyle,
          ),
          const SizedBox(height: 8),
          Text(
            t(
              '1. Tìm ingredient riêng lẻ bằng tên hoặc INCI.',
              '1. Search a single ingredient by name or INCI.',
            ),
          ),
          Text(
            t(
              '2. Dán full INCI hoặc quét ảnh để phân tích công thức.',
              '2. Paste a full INCI list or scan an image to analyze a formula.',
            ),
          ),
          Text(
            t(
              '3. Xem lợi ích, rủi ro và gợi ý sử dụng.',
              '3. Review benefits, concerns, and usage suggestions.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LuxuryPanel(child: child);
  }
}

const _titleStyle = TextStyle(fontWeight: FontWeight.w900, fontSize: 18);
