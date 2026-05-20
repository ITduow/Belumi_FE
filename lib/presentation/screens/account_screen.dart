import 'package:flutter/material.dart';

import '../../data/repositories/belumi_repository.dart';
import '../widgets/belumi_luxury.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.repository});

  final BelumiRepository repository;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final message = TextEditingController();

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
      ],
    );
  }
}
