import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/i18n/app_strings.dart';
import '../../core/platform/picked_skin_image.dart';
import '../../core/platform/skin_image_picker.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class SkinAnalysisScreen extends ConsumerStatefulWidget {
  const SkinAnalysisScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends ConsumerState<SkinAnalysisScreen> {
  int step = 0;
  bool consent = false;
  bool deleteAfter = true;
  bool loading = false;
  String? error;
  PickedSkinImage? pickedImage;
  SkinAnalysisResult? result;

  String skinType = '';

  bool get isPlusOrPro =>
      widget.repository.currentPlan == 'plus' ||
      widget.repository.currentPlan == 'pro';
  bool get isPro => widget.repository.currentPlan == 'pro';
  bool get canUsePhotoAnalysis => true;

  bool get isVi => ref.read(appLocaleProvider) == 'vi';

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (step) {
        0 => _IntroStep(
          key: const ValueKey('intro'),
          locale: locale,
          onStart: _next,
        ),
        1 => _ConsentStep(
          key: const ValueKey('consent'),
          locale: locale,
          consent: consent,
          deleteAfter: deleteAfter,
          onConsentChanged: (value) => setState(() => consent = value),
          onDeleteChanged: (value) => setState(() => deleteAfter = value),
          onBack: _back,
          onNext: consent ? _next : null,
        ),
        2 => _PhotoStep(
          key: const ValueKey('photo'),
          locale: locale,
          canUsePhotoAnalysis: canUsePhotoAnalysis,
          image: pickedImage,
          onCamera: () => _pickImage(true),
          onUpload: () => _pickImage(false),
          onClear: () => setState(() => pickedImage = null),
          onBack: _back,
          onNext: pickedImage == null ? null : _next,
        ),
        3 => _QuizStep(
          key: const ValueKey('quiz'),
          locale: locale,
          skinType: skinType,
          loading: loading,
          error: error,
          onBack: _quizBack,
          onSelectSkinType: (value) => setState(() => skinType = value),
          onAnalyze: _analyze,
        ),
        _ => _ResultStep(
          key: const ValueKey('result'),
          locale: locale,
          result: result,
          isDetailed: isPlusOrPro,
          onRestart: _restart,
          onSave: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isVi
                    ? 'Đã lưu quy trình trong demo'
                    : 'Routine saved in demo mode',
              ),
            ),
          ),
        ),
      },
    );
  }

  void _next() => setState(() => step++);

  void _back() => setState(() => step--);

  void _quizBack() {
    _back();
  }

  void _restart() {
    setState(() {
      step = 0;
      error = null;
      result = null;
    });
  }

  Future<void> _pickImage(bool preferCamera) async {
    try {
      final image = await pickSkinImage(preferCamera: preferCamera);
      if (image == null) return;
      setState(() => pickedImage = image);
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chua chon anh. Hay thu lai.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong mo duoc camera tren thiet bi nay.'),
        ),
      );
    }
  }

  Future<void> _analyze() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (!widget.repository.isLoggedIn) {
        throw Exception(
          'Vui lòng đăng nhập bằng Firebase trước khi phân tích.',
        );
      }
      if (pickedImage == null) {
        throw Exception('Vui long chon anh truoc khi phan tich.');
      }

      final data = await widget.repository.analyzeSkin(
        skinType: skinType,
        concerns: [skinType],
        goal: 'Tu van quy trinh cham soc da ca nhan hoa',
        planCode: widget.repository.currentPlan,
        imageUrl: pickedImage!.dataUrl,
      );
      if (!mounted) return;
      setState(() {
        result = data;
        step = 4;
      });
    } catch (exception) {
      setState(() {
        error = exception.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class _PageShell extends StatelessWidget {
  const _PageShell({
    required this.child,
    required this.locale,
    this.badge,
    this.title,
    this.subtitle,
  });

  final Widget child;
  final String locale;
  final String? badge;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return LuxuryPage(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        if (badge != null) Center(child: _StepBadge(label: badge!)),
        if (title != null) ...[
          const SizedBox(height: 12),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: BelumiLuxury.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _L {
  const _L(this.locale);
  final String locale;

  bool get vi => locale == 'vi';

  String t(String viText, String enText) => vi ? viText : enText;
}

class _IntroStep extends StatelessWidget {
  const _IntroStep({super.key, required this.locale, required this.onStart});

  final String locale;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    return _PageShell(
      locale: locale,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF5BA4D2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.t('Phân tích da bằng AI', 'AI Skin Analysis'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: const Color(0xFF284866),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l.t(
              'Nhận gợi ý chăm sóc da cá nhân được hỗ trợ bởi phân tích AI',
              'Get personalized skincare recommendations powered by AI analysis',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _GlassCard(
            child: Column(
              children: [
                Text(
                  l.t('Cách hoạt động:', 'How it works:'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                _HowItem(
                  number: '1',
                  title: l.t('Chụp ảnh selfie', 'Take a selfie'),
                  subtitle: l.t(
                    'Ánh sáng tự nhiên, không lọc, khuôn mặt giữa khung',
                    'Natural light, no filters, face centered in frame',
                  ),
                ),
                _HowItem(
                  number: '2',
                  title: l.t('Trả lời câu hỏi nhanh', 'Answer quick questions'),
                  subtitle: l.t(
                    '5 thao tác về da, không cần gõ',
                    '5 simple skin profile steps, no typing needed',
                  ),
                ),
                _HowItem(
                  number: '3',
                  title: l.t(
                    'Nhận quy trình cá nhân',
                    'Receive a personalized routine',
                  ),
                  subtitle: l.t(
                    'Gợi ý được hỗ trợ bởi AI phù hợp với da của bạn',
                    'AI-supported recommendations tailored to your skin',
                  ),
                  dark: true,
                ),
                const SizedBox(height: 10),
                _NoticeBox(locale: locale),
              ],
            ),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: 240,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l.t('Bắt đầu phân tích da', 'Start skin analysis')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
    super.key,
    required this.locale,
    required this.consent,
    required this.deleteAfter,
    required this.onConsentChanged,
    required this.onDeleteChanged,
    required this.onBack,
    required this.onNext,
  });

  final String locale;
  final bool consent;
  final bool deleteAfter;
  final ValueChanged<bool> onConsentChanged;
  final ValueChanged<bool> onDeleteChanged;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    return _PageShell(
      locale: locale,
      badge: l.t('Bước 1 / 3', 'Step 1 of 3'),
      title: l.t('Quyền riêng tư & Chấp thuận', 'Privacy & Consent'),
      subtitle: l.t('Dữ liệu của bạn, quyền của bạn', 'Your data, your rights'),
      child: _GlassCard(
        child: Column(
          children: [
            _ConsentTile(
              value: consent,
              title: l.t(
                'Tôi đồng ý xử lý ảnh để phân tích',
                'I consent to image processing for analysis',
              ),
              subtitle: l.t(
                'Ảnh của bạn sẽ được xử lý để phân tích loại da và tình trạng. Chúng tôi bảo mật dữ liệu an toàn.',
                'Your image will be processed to analyze skin type and condition. We keep your data protected.',
              ),
              onChanged: onConsentChanged,
            ),
            const SizedBox(height: 12),
            _ConsentTile(
              value: deleteAfter,
              title: l.t(
                'Xóa ảnh sau khi phân tích xong',
                'Delete image after analysis',
              ),
              subtitle: l.t(
                'Tự động xóa ảnh của bạn sau khi kết quả được tạo ra',
                'Automatically delete your image after the result is generated',
              ),
              onChanged: onDeleteChanged,
            ),
            const SizedBox(height: 28),
            _NavRow(
              onBack: onBack,
              onNext: onNext,
              backLabel: l.t('Quay lại', 'Back'),
              nextLabel: l.t('Tiếp tục', 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    super.key,
    required this.locale,
    required this.canUsePhotoAnalysis,
    required this.image,
    required this.onCamera,
    required this.onUpload,
    required this.onClear,
    required this.onBack,
    required this.onNext,
  });

  final String locale;
  final bool canUsePhotoAnalysis;
  final PickedSkinImage? image;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    return _PageShell(
      locale: locale,
      badge: l.t('Bước 2 / 3', 'Step 2 of 3'),
      title: l.t('Chụp ảnh Selfie', 'Take a Selfie'),
      subtitle: l.t(
        'Để có kết quả tốt nhất, hãy làm theo hướng dẫn dưới đây',
        'For the best result, follow the guidance below',
      ),
      child: _GlassCard(
        child: Column(
          children: [
            Wrap(
              spacing: 20,
              runSpacing: 16,
              children: [
                _GuideCard(
                  good: true,
                  title: l.t('Nên làm', 'Do'),
                  items: [
                    l.t('Dùng ánh sáng tự nhiên', 'Use natural light'),
                    l.t('Tháo kính nếu có thể', 'Remove glasses if possible'),
                    l.t(
                      'Căn giữa khuôn mặt trong khung',
                      'Center your face in the frame',
                    ),
                    l.t('Giữ biểu cảm trung lập', 'Keep a neutral expression'),
                    l.t(
                      'Da sạch, không trang điểm nếu có thể',
                      'Clean skin, no makeup if possible',
                    ),
                  ],
                ),
                _GuideCard(
                  good: false,
                  title: l.t('Không nên', 'Avoid'),
                  items: [
                    l.t(
                      'Dùng nhiều bộ lọc hoặc chỉnh sửa',
                      'Using filters or heavy edits',
                    ),
                    l.t(
                      'Chụp ảnh trong ánh sáng yếu',
                      'Taking photos in low light',
                    ),
                    l.t(
                      'Dùng đèn flash thẳng vào mặt',
                      'Using direct flash on your face',
                    ),
                    l.t(
                      'Che mặt bằng tóc hoặc tay',
                      'Covering your face with hair or hands',
                    ),
                    l.t('Dùng hình ảnh bị mờ', 'Using blurry photos'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (image != null)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 330,
                      width: double.infinity,
                      color: const Color(0xFFF6FCFF),
                      child: _PickedImagePreview(image: image!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onClear,
                          icon: const Icon(Icons.close),
                          label: Text(l.t('Hủy', 'Cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onCamera,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: Text(l.t('Chụp lại', 'Retake')),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _PhotoAction(
                      icon: Icons.camera_alt_outlined,
                      title: canUsePhotoAnalysis
                          ? l.t('Dùng camera', 'Use camera')
                          : l.t('Mở khóa camera', 'Unlock camera'),
                      onTap: onCamera,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _PhotoAction(
                      icon: Icons.upload_file,
                      title: canUsePhotoAnalysis
                          ? l.t('Tải ảnh lên', 'Upload image')
                          : l.t('Mở khóa upload', 'Unlock upload'),
                      onTap: onUpload,
                    ),
                  ),
                ],
              ),
            if (!canUsePhotoAnalysis) ...[
              const SizedBox(height: 14),
              _PaywallNote(locale: locale),
            ],
            const SizedBox(height: 22),
            _NavRow(
              onBack: onBack,
              onNext: onNext,
              backLabel: l.t('Quay lại', 'Back'),
              nextLabel: l.t('Tiếp tục', 'Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizStep extends StatelessWidget {
  const _QuizStep({
    super.key,
    required this.locale,
    required this.skinType,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onSelectSkinType,
    required this.onAnalyze,
  });

  final String locale;
  final String skinType;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectSkinType;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    final options = _skinTypeOptions(l);
    final selectedLabels = options
        .where((option) => option.value == skinType)
        .map((option) => option.label)
        .toSet();

    return _PageShell(
      locale: locale,
      badge: l.t('Bước 3 / 3', 'Step 3 of 3'),
      title: l.t('Xác định loại da', 'Identify Your Skin Type'),
      subtitle: l.t(
        'Chọn cảm giác da sau khi rửa mặt và chờ khoảng 30 phút.',
        'Choose how your skin feels about 30 minutes after cleansing.',
      ),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.t(
                'Sau khi rửa mặt và chờ khoảng 30 phút, da bạn cảm thấy như thế nào?',
                'After washing your face and waiting about 30 minutes, how does your skin feel?',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l.t(
                'Câu trả lời này sẽ được gửi về API dưới dạng loại da tương ứng.',
                'This answer is sent to the API as the matching skin type.',
              ),
            ),
            const SizedBox(height: 20),
            _OptionGrid(
              options: options.map((option) => option.label).toList(),
              selected: selectedLabels,
              onTap: (label) => onSelectSkinType(
                options.firstWhere((option) => option.label == label).value,
              ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            _NavRow(
              onBack: onBack,
              onNext: skinType.isEmpty || loading ? null : onAnalyze,
              nextLabel: loading
                  ? l.t('Đang phân tích...', 'Analyzing...')
                  : l.t('Phân tích da của tôi', 'Analyze my skin'),
              backLabel: l.t('Quay lại', 'Back'),
            ),
          ],
        ),
      ),
    );
  }

  List<_SkinTypeOption> _skinTypeOptions(_L l) => [
    _SkinTypeOption(
      label: l.t(
        'A. Da bóng dầu hoặc nhờn rõ rệt',
        'A. Skin is clearly oily or greasy',
      ),
      value: 'oily',
    ),
    _SkinTypeOption(
      label: l.t(
        'B. Da khô, căng hoặc hơi bong tróc',
        'B. Skin feels dry, tight, or slightly flaky',
      ),
      value: 'dry',
    ),
    _SkinTypeOption(
      label: l.t(
        'C. Vùng chữ T dầu nhưng hai bên má khô hoặc bình thường',
        'C. T-zone is oily while cheeks are dry or normal',
      ),
      value: 'combination',
    ),
    _SkinTypeOption(
      label: l.t(
        'D. Da thoải mái, không căng, không nhờn',
        'D. Skin feels comfortable, not tight and not oily',
      ),
      value: 'normal',
    ),
    _SkinTypeOption(
      label: l.t(
        'E. Da đỏ, châm chích, nóng rát hoặc ngứa',
        'E. Skin is red, stinging, burning, or itchy',
      ),
      value: 'sensitive',
    ),
  ];
}

class _SkinTypeOption {
  const _SkinTypeOption({required this.label, required this.value});

  final String label;
  final String value;
}

class _ResultStep extends StatelessWidget {
  const _ResultStep({
    super.key,
    required this.locale,
    required this.result,
    required this.isDetailed,
    required this.onRestart,
    required this.onSave,
  });

  final String locale;
  final SkinAnalysisResult? result;
  final bool isDetailed;
  final VoidCallback onRestart;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    final data = result;
    if (data == null) {
      return _PageShell(
        locale: locale,
        child: Center(
          child: FilledButton(
            onPressed: onRestart,
            child: Text(l.t('Làm lại', 'Restart')),
          ),
        ),
      );
    }
    final concernLabels = _concernLabels(data.topConcerns, l);
    return _PageShell(
      locale: locale,
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 34),
          const SizedBox(height: 10),
          Text(
            l.t('Kết quả phân tích da của bạn', 'Your Skin Analysis Result'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF284866),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.t(
              'Quy trình cá nhân dựa trên hồ sơ da của bạn',
              'A personalized routine based on your skin profile',
            ),
          ),
          const SizedBox(height: 24),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetectedSkinType(result: data, locale: locale),
                const SizedBox(height: 20),
                _MiniSection(
                  title: l.t('Phân tích hoàn tất', 'Analysis complete'),
                  body: data.description.isNotEmpty
                      ? data.description
                      : data.recommendations,
                  icon: Icons.manage_search,
                ),
                const SizedBox(height: 18),
                _ResultCardGrid(
                  children: [
                    _RoutineCard(
                      title: l.t('Lời khuyên', 'Advice'),
                      color: const Color(0xFFFFB020),
                      body: _bulletList(
                        data.advice,
                        fallback: l.t(
                          'Đang cập nhật lời khuyên từ AI.',
                          'AI advice is being updated.',
                        ),
                      ),
                    ),
                    _RoutineCard(
                      title: l.t('Cần lưu ý', 'Use with caution'),
                      color: Colors.deepOrange,
                      body: _bulletList(
                        data.warnings,
                        fallback: l.t(
                          'Chưa có cảnh báo đặc biệt.',
                          'No special cautions detected.',
                        ),
                      ),
                    ),
                    _RoutineCard(
                      title: l.t(
                        'Vấn đề da phát hiện',
                        'Detected skin concerns',
                      ),
                      color: Colors.green,
                      body: _bulletList(
                        concernLabels,
                        fallback: l.t(
                          'Chưa phát hiện vấn đề da rõ ràng.',
                          'No clear skin concerns detected.',
                        ),
                      ),
                    ),
                    _RoutineCard(
                      title: l.t('Tín hiệu phân tích', 'Analysis signals'),
                      color: const Color(0xFF7C5CFF),
                      body: _signalSummary(data, l).isEmpty
                          ? l.t(
                              'Không có tín hiệu đặc biệt.',
                              'No special signals detected.',
                            )
                          : _signalSummary(data, l),
                    ),
                    _RoutineCard(
                      title: l.t(
                        'Thành phần nên ưu tiên',
                        'Ingredients to prioritize',
                      ),
                      color: Colors.green,
                      body: _ingredientList(
                        data.recommendedIngredients,
                        fallback: l.t(
                          'Chưa có gợi ý thành phần cụ thể.',
                          'No specific ingredient suggestions yet.',
                        ),
                      ),
                      icon: Icons.spa_outlined,
                    ),
                    _RoutineCard(
                      title: l.t(
                        'Cần tránh / hỏi chuyên gia',
                        'Avoid / ask a professional',
                      ),
                      color: Colors.deepOrange,
                      body: _ingredientList(
                        data.avoidOrProfessionalOnly,
                        fallback: l.t(
                          'Chưa có thành phần cần lưu ý đặc biệt.',
                          'No special ingredient cautions detected.',
                        ),
                      ),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MiniSection(
                  title: l.t('Độ tin cậy phân tích', 'Analysis confidence'),
                  body:
                      '${l.t('Độ tin cậy', 'Confidence')}: ${(data.confidence * 100).round()}%',
                  icon: Icons.spa_outlined,
                ),
                if (!isDetailed) ...[
                  const SizedBox(height: 16),
                  _PaywallNote(locale: locale),
                ],
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA4D2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l.t(
                      'Mẹo chuyên gia để có kết quả tốt nhất: Hãy kiên nhẫn, thử nghiệm từng sản phẩm, theo dõi thay đổi và kiên trì với quy trình.',
                      'Expert tips for better results: be patient, patch-test products, track changes, and stay consistent with your routine.',
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onRestart,
                        child: Text(
                          l.t('Bắt đầu phân tích mới', 'Start new analysis'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: onSave,
                        child: Text(l.t('Lưu quy trình', 'Save routine')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _bulletList(List<String> items, {required String fallback}) =>
      items.isEmpty ? fallback : items.map((item) => '- $item').join('\n');

  String _ingredientList(
    List<IngredientRecommendation> items, {
    required String fallback,
  }) {
    final lines = items.where((item) => item.name.trim().isNotEmpty).map((
      item,
    ) {
      final reason = item.reason.trim();
      return reason.isEmpty ? '- ${item.name}' : '- ${item.name}: $reason';
    }).toList();
    return lines.isEmpty ? fallback : lines.join('\n');
  }

  List<String> _concernLabels(List<String> values, _L l) =>
      values.map((value) => _concernLabel(value, l)).toList();

  String _concernLabel(String value, _L l) {
    return switch (value.toLowerCase().trim()) {
      'acne' => l.t('mụn', 'acne'),
      'redness' => l.t('đỏ da', 'redness'),
      'dullness' => l.t('xỉn màu', 'dullness'),
      'dark_spots' || 'dark spots' => l.t('thâm/nám', 'dark spots'),
      'enlarged_pores' ||
      'enlarged pores' => l.t('lỗ chân lông to', 'enlarged pores'),
      'uneven_tone' || 'uneven tone' => l.t('da không đều màu', 'uneven tone'),
      _ => value,
    };
  }

  String _signalSummary(SkinAnalysisResult data, _L l) {
    final signals = <String>[
      '${l.t('Mụn', 'Acne')}: ${_acneLabel(data.acneLevel, l)}',
      if (data.darkSpots) l.t('Thâm/nám', 'Dark spots'),
      if (data.enlargedPores) l.t('Lỗ chân lông to', 'Enlarged pores'),
      if (data.redness) l.t('Đỏ da', 'Redness'),
      if (data.unevenTone) l.t('Da không đều màu', 'Uneven tone'),
      if (data.skinCondition.isNotEmpty)
        '${l.t('Tình trạng', 'Condition')}: ${_conditionLabel(data.skinCondition, l)}',
    ];
    return signals.join('\n');
  }

  String _acneLabel(String value, _L l) {
    return switch (value.toLowerCase().trim()) {
      'mild' => l.t('nhẹ', 'mild'),
      'moderate' => l.t('trung bình', 'moderate'),
      'severe' => l.t('nặng', 'severe'),
      _ => l.t('không có', 'none'),
    };
  }

  String _conditionLabel(String value, _L l) {
    return switch (value.toLowerCase().trim()) {
      'critical' => l.t('cần chú ý nhiều', 'critical'),
      'needs_care' => l.t('cần chăm sóc', 'needs care'),
      'needs_attention' => l.t('cần theo dõi', 'needs attention'),
      'good' => l.t('ổn định', 'good'),
      _ => value,
    };
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.auto_awesome, size: 16),
      label: Text(label),
      side: const BorderSide(color: Color(0xFFD9EAF5)),
      backgroundColor: Colors.white,
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5BA4D2).withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HowItem extends StatelessWidget {
  const _HowItem({
    required this.number,
    required this.title,
    required this.subtitle,
    this.dark = false,
  });

  final String number;
  final String title;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7E0F1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: dark
                ? const Color(0xFF284866)
                : const Color(0xFF5BA4D2),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC84D)),
      ),
      child: Text(
        l.t(
          'Quan trọng: Đây chỉ là hướng dẫn thẩm mỹ, không phải tư vấn y tế. Hãy tham khảo bác sĩ da liễu khi có mối lo ngại về da.',
          'Important: This is cosmetic guidance only, not medical advice. Please consult a dermatologist for skin health concerns.',
        ),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E6F1)),
        ),
        child: Row(
          children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.good,
    required this.title,
    required this.items,
  });

  final bool good;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final color = good ? Colors.green : Colors.red;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${good ? '✓' : 'X'} $title',
              style: TextStyle(
                color: color.shade700,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${good ? '✓' : 'X'} $item',
                  style: TextStyle(color: color.shade700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  const _PhotoAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD6E6F1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF5BA4D2),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _PickedImagePreview extends StatelessWidget {
  const _PickedImagePreview({required this.image});

  final PickedSkinImage image;

  @override
  Widget build(BuildContext context) {
    final dataUrl = image.dataUrl;
    if (dataUrl.startsWith('data:')) {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        try {
          final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
          return Image.memory(bytes, fit: BoxFit.contain);
        } catch (_) {
          // Fall through to the error placeholder below.
        }
      }
    }

    if (dataUrl.startsWith('http')) {
      return Image.network(dataUrl, fit: BoxFit.contain);
    }

    return const Center(
      child: Icon(Icons.broken_image_outlined, color: Color(0xFFB84A62)),
    );
  }
}

class _PaywallNote extends StatelessWidget {
  const _PaywallNote({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC84D)),
      ),
      child: Text(
        l.t(
          'Gói Pro mở phân tích ảnh selfie. Free/Plus vẫn có hồ sơ da và tư vấn bằng câu hỏi.',
          'Pro unlocks selfie photo analysis. Free/Plus still support the skin profile and question-based consultation.',
        ),
      ),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options) ...[
          Builder(
            builder: (context) {
              final active = selected.contains(option);
              return InkWell(
                onTap: () => onTap(option),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE3F2FC) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF5BA4D2)
                          : const Color(0xFFCFE3F2),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (active) ...[
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Color(0xFF5BA4D2),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: const Color(0xFF566577),
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (option != options.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.onBack,
    required this.onNext,
    this.backLabel = 'Quay lại',
    this.nextLabel = 'Tiep tuc',
  });

  final VoidCallback onBack;
  final VoidCallback? onNext;
  final String backLabel;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: onBack, child: Text(backLabel)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton(onPressed: onNext, child: Text(nextLabel)),
        ),
      ],
    );
  }
}

class _DetectedSkinType extends StatelessWidget {
  const _DetectedSkinType({required this.result, required this.locale});

  final SkinAnalysisResult result;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    final concerns = _concernLabels(result.topConcerns, l);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FCFF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.t('Loại da được phát hiện', 'Detected skin type')),
                Text(
                  _skinTypeLabel(result.skinType, l),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF5BA4D2),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (concerns.isNotEmpty) Text(concerns.join(', ')),
              ],
            ),
          ),
          Chip(label: Text('${result.score}/100')),
        ],
      ),
    );
  }

  String _skinTypeLabel(String value, _L l) {
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('oily')) return l.t('Da dầu', 'Oily');
    if (normalized.contains('dry')) return l.t('Da khô', 'Dry');
    if (normalized.contains('combination')) {
      return l.t('Da hỗn hợp', 'Combination');
    }
    if (normalized.contains('sensitive')) {
      return l.t('Da nhạy cảm', 'Sensitive');
    }
    return l.t('Da thường', 'Normal');
  }

  List<String> _concernLabels(List<String> values, _L l) =>
      values.map((value) => _concernLabel(value, l)).toList();

  String _concernLabel(String value, _L l) {
    return switch (value.toLowerCase().trim()) {
      'acne' => l.t('mụn', 'acne'),
      'redness' => l.t('đỏ da', 'redness'),
      'dullness' => l.t('xỉn màu', 'dullness'),
      'dark_spots' || 'dark spots' => l.t('thâm/nám', 'dark spots'),
      'enlarged_pores' ||
      'enlarged pores' => l.t('lỗ chân lông to', 'enlarged pores'),
      'uneven_tone' || 'uneven tone' => l.t('da không đều màu', 'uneven tone'),
      _ => value,
    };
  }
}

class _MiniSection extends StatelessWidget {
  const _MiniSection({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _RoutineCard(
      title: title,
      color: const Color(0xFF5BA4D2),
      body: body,
      icon: icon,
    );
  }
}

class _ResultCardGrid extends StatelessWidget {
  const _ResultCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final spacing = twoColumns ? 12.0 : 10.0;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.title,
    required this.color,
    required this.body,
    this.icon,
  });

  final String title;
  final Color color;
  final String body;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon ?? Icons.check_circle_outline, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body.isEmpty ? 'Đang cập nhật gợi ý từ AI.' : body),
        ],
      ),
    );
  }
}
