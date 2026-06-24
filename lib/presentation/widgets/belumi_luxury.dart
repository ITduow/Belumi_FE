import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/i18n/app_strings.dart';

BelumiCopy belumiCopy(BuildContext context) {
  return BelumiCopy(ProviderScope.containerOf(context).read(appLocaleProvider));
}

class BelumiLuxury {
  static const ink = Color(0xFF193447);
  static const black = Color(0xFF15110F);
  static const rose = Color(0xFFE7B5AA);
  static const peach = Color(0xFFFFE8E0);
  static const cream = Color(0xFFFFF9F5);
  static const muted = Color(0xFF7E6E68);

  static const background = BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.topLeft,
      radius: 1.35,
      colors: [Color(0xFFFFE8E0), Color(0xFFFFFFFF)],
    ),
  );
}

class BelumiLogo extends StatefulWidget {
  const BelumiLogo({super.key, this.height = 36, this.dark = false});

  final double height;
  final bool dark;

  @override
  State<BelumiLogo> createState() => _BelumiLogoState();
}

class _BelumiLogoState extends State<BelumiLogo> {
  Timer? _adminHoldTimer;
  bool _isHolding = false;
  bool _opened = false;

  void _startAdminHold() {
    if (_isHolding) return;
    _adminHoldTimer?.cancel();
    setState(() {
      _isHolding = true;
      _opened = false;
    });

    _adminHoldTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _opened = true;
      setState(() => _isHolding = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            belumiCopy(
              context,
            ).t('Đang mở chế độ quản trị...', 'Opening admin mode...'),
          ),
        ),
      );
      context.go('/admin-login');
    });
  }

  void _cancelAdminHold() {
    _adminHoldTimer?.cancel();
    _adminHoldTimer = null;
    if (!mounted || _opened) return;
    setState(() => _isHolding = false);
  }

  static const int _adminTapTarget = 5;
  int _adminTapCount = 0;
  DateTime? _lastTapAt;

  void _handleAdminTap() {
    final now = DateTime.now();
    final lastTapAt = _lastTapAt;
    if (lastTapAt == null ||
        now.difference(lastTapAt) > const Duration(seconds: 3)) {
      _adminTapCount = 0;
    }

    _lastTapAt = now;
    _adminTapCount += 1;
    if (_adminTapCount < _adminTapTarget) return;

    _adminTapCount = 0;
    _lastTapAt = null;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          belumiCopy(
            context,
          ).t('Đang mở chế độ quản trị...', 'Opening admin mode...'),
        ),
      ),
    );
    context.go('/admin-login');
  }

  @override
  void dispose() {
    _adminHoldTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/belumi_logo_mark.png',
      height: widget.height,
      fit: BoxFit.contain,
      color: widget.dark ? Colors.white : null,
    );
  }
}

class LuxuryPage extends StatelessWidget {
  const LuxuryPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 34),
    this.maxWidth = 1040,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BelumiLuxury.background,
      child: ListView(
        padding: padding,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LuxuryPanel extends StatelessWidget {
  const LuxuryPanel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1DFD8)),
        boxShadow: [
          BoxShadow(
            color: BelumiLuxury.rose.withOpacity(0.16),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class LuxuryHeader extends StatelessWidget {
  const LuxuryHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: BelumiLuxury.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: BelumiLuxury.black,
                  height: 1.04,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BelumiLuxury.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ],
    );
  }
}

class LuxuryHero extends StatelessWidget {
  const LuxuryHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.eyebrow = 'Belumi Beauty',
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).width >= 760 ? 330 : 390,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/belumi_home_hero.jpg',
                fit: BoxFit.cover,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xDF8F5F57),
                    Color(0xAA9E6A61),
                    Color(0x25000000),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BelumiLogo(height: 34, dark: true),
                  const Spacer(),
                  _GlassPill(label: eyebrow),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: Colors.white,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 10, runSpacing: 10, children: actions),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LuxuryButton extends StatelessWidget {
  const LuxuryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: BelumiLuxury.black,
          side: const BorderSide(color: Color(0xFFE7D7D1)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label),
      );
    }

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: BelumiLuxury.black,
        foregroundColor: Colors.white,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class LuxuryInfoTile extends StatelessWidget {
  const LuxuryInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LuxuryPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: BelumiLuxury.peach,
            child: Icon(icon, color: BelumiLuxury.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: BelumiLuxury.muted),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
