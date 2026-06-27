import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/i18n/app_strings.dart';
import '../../core/platform/picked_skin_image.dart';
import '../../core/platform/skin_image_picker.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/onboarding/onboarding_quiz_sheet.dart';
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

  /// skin_type lấy từ BeautyProfile. Nếu user chưa có profile thì hiện bước hỏi.
  String skinType = '';

  /// null = đang load, true = có profile, false = chưa có
  bool? _hasProfile;

  /// Hồ sơ BeautyProfile của user để hiển thị mục tiêu, thành phần tránh, ngân sách ở màn kết quả
  BeautyProfile? _beautyProfile;

  bool get isPlusOrPro =>
      widget.repository.currentPlan == 'monthly' ||
      widget.repository.currentPlan == 'yearly';
  bool get isPro => widget.repository.currentPlan == 'yearly';
  bool get canUsePhotoAnalysis => true;

  bool get isVi => ref.read(appLocaleProvider) == 'vi';

  @override
  void initState() {
    super.initState();
    _loadBeautyProfile();
  }

  Future<void> _loadBeautyProfile() async {
    try {
      final profile = await widget.repository.getBeautyProfile();
      if (!mounted) return;
      if (profile != null && profile.skinType != null) {
        setState(() {
          skinType = profile.skinType!;
          _hasProfile = true;
          _beautyProfile = profile;
        });
      } else {
        setState(() {
          _hasProfile = false;
          _beautyProfile = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasProfile = false;
          _beautyProfile = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    
    // 1. Loading state
    if (_hasProfile == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF9F5),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 2. Block user if quiz not completed
    if (_hasProfile == false) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF9F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BelumiLuxury.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                size: 80,
                color: BelumiLuxury.rose,
              ),
              const SizedBox(height: 24),
              Text(
                isVi
                    ? 'Yêu cầu hoàn thành khảo sát'
                    : 'Survey completion required',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: BelumiLuxury.black,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isVi
                    ? 'Bạn cần hoàn thành bộ câu hỏi khảo sát cá nhân hóa trước khi tiến hành phân tích da AI.'
                    : 'You need to complete the personalized survey quiz before proceeding with AI skin analysis.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: BelumiLuxury.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final profile = await showOnboardingQuiz(
                      context,
                      repository: widget.repository,
                    );
                    if (profile != null) {
                      _loadBeautyProfile();
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: BelumiLuxury.rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isVi ? 'Làm khảo sát ngay ✨' : 'Take survey now ✨',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Normal flow
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
          // Nếu đã hoàn thành khảo sát, đi thẳng tới analyze
          onNext: pickedImage == null ? null : _analyze,
        ),
        _ => _ResultStep(
          key: const ValueKey('result'),
          locale: locale,
          result: result,
          profile: _beautyProfile,
          isDetailed: isPlusOrPro,
          onRestart: _restart,
          pickedImage: pickedImage,
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

  void _restart() {
    setState(() {
      step = 0;
      error = null;
      result = null;
    });
    // Reload profile để sync với quiz mới nhất
    _loadBeautyProfile();
  }

  Future<void> _pickImage(bool preferCamera) async {
    try {
      final image = await pickSkinImage(preferCamera: preferCamera);
      if (image == null) return;
      setState(() => pickedImage = image);
    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa chọn ảnh. Hãy thử lại.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không mở được camera trên thiết bị này.'),
        ),
      );
    }
  }

  Future<void> _analyze() async {
    setState(() {
      loading = true;
      error = null;
    });

    // Fallback nếu skinType vẫn trống (user bỏ qua bước quiz)
    final effectiveSkinType = skinType.isEmpty ? 'normal' : skinType;

    try {
      if (!widget.repository.isLoggedIn) {
        throw Exception(
          'Vui lòng đăng nhập bằng Firebase trước khi phân tích.',
        );
      }
      if (pickedImage == null) {
        throw Exception('Vui lòng chọn ảnh trước khi phân tích.');
      }

      final data = await widget.repository.analyzeSkin(
        skinType: effectiveSkinType,
        concerns: [effectiveSkinType],
        goal: 'Tư vấn quy trình chăm sóc da cá nhân hóa',
        planCode: widget.repository.currentPlan,
        imageUrl: pickedImage!.dataUrl,
      );
      if (!mounted) return;
      setState(() {
        result = data;
        // Bước result: nếu có profile (3 bước) → step 3; nếu qua quiz (4 bước) → step 4
        step = _hasProfile == true ? 3 : 4;
      });
    } catch (exception) {
      setState(() {
        error = exception.toString().replaceFirst('Exception: ', '');
        // Nếu analyze từ photo step trực tiếp thư bại → ở lại photo step
        if (_hasProfile == true && step != 3) {
          step = 2;
        }
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
              color: BelumiLuxury.ink,
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
              color: BelumiLuxury.black,
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
                'Ảnh của bạn sẽ được xử lý để phân tích tình trạng da. Belumi không xem đây là chẩn đoán y tế.',
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
      title: l.t('Chụp ảnh selfie', 'Take a Selfie'),
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
                      color: BelumiLuxury.cream,
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



class _ResultStep extends StatelessWidget {
  const _ResultStep({
    super.key,
    required this.locale,
    required this.result,
    this.profile,
    required this.isDetailed,
    required this.onRestart,
    required this.onSave,
    this.pickedImage,
  });

  final String locale;
  final SkinAnalysisResult? result;
  final BeautyProfile? profile;
  final bool isDetailed;
  final VoidCallback onRestart;
  final VoidCallback onSave;
  final PickedSkinImage? pickedImage;

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

    final isVi = locale == 'vi';

    return _PageShell(
      locale: locale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4D8B6F), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.t('Chào Mai!', 'Hello Mai!'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: BelumiLuxury.black,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.t('Đây là hồ sơ da của bạn', 'This is your skin profile'),
            style: const TextStyle(color: BelumiLuxury.muted),
          ),
          if (pickedImage != null) ...[
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFF1DFD8)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _PickedImagePreview(image: pickedImage!),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // TIÊU ĐỀ: ĐẶC ĐIỂM BỀ MẶT - TỪ ẢNH PHÂN TÍCH
          Text(
            isVi ? 'ĐẶC ĐIỂM BỀ MẶT – TỪ ẢNH PHÂN TÍCH' : 'SURFACE CHARACTERISTICS – FROM ANALYSIS',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: BelumiLuxury.muted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Grid chứa các thanh chỉ số đo đặc điểm bề mặt da
          _MetricGrid(result: data, locale: locale),
          const SizedBox(height: 16),

          // Lời khuyên/Gợi ý từ kết quả phân tích
          if (data.description.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF4D8B6F).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4D8B6F).withValues(alpha: 0.2)),
              ),
              child: Text(
                data.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF2C5E47),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // MỤC TIÊU CỦA BẠN
          if (profile?.skinGoals != null && profile!.skinGoals.isNotEmpty) ...[
            Text(
              isVi ? 'MỤC TIÊU CỦA BẠN' : 'YOUR SKIN GOALS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: BelumiLuxury.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile!.skinGoals.map((goal) {
                return _GoalChip(goal: goal, locale: locale);
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // THÀNH PHẦN BẠN MUỐN TRÁNH
          if (profile?.avoidedIngredients != null &&
              profile!.avoidedIngredients.isNotEmpty &&
              !profile!.avoidedIngredients.contains('none')) ...[
            Text(
              isVi ? 'THÀNH PHẦN BẠN MUỐN TRÁNH' : 'INGREDIENTS TO AVOID',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: BelumiLuxury.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profile!.avoidedIngredients.map((ing) {
                return Chip(
                  label: Text(
                    _displayAvoidedIngredient(ing, isVi),
                    style: const TextStyle(
                      color: Color(0xFFB85C5C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: const Color(0xFFFFF0F0),
                  side: const BorderSide(color: Color(0xFFFCDCDC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // NGÂN SÁCH THAM KHẢO / SẢN PHẨM
          if (profile?.budgetRange != null) ...[
            Text(
              isVi ? 'NGÂN SÁCH THAM KHẢO / SẢN PHẨM' : 'REFERENCE BUDGET / PRODUCT',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: BelumiLuxury.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _BudgetIndicator(rangeCode: profile!.budgetRange!),
            const SizedBox(height: 32),
          ],

          _ResultCardGrid(
            children: [
              _RoutineCard(
                title: l.t('Lời khuyên skincare', 'Skincare Advice'),
                color: BelumiLuxury.ink,
                icon: Icons.spa_outlined,
                body: _bulletList(
                  data.advice,
                  fallback: l.t(
                    'Đang cập nhật lời khuyên từ AI.',
                    'AI advice is being updated.',
                  ),
                ),
              ),
              _RoutineCard(
                title: l.t('Lưu ý đặc biệt', 'Special Cautions'),
                color: const Color(0xFFB85C5C),
                icon: Icons.warning_amber_rounded,
                body: _bulletList(
                  data.warnings,
                  fallback: l.t(
                    'Chưa có cảnh báo đặc biệt.',
                    'No special cautions detected.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRestart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BelumiLuxury.black,
                    side: const BorderSide(color: Color(0xFFF1DFD8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    l.t('Bắt đầu phân tích mới', 'New Analysis'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: BelumiLuxury.rose,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(l.t('Lưu quy trình', 'Save Routine')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _bulletList(List<String> items, {required String fallback}) =>
      items.isEmpty ? fallback : items.map((item) => '- $item').join('\n');
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.auto_awesome, size: 16, color: BelumiLuxury.ink),
      label: Text(label),
      side: const BorderSide(color: Color(0xFFF1DFD8)),
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
        border: Border.all(color: const Color(0xFFF1DFD8)),
        boxShadow: [
          BoxShadow(
            color: BelumiLuxury.rose.withValues(alpha: 0.16),
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
        color: BelumiLuxury.peach.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1DFD8)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: dark ? BelumiLuxury.ink : BelumiLuxury.rose,
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
          border: Border.all(color: const Color(0xFFF1DFD8)),
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
              '${good ? '' : 'X'} $title',
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
                  '${good ? '' : 'X'} $item',
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
          border: Border.all(color: const Color(0xFFF1DFD8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: BelumiLuxury.ink,
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



// ─────────────────────────────────────────────────────────────────────────────
// New Custom UI widgets for Skin Profile mockup
// ─────────────────────────────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.result, required this.locale});

  final SkinAnalysisResult result;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isVi = locale == 'vi';

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 520;
        final spacing = 12.0;
        final itemWidth = twoColumns
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'MỨC ĐỘ MỤN' : 'ACNE SEVERITY',
                level: result.acneLevel,
                locale: locale,
                badge: result.acneTypes.isNotEmpty
                    ? result.acneTypes.join(', ')
                    : null,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'ĐỘ BÓNG DẦU' : 'OILINESS',
                level: result.oilinessLevel,
                locale: locale,
                badge: result.oilinessZones.contains('forehead') || result.oilinessZones.contains('nose')
                    ? (isVi ? 'Vùng T' : 'T-Zone')
                    : null,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'LỖ CHÂN LÔNG' : 'PORES',
                level: result.poreVisibilityLevel,
                locale: locale,
                badge: isVi ? 'Vùng mũi' : 'Nose area',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'ĐỘ ĐỀU MÀU' : 'SKIN TONE EVENNESS',
                level: result.skinToneEvennessLevel,
                locale: locale,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'VẾT THÂM / ĐỐM SẬM' : 'DARK SPOTS / PIGMENTATION',
                level: result.pigmentationLevel,
                locale: locale,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'DẤU HIỆU LÃO HOÁ' : 'AGING SIGNS',
                level: result.visibleWrinkleLevel,
                locale: locale,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricBar(
                title: isVi ? 'ĐỘ ỬNG ĐỎ / DỄ PHẢN ỨNG' : 'REDNESS / SENSITIVITY',
                level: result.visibleRednessLevel,
                locale: locale,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.title,
    required this.level,
    required this.locale,
    this.badge,
  });

  final String title;
  final String level;
  final String locale;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final isVi = locale == 'vi';
    final double alignmentValue;
    final String label;
    final Color pointerColor;

    switch (level.toLowerCase().trim()) {
      case 'high':
      case 'severe':
        alignmentValue = 1.0;
        label = isVi ? 'Nặng' : 'Severe';
        pointerColor = const Color(0xFFB85C5C);
        break;
      case 'medium':
      case 'moderate':
        alignmentValue = 0.0;
        label = isVi ? 'Vừa' : 'Moderate';
        pointerColor = const Color(0xFFC9965D);
        break;
      case 'mild':
        alignmentValue = -0.5;
        label = isVi ? 'Nhẹ' : 'Mild';
        pointerColor = const Color(0xFF4D8B6F);
        break;
      case 'none':
        alignmentValue = -1.0;
        label = isVi ? 'Không có' : 'None';
        pointerColor = const Color(0xFF4D8B6F);
        break;
      default: // 'low'
        alignmentValue = -1.0;
        label = isVi ? 'Thấp' : 'Low';
        pointerColor = const Color(0xFF4D8B6F);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: level.toLowerCase().trim() == 'high'
              ? const Color(0xFFB85C5C)
              : const Color(0xFFF1DFD8),
          width: level.toLowerCase().trim() == 'high' ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: BelumiLuxury.black,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EDE4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: BelumiLuxury.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Tiến trình trượt 3 mức độ
          Stack(
            alignment: Alignment.center,
            children: [
              // Thanh background mảnh nhẹ
              Container(
                height: 2,
                color: const Color(0xFFF1DFD8),
              ),
              // Ba điểm mốc định vị
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _markerLabel(isVi ? 'THẤP' : 'LOW'),
                  _markerLabel(isVi ? 'VỪA' : 'MID'),
                  _markerLabel(isVi ? 'CAO' : 'HIGH'),
                ],
              ),
              // Pointer chỉ giá trị hiện tại
              AnimatedAlign(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                alignment: Alignment(alignmentValue, 0.0),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: pointerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: pointerColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: pointerColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _markerLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Color(0xFFBFB0A8),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.goal, required this.locale});

  final String goal;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isVi = locale == 'vi';
    final String label;
    switch (goal) {
      case 'hydration':
        label = isVi ? 'Cấp ẩm' : 'Hydration';
        break;
      case 'brightening':
        label = isVi ? 'Làm sáng' : 'Brightening';
        break;
      case 'pore_control':
        label = isVi ? 'Kiềm dầu' : 'Pore control';
        break;
      case 'dark_spot':
        label = isVi ? 'Mờ thâm mụn' : 'Fading dark spots';
        break;
      case 'anti_aging':
        label = isVi ? 'Cải thiện nếp nhăn' : 'Anti aging';
        break;
      case 'soothing':
        label = isVi ? 'Làm dịu da' : 'Soothing';
        break;
      default:
        label = goal;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2C5E47),
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: const Color(0xFFE8F5EE),
      side: const BorderSide(color: Color(0xFFD0EDDF)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

class _BudgetIndicator extends StatelessWidget {
  const _BudgetIndicator({required this.rangeCode});

  final String rangeCode;

  @override
  Widget build(BuildContext context) {
    double alignmentValue = -1.0;
    String minLabel = '200.000đ';
    String maxLabel = '300.000đ';

    switch (rangeCode) {
      case 'under200k':
        alignmentValue = -1.0;
        minLabel = 'Dưới 200.000đ';
        maxLabel = '';
        break;
      case '200-300k':
        alignmentValue = -0.5;
        minLabel = '200.000đ';
        maxLabel = '300.000đ';
        break;
      case '300-500k':
        alignmentValue = 0.0;
        minLabel = '300.000đ';
        maxLabel = '500.000đ';
        break;
      case '500k-1m':
        alignmentValue = 0.5;
        minLabel = '500.000đ';
        maxLabel = '1.000.000đ';
        break;
      case 'over1m':
        alignmentValue = 1.0;
        minLabel = '';
        maxLabel = 'Trên 1.000.000đ';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1DFD8)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1DFD8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Align(
                alignment: Alignment(alignmentValue, 0.0),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC9965D),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (minLabel.isNotEmpty)
                Text(
                  minLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BelumiLuxury.black),
                ),
              if (maxLabel.isNotEmpty)
                Text(
                  maxLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: BelumiLuxury.black),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _displayAvoidedIngredient(String code, bool isVi) {
  switch (code) {
    case 'fragrance':
      return isVi ? 'Hương liệu' : 'Fragrance';
    case 'alcohol':
      return isVi ? 'Cồn khô' : 'Alcohol';
    case 'paraben':
      return isVi ? 'Paraben' : 'Paraben';
    case 'mineral_oil':
      return isVi ? 'Dầu khoáng' : 'Mineral oil';
    case 'retinol':
      return isVi ? 'Retinol' : 'Retinol';
    default:
      return code;
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.onBack,
    required this.onNext,
    this.backLabel = 'Quay lại',
    this.nextLabel = 'Tiếp tục',
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

class SkinAnalysisDetailScreen extends ConsumerStatefulWidget {
  const SkinAnalysisDetailScreen({
    super.key,
    required this.analysisId,
    required this.repository,
  });

  final String analysisId;
  final BelumiRepository repository;

  @override
  ConsumerState<SkinAnalysisDetailScreen> createState() => _SkinAnalysisDetailScreenState();
}

class _SkinAnalysisDetailScreenState extends ConsumerState<SkinAnalysisDetailScreen> {
  bool _loading = true;
  String? _error;
  SkinAnalysisResult? _result;
  BeautyProfile? _beautyProfile;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final res = await widget.repository.getSkinHistoryDetail(widget.analysisId);
      final profile = await widget.repository.getBeautyProfile();
      if (mounted) {
        setState(() {
          _result = res;
          _beautyProfile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final isVi = locale == 'vi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      appBar: AppBar(
        title: Text(isVi ? 'Chi tiết kết quả da' : 'Skin Analysis Detail'),
        elevation: 0,
        backgroundColor: const Color(0xFFFFF9F5),
        foregroundColor: BelumiLuxury.ink,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _result == null
              ? Center(
                  child: Text(
                    isVi ? 'Không tải được chi tiết kết quả.' : 'Failed to load details.',
                    style: const TextStyle(color: BelumiLuxury.muted),
                  ),
                )
              : _ResultStep(
                  locale: locale,
                  result: _result,
                  profile: _beautyProfile,
                  isDetailed: true,
                  onRestart: () => Navigator.of(context).pop(),
                  onSave: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isVi
                              ? 'Đã lưu quy trình thành công'
                              : 'Routine saved successfully',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class SkinAnalysisHistoryScreen extends ConsumerStatefulWidget {
  const SkinAnalysisHistoryScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<SkinAnalysisHistoryScreen> createState() => _SkinAnalysisHistoryScreenState();
}

class _SkinAnalysisHistoryScreenState extends ConsumerState<SkinAnalysisHistoryScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await widget.repository.getSkinHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final isVi = locale == 'vi';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F5),
      appBar: AppBar(
        title: Text(isVi ? 'Lịch sử phân tích da' : 'Skin History'),
        elevation: 0,
        backgroundColor: const Color(0xFFFFF9F5),
        foregroundColor: BelumiLuxury.ink,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Text(
                    isVi ? 'Bạn chưa phân tích da lần nào.' : 'No analysis history found.',
                    style: const TextStyle(color: BelumiLuxury.muted),
                  ),
                )
              : LuxuryPage(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        final id = (item['id'] ?? item['Id'] ?? '').toString();
                        final skinType = (item['skinType'] ?? item['skin_type'] ?? item['SkinType'] ?? 'Normal').toString();
                        final dateStr = (item['analyzedAt'] ?? item['analyzed_at'] ?? item['AnalyzedAt'] ?? '').toString();
                        DateTime? parsedDate = DateTime.tryParse(dateStr);
                        String formattedDate = parsedDate != null
                            ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
                            : dateStr;

                        return InkWell(
                          onTap: () async {
                            if (id.isEmpty) return;
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => SkinAnalysisDetailScreen(
                                  analysisId: id,
                                  repository: widget.repository,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFF1DFD8)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.analytics_outlined, color: BelumiLuxury.rose, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isVi ? 'Phân tích da: $skinType' : 'Skin Analysis: $skinType',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: BelumiLuxury.black),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 11, color: BelumiLuxury.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: BelumiLuxury.muted, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}


