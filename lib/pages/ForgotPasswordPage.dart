import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/pages/LoginPage.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/auth/login_decor.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool _otpSent = false;
  bool _isLoading = false;
  bool _isObscure = true;
  bool _isCObscure = true;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetOtp() async {
    if (!_validateEmailField()) return;

    setState(() => _isLoading = true);

    try {
      final identifier = emailController.text.trim();
      final isEmail = identifier.contains('@');
      final response = await Dio().post(
        forgotPasswordEP,
        data: {
          'login': identifier,
          if (isEmail) 'email': identifier,
          if (!isEmail) 'phone': identifier,
        },
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (!mounted) return;

      final data = response.data;
      final ok = response.statusCode == 200 &&
          data is Map &&
          (data['status']?.toString() == 'success' ||
              data['status_code']?.toString() == '200');

      if (ok) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(response.statusCode, response.data)),
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e.response?.statusCode, e.response?.data)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await Dio().post(
        resetPasswordEP,
        data: {
          'login': emailController.text.trim(),
          'email': emailController.text.trim(),
          'otp': otpController.text.trim(),
          'new_password': passwordController.text,
          'new_password_confirmation': confirmPasswordController.text,
        },
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تغيير كلمة المرور بنجاح'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(response.statusCode, response.data)),
          ),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage(e.response?.statusCode, e.response?.data)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _validateEmailField() {
    final value = emailController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل البريد الإلكتروني أو رقم الهاتف')),
      );
      return false;
    }
    if (value.contains('@')) {
      final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
      if (!emailRegex.hasMatch(value)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('صيغة البريد الإلكتروني غير صحيحة')),
        );
        return false;
      }
      return true;
    }
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم الهاتف غير صحيح')),
      );
      return false;
    }
    return true;
  }

  String _errorMessage(int? statusCode, dynamic data) {
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        if (_isServerCodeError(message)) {
          return 'خطأ في ملف AuthController.php على السيرفر. ارفع النسخة الصحيحة من المشروع.';
        }
        return message;
      }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        if (errors['new_password'] is List && errors['new_password'].isNotEmpty) {
          return _translateValidationError(errors['new_password'].first.toString());
        }
        if (errors['password'] is List && errors['password'].isNotEmpty) {
          return _translateValidationError(errors['password'].first.toString());
        }
        if (errors['otp'] is List && errors['otp'].isNotEmpty) {
          return _translateValidationError(errors['otp'].first.toString());
        }
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return _translateValidationError(first.first.toString());
        }
      }
    }

    if (statusCode == 404) {
      return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
    }
    if (statusCode == 422) {
      return 'تحقق من البيانات المدخلة وحاول مرة أخرى';
    }
    if (statusCode == 500) {
      return 'تعذر إرسال رمز التحقق. تحقق من إعدادات البريد على السيرفر';
    }
    return 'حدث خطأ، حاول مرة أخرى';
  }

  String _translateValidationError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('new password field is required') ||
        lower.contains('password field is required')) {
      return 'كلمة المرور الجديدة مطلوبة';
    }
    if (lower.contains('confirmation') && lower.contains('match')) {
      return 'كلمة المرور غير متطابقة';
    }
    if (lower.contains('otp') && lower.contains('required')) {
      return 'رمز التحقق مطلوب';
    }
    if (lower.contains('size') && lower.contains('4')) {
      return 'رمز التحقق يجب أن يكون 4 أرقام';
    }
    return message;
  }

  bool _isServerCodeError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('syntax error') ||
        lower.contains('parseerror') ||
        lower.contains('unexpected identifier') ||
        lower.contains('expecting "function"');
  }

  InputDecoration _fieldDecoration({
    required String label,
    Widget? suffixIcon,
    String? counterText,
  }) {
    return InputDecoration(
      labelText: label,
      counterText: counterText,
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(
        fontFamily: 'Cairo',
        color: AuthTheme.textMuted,
      ),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthTheme.fieldBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthTheme.fieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AuthTheme.primary, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AuthTheme.creamBg,
        body: Container(
          decoration: AuthTheme.screenBackground(),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 110,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LoginCitySkylinePainter(
                      color: AuthTheme.skyline.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AuthTheme.textDark,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.asset(
                                    AppAssets.appIcon,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'استعادة كلمة المرور',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  color: AuthTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _otpSent
                                    ? 'أدخل رمز التحقق المرسل إلى بريدك ثم عيّن كلمة مرور جديدة'
                                    : 'أدخل بريدك الإلكتروني أو رقم الهاتف وسنرسل رمز التحقق إلى البريد المسجّل على الحساب',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  color: AuthTheme.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                readOnly: _otpSent,
                                style: const TextStyle(fontFamily: 'Cairo'),
                                decoration: _fieldDecoration(
                                  label: 'البريد الإلكتروني أو رقم الهاتف',
                                  suffixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: AuthTheme.textMuted,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'أدخل البريد الإلكتروني أو رقم الهاتف';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              if (!_otpSent)
                                _PrimaryButton(
                                  label: 'إرسال رمز التحقق',
                                  loading: _isLoading,
                                  onPressed: _sendResetOtp,
                                )
                              else ...[
                                TextFormField(
                                  controller: otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 22,
                                    letterSpacing: 8,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  decoration: _fieldDecoration(
                                    label: 'رمز التحقق',
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().length != 4) {
                                      return 'أدخل رمز التحقق المكون من 4 أرقام';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: passwordController,
                                  obscureText: _isObscure,
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                  decoration: _fieldDecoration(
                                    label: 'كلمة المرور الجديدة',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isObscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AuthTheme.textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _isObscure = !_isObscure,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: confirmPasswordController,
                                  obscureText: _isCObscure,
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                  decoration: _fieldDecoration(
                                    label: 'تأكيد كلمة المرور',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isCObscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AuthTheme.textMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _isCObscure = !_isCObscure,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != passwordController.text) {
                                      return 'كلمة المرور غير متطابقة';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                _PrimaryButton(
                                  label: 'تغيير كلمة المرور',
                                  loading: _isLoading,
                                  onPressed: _resetPassword,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _otpSent = false;
                                            otpController.clear();
                                            passwordController.clear();
                                            confirmPasswordController.clear();
                                          });
                                        },
                                  child: const Text(
                                    'إعادة إرسال الرمز لبريد آخر',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      color: AuthTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthTheme.primary.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}
