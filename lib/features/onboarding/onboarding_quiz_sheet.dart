import 'package:flutter/material.dart';

import '../../data/models/belumi_models.dart';
import '../../data/repositories/belumi_repository.dart';
import '../../presentation/widgets/belumi_luxury.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

Future<BeautyProfile?> showOnboardingQuiz(
  BuildContext context, {
  required BelumiRepository repository,
}) {
  return showDialog<BeautyProfile?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFFFF9F5),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
          maxWidth: 480,
        ),
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

  void _skip() => Navigator.of(context).pop(null);

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuizHeader(
          currentPage: _currentPage,
          totalPages: _totalPages,
          onSkip: _skip,
        ),
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
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        _QuizFooter(
          currentPage: _currentPage,
          totalPages: _totalPages,
          submitting: _submitting,
          onBack: _currentPage > 0 ? _prevPage : null,
          onNext: _isPageValid ? _nextPage : null,
        ),
      ],
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
    required this.onSkip,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = (currentPage + 1) / totalPages;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Row(
            children: [
              const BelumiLogo(height: 22),
              const Spacer(),
              Text(
                '${currentPage + 1} / $totalPages',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: BelumiLuxury.muted),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Bỏ qua',
                  style: TextStyle(color: BelumiLuxury.muted, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFF1DFD8),
              color: BelumiLuxury.rose,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
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
    this.onBack,
  });

  final int currentPage;
  final int totalPages;
  final bool submitting;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  bool get isLastPage => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            if (onBack != null) ...[
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BelumiLuxury.black,
                  side: const BorderSide(color: Color(0xFFF1DFD8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Quay lại'),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: submitting ? null : onNext,
                style: FilledButton.styleFrom(
                  backgroundColor: BelumiLuxury.rose,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    : Text(isLastPage ? 'Hoàn thành ✨' : 'Tiếp theo →'),
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: BelumiLuxury.black,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: TextStyle(color: BelumiLuxury.muted, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
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
    this.emoji,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? BelumiLuxury.rose.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? BelumiLuxury.rose : const Color(0xFFF1DFD8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? BelumiLuxury.rose : BelumiLuxury.black,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: BelumiLuxury.rose, size: 20),
          ],
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
      question: 'Belumi nên gọi bạn là gì nhỉ?',
      hint: 'Điền biệt danh hoặc tên bạn muốn Belumi gọi (tuỳ chọn)',
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Ví dụ: Mai, Linh, An...',
          prefixIcon: Icon(Icons.person_outline),
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
      ('female', 'Nữ', '👩'),
      ('male', 'Nam', '👨'),
      ('other', 'Khác', '🌈'),
    ];
    return _QuizPage(
      question:
          'Để gợi ý thông tin được cá nhân hóa và phù hợp hơn, bạn cho Belumi biết giới tính nhé?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
                emoji: opt.$3,
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
      ('18-22', '18 – 22'),
      ('23-26', '23 – 26'),
      ('over27', 'Trên 27'),
    ];
    return _QuizPage(
      question:
          'Vì làn da ở mỗi độ tuổi có nhu cầu khác nhau, bạn thuộc nhóm tuổi nào?',
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
      ('normal', 'Da đủ ẩm, không bóng dầu, khá mịn', '✨'),
      ('dry', 'Da thường thấy khô căng, dễ bong, thiếu ẩm', '🌵'),
      ('combination', 'Vùng chữ T bóng dầu, hai má khô', '🌗'),
      ('oily', 'Da dễ tiết nhiều dầu và bóng nhờn', '💧'),
      (
        'sensitive',
        'Your face feels itchy, tight, or easily irritated/reddened by the air or natural state.',
        '🌬️',
      ),
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
                emoji: opt.$3,
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
      ('hydration', 'Cấp ẩm, giảm cảm giác khô', '💧'),
      ('brightening', 'Làm sáng, đều màu', '☀️'),
      ('pore_control', 'Kiềm dầu, lỗ chân lông thông thoáng', '🌿'),
      ('dark_spot', 'Làm mờ vết thâm sau mụn', '✨'),
      ('anti_aging', 'Cải thiện nếp nhăn, dấu hiệu lão hóa', '⏳'),
      ('soothing', 'Làm dịu cảm giác khó chịu', '🌸'),
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
                emoji: opt.$3,
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
      ('stable', 'Khá ổn định, ít khi khó chịu', '🟢'),
      ('mild', 'Thỉnh thoảng hơi nhạy cảm', '🟡'),
      (
        'sensitive',
        'Rất nhạy cảm với hầu hết sản phẩm, cần chọn cẩn thận',
        '🔴',
      ),
    ];
    return _QuizPage(
      question:
          'Khi thử mỹ phẩm mới hoặc thời tiết thay đổi, bạn thường cảm thấy da như thế nào?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
                emoji: opt.$3,
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
      ('fragrance', 'Hương liệu', '🌸'),
      ('alcohol', 'Cồn', '🧪'),
      ('paraben', 'Paraben', '⚗️'),
      ('mineral_oil', 'Dầu khoáng', '🛢️'),
      ('retinol', 'Retinol', '💊'),
      ('none', 'Không có', '✅'),
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
              emoji: opt.$3,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: customController,
            enabled: !selected.contains('none'),
            onChanged: (_) => onCustomChanged(),
            decoration: const InputDecoration(
              hintText: 'Khác: điền tên thành phần...',
              prefixIcon: Icon(Icons.edit_outlined),
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
      ('under200k', 'Dưới 200.000đ', '💰'),
      ('200-300k', '200.000 – 300.000đ', '💰💰'),
      ('300-500k', '300.000 – 500.000đ', '💰💰💰'),
      ('500k-1m', '500.000đ – 1.000.000đ', '💎'),
      ('over1m', 'Trên 1.000.000đ', '💎💎'),
    ];
    return _QuizPage(
      question:
          'Mức chi trung bình cho 1 sản phẩm chăm sóc da của bạn khoảng bao nhiêu?',
      child: Column(
        children: options
            .map(
              (opt) => _OptionButton(
                label: opt.$2,
                selected: selected == opt.$1,
                onTap: () => onSelect(opt.$1),
                emoji: opt.$3,
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
      question: 'Tên những mỹ phẩm bạn đang dùng là gì?',
      hint: 'Tuỳ chọn — liệt kê sản phẩm bạn đang dùng hàng ngày',
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 6,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          hintText: 'Ví dụ: Cosrx snail toner, La Roche-Posay Effaclar...',
          prefixIcon: Padding(
            padding: EdgeInsets.only(top: 12),
            child: Icon(Icons.inventory_2_outlined),
          ),
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}
