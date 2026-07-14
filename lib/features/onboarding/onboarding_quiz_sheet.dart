import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

Future<BeautyProfile?> showOnboardingQuiz(
  BuildContext context, {
  required BelumiRepository repository,
}) {
  return showGeneralDialog<BeautyProfile?>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xFFF6F5F4),
    transitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
      backgroundColor: const Color(0xFFF6F5F4), // var(--neutral-bg-canvas)
      body: SafeArea(
        child: OnboardingQuizSheet(repository: repository),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingQuizSheet extends StatefulWidget {
  const OnboardingQuizSheet({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<OnboardingQuizSheet> createState() => _OnboardingQuizSheetState();
}

class _OnboardingQuizSheetState extends State<OnboardingQuizSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _submitting = false;
  String? _error;

  // ── Q1 ──
  final _nicknameController = TextEditingController();

  // ── Q2 ──
  String? _gender;

  // ── Q3 ──
  String? _ageGroup;

  // ── Q4 ──
  String? _skinType;

  // ── Q5 — max 3 ──
  final Set<String> _skinGoals = {};

  // ── Q6 ──
  String? _skinSensitivity;

  // ── Q7 — max 3 + custom ──
  final Set<String> _avoidedIngredients = {};
  final _customIngredientController = TextEditingController();

  // ── Q8 ──
  String? _budgetRange;

  // ── Q9 ──
  final _currentProductsController = TextEditingController();

  static const int _totalPages = 9;

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _customIngredientController.dispose();
    _currentProductsController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _error = null);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }


  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    // Gộp avoided ingredients: preset + custom nếu có
    final avoidsWithCustom = <String>{..._avoidedIngredients};
    final customIngredient = _customIngredientController.text.trim();
    if (customIngredient.isNotEmpty && !avoidsWithCustom.contains('none')) {
      avoidsWithCustom.add(customIngredient);
    }

    final request = QuizSubmitRequest(
      nickname: _nicknameController.text.trim().isEmpty
          ? null
          : _nicknameController.text.trim(),
      gender: _gender,
      ageGroup: _ageGroup,
      skinType: _skinType,
      skinGoals: _skinGoals.toList(),
      skinSensitivity: _skinSensitivity,
      avoidedIngredients: avoidsWithCustom.toList(),
      budgetRange: _budgetRange,
      currentProducts: _currentProductsController.text.trim().isEmpty
          ? null
          : _currentProductsController.text.trim(),
    );

    try {
      final profile = await widget.repository.submitQuiz(request);
      if (!mounted) return;
      Navigator.of(context).pop(profile);
    } catch (_) {
      // Nếu quiz đã tồn tại (409 Conflict), thử PUT
      try {
        final profile = await widget.repository.updateQuiz(request);
        if (!mounted) return;
        Navigator.of(context).pop(profile);
      } catch (e2) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error = 'Không thể lưu quiz. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuizHeader(
            currentPage: _currentPage,
            totalPages: _totalPages,
            onBack: _currentPage > 0 
                ? _prevPage 
                : () => Navigator.of(context).pop(null),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _Q1Nickname(controller: _nicknameController),
                _Q2Gender(
                  selected: _gender,
                  onSelect: (v) => setState(() => _gender = v),
                ),
                _Q3AgeGroup(
                  selected: _ageGroup,
                  onSelect: (v) => setState(() => _ageGroup = v),
                ),
                _Q4SkinType(
                  selected: _skinType,
                  onSelect: (v) => setState(() => _skinType = v),
                ),
                _Q5SkinGoals(
                  selected: _skinGoals,
                  onToggle: (v) => setState(() {
                    if (_skinGoals.contains(v)) {
                      _skinGoals.remove(v);
                    } else if (_skinGoals.length < 3) {
                      _skinGoals.add(v);
                    }
                  }),
                ),
                _Q6SkinSensitivity(
                  selected: _skinSensitivity,
                  onSelect: (v) => setState(() => _skinSensitivity = v),
                ),
                _Q7AvoidedIngredients(
                  selected: _avoidedIngredients,
                  customController: _customIngredientController,
                  onCustomChanged: () => setState(() {}),
                  onToggle: (v) => setState(() {
                    if (v == 'none') {
                      _avoidedIngredients.clear();
                      _avoidedIngredients.add('none');
                    } else {
                      _avoidedIngredients.remove('none');
                      if (_avoidedIngredients.contains(v)) {
                        _avoidedIngredients.remove(v);
                      } else if (_avoidedIngredients.length < 3) {
                        _avoidedIngredients.add(v);
                      }
                    }
                  }),
                ),
                _Q8BudgetRange(
                  selected: _budgetRange,
                  onSelect: (v) => setState(() => _budgetRange = v),
                ),
                _Q9CurrentProducts(controller: _currentProductsController),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.monaSans(color: Colors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          _QuizFooter(
            currentPage: _currentPage,
            totalPages: _totalPages,
            submitting: _submitting,
            onNext: _isPageValid ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  bool get _isPageValid {
    switch (_currentPage) {
      case 0:
        return true; // Nickname is optional
      case 1:
        return _gender != null;
      case 2:
        return _ageGroup != null;
      case 3:
        return _skinType != null;
      case 4:
        return _skinGoals.isNotEmpty;
      case 5:
        return _skinSensitivity != null;
      case 6:
        return _avoidedIngredients.isNotEmpty || _customIngredientController.text.trim().isNotEmpty;
      case 7:
        return _budgetRange != null;
      case 8:
        return true; // Products is optional
      default:
        return false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout helpers
// ─────────────────────────────────────────────────────────────────────────────

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({
    required this.currentPage,
    required this.totalPages,
    required this.onBack,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (currentPage + 1) / totalPages;
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEBE6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_left,
              color: Color(0xFF3F2E1E),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE6E1DC),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF976D48)),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuizFooter extends StatelessWidget {
  const _QuizFooter({
    required this.currentPage,
    required this.totalPages,
    required this.submitting,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final bool submitting;
  final VoidCallback? onNext;

  bool get isLastPage => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onNext != null;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: submitting ? null : onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? const Color(0xFF976D48) : const Color(0xFFEFEBE6),
          foregroundColor: isEnabled ? Colors.white : const Color(0xFFC4B4A6),
          disabledBackgroundColor: const Color(0xFFEFEBE6),
          disabledForegroundColor: const Color(0xFFC4B4A6),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                isLastPage ? 'Hoàn thành ✨' : 'Tiếp tục',
                style: GoogleFonts.monaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

class _QuizPage extends StatelessWidget {
  const _QuizPage({required this.question, required this.child, this.hint});

  final String question;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity, // align-self: stretch
            child: Text(
              question,
              style: GoogleFonts.monaSans(
                color: const Color(0xFF44403D), // var(--neutral-text-heading)
                fontSize: 24,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w500,
                height: 1.20, // line-height: 120%
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: GoogleFonts.monaSans(
                color: const Color(0xFF816A5C),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFE8E1) : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: selected ? const Color(0xFF976D48) : const Color(0xFFE6E1DC),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.monaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF3F2E1E),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q1 — Biệt danh
// ─────────────────────────────────────────────────────────────────────────────

class _Q1Nickname extends StatelessWidget {
  const _Q1Nickname({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _QuizPage(
      question: 'Tên của bạn là gì?',
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.monaSans(
            color: const Color(0xFF3F2E1E),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.25,
            letterSpacing: 0.08,
          ),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Nhập biệt danh của bạn',
            hintStyle: GoogleFonts.monaSans(
              color: const Color(0xFFA19891), // var(--neutral-text-placeholder)
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.25,
              letterSpacing: 0.08,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            filled: true,
            fillColor: const Color(0xFFF6F5F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: const BorderSide(color: Color(0xFFC4B4A6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: const BorderSide(color: Color(0xFFC4B4A6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(9999),
              borderSide: const BorderSide(color: Color(0xFF976D48), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q2 — Giới tính
// ─────────────────────────────────────────────────────────────────────────────

class _Q2Gender extends StatelessWidget {
  const _Q2Gender({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('female', 'Nữ'),
      ('male', 'Nam'),
      ('other', 'Khác'),
    ];
    return _QuizPage(
      question: 'Giới tính của bạn là gì?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q3 — Nhóm tuổi
// ─────────────────────────────────────────────────────────────────────────────

class _Q3AgeGroup extends StatelessWidget {
  const _Q3AgeGroup({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('under18', 'Dưới 18'),
      ('18-22', '18-22'),
      ('23-26', '23-26'),
      ('over27', 'Trên 27'),
    ];
    return _QuizPage(
      question: 'Bạn thuộc nhóm tuổi nào?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q4 — Loại da
// ─────────────────────────────────────────────────────────────────────────────

class _Q4SkinType extends StatelessWidget {
  const _Q4SkinType({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('normal', 'Da đủ ẩm, không bóng dầu, khá mịn'),
      ('dry', 'Thường khô căng, dễ bong, thiếu ẩm'),
      ('combination', 'Vùng chữ T bóng dầu, hai má khô'),
      ('oily', 'Da dễ tiết nhiều dầu và bóng nhờn'),
      ('sensitive', 'Da dễ bị ngứa, kích ứng hoặc mẩn đỏ'),
    ];
    return _QuizPage(
      question: 'Cảm nhận về làn da hiện tại của bạn giống mô tả nào nhất?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q5 — Mục tiêu da (max 3)
// ─────────────────────────────────────────────────────────────────────────────

class _Q5SkinGoals extends StatelessWidget {
  const _Q5SkinGoals({required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('hydration', 'Cấp ẩm, giảm cảm giác khô'),
      ('brightening', 'Làm sáng, đều màu'),
      ('pore_control', 'Kiềm dầu, lỗ chân lông thông thoáng'),
      ('dark_spot', 'Làm mờ vết thâm sau mụn'),
      ('anti_aging', 'Cải thiện nếp nhăn, dấu hiệu lão hóa'),
      ('soothing', 'Làm dịu cảm giác khó chịu'),
    ];
    return _QuizPage(
      question: 'Bạn muốn cải thiện những điều gì ở làn da hiện tại?',
      hint: 'Chọn tối đa 3 mục tiêu',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected.contains(opt.$1),
                onTap: () => onToggle(opt.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q6 — Độ nhạy cảm
// ─────────────────────────────────────────────────────────────────────────────

class _Q6SkinSensitivity extends StatelessWidget {
  const _Q6SkinSensitivity({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('stable', 'Khá ổn định, ít khi khó chịu'),
      ('mild', 'Thỉnh thoảng hơi nhạy cảm'),
      ('sensitive', 'Rất nhạy cảm với hầu hết sản phẩm, cần chọn cẩn thận'),
    ];
    return _QuizPage(
      question: 'Khi thử mỹ phẩm mới hoặc thời tiết thay đổi, bạn thường cảm thấy da như thế nào?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q7 — Thành phần muốn tránh (max 3 + custom)
// ─────────────────────────────────────────────────────────────────────────────

class _Q7AvoidedIngredients extends StatelessWidget {
  const _Q7AvoidedIngredients({
    required this.selected,
    required this.customController,
    required this.onToggle,
    required this.onCustomChanged,
  });

  final Set<String> selected;
  final TextEditingController customController;
  final ValueChanged<String> onToggle;
  final VoidCallback onCustomChanged;

  @override
  Widget build(BuildContext context) {
    const presets = [
      ('fragrance', 'Hương liệu'),
      ('alcohol', 'Cồn'),
      ('paraben', 'Paraben'),
      ('mineral_oil', 'Dầu khoáng'),
      ('retinol', 'Retinol'),
      ('none', 'Không có'),
    ];
    return _QuizPage(
      question: 'Có những thành phần mỹ phẩm nào bạn muốn tránh không?',
      hint: 'Chọn tối đa 3 mục',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...presets.map(
            (opt) => _OptionButton(
              label: opt.$2,
              selected: selected.contains(opt.$1),
              onTap: () => onToggle(opt.$1),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: customController,
            enabled: !selected.contains('none'),
            onChanged: (_) => onCustomChanged(),
            style: GoogleFonts.monaSans(
              color: const Color(0xFF3F2E1E),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.25,
              letterSpacing: 0.08,
            ),
            decoration: InputDecoration(
              hintText: 'Khác: điền tên thành phần...',
              hintStyle: GoogleFonts.monaSans(
                color: const Color(0xFFA19891), // var(--neutral-text-placeholder)
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.25,
                letterSpacing: 0.08,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              filled: true,
              fillColor: const Color(0xFFF6F5F4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9999),
                borderSide: const BorderSide(color: Color(0xFFC4B4A6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9999),
                borderSide: const BorderSide(color: Color(0xFFC4B4A6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9999),
                borderSide: const BorderSide(color: Color(0xFF976D48), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q8 — Ngân sách
// ─────────────────────────────────────────────────────────────────────────────

class _Q8BudgetRange extends StatelessWidget {
  const _Q8BudgetRange({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    const options = [
      ('under200k', 'Dưới 200.000đ'),
      ('200-300k', '200.000 – 300.000đ'),
      ('300-500k', '300.000 – 500.000đ'),
      ('500k-1m', '500.000đ – 1.000.000đ'),
      ('over1m', 'Trên 1.000.000đ'),
    ];
    return _QuizPage(
      question: 'Mức chi trung bình cho 1 sản phẩm chăm sóc da của bạn khoảng bao nhiêu?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Q9 — Sản phẩm đang dùng
// ─────────────────────────────────────────────────────────────────────────────

class _Q9CurrentProducts extends StatelessWidget {
  const _Q9CurrentProducts({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return _QuizPage(
      question: 'Hãy điền tên các loại mỹ phẩm bạn đang sử dụng nhé!',
      hint: 'Tuỳ chọn — liệt kê sản phẩm bạn đang dùng hàng ngày',
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: TextField(
          controller: controller,
          minLines: 4,
          maxLines: 8,
          keyboardType: TextInputType.multiline,
          style: GoogleFonts.monaSans(
            color: const Color(0xFF3F2E1E),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.25,
            letterSpacing: 0.08,
          ),
          decoration: InputDecoration(
            hintText: 'Ví dụ: Sữa rửa mặt Cetaphil, Serum Klairs...',
            hintStyle: GoogleFonts.monaSans(
              color: const Color(0xFFA19891), // var(--neutral-text-placeholder)
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.25,
              letterSpacing: 0.08,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            filled: true,
            fillColor: const Color(0xFFF6F5F4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFC4B4A6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFC4B4A6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF976D48), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
