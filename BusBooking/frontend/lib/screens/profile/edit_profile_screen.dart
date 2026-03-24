import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/mock_data.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, this.user});

  final UserProfile? user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late String email;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.user ?? AuthRepository.instance.currentUser;
    email = current?.email ?? '';
    _nameCtrl = TextEditingController(text: current?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: current?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = AuthRepository.instance.currentUser;
    final profile = UserProfile(
      id: existing?.id ?? widget.user?.id ?? 0,
      email: email,
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: existing?.role ?? widget.user?.role ?? 'User',
    );

    setState(() => saving = true);
    try {
      final updated = await ProfileRepository.instance.updateProfile(profile);
      AuthRepository.instance.currentUser = updated;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật hồ sơ thành công')),
      );
      Navigator.pop(context, updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi cập nhật: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thông tin tài khoản', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập họ tên';
                  }
                  if (value.trim().length < 3) {
                    return 'Họ tên tối thiểu 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Vui lòng nhập số điện thoại';
                  if (text.length < 9 || text.length > 12) return 'Số điện thoại không hợp lệ';
                  if (!RegExp(r'^\+?\d{9,12}$').hasMatch(text)) return 'Chỉ nhập số hoặc +';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Đang lưu...' : 'Lưu thay đổi'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.tripSearch, (route) => false);
                        },
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Về trang chủ'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
