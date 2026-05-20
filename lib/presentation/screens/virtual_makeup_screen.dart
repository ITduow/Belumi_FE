import 'package:flutter/material.dart';

import '../../core/platform/picked_skin_image.dart';
import '../../core/platform/skin_image_picker.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';
import 'pricing_screen.dart';

class VirtualMakeupScreen extends StatefulWidget {
  const VirtualMakeupScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<VirtualMakeupScreen> createState() => _VirtualMakeupScreenState();
}

class _VirtualMakeupScreenState extends State<VirtualMakeupScreen> {
  String tone = 'neutral light';
  String occasion = 'daily';
  String style = 'clean';
  MakeupResult? result;
  MakeupTryOnResult? tryOn;
  PickedSkinImage? selfie;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return LuxuryPage(
      children: [
        LuxuryHero(
          title: t('Trang điểm ảo', 'Virtual Makeup'),
          subtitle: widget.repository.isPro
              ? t(
                  'Pro đã mở khóa: AI gợi ý tone, sản phẩm và try-on kết nối API.',
                  'Pro unlocked: AI shade matching, product recommendations and virtual try-on are connected to API.',
                )
              : t(
                  'Bản xem trước miễn phí: nâng cấp Pro để mở try-on nâng cao và gợi ý ưu tiên.',
                  'Free preview: upgrade to Pro for advanced virtual try-on and priority recommendations.',
                ),
          imageUrl:
              'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?auto=format&fit=crop&w=1200&q=80',
          actions: [
            LuxuryButton(
              label: widget.repository.currentPlan.toUpperCase(),
              icon: Icons.workspace_premium,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PricingScreen(repository: widget.repository),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SelfiePanel(
          selfie: selfie,
          onCamera: () => _pickSelfie(true),
          onUpload: () => _pickSelfie(false),
          onClear: () => setState(() => selfie = null),
        ),
        const SizedBox(height: 16),
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuxuryHeader(
                eyebrow: t('Tư vấn makeup', 'Makeup consultation'),
                title: t('Chọn vibe makeup', 'Choose your makeup vibe'),
                subtitle: t(
                  'Belumi gợi ý tone, nền, mắt, môi và má hồng.',
                  'Belumi suggests tone, base, eyes, lips and blush.',
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Choice(
                    label: t('Hằng ngày', 'Daily'),
                    selected: occasion == 'daily',
                    onTap: () => setState(() => occasion = 'daily'),
                  ),
                  _Choice(
                    label: t('Dự tiệc', 'Party'),
                    selected: occasion == 'party',
                    onTap: () => setState(() => occasion = 'party'),
                  ),
                  _Choice(
                    label: t('Ấm', 'Warm'),
                    selected: tone == 'warm medium',
                    onTap: () => setState(() => tone = 'warm medium'),
                  ),
                  _Choice(
                    label: t('Trong trẻo', 'Clean'),
                    selected: style == 'clean',
                    onTap: () => setState(() => style = 'clean'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LuxuryButton(
                label: !widget.repository.isPro
                    ? t('Mở khóa Pro', 'Unlock Pro')
                    : loading
                    ? t('Đang tư vấn...', 'Consulting...')
                    : t('Tư vấn makeup', 'Consult makeup'),
                icon: Icons.face_retouching_natural,
                onPressed: !widget.repository.isPro
                    ? () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PricingScreen(repository: widget.repository),
                          ),
                        );
                        setState(() {});
                      }
                    : _consultMakeup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _TryOnPreview(tryOn: tryOn),
        if (tryOn != null) ...[
          const SizedBox(height: 12),
          LuxuryPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Virtual Try-On: ${tryOn!.productName}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(tryOn!.previewNote),
                const SizedBox(height: 8),
                ...tryOn!.applicationTips.map((tip) => Text('- $tip')),
              ],
            ),
          ),
        ],
        if (result != null) ...[
          const SizedBox(height: 16),
          LuxuryPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result!.lookName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text('${t('Nền', 'Base')}: ${result!.base}'),
                Text('${t('Mắt', 'Eyes')}: ${result!.eyes}'),
                Text('${t('Môi', 'Lips')}: ${result!.lips}'),
                Text(
                  '${t('Sản phẩm', 'Products')}: ${result!.productSuggestions.join(', ')}',
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        LuxuryHeader(
          eyebrow: t('Danh mục làm đẹp', 'Beauty Catalogue'),
          title: t('Catalog makeup', 'Makeup catalog'),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<MakeupCatalogItem>>(
          future: widget.repository.makeupCatalog(),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <MakeupCatalogItem>[];
            if (items.isEmpty) {
              return LuxuryInfoTile(
                icon: Icons.palette_outlined,
                title: t('Catalog đang cập nhật', 'Catalog is updating'),
                subtitle: t(
                  'Belumi sẽ hiển thị sản phẩm makeup tại đây.',
                  'Belumi will show makeup products here.',
                ),
              );
            }
            return Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LuxuryPanel(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _hexColor(item.hexColor),
                          ),
                          title: Text(item.name),
                          subtitle: Text('${item.productType} • ${item.shade}'),
                          trailing: FilledButton(
                            onPressed: widget.repository.isPro
                                ? () => _tryOn(item)
                                : null,
                            child: Text(item.isPro ? 'Try Pro' : 'Try'),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Color _hexColor(String hex) {
    final clean = hex.replaceAll('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  Future<void> _pickSelfie(bool camera) async {
    final picked = await pickSkinImage(preferCamera: camera);
    if (picked == null) return;
    setState(() => selfie = picked);
  }

  Future<void> _consultMakeup() async {
    setState(() => loading = true);
    final data = await widget.repository.consultMakeup(tone, occasion, style);
    if (!mounted) return;
    setState(() {
      result = data;
      loading = false;
    });
  }

  Future<void> _tryOn(MakeupCatalogItem item) async {
    if (selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            belumiCopy(context).t(
              'Tải lên hoặc chụp selfie trước.',
              'Upload or capture a selfie first.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => loading = true);
    final data = await widget.repository.tryOnMakeup(item, selfie!.dataUrl);
    if (!mounted) return;
    setState(() {
      tryOn = data;
      loading = false;
    });
  }
}

class _SelfiePanel extends StatelessWidget {
  const _SelfiePanel({
    required this.selfie,
    required this.onCamera,
    required this.onUpload,
    required this.onClear,
  });

  final PickedSkinImage? selfie;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return LuxuryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LuxuryHeader(
            eyebrow: t('Selfie thử màu', 'Selfie try-on'),
            title: t('Selfie AI chọn tone', 'AI shade matching selfie'),
            subtitle: t(
              'Dùng selfie rõ, ánh sáng đều để kết quả khớp tốt hơn.',
              'Use a clean, evenly lit selfie for better match results.',
            ),
          ),
          const SizedBox(height: 14),
          if (selfie != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                selfie!.dataUrl,
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close),
              label: Text(t('Xóa selfie', 'Clear selfie')),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(t('Camera', 'Camera')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_file),
                  label: Text(t('Tải ảnh', 'Upload')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TryOnPreview extends StatelessWidget {
  const _TryOnPreview({required this.tryOn});

  final MakeupTryOnResult? tryOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE8E0), Color(0xFF193447)],
        ),
      ),
      child: Center(
        child: tryOn == null
            ? const Icon(
                Icons.face_retouching_natural,
                size: 92,
                color: Colors.white,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(
                      int.parse(
                        'FF${tryOn!.hexColor.replaceAll('#', '')}',
                        radix: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${tryOn!.shade} - ${tryOn!.matchScore}% match',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
