import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/constants/app_assets.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/pages/ForgotPasswordPage.dart';
import 'package:motorent/pages/RegisterPage.dart';
import 'package:motorent/services/firebase_api.dart';
import 'package:motorent/widgets/RootShell.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/auth/login_decor.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 120,
                child: IgnorePointer(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LoginCitySkylinePainter(
                            color: AuthTheme.skyline.withValues(alpha: 0.65),
                            mirror: true,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LoginDashedRoutePainter(
                            color: AuthTheme.primary.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 18,
                        bottom: 28,
                        child: Icon(
                          Icons.location_on,
                          color: AuthTheme.primary,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28, 8, 28, 24 + bottomInset),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset(
                              AppAssets.appIcon,
                              height: 168,
                              width: 168,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'مرحبًا بك في توصيله برو',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AuthTheme.textDark,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'سجّل الدخول للمتابعة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AuthTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _LoginField(
                          controller: phoneController,
                          hint: 'رقم الهاتف',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'يرجى إدخال رقم الهاتف';
                            }
                            final digits =
                                v.replaceAll(RegExp(r'[^0-9]'), '');
                            if (digits.length < 10 || digits.length > 15) {
                              return 'رقم الهاتف غير صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _LoginField(
                          controller: passwordController,
                          hint: 'كلمة المرور',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _isObscure,
                          suffix: IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AuthTheme.textMuted,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _isObscure = !_isObscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'يرجى إدخال كلمة المرور';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ForgotPasswordPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AuthTheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AuthTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LoginButton(
                          isLoading: _isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await login();
                            }
                          },
                        ),
                        const SizedBox(height: 22),
                        const _OrDivider(),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterPage(),
                              ),
                            );
                          },
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 14,
                                color: AuthTheme.textDark,
                              ),
                              children: [
                                TextSpan(text: 'ليس لديك حساب؟ '),
                                TextSpan(
                                  text: 'إنشاء حساب',
                                  style: TextStyle(
                                    color: AuthTheme.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _arabicValidationMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('email field is required') ||
        lower.contains('the email field is required') ||
        (lower.contains('email') && lower.contains('required'))) {
      return 'السيرفر لسه بيطلب إيميل. ارفع ملف AuthController.php المحدّث ثم سجّل برقم الهاتف.';
    }
    if (lower.contains('phone field is required') ||
        lower.contains('login field is required') ||
        lower == 'أدخل رقم الهاتف.') {
      return 'تعذر قراءة رقم الهاتف. حاول مرة أخرى.';
    }
    if (lower.contains('password field is required')) {
      return 'أدخل كلمة المرور.';
    }
    if (lower.contains('invalid email or password') ||
        lower.contains('رقم الهاتف أو كلمة المرور غير صحيحة')) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    }
    return raw;
  }

  String _loginErrorMessage(dynamic responseData, int? statusCode) {
    if (responseData is Map) {
      if (responseData['status'] == 'error') {
        final msg = responseData['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return _arabicValidationMessage(msg);
        }
      }
      if (responseData['message'] != null &&
          statusCode != null &&
          statusCode >= 500) {
        return 'خطأ في السيرفر. تأكد من إعداد قاعدة البيانات ثم حاول مرة أخرى';
      }
      final errors = responseData['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return _arabicValidationMessage(first.first.toString());
        }
      }
      final message = responseData['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return _arabicValidationMessage(message);
      }
    }
    if (statusCode == 401) {
      return 'رقم الهاتف أو كلمة المرور غير صحيحة';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'خطأ في السيرفر. حاول مرة أخرى لاحقاً';
    }
    return 'فشل الاتصال بالسيرفر، حاول مرة أخرى';
  }

  Future<void> login() async {
    setState(() => _isLoading = true);
    try {
      final loginId = phoneController.text.trim();
      if (loginId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('أدخل رقم الهاتف.')),
        );
        return;
      }
      final isEmail = loginId.contains('@');
      final data = <String, dynamic>{
        'login': loginId,
        'username': loginId,
        'password': passwordController.text,
        if (isEmail) 'email': loginId,
        if (!isEmail) 'phone': loginId,
        if (!isEmail) 'mobile': loginId,
      };

      final response = await Dio().post(
        loginRento,
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 600,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

      final resData = response.data;
      final statusCode = response.statusCode;

      if (statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loginErrorMessage(resData, statusCode))),
        );
        print('Login failed ($statusCode): $resData');
        return;
      }

      if (resData is! Map) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('استجابة غير متوقعة من السيرفر')),
        );
        return;
      }

      var status = resData['status'];

      if (status == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_loginErrorMessage(resData, statusCode))),
        );
        return;
      }

      final token = resData['token'];
      final user = resData['user'];

      if (status == 'suspended') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resData['message']?.toString() ??
                  'تم إيقاف الحساب مؤقتاً. تواصل مع الإدارة.',
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      } else if (status == 'success' ||
          status == 'nosub' ||
          status == 'not_approved' ||
          status == 'expired' ||
          status == 'plans_disabled') {
        final userMap =
            user is Map ? Map<String, dynamic>.from(user) : <String, dynamic>{};
        var cachedTitle = userMap['title']?.toString() ?? 'user';
        if (cachedTitle == 'vendor') cachedTitle = 'merchant';
        if (status == 'not_approved' && cachedTitle != 'driver') {
          status = 'success';
        }
        // حساب جديد على نفس الجهاز: لا نرث قسم النشاط ولا إشعارات الحساب السابق.
        final previousId = CacheHelper.getData(key: 'id')?.toString();
        if (previousId != userMap['id']?.toString()) {
          await AuthPrefs.clearAccountScopedData();
        }
        final hubFromServer =
            (userMap['vendor_hub_section'] ?? '').toString().trim().toLowerCase();
        if (hubFromServer == 'orders' ||
            hubFromServer == 'bookings' ||
            hubFromServer == 'services') {
          await AuthPrefs.saveVendorHubSection(hubFromServer);
        }
        await CacheHelper.saveData(key: 'token', value: token);
        await CacheHelper.saveData(key: 'id', value: userMap['id']);
        await CacheHelper.saveData(
          key: 'name',
          value: userMap['name']?.toString() ?? '',
        );
        await CacheHelper.saveData(
          key: 'username',
          value: userMap['username']?.toString() ?? '',
        );
        await CacheHelper.saveData(
          key: 'email',
          value: userMap['email']?.toString() ?? '',
        );
        await CacheHelper.saveData(
          key: 'title',
          value: cachedTitle,
        );
        final isAdminFlag = userMap['is_admin'] == 1 ||
            userMap['is_admin'] == true ||
            userMap['is_admin'] == '1' ||
            (userMap['title']?.toString() == 'admin');
        await CacheHelper.saveData(key: 'is_admin', value: isAdminFlag);
        if (isAdminFlag) {
          await CacheHelper.saveData(key: 'title', value: 'admin');
          final keys = userMap['permission_keys'] ?? userMap['permissions'];
          String stored = '*';
          if (keys is List) {
            stored = keys.map((e) => e.toString()).join(',');
          } else if (keys != null) {
            stored = keys.toString();
          }
          await CacheHelper.saveData(key: 'admin_permissions', value: stored);
          await CacheHelper.saveData(
            key: 'is_super_admin',
            value: userMap['is_super_admin'] == true ||
                userMap['is_super_admin'] == 1 ||
                userMap['is_super_admin'] == '1',
          );
        }
        await CacheHelper.saveData(key: 'status', value: status);
        final phone = userMap['phone']?.toString() ?? loginId;
        if (phone.isNotEmpty) {
          await CacheHelper.saveData(key: 'phone', value: phone);
        }
        await AuthPrefs.markRegistrationCompleted();

        unawaited(
          FirebaseApi()
              .initNotification()
              .timeout(const Duration(seconds: 15))
              .catchError((e) => print('FCM init failed: $e')),
        );
        navigateTo(RootShell());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع')),
        );
      }
    } on DioException catch (e) {
      print('Login DioException: $e');
      final resData = e.response?.data;
      final statusCode = e.response?.statusCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.type == DioExceptionType.connectionTimeout ||
                    e.type == DioExceptionType.receiveTimeout ||
                    e.error is SocketException
                ? 'تعذر الاتصال بالسيرفر. تحقق من الإنترنت'
                : _loginErrorMessage(resData, statusCode),
          ),
        ),
      );
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ بيانات الدخول')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void navigateTo(Widget page) {
    Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => page),
      );
    });
  }
}

class _LoginField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 15,
        color: AuthTheme.textDark,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 14,
          color: AuthTheme.textMuted,
        ),
        // RTL: suffix = visual left — icon box (+ eye for password).
        suffixIconConstraints: const BoxConstraints(minHeight: 52, minWidth: 0),
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suffix != null) suffix!,
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AuthTheme.textMuted, size: 20),
              ),
            ],
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _LoginButton({
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthTheme.primary.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: Divider(color: Color(0xFFD1D5DB), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'أو',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              color: AuthTheme.textMuted,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFD1D5DB), thickness: 1)),
      ],
    );
  }
}
