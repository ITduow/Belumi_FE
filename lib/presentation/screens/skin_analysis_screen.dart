import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/i18n/app_strings.dart';
import '../../core/platform/picked_skin_image.dart';
import '../../core/platform/skin_image_picker.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';
import 'pricing_screen.dart';

class SkinAnalysisScreen extends ConsumerStatefulWidget {
  const SkinAnalysisScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<SkinAnalysisScreen> createState() => _SkinAnalysisScreenState();
}

class _SkinAnalysisScreenState extends ConsumerState<SkinAnalysisScreen> {
  int step = 0;
  int quizStep = 0;
  bool consent = false;
  bool deleteAfter = true;
  bool loading = false;
  String? error;
  PickedSkinImage? pickedImage;
  SkinAnalysisResult? result;

  String skinType = '';
  String sensitivity = '';
  String routine = '';
  final Set<String> concerns = {};
  final Set<String> allergies = {};

  bool get isPlusOrPro =>
      widget.repository.currentPlan == 'plus' ||
      widget.repository.currentPlan == 'pro';
  bool get isPro => widget.repository.currentPlan == 'pro';

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
          isPro: isPro,
          image: pickedImage,
          onCamera: isPro ? () => _pickImage(true) : _openPricing,
          onUpload: isPro ? () => _pickImage(false) : _openPricing,
          onClear: () => setState(() => pickedImage = null),
          onBack: _back,
          onNext: _next,
        ),
        3 => _QuizStep(
          key: ValueKey('quiz-$quizStep'),
          locale: locale,
          quizStep: quizStep,
          skinType: skinType,
          sensitivity: sensitivity,
          routine: routine,
          concerns: concerns,
          allergies: allergies,
          loading: loading,
          error: error,
          onBack: _quizBack,
          onSelectSkinType: (value) => setState(() => skinType = value),
          onSelectSensitivity: (value) => setState(() => sensitivity = value),
          onToggleConcern: _toggleConcern,
          onSelectRoutine: (value) => setState(() => routine = value),
          onToggleAllergy: _toggleAllergy,
          onNext: _quizNext,
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
    if (quizStep == 0) {
      _back();
      return;
    }
    setState(() => quizStep--);
  }

  void _quizNext() {
    if (quizStep < 4) {
      setState(() => quizStep++);
    }
  }

  void _restart() {
    setState(() {
      step = 0;
      quizStep = 0;
      error = null;
      result = null;
    });
  }

  void _toggleConcern(String value) {
    setState(() {
      if (concerns.contains(value)) {
        concerns.remove(value);
      } else if (concerns.length < 3) {
        concerns.add(value);
      }
    });
  }

  void _toggleAllergy(String value) {
    setState(() {
      if (allergies.contains(value)) {
        allergies.remove(value);
      } else {
        allergies.add(value);
      }
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

  void _openPricing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PricingScreen(repository: widget.repository),
      ),
    );
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
      final mergedConcerns = [
        ...concerns,
        if (sensitivity.isNotEmpty) 'Nhay cam: $sensitivity',
        if (routine.isNotEmpty) 'Routine: $routine',
        if (allergies.isNotEmpty) 'Di ung: ${allergies.join(', ')}',
      ];
      final data = await widget.repository.analyzeSkin(
        skinType: skinType.isEmpty ? 'Khong chac' : skinType,
        concerns: mergedConcerns,
        goal: 'Tu van quy trinh cham soc da ca nhan hoa',
        planCode: widget.repository.currentPlan,
        imageUrl: isPro ? pickedImage?.dataUrl : null,
      );
      if (!mounted) return;
      setState(() {
        result = data;
        step = 4;
      });
    } catch (_) {
      setState(() {
        error = 'Khong goi duoc API skin-analysis. Kiem tra backend.';
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
    required this.isPro,
    required this.image,
    required this.onCamera,
    required this.onUpload,
    required this.onClear,
    required this.onBack,
    required this.onNext,
  });

  final String locale;
  final bool isPro;
  final PickedSkinImage? image;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback onNext;

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
                    child: Image.network(
                      image!.dataUrl,
                      height: 330,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
                      title: isPro
                          ? l.t('Dùng camera', 'Use camera')
                          : l.t('Mở khóa camera', 'Unlock camera'),
                      onTap: onCamera,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _PhotoAction(
                      icon: Icons.upload_file,
                      title: isPro
                          ? l.t('Tải ảnh lên', 'Upload image')
                          : l.t('Mở khóa upload', 'Unlock upload'),
                      onTap: onUpload,
                    ),
                  ),
                ],
              ),
            if (!isPro) ...[
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
    required this.quizStep,
    required this.skinType,
    required this.sensitivity,
    required this.routine,
    required this.concerns,
    required this.allergies,
    required this.loading,
    required this.error,
    required this.onBack,
    required this.onSelectSkinType,
    required this.onSelectSensitivity,
    required this.onToggleConcern,
    required this.onSelectRoutine,
    required this.onToggleAllergy,
    required this.onNext,
    required this.onAnalyze,
  });

  final String locale;
  final int quizStep;
  final String skinType;
  final String sensitivity;
  final String routine;
  final Set<String> concerns;
  final Set<String> allergies;
  final bool loading;
  final String? error;
  final VoidCallback onBack;
  final ValueChanged<String> onSelectSkinType;
  final ValueChanged<String> onSelectSensitivity;
  final ValueChanged<String> onToggleConcern;
  final ValueChanged<String> onSelectRoutine;
  final ValueChanged<String> onToggleAllergy;
  final VoidCallback onNext;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    final config = _config();
    final canContinue = switch (quizStep) {
      0 => skinType.isNotEmpty,
      1 => sensitivity.isNotEmpty,
      2 => concerns.isNotEmpty,
      3 => routine.isNotEmpty,
      _ => allergies.isNotEmpty,
    };

    return _PageShell(
      locale: locale,
      badge: l.t('Bước 3 / 3', 'Step 3 of 3'),
      title: l.t('Hồ sơ da nhanh', 'Quick Skin Profile'),
      subtitle: l.t(
        'Chỉ vài thao tác - không cần gõ!',
        'A few taps, no typing needed!',
      ),
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: _ProgressDots(index: quizStep, locale: locale),
            ),
            const SizedBox(height: 26),
            Text(
              config.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(config.subtitle),
            const SizedBox(height: 20),
            _OptionGrid(
              options: config.options,
              selected: _selectedForStep(),
              multi: quizStep == 2 || quizStep == 4,
              maxCount: quizStep == 2 ? 3 : null,
              onTap: _onTapForStep,
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 28),
            _NavRow(
              onBack: onBack,
              onNext: canContinue
                  ? quizStep == 4
                        ? onAnalyze
                        : onNext
                  : null,
              nextLabel: quizStep == 4
                  ? loading
                        ? l.t('Đang phân tích...', 'Analyzing...')
                        : l.t('Phân tích da của tôi', 'Analyze my skin')
                  : l.t('Tiếp tục', 'Continue'),
              backLabel: l.t('Quay lại', 'Back'),
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _selectedForStep() => switch (quizStep) {
    0 => {if (skinType.isNotEmpty) skinType},
    1 => {if (sensitivity.isNotEmpty) sensitivity},
    2 => concerns,
    3 => {if (routine.isNotEmpty) routine},
    _ => allergies,
  };

  void _onTapForStep(String value) {
    switch (quizStep) {
      case 0:
        onSelectSkinType(value);
      case 1:
        onSelectSensitivity(value);
      case 2:
        onToggleConcern(value);
      case 3:
        onSelectRoutine(value);
      default:
        onToggleAllergy(value);
    }
  }

  _QuizConfig _config() {
    final l = _L(locale);
    return switch (quizStep) {
      0 => _QuizConfig(
        l.t(
          'Da của bạn thường cảm thấy như thế nào?',
          'How does your skin usually feel?',
        ),
        l.t(
          'Chọn loại mô tả đúng nhất về da của bạn',
          'Choose the description that fits your skin best',
        ),
        [
          l.t('Da dầu', 'Oily'),
          l.t('Da hỗn hợp', 'Combination'),
          l.t('Da thường', 'Normal'),
          l.t('Da khô', 'Dry'),
          l.t('Không chắc', 'Not sure'),
        ],
      ),
      1 => _QuizConfig(
        l.t('Da của bạn nhạy cảm như thế nào?', 'How sensitive is your skin?'),
        l.t(
          'Da của bạn phản ứng với sản phẩm như thế nào?',
          'How does your skin react to products?',
        ),
        [
          l.t('Thường xuyên phản ứng', 'Reacts often'),
          l.t('Đôi khi', 'Sometimes'),
          l.t('Hiếm khi', 'Rarely'),
          l.t('Không chắc', 'Not sure'),
        ],
      ),
      2 => _QuizConfig(
        l.t(
          'Những vấn đề da hàng đầu của bạn là gì?',
          'What are your top skin concerns?',
        ),
        l.t(
          'Chọn tối đa 3 vấn đề quan trọng nhất với bạn',
          'Choose up to 3 concerns that matter most',
        ),
        [
          l.t('Da bị mụn', 'Acne'),
          l.t('Da dầu', 'Oily skin'),
          l.t('Da bị khô/bong tróc', 'Dry or flaky skin'),
          l.t('Da bị dị ứng', 'Irritation'),
          l.t('Da nổi đốm nâu', 'Dark spots'),
          l.t('Da không đều màu', 'Uneven tone'),
          l.t('Da bị tắc lỗ chân lông', 'Clogged pores'),
          l.t('Da xỉn màu', 'Dullness'),
        ],
      ),
      3 => _QuizConfig(
        l.t(
          'Quy trình chăm sóc da hiện tại?',
          'What is your current skincare routine?',
        ),
        l.t(
          'Điều này giúp chúng tôi đề xuất mức độ phức tạp phù hợp',
          'This helps us suggest the right routine complexity',
        ),
        [
          l.t('Chưa có quy trình', 'No routine yet'),
          l.t('Cơ bản', 'Basic'),
          l.t('Đầy đủ', 'Advanced'),
        ],
      ),
      _ => _QuizConfig(
        l.t(
          'Bạn có nhạy cảm với sản phẩm cụ thể nào không?',
          'Are you sensitive to any specific product types?',
        ),
        l.t(
          'Tùy chọn - Chọn những gì phù hợp',
          'Optional - choose what applies',
        ),
        [
          l.t('Mùi hương', 'Fragrance'),
          l.t('Cồn', 'Alcohol'),
          l.t('Axit/Retinoid', 'Acids/Retinoids'),
          l.t('Kem chống nắng', 'Sunscreen'),
          l.t('Không biết', 'Not sure'),
        ],
      ),
    };
  }
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
    final sections = _parseSections(data.recommendations);
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
                  body: sections['Analysis'] ?? data.recommendations,
                  icon: Icons.manage_search,
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RoutineCard(
                        title: l.t('Quy trình buổi sáng', 'Morning routine'),
                        color: const Color(0xFFFFB020),
                        body: sections['Morning routine'] ?? '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoutineCard(
                        title: l.t('Quy trình buổi tối', 'Evening routine'),
                        color: const Color(0xFF7C5CFF),
                        body: sections['Evening routine'] ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RoutineCard(
                        title: l.t(
                          'Thành phần tốt cho bạn',
                          'Ingredients to use',
                        ),
                        color: Colors.green,
                        body: sections['Ingredients to use'] ?? '',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoutineCard(
                        title: l.t('Cẩn thận', 'Use with caution'),
                        color: Colors.deepOrange,
                        body: sections['Ingredients to avoid'] ?? '',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MiniSection(
                  title: l.t('Gợi ý loại sản phẩm', 'Product suggestions'),
                  body: sections['Product suggestions'] ?? '',
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

  Map<String, String> _parseSections(String value) {
    final output = <String, String>{};
    for (final part in value.split('\n\n')) {
      final index = part.indexOf(':');
      if (index > 0) {
        output[part.substring(0, index).trim()] = part
            .substring(index + 1)
            .trim();
      }
    }
    return output;
  }
}

class _QuizConfig {
  const _QuizConfig(this.title, this.subtitle, this.options);
  final String title;
  final String subtitle;
  final List<String> options;
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

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.index, required this.locale});

  final int index;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Container(
              width: i == index ? 58 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: i == index
                    ? const Color(0xFF5BA4D2)
                    : const Color(0xFFDDE7EF),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _L(locale).t('Bước ${index + 1} trong 5', 'Step ${index + 1} of 5'),
        ),
      ],
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.maxCount,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final bool multi;
  final int? maxCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 310,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 4.8,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        final active = selected.contains(option);
        final disabled =
            multi &&
            maxCount != null &&
            selected.length >= maxCount! &&
            !active;
        return InkWell(
          onTap: disabled ? null : () => onTap(option),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: disabled ? Colors.grey : const Color(0xFF566577),
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  result.skinType,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF5BA4D2),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(result.concerns),
              ],
            ),
          ),
          Chip(label: Text('${result.score}/100')),
        ],
      ),
    );
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
          Text(body.isEmpty ? 'Dang cap nhat goi y tu AI.' : body),
        ],
      ),
    );
  }
}
