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

// ─────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────
class _T {
  _T._();
  static const canvas = Color(0xFFF6F5F4);
  static const ink = Color(0xFF4B3228);
  static const muted = Color(0xFF816A5C);
  static const sand = Color(0xFFE7D8C6);
  static const cream = Color(0xFFF6EDE4);
  static const paper = Color(0xFFFFFAF4);
  static const accent = Color(0xFFC9965D);
  static const espresso = Color(0xFF6A4634);
  static const radius = 16.0;
}

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
  String? _processingStatus; // Status message during OCR processing
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
    return Container(
      color: _T.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 402),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              _buildHeader(t),
              const SizedBox(height: 24),
              _buildCustomTabBar(t),
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
          if (_processingStatus != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _processingStatus!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
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
              const SizedBox(height: 22),
              const _HowToUseCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.science, color: _T.accent, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t('Tra cứu thành phần', 'Ingredient Lookup'),
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _T.ink,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          t('Tìm kiếm thành phần hoặc phân tích danh sách INCI.', 'Search ingredients or analyze INCI.'),
          style: const TextStyle(
            color: _T.muted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTabBar(dynamic t) {
    final labels = [
      t('Tìm kiếm', 'Search'),
      t('Dán INCI', 'Paste'),
      t('Quét ảnh', 'Scan'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _T.sand.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: _T.espresso.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isSelected = tab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => tab = index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _T.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _T.muted,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
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

  Future<void> _showLimitDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hết lượt sử dụng hôm nay 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn đã dùng hết lượt tra cứu/phân tích thành phần miễn phí hôm nay (1 lần/ngày). Vui lòng nâng cấp gói Paid để sử dụng không giới hạn!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: BelumiLuxury.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BelumiLuxury.rose,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              context.push('/pricing');
            },
            child: const Text('Nâng cấp ngay'),
          ),
        ],
      ),
    );
  }

  Future<void> _scan(String value) async {
    if (value.trim().isEmpty) return;
    final allowed = await widget.repository.checkAndIncrementLimit('ingredient_scan');
    if (!allowed) {
      if (!mounted) return;
      _showLimitDialog();
      return;
    }
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
    final allowed = await widget.repository.checkAndIncrementLimit('ingredient_scan');
    if (!allowed) {
      if (!mounted) return;
      _showLimitDialog();
      return;
    }

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
      _processingStatus = 'Đang tăng cường ảnh (auto-contrast)...';
    });

    try {
      // Step 1: Auto-contrast + OCR text extraction
      setState(() => _processingStatus = 'Đang nhận diện chữ (OCR)...');
      final extractedText = await OcrService.instance.extractTextFromFile(
        imagePath,
      );

      if (!mounted) return;
      setState(() {
        _ocrText = extractedText;
        _processingStatus = 'Đang phân tích thành phần...';
      });

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
      if (mounted) setState(() {
        loading = false;
        _processingStatus = null;
      });
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
                    if (ingredient.suitableSkin != null && ingredient.suitableSkin!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(t('Da phù hợp', 'Suitable Skin'), style: _titleStyle),
                      const SizedBox(height: 8),
                      _buildSkinChips(ingredient.suitableSkin!, Colors.green),
                    ],
                    if (ingredient.notForSkin != null && ingredient.notForSkin!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(t('Da không phù hợp', 'Not For Skin'), style: _titleStyle),
                      const SizedBox(height: 8),
                      _buildSkinChips(ingredient.notForSkin!, Colors.red),
                    ],
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

  Widget _buildSkinChips(String skinString, Color baseColor) {
    final skins = skinString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (skins.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skins.map((skin) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: baseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: baseColor.withOpacity(0.5)),
          ),
          child: Text(
            _translateSkin(skin),
            style: TextStyle(
              color: baseColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _translateSkin(String skin) {
    final s = skin.toLowerCase();
    if (s.contains('oily')) return 'Da dầu';
    if (s.contains('dry')) return 'Da khô';
    if (s.contains('combination')) return 'Da hỗn hợp';
    if (s.contains('normal')) return 'Da thường';
    if (s.contains('sensitive')) return 'Da nhạy cảm';
    if (s.contains('all')) return 'Mọi loại da';
    return skin;
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
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _T.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: _T.canvas,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.radius),
                borderSide: const BorderSide(color: _T.sand),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.radius),
                borderSide: const BorderSide(color: _T.sand),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.radius),
                borderSide: const BorderSide(color: _T.accent),
              ),
              prefixIcon: const Icon(Icons.search, color: _T.muted),
              labelText: t(
                'Tên thành phần, INCI, danh mục',
                'Ingredient name, INCI, category',
              ),
              labelStyle: const TextStyle(color: _T.muted),
              hintText: 'Hyaluronic Acid, Retinol, Niacinamide...',
              hintStyle: TextStyle(color: _T.muted.withValues(alpha: 0.5)),
              suffixIcon: IconButton(
                onPressed: loading ? null : onSearch,
                icon: const Icon(Icons.arrow_forward, color: _T.ink),
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
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _T.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Sao chép danh sách INCI trên nhãn sản phẩm và dán vào đây.',
              'Copy the INCI list from the product label and paste it here.',
            ),
            style: const TextStyle(color: _T.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              filled: true,
              fillColor: _T.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.radius),
                borderSide: const BorderSide(color: _T.sand),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.radius),
                borderSide: const BorderSide(color: _T.sand),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_T.radius),
                borderSide: const BorderSide(color: _T.accent),
              ),
              labelText: t('Danh sách INCI đầy đủ', 'Full INCI list'),
              labelStyle: const TextStyle(color: _T.muted),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: loading ? null : onAnalyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.analytics_outlined, size: 18),
              label: Text(
                loading
                    ? t('Đang phân tích...', 'Analyzing...')
                    : t('Phân tích thành phần', 'Analyze ingredients'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
            style: const TextStyle(
              fontFamily: 'Playfair Display',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _T.ink,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(
              'Dùng camera hoặc tải ảnh rõ nét của bảng thành phần.',
              'Use camera or upload a clear photo of the ingredient list.',
            ),
            style: const TextStyle(color: _T.muted, fontSize: 13),
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
                color: _T.cream.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.sand),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.text_snippet_outlined, size: 18, color: _T.ink),
                      const SizedBox(width: 8),
                      Text(
                        t('Chữ nhận diện được (OCR)', 'Detected text (OCR)'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _T.ink,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ocrText!,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: _T.espresso),
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : onCamera,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _T.ink,
                      side: const BorderSide(color: _T.ink),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(
                      t('Camera', 'Camera'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : onUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      t('Tải ảnh', 'Upload'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (image != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onClear,
                style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
                icon: const Icon(Icons.close, size: 16),
                label: Text(t('Xóa ảnh', 'Clear image')),
              ),
            ),
          ],
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
              const Icon(Icons.science_outlined, color: _T.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t(
                    'Tìm thấy ${result.total} thành phần',
                    '${result.total} ingredients found',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _T.ink,
                    fontSize: 16,
                  ),
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
        leading: CircleAvatar(
          backgroundColor: _T.cream,
          child: const Icon(Icons.science_outlined, color: _T.accent, size: 20),
        ),
        title: Text(
          ingredient.nameInc,
          style: const TextStyle(fontWeight: FontWeight.w900, color: _T.ink),
        ),
        subtitle: Text(
          '${ingredient.name} - ${ingredient.category}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _T.muted, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: _T.muted),
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
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _T.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  result.status.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
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
