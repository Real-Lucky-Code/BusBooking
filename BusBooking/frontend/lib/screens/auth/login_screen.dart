import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_client.dart';
import '../../utils/animation_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscurePassword = true;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final user = await AuthRepository.instance.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      if (!mounted) return;
      
      // Route based on user role
      final role = user.role.toLowerCase();
      
      // Check company registration status for Provider
      if (role == 'provider') {
        final companyStatus = user.companyStatus;
        if (companyStatus == null || companyStatus.isNone || companyStatus.isRejected) {
          // Inform but allow landing on dashboard; dashboard will gate features and guide to register
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vui lòng đăng ký công ty để sử dụng đầy đủ tính năng quản lý.'),
              duration: Duration(seconds: 3),
            ),
          );
        } else if (companyStatus.isPending) {
          // Show pending approval notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Công ty của bạn đang chờ phê duyệt. Vui lòng chờ hoặc cập nhật thông tin'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
      
      final route = role == 'admin'
          ? AppRoutes.adminDashboard
          : role == 'provider'
              ? AppRoutes.companyDashboard
              : AppRoutes.tripSearch; // default: User
      
      if (mounted) Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.08), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -40,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                height: 220,
                width: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Theme.of(context).primaryGradient,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Opacity(
              opacity: 0.16,
              child: Container(
                height: 240,
                width: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Theme.of(context).accentGradient,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: glassSurface(borderRadius: AppRadius.large),
                        child: const Icon(Icons.directions_bus, size: 64, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Column(
                      children: [
                        Text(
                          'Chào mừng quay lại',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng nhập để tiếp tục',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (error != null)
                      ScaleTransition(
                        scale: AlwaysStoppedAnimation(1.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            error!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          ),
                        ),
                      ),
                    if (error != null) const SizedBox(height: 16),
                    Container(
                      decoration: glassSurface(borderRadius: AppRadius.large),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TextField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  borderSide: const BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ProfessionalButton(
                      label: 'Đăng nhập',
                      onPressed: _handleLogin,
                      isLoading: isLoading,
                      icon: Icons.login_rounded,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('hoặc', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: isLoading ? null : () {},
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fingerprint, size: 20, color: primaryColor),
                          const SizedBox(width: 8),
                          Text('Đăng nhập bằng vân tay', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: primaryColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: RichText(
                          text: TextSpan(
                            text: 'Chưa có tài khoản? ',
                            style: TextStyle(color: Colors.grey.shade600),
                            children: [
                              TextSpan(
                                text: 'Đăng ký',
                                style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Đối với tester:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          label: const Text('User', style: TextStyle(fontSize: 11)),
                          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.tripSearch),
                        ),
                        ActionChip(
                          label: const Text('Company', style: TextStyle(fontSize: 11)),
                          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.companyDashboard),
                        ),
                        ActionChip(
                          label: const Text('Admin', style: TextStyle(fontSize: 11)),
                          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard),
                        ),
                        ActionChip(
                          label: const Text('Clear token', style: TextStyle(fontSize: 11)),
                          onPressed: () async {
                            await ApiClient.instance.clearToken();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Token đã xóa')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
