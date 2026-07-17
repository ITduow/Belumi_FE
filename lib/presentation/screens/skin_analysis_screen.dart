import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/i18n/app_strings.dart';
import '../../core/platform/picked_skin_image.dart';
import '../../core/platform/skin_image_picker.dart';
import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
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
    final authState = ref.watch(authControllerProvider);
    final user = authState.valueOrNull;

    ref.listen(authControllerProvider, (prev, next) {
      final prevUser = prev?.valueOrNull;
      final nextUser = next.valueOrNull;
      if (prevUser == null && nextUser != null) {
        _loadBeautyProfile();
      }
    });

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF9F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: BelumiLuxury.rose,
              ),
              const SizedBox(height: 24),
              Text(
                isVi
                    ? 'Yêu cầu đăng nhập'
                    : 'Authentication required',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: BelumiLuxury.black,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isVi
                    ? 'Vui lòng đăng nhập để sử dụng tính năng phân tích da AI này.'
                    : 'Please log in to use this AI skin analysis feature.',
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
                  onPressed: () {
                    context.go('/login');
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
                    isVi ? 'Đăng nhập ngay' : 'Log in now',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
          automaticallyImplyLeading: false,
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
    return Stack(
      children: [
        AnimatedSwitcher(
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
              loading: loading,
              onCamera: () => _pickImage(true),
              onUpload: () => _pickImage(false),
              onClear: () => setState(() => pickedImage = null),
              onBack: _back,
              onNext: pickedImage == null || loading ? null : _analyze,
            ),
            _ => _ResultStep(
              key: const ValueKey('result'),
              locale: locale,
              result: result,
              profile: _beautyProfile,
              isDetailed: isPlusOrPro,
              onRestart: _restart,
              pickedImage: pickedImage,
              repository: widget.repository,
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
        ),
        // Loading overlay khi đang phân tích
        if (loading)
          Container(
            color: Colors.black.withValues(alpha: 0.35),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: BelumiLuxury.rose.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(BelumiLuxury.ink),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      locale == 'vi'
                          ? 'AI đang phân tích da...'
                          : 'AI is analyzing your skin...',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: BelumiLuxury.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locale == 'vi' ? 'Thường mất 10–20 giây' : 'Usually takes 10–20 seconds',
                      style: const TextStyle(
                        fontSize: 13,
                        color: BelumiLuxury.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
    final allowed = await widget.repository.checkAndIncrementLimit('skin_analysis');
    if (!allowed) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hết lượt sử dụng hôm nay 🔒', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Bạn đã dùng hết lượt phân tích da miễn phí của ngày hôm nay (1 lần/ngày). Vui lòng nâng cấp gói Paid để sử dụng không giới hạn!'),
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
      return;
    }

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
    this.loading = false,
  });

  final String locale;
  final bool canUsePhotoAnalysis;
  final PickedSkinImage? image;
  final VoidCallback onCamera;
  final VoidCallback onUpload;
  final VoidCallback onClear;
  final VoidCallback onBack;
  final VoidCallback? onNext;
  final bool loading;

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
    required this.repository,
  });

  final String locale;
  final SkinAnalysisResult? result;
  final BeautyProfile? profile;
  final bool isDetailed;
  final VoidCallback onRestart;
  final VoidCallback onSave;
  final PickedSkinImage? pickedImage;
  final BelumiRepository repository;

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
                  l.t(
                    'Chào ${profile?.nickname ?? 'bạn'}!',
                    'Hello ${profile?.nickname ?? 'there'}!',
                  ),
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
              _AdviceWidget(advice: data.advice, locale: locale),
              _RoutineWidget(routine: data.routine, locale: locale, isDetailed: isDetailed),
              _WarningWidget(warnings: data.warnings, locale: locale),
            ],
          ),
          const SizedBox(height: 24),
          _NoticeBox(locale: locale),
          const SizedBox(height: 24),
          _RecommendedProductsView(locale: locale, skinType: data.skinType, repository: repository),
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

class _AdviceWidget extends StatelessWidget {
  const _AdviceWidget({required this.advice, required this.locale});
  final List<SkinAdvice> advice;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    if (advice.isEmpty) return const SizedBox.shrink();

    return _RoutineCard(
      title: l.t('Lời khuyên skincare', 'Skincare Advice'),
      color: BelumiLuxury.ink,
      icon: Icons.lightbulb_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: advice.map((item) {
          final isHigh = item.priority.toLowerCase() == 'high';
          final isMed = item.priority.toLowerCase() == 'medium';
          // match app palette: high=rose accent, medium=peach-amber, low=ink soft
          final badgeColor = isHigh
              ? BelumiLuxury.rose
              : isMed
                  ? const Color(0xFFD9A090)   // warm peach-amber
                  : BelumiLuxury.ink;
          final badgeLabel = isHigh
              ? l.t('Ưu tiên', 'Priority')
              : isMed
                  ? l.t('Lưu ý', 'Note')
                  : l.t('Tham khảo', 'Info');
          final color = badgeColor;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isHigh
                        ? BelumiLuxury.rose.withValues(alpha: 0.18)
                        : BelumiLuxury.peach,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHigh
                          ? BelumiLuxury.rose
                          : BelumiLuxury.rose.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: isHigh ? const Color(0xFF8B3A2F) : BelumiLuxury.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.concern,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: BelumiLuxury.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: BelumiLuxury.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RoutineWidget extends StatefulWidget {
  const _RoutineWidget({required this.routine, required this.locale, required this.isDetailed});
  final List<SkinRoutineStep> routine;
  final String locale;
  final bool isDetailed;

  @override
  State<_RoutineWidget> createState() => _RoutineWidgetState();
}

class _RoutineWidgetState extends State<_RoutineWidget> {
  String _selectedTab = 'AM';

  @override
  Widget build(BuildContext context) {
    final l = _L(widget.locale);
    if (widget.routine.isEmpty) return const SizedBox.shrink();

    final amSteps = widget.routine.where((s) => s.period == 'AM' || s.period == 'ANY').toList();
    final pmSteps = widget.routine.where((s) => s.period == 'PM' || s.period == 'ANY').toList();
    final allCurrentSteps = _selectedTab == 'AM' ? amSteps : pmSteps;

    // If free plan, show only the first step
    final currentSteps = widget.isDetailed ? allCurrentSteps : allCurrentSteps.take(1).toList();

    return _RoutineCard(
      title: l.t('Routine đề xuất', 'Suggested Routine'),
      color: BelumiLuxury.ink,
      icon: Icons.checklist_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: l.t('Sáng', 'Morning'),
                  isSelected: _selectedTab == 'AM',
                  onTap: () => setState(() => _selectedTab = 'AM'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TabButton(
                  label: l.t('Tối', 'Night'),
                  isSelected: _selectedTab == 'PM',
                  onTap: () => setState(() => _selectedTab = 'PM'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (currentSteps.isEmpty)
            Text(
              l.t('Không có bước nào cho buổi này.', 'No steps for this time.'),
              style: const TextStyle(color: BelumiLuxury.muted),
            )
          else ...[
            ...currentSteps.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: BelumiLuxury.rose.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${step.step}',
                          style: const TextStyle(
                            color: BelumiLuxury.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          step.content,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: BelumiLuxury.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            if (!widget.isDetailed && allCurrentSteps.length > 1) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BelumiLuxury.peach.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BelumiLuxury.rose.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: BelumiLuxury.rose, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.t(
                              '🔒 Các bước tiếp theo đã bị ẩn',
                              '🔒 Next steps are hidden',
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B3A2F)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.t(
                        'Nâng cấp lên gói Paid để mở khóa toàn bộ các bước skincare chi tiết từ PDF.',
                        'Upgrade to a Paid package to unlock all detailed skincare steps from the PDF.',
                      ),
                      style: const TextStyle(fontSize: 12, color: BelumiLuxury.muted, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: BelumiLuxury.rose,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => context.push('/pricing'),
                        icon: const Icon(Icons.workspace_premium, size: 16),
                        label: Text(l.t('Mở khóa Routine ngay 🔓', 'Unlock Routine Now 🔓'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? BelumiLuxury.rose : BelumiLuxury.peach.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? BelumiLuxury.rose : const Color(0xFFF1DFD8),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6B2A1D) : BelumiLuxury.muted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _WarningWidget extends StatelessWidget {
  const _WarningWidget({required this.warnings, required this.locale});
  final List<SkinWarning> warnings;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l = _L(locale);
    if (warnings.isEmpty) return const SizedBox.shrink();

    final highWarnings = warnings.where((w) => w.priority.toLowerCase() == 'high').toList();
    final otherWarnings = warnings.where((w) => w.priority.toLowerCase() != 'high').toList();

    return _RoutineCard(
      title: l.t('Lưu ý đặc biệt', 'Special Cautions'),
      color: BelumiLuxury.rose,
      icon: Icons.warning_amber_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (highWarnings.isNotEmpty)
            ...highWarnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: BelumiLuxury.rose,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w.content,
                          style: const TextStyle(
                            color: Color(0xFF6B2A1D),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          if (otherWarnings.isNotEmpty && highWarnings.isNotEmpty)
            const Divider(color: Color(0xFFF1DFD8), height: 28),
          if (otherWarnings.isNotEmpty)
            ...otherWarnings.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    w.content,
                    style: const TextStyle(
                      color: BelumiLuxury.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                )),
        ],
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BelumiLuxury.peach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BelumiLuxury.rose),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: BelumiLuxury.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.t(
                'Lưu ý: Đây chỉ là hướng dẫn thẩm mỹ, không phải tư vấn y tế. Hãy tham khảo bác sĩ da liễu khi có mối lo ngại về da.',
                'Note: This is cosmetic guidance only, not medical advice. Please consult a dermatologist for skin health concerns.',
              ),
              style: const TextStyle(
                color: BelumiLuxury.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? BelumiLuxury.peach.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? BelumiLuxury.rose : const Color(0xFFF1DFD8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? BelumiLuxury.rose : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? BelumiLuxury.rose : const Color(0xFFD0C4BF),
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: BelumiLuxury.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: BelumiLuxury.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
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
    // Good = ink palette nhạt, Bad = rose rất nhạt
    final bgColor = good
        ? BelumiLuxury.ink.withValues(alpha: 0.04)
        : BelumiLuxury.rose.withValues(alpha: 0.08);
    final borderColor = good
        ? BelumiLuxury.ink.withValues(alpha: 0.15)
        : BelumiLuxury.rose.withValues(alpha: 0.35);
    final titleColor = good ? BelumiLuxury.ink : BelumiLuxury.muted;
    final textColor = good ? BelumiLuxury.black : BelumiLuxury.muted;
    final icon = good ? Icons.check_circle_outline : Icons.cancel_outlined;
    final iconColor = good
        ? BelumiLuxury.ink
        : BelumiLuxury.rose.withValues(alpha: 0.7);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      good ? Icons.check : Icons.close,
                      size: 15,
                      color: iconColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          color: BelumiLuxury.peach.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BelumiLuxury.rose),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: BelumiLuxury.ink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: BelumiLuxury.black,
                fontSize: 13,
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BelumiLuxury.peach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BelumiLuxury.rose),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: BelumiLuxury.muted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.t(
                'Gói Pro mở phân tích ảnh selfie. Free/Plus vẫn có hồ sơ da và tư vấn bằng câu hỏi.',
                'Pro unlocks selfie photo analysis. Free/Plus still support the skin profile and question-based consultation.',
              ),
              style: const TextStyle(
                color: BelumiLuxury.muted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
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
        pointerColor = BelumiLuxury.rose;
        break;
      case 'medium':
      case 'moderate':
        alignmentValue = 0.0;
        label = isVi ? 'Vừa' : 'Moderate';
        pointerColor = const Color(0xFFD9A090); // warm peach-amber
        break;
      case 'mild':
        alignmentValue = -0.5;
        label = isVi ? 'Nhẹ' : 'Mild';
        pointerColor = BelumiLuxury.ink;
        break;
      case 'none':
        alignmentValue = -1.0;
        label = isVi ? 'Không có' : 'None';
        pointerColor = BelumiLuxury.ink;
        break;
      default: // 'low'
        alignmentValue = -1.0;
        label = isVi ? 'Thấp' : 'Low';
        pointerColor = BelumiLuxury.ink;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: level.toLowerCase().trim() == 'high' || level.toLowerCase().trim() == 'severe'
              ? BelumiLuxury.rose
              : const Color(0xFFF1DFD8),
          width: level.toLowerCase().trim() == 'high' || level.toLowerCase().trim() == 'severe' ? 1.5 : 1,
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
          color: BelumiLuxury.ink,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: BelumiLuxury.peach,
      side: const BorderSide(color: Color(0xFFF1DFD8)),
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
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: BelumiLuxury.black,
              side: const BorderSide(color: Color(0xFFF1DFD8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(backLabel),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: onNext != null ? BelumiLuxury.ink : BelumiLuxury.muted,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(nextLabel),
          ),
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
    required this.child,
    this.icon,
  });

  final String title;
  final Color color;
  final Widget child;
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
          child,
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
                  isDetailed: widget.repository.currentPlan == 'monthly' || widget.repository.currentPlan == 'yearly',
                  onRestart: () => Navigator.of(context).pop(),
                  repository: widget.repository,
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

class _RecommendedProductsView extends StatefulWidget {
  const _RecommendedProductsView({
    required this.locale,
    required this.skinType,
    required this.repository,
  });
  final String locale;
  final String skinType;
  final BelumiRepository repository;

  @override
  State<_RecommendedProductsView> createState() => _RecommendedProductsViewState();
}

class _RecommendedProductsViewState extends State<_RecommendedProductsView> {
  List<Product>? _suitableProducts;
  int _visibleCount = 25;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await widget.repository.recommendProductsBySkin(widget.skinType);
    if (mounted) {
      setState(() {
        _suitableProducts = list;
      });
    }
  }

  void _showDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductDetailSheet(product: product, locale: widget.locale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.locale == 'vi';

    if (_suitableProducts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suitableProducts!.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasMore = _suitableProducts!.length > _visibleCount;
    final itemCount = hasMore ? _visibleCount + 1 : _suitableProducts!.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isVi ? 'Gợi ý sản phẩm cho da ${widget.skinType}' : 'Recommended for ${widget.skinType} skin',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: BelumiLuxury.black,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == _visibleCount) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _visibleCount += 25;
                    });
                  },
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1DFD8)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_outline,
                            color: BelumiLuxury.rose,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isVi ? 'Xem thêm' : 'See more',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: BelumiLuxury.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final product = _suitableProducts![index];
              return GestureDetector(
                onTap: () => _showDetail(context, product),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1DFD8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? Image.network(product.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.grey))
                              : const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductDetailSheet extends StatelessWidget {
  const _ProductDetailSheet({required this.product, required this.locale});
  final Product product;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final isVi = locale == 'vi';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    product.imageUrl!,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 100, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (product.brand != null && product.brand!.isNotEmpty)
              Text(
                product.brand!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: BelumiLuxury.rose,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: BelumiLuxury.black,
              ),
            ),
            if (product.sourceUrl != null && product.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final uri = Uri.parse(product.sourceUrl!);
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isVi ? 'Không thể mở liên kết: $e' : 'Cannot open link: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1DFD8)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: BelumiLuxury.rose, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVi ? 'Liên kết sản phẩm / Mua ngay' : 'Product Link / Buy Now',
                              style: const TextStyle(
                                color: BelumiLuxury.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.sourceUrl!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.open_in_new, color: BelumiLuxury.rose, size: 16),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              isVi ? 'Thành phần' : 'Ingredients',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: BelumiLuxury.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.ingredients ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: BelumiLuxury.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isVi ? 'Đóng' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



