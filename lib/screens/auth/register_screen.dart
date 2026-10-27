import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/field_label.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        displayName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // สมัครสำเร็จ Firebase จะ login ให้อัตโนมัติ → router redirect ไปหน้าหลักเอง
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggleVisibility = IconButton(
      icon: Icon(
        _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
        size: 20,
      ),
      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
    );

    return AuthLayout(
      title: 'สมัครสมาชิก',
      subtitle: 'สร้างบัญชีเพื่อเริ่มบันทึกของในตู้เย็น',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FieldLabel('ชื่อ'),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                hintText: 'ชื่อที่ใช้แสดง',
                prefixIcon: Icon(LucideIcons.user, size: 20),
              ),
              validator: Validators.displayName,
            ),
            const SizedBox(height: 16),
            const FieldLabel('อีเมล'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(LucideIcons.mail, size: 20),
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            const FieldLabel('รหัสผ่าน'),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                hintText: 'อย่างน้อย 6 ตัวอักษร',
                prefixIcon: const Icon(LucideIcons.lock, size: 20),
                suffixIcon: toggleVisibility,
              ),
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            const FieldLabel('ยืนยันรหัสผ่าน'),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'กรอกรหัสผ่านอีกครั้ง',
                prefixIcon: const Icon(LucideIcons.lock, size: 20),
                suffixIcon: toggleVisibility,
              ),
              validator: (value) =>
                  Validators.confirmPassword(value, _passwordController.text),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Text('สมัครสมาชิก'),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'มีบัญชีอยู่แล้ว?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => context.go('/login'),
            child: const Text('เข้าสู่ระบบ'),
          ),
        ],
      ),
    );
  }
}
