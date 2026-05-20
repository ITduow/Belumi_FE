import 'package:flutter/material.dart';

import '../../core/platform/picked_skin_image.dart';
import '../../core/platform/skin_image_picker.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class IngredientLookupScreen extends StatefulWidget {
  const IngredientLookupScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<IngredientLookupScreen> createState() => _IngredientLookupScreenState();
}

class _IngredientLookupScreenState extends State<IngredientLookupScreen> {
  final searchController = TextEditingController(text: 'Niacinamide');
  final pasteController = TextEditingController(
    text:
        'Aqua, Niacinamide, Glycerin, Hyaluronic Acid, Ceramide NP, Fragrance',
  );
  int tab = 0;
  bool loading = false;
  PickedSkinImage? image;
  IngredientResult? lookup;
  IngredientScanResult? scan;

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
            'Giải mã nhãn sản phẩm bằng tìm kiếm, dán danh sách thành phần hoặc quét ảnh.',
            'Decode product labels with search, paste-list analysis, or OCR-style image scanning.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&w=1200&q=80',
        ),
        const SizedBox(height: 18),
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: 0, label: Text(t('Tìm kiếm', 'Search'))),
            ButtonSegment(value: 1, label: Text(t('Dán', 'Paste'))),
            ButtonSegment(value: 2, label: Text(t('Quét', 'Scan'))),
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
              onAnalyze: () => _lookup(searchController.text),
            ),
            1 => _PastePanel(
              controller: pasteController,
              loading: loading,
              onAnalyze: () => _scan(pasteController.text),
            ),
            _ => _ScanPanel(
              image: image,
              loading: loading,
              onCamera: () => _pickAndScan(true),
              onUpload: () => _pickAndScan(false),
              onClear: () => setState(() => image = null),
            ),
          },
        ),
        if (lookup != null) ...[
          const SizedBox(height: 18),
          _LookupResultCard(result: lookup!),
        ],
        if (scan != null) ...[
          const SizedBox(height: 18),
          _ScanResultCard(result: scan!),
        ],
        const SizedBox(height: 22),
        const _HowToUseCard(),
      ],
    );
  }

  Future<void> _lookup(String value) async {
    if (value.trim().isEmpty) return;
    setState(() {
      loading = true;
      scan = null;
    });
    final data = await widget.repository.lookupIngredient(value.trim());
    if (!mounted) return;
    setState(() {
      lookup = data;
      loading = false;
    });
  }

  Future<void> _scan(String value) async {
    if (value.trim().isEmpty) return;
    setState(() {
      loading = true;
      lookup = null;
    });
    final data = await widget.repository.scanIngredientLabel(value.trim());
    if (!mounted) return;
    setState(() {
      scan = data;
      loading = false;
    });
  }

  Future<void> _pickAndScan(bool preferCamera) async {
    final picked = await pickSkinImage(preferCamera: preferCamera);
    if (picked == null) return;
    setState(() => image = picked);
    await _scan(picked.dataUrl);
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
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
            t('Tìm một thành phần', 'Search a single ingredient'),
            style: _titleStyle,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: t(
                'Tên thành phần hoặc INCI',
                'Ingredient name or INCI',
              ),
              hintText: 'Hyaluronic Acid, Retinol, Niacinamide...',
            ),
            onSubmitted: (_) => onAnalyze(),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onAnalyze,
            icon: const Icon(Icons.science_outlined),
            label: Text(
              loading
                  ? t('Đang phân tích...', 'Analyzing...')
                  : t('Xem chi tiết', 'View details'),
            ),
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
    required this.loading,
    required this.onCamera,
    required this.onUpload,
    required this.onClear,
  });

  final PickedSkinImage? image;
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
          if (loading) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _LookupResultCard extends StatelessWidget {
  const _LookupResultCard({required this.result});

  final IngredientResult result;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return _ToolCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('Chi tiết thành phần', 'Ingredient Details'),
            style: _titleStyle,
          ),
          const SizedBox(height: 8),
          Text(result.summary),
          _ListSection(
            title: t('Lợi ích / An toàn', 'Benefits / Safe'),
            items: result.safeIngredients,
          ),
          _ListSection(
            title: t('Cần lưu ý', 'Use With Care'),
            items: result.watchlist,
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
              '1. Chọn tìm kiếm, dán hoặc quét.',
              '1. Choose search, paste, or scan.',
            ),
          ),
          Text(
            t(
              '2. Xem lợi ích, rủi ro và độ phù hợp.',
              '2. Review benefits, concerns, and suitability.',
            ),
          ),
          Text(
            t(
              '3. Lưu hoặc so sánh sản phẩm trước khi mua.',
              '3. Save or compare products before buying.',
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
