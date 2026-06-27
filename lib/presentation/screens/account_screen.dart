import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/belumi_repository.dart';
import '../../features/auth/application/auth_controller.dart';
import '../widgets/belumi_luxury.dart';
import 'skin_analysis_screen.dart';


class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final message = TextEditingController();
  bool deletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final t = belumiCopy(context).t;
    return LuxuryPage(
      children: [
        LuxuryHero(
          title: t('Hồ sơ Belumi', 'Your Belumi Profile'),
          subtitle: t(
            'Quản lý thông tin cá nhân, gói hiện tại, liên hệ và beauty profile trong một nơi.',
            'Manage your personal info, current plan, contact requests and beauty profile in one place.',
          ),
          imageUrl:
              'https://images.unsplash.com/photo-1498843053639-170ff2122f35?auto=format&fit=crop&w=1200&q=80',
        ),
        const SizedBox(height: 18),
        LuxuryPanel(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(
              widget.repository.currentUser?.fullName ??
                  t('Chưa đăng nhập', 'Not signed in'),
            ),
            subtitle: Text(
              widget.repository.currentUser?.email ??
                  t(
                    'Đăng nhập hoặc đăng ký để đồng bộ Wishlist, Skin AI và Beauty Profile.',
                    'Sign in or register to sync Wishlist, Skin AI and Beauty Profile.',
                  ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (widget.repository.isLoggedIn) ...[
          LuxuryPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxuryHeader(
                  eyebrow: t('Dữ liệu cá nhân', 'Personal Data'),
                  title: t('Hồ sơ & Lịch sử da', 'Skin Profile & History'),
                  subtitle: t(
                    'Xem lại các khảo sát đã trả lời và lịch sử phân tích da của bạn.',
                    'Review your completed survey answers and skin analysis history.',
                  ),
                ),
                const SizedBox(height: 16),
                
                // 1. Hồ sơ Khảo sát sắc đẹp
                InkWell(
                  onTap: () async {
                    final profile = await widget.repository.getBeautyProfile();
                    if (context.mounted) {
                      if (profile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t('Bạn chưa hoàn thành khảo sát nào.', 'No survey completed yet.'))),
                        );
                      } else {
                        // Hiển thị dialog thông tin khảo sát
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: const Color(0xFFFFF9F5),
                            title: Row(
                              children: [
                                const Icon(Icons.assignment_outlined, color: BelumiLuxury.ink),
                                const SizedBox(width: 8),
                                Text(t('Khảo sát của bạn', 'Your Survey')),
                              ],
                            ),
                            content: SingleChildScrollView(
                              child: ListBody(
                                children: [
                                  _surveyDetailItem(t('Biệt danh', 'Nickname'), profile.nickname ?? t('Chưa đặt', 'None')),
                                  _surveyDetailItem(t('Giới tính', 'Gender'), profile.gender == 'female' ? t('Nữ', 'Female') : (profile.gender == 'male' ? t('Nam', 'Male') : t('Khác', 'Other'))),
                                  _surveyDetailItem(t('Độ tuổi', 'Age group'), profile.ageGroup ?? t('Chưa rõ', 'Unknown')),
                                  _surveyDetailItem(t('Loại da', 'Skin type'), profile.skinType == 'oily' ? t('Da dầu', 'Oily') : (profile.skinType == 'dry' ? t('Da khô', 'Dry') : (profile.skinType == 'combination' ? t('Da hỗn hợp', 'Combination') : t('Da thường', 'Normal')))),
                                  _surveyDetailItem(t('Độ nhạy cảm', 'Sensitivity'), profile.skinSensitivity == 'sensitive' ? t('Rất nhạy cảm', 'Highly sensitive') : (profile.skinSensitivity == 'mild' ? t('Hơi nhạy cảm', 'Mildly sensitive') : t('Khá ổn định', 'Stable'))),
                                  _surveyDetailItem(t('Ngân sách tối đa', 'Budget'), profile.budgetRange ?? ''),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text(t('Đóng', 'Close'), style: const TextStyle(color: BelumiLuxury.ink, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BelumiLuxury.peach.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1DFD8)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.assignment_turned_in_outlined, color: BelumiLuxury.rose),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Kết quả Khảo sát đầu vào', 'Entry Survey Result'),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: BelumiLuxury.black),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t('Bấm xem chi tiết câu trả lời khảo sát', 'Tap to view survey answers detail'),
                                style: TextStyle(fontSize: 12, color: BelumiLuxury.muted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: BelumiLuxury.muted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Lịch sử phân tích da
                InkWell(
                  onTap: () async {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => SkinAnalysisHistoryScreen(repository: widget.repository),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BelumiLuxury.peach.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1DFD8)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.history_toggle_off, color: BelumiLuxury.rose),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Lịch sử phân tích da AI', 'AI Skin Analysis History'),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: BelumiLuxury.black),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t('Xem danh sách ảnh chụp & kết quả cũ', 'View list of selfies & past results'),
                                style: TextStyle(fontSize: 12, color: BelumiLuxury.muted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: BelumiLuxury.muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        LuxuryPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LuxuryHeader(
                eyebrow: t('Tư vấn', 'Consultation'),
                title: t('Liên hệ tư vấn', 'Contact for consultation'),
                subtitle: t(
                  'Belumi sẽ liên hệ để hỗ trợ routine và sản phẩm phù hợp.',
                  'Belumi will contact you to support a suitable routine and product selection.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: t('Họ tên', 'Full name'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                decoration: InputDecoration(
                  labelText: t('Số điện thoại', 'Phone'),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: message,
                decoration: InputDecoration(
                  labelText: t('Nội dung', 'Message'),
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 14),
              LuxuryButton(
                label: t('Gửi yêu cầu', 'Send request'),
                icon: Icons.send,
                onPressed: () async {
                  try {
                    await widget.repository.contact(
                      name.text,
                      phone.text,
                      email.text,
                      message.text,
                    );
                  } catch (_) {
                    // Offline demo still confirms the UX flow.
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t(
                            'Belumi đã nhận yêu cầu tư vấn',
                            'Belumi received your consultation request',
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        if (widget.repository.isAdmin) ...[
          const SizedBox(height: 24),
          LuxuryInfoTile(
            icon: Icons.admin_panel_settings_outlined,
            title: t('Admin panel', 'Admin panel'),
            subtitle: t(
              'Bạn đang đăng nhập với quyền Admin.',
              'You are signed in with Admin access.',
            ),
          ),
        ],
        if (widget.repository.isLoggedIn) ...[
          const SizedBox(height: 24),
          LuxuryPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LuxuryHeader(
                  eyebrow: t('Tài khoản', 'Account'),
                  title: t('Xóa tài khoản', 'Delete account'),
                  subtitle: t(
                    'Xóa tài khoản Belumi và dữ liệu liên quan khỏi hệ thống. Hành động này không thể hoàn tác.',
                    'Delete your Belumi account and related data from the system. This action cannot be undone.',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: deletingAccount ? null : _confirmDeleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB85C5C),
                      side: const BorderSide(color: Color(0xFFB85C5C)),
                    ),
                    icon: deletingAccount
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_outlined),
                    label: Text(
                      deletingAccount
                          ? t('Đang xóa...', 'Deleting...')
                          : t('Xóa tài khoản', 'Delete account'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final t = belumiCopy(context).t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Xóa tài khoản?', 'Delete account?')),
        content: Text(
          t(
            'Tài khoản và dữ liệu Belumi liên quan sẽ bị xóa khỏi hệ thống. Bạn có chắc muốn tiếp tục?',
            'Your Belumi account and related data will be deleted from the system. Are you sure you want to continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('Hủy', 'Cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB85C5C),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('Xóa', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final t = belumiCopy(context).t;
    setState(() => deletingAccount = true);
    try {
      await widget.repository.deleteAccount();
      await ref.read(authControllerProvider.notifier).logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('Tài khoản đã được xóa.', 'Your account has been deleted.'),
          ),
        ),
      );
      context.go('/login');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Không xóa được tài khoản. Vui lòng thử lại.',
              'Could not delete the account. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => deletingAccount = false);
    }
  }
}

// Helper widget for Survey Detail items
Widget _surveyDetailItem(String title, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$title:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: BelumiLuxury.muted,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: BelumiLuxury.black,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );
}

