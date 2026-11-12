import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/data/remote/ApiService.dart';
import 'package:motorent/models/vehicle_type_model.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/widgets/auth/auth_brand_mark.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/auth/login_decor.dart';

import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/pages/LoginPage.dart';
import 'package:motorent/pages/Privacy_policy_page.dart';

import '../data/local/cache_helper.dart';
import '../services/firebase_api.dart';
import '../widgets/RootShell.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_business_type_page.dart';

/// موديلات الأماكن (تقدر تحطهم في ملف مستقل)
/*class AreaModel {
  final int? id;
  final String name;

  AreaModel({this.id, required this.name});

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'],
      name: json['name'] ?? '',
    );
  }
}

class GovernorateModel {
  final int? id;
  final String name;
  final List<AreaModel> areas;

  GovernorateModel({
    this.id,
    required this.name,
    required this.areas,
  });

  factory GovernorateModel.fromJson(Map<String, dynamic> json) {
    final areasJson = (json['areas'] as List?) ?? [];
    return GovernorateModel(
      id: json['id'],
      name: json['name'] ?? '',
      areas: areasJson
          .map((e) => AreaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}*/

/// TEMP: عطّل إرسال/إدخال رمز التحقق (واتساب/إيميل) مؤقتاً أثناء التسجيل
/// حتى لا يتعطل المسجّل إذا تأخر وصول الرمز.
/// لا تحذف منطق OTP — فقط أعد هذه القيمة إلى `true` عند استقرار الإرسال.
const bool kRegistrationOtpEnabled = false;

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  String? userType; // user, driver, merchant
  String? vehicleType;

  final ImagePicker picker = ImagePicker();

  bool _isObscure = true;
  bool _isCObscure = true;

  VehicleTypeModel? _selectedVehicleType;
  List<VehicleTypeModel> _vehicleTypes = [];
  bool _loadingVehicleTypes = false;
  String? _vehicleTypesError;
  bool _isSendingOtp = false;
  bool _isRegistering = false;

  /// مستندات من لوحة الإدارة (سائق / صاحب نشاط)
  List<_RequiredDocItem> _requiredDocs = const [];
  final Map<int, XFile> _docFiles = {};
  bool _loadingDocs = false;
  String? _docsError;

  bool get _needsDocuments =>
      userType == 'driver' || userType == 'merchant';

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  String _autoUsername() {
    final name = nameController.text.trim().replaceAll(RegExp(r'\s+'), '_');
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    if (name.isNotEmpty) {
      return '${name}_$stamp';
    }
    final digits = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 8) return '${digits}_$stamp';
    return 'user_$stamp';
  }

  Future<void> _loadVehicleTypes() async {
    setState(() {
      _loadingVehicleTypes = true;
      _vehicleTypesError = null;
    });

    try {
      final api = ApiService();
      final types = await api.fetchVehicleTypes();
      setState(() {
        _vehicleTypes = types;
        _loadingVehicleTypes = false;
      });
    } catch (e) {
      setState(() {
        _vehicleTypesError = 'تعذَّر تحميل أنواع المركبات، حاول مرة أخرى.';
        _loadingVehicleTypes = false;
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final busy = _isSendingOtp || _isRegistering;

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
                height: 100,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: LoginCitySkylinePainter(
                      color: AuthTheme.skyline.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 100,
                child: IgnorePointer(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LoginCitySkylinePainter(
                            color: AuthTheme.skyline.withValues(alpha: 0.6),
                            mirror: true,
                          ),
                        ),
                      ),
                      const Positioned(
                        right: 18,
                        bottom: 22,
                        child: Icon(
                          Icons.location_on,
                          color: AuthTheme.primary,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
                  child: Column(
                    children: [
                      const AuthCourierHero(height: 148),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 24,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: nameController,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AuthTheme.textDark,
                                ),
                                decoration: authFormDecoration(
                                  hint: 'الاسم',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'برجاء إدخال الاسم';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AuthTheme.textDark,
                                ),
                                decoration: authFormDecoration(
                                  hint: 'رقم الهاتف',
                                  icon: Icons.smartphone_outlined,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'برجاء إدخال رقم الهاتف';
                                  }
                                  if (val.trim().length < 9) {
                                    return 'رقم الهاتف غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AuthTheme.textDark,
                                ),
                                decoration: authFormDecoration(
                                  hint: 'الإيميل',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'برجاء إدخال الإيميل';
                                  }
                                  final emailRegex = RegExp(
                                    r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
                                  );
                                  if (!emailRegex.hasMatch(val.trim())) {
                                    return 'الإيميل غير صحيح';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: userType,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AuthTheme.textMuted,
                                ),
                                decoration: authFormDecoration(
                                  hint: 'نوع الحساب',
                                  icon: Icons.person_outline_rounded,
                                ),
                                hint: const Text(
                                  'نوع الحساب',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: AuthTheme.textMuted,
                                  ),
                                ),
                                items: [
                                  _accountTypeItem(
                                    value: 'user',
                                    label: 'عميل',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  _accountTypeItem(
                                    value: 'driver',
                                    label: 'سائق',
                                    icon: Icons.two_wheeler_outlined,
                                  ),
                                  _accountTypeItem(
                                    value: 'merchant',
                                    label: 'صاحب نشاط',
                                    icon: Icons.storefront_outlined,
                                  ),
                                ],
                                selectedItemBuilder: (context) => const [
                                  Text('عميل', style: TextStyle(fontFamily: 'Cairo')),
                                  Text('سائق', style: TextStyle(fontFamily: 'Cairo')),
                                  Text('صاحب نشاط', style: TextStyle(fontFamily: 'Cairo')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    userType = value;
                                    _selectedVehicleType = null;
                                    _requiredDocs = const [];
                                    _docFiles.clear();
                                    _docsError = null;
                                  });
                                  if (value == 'merchant') {
                                    _loadRequiredDocuments(value!);
                                  }
                                },
                                validator: (val) {
                                  if (val == null) {
                                    return 'برجاء اختيار نوع الحساب';
                                  }
                                  return null;
                                },
                              ),
                              if (_needsDocuments) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AuthTheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: AuthTheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          userType == 'driver'
                                              ? 'بيانات السائق والمستندات المطلوبة'
                                              : 'مستندات صاحب النشاط المطلوبة',
                                          style: const TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 12,
                                            color: AuthTheme.textDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (userType == 'driver') ...[
                                  const SizedBox(height: 12),
                                  if (_loadingVehicleTypes)
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 8),
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  else if (_vehicleTypesError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        _vehicleTypesError!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    )
                                  else
                                    DropdownButtonFormField<VehicleTypeModel>(
                                      value: _selectedVehicleType,
                                      isExpanded: true,
                                      decoration: authFormDecoration(
                                        hint: 'نوع المركبة',
                                        icon: Icons.two_wheeler_outlined,
                                      ),
                                      items: _vehicleTypes
                                          .map(
                                            (t) => DropdownMenuItem<VehicleTypeModel>(
                                              value: t,
                                              child: _dropdownLabel(t.displayName),
                                            ),
                                          )
                                          .toList(),
                                      selectedItemBuilder: (context) => _vehicleTypes
                                          .map((t) => _dropdownLabel(t.displayName))
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() => _selectedVehicleType = val);
                                        if (userType == 'driver' && val != null) {
                                          _loadRequiredDocuments(
                                            'driver',
                                            vehicleTypeKey: val.key,
                                          );
                                        }
                                      },
                                    ),
                                ],
                                const SizedBox(height: 12),
                                if (userType == 'driver' &&
                                    _selectedVehicleType == null)
                                  const Text(
                                    'اختر نوع المركبة أولاً لعرض المستندات المطلوبة.',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: AuthTheme.textMuted,
                                    ),
                                  )
                                else if (_loadingDocs)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 8),
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                else if (_docsError != null)
                                  Column(
                                    children: [
                                      Text(
                                        _docsError!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontFamily: 'Cairo',
                                          fontSize: 12,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _loadRequiredDocuments(
                                          userType ?? 'merchant',
                                          vehicleTypeKey:
                                              _selectedVehicleType?.key,
                                        ),
                                        child: const Text(
                                          'إعادة المحاولة',
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (_requiredDocs.isEmpty)
                                  const Text(
                                    'لا توجد مستندات مطلوبة حالياً من لوحة التحكم.',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 12,
                                      color: AuthTheme.textMuted,
                                    ),
                                  )
                                else
                                  ..._requiredDocs.map((doc) {
                                    final file = _docFiles[doc.id];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _buildDriverImageSection(
                                        label: doc.name,
                                        image: file,
                                        buttonColor: AuthTheme.primary,
                                        onPick: () => _pickRequiredDocument(doc.id),
                                        onRemove: () => setState(
                                          () => _docFiles.remove(doc.id),
                                        ),
                                      ),
                                    );
                                  }),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: passwordController,
                                obscureText: _isObscure,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AuthTheme.textDark,
                                ),
                                decoration: authFormDecoration(
                                  hint: 'كلمة المرور',
                                  icon: Icons.lock_outline_rounded,
                                  trailing: IconButton(
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
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'برجاء إدخال كلمة المرور';
                                  }
                                  if (val.length < 6) {
                                    return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: confirmPasswordController,
                                obscureText: _isCObscure,
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 15,
                                  color: AuthTheme.textDark,
                                ),
                                decoration: authFormDecoration(
                                  hint: 'أعد كتابة كلمة المرور',
                                  icon: Icons.lock_outline_rounded,
                                  trailing: IconButton(
                                    icon: Icon(
                                      _isCObscure
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AuthTheme.textMuted,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        setState(() => _isCObscure = !_isCObscure),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'برجاء تأكيد كلمة المرور';
                                  }
                                  if (val != passwordController.text) {
                                    return 'كلمة المرور غير متطابقة';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              _buildTermsConsentNotice(busy),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          if (!_formKey.currentState!.validate()) {
                                            return;
                                          }
                                          final driverError =
                                              _validateDriverRegistration();
                                          if (driverError != null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(content: Text(driverError)),
                                            );
                                            return;
                                          }
                                          if (kRegistrationOtpEnabled) {
                                            await _sendOtpAndShowDialog();
                                          } else {
                                            await _verifyAndRegister(
                                              '',
                                              ScaffoldMessenger.maybeOf(context),
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AuthTheme.primary,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        AuthTheme.primary.withValues(alpha: 0.7),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'إنشاء الحساب',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
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
                              TextSpan(text: 'لديك حساب بالفعل؟ '),
                              TextSpan(
                                text: 'تسجيل الدخول',
                                style: TextStyle(
                                  color: AuthTheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsConsentNotice(bool busy) {
    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12,
          color: AuthTheme.textMuted,
          height: 1.6,
        ),
        children: [
          const TextSpan(
            text: 'بمجرد الضغط على إنشاء الحساب فأنت توافق على ',
          ),
          TextSpan(
            text: 'سياسة الخصوصية والشروط والأحكام',
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AuthTheme.primary,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: AuthTheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = busy
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _accountTypeItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return DropdownMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: AuthTheme.primary, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              color: AuthTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownLabel(String text) {
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }

  Widget _buildDriverImageSection({
    required String label,
    required XFile? image,
    required Color buttonColor,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onPick,
          icon: Icon(image == null ? Icons.upload : Icons.check_circle),
          label: Text(image == null ? 'رفع $label' : 'تم اختيار $label'),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (image != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(image.path),
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onRemove,
              child: const Text('إزالة الصورة'),
            ),
          ),
        ],
      ],
    );
  }

  List<_RequiredDocItem> _parseRequiredDocuments(dynamic data) {
    List list = const [];
    if (data is Map) {
      final raw = data['documents'] ?? data['data'] ?? data['required_documents'];
      if (raw is List) list = raw;
    } else if (data is List) {
      list = data;
    }

    final docs = <_RequiredDocItem>[];
    for (final item in list) {
      if (item is! Map) continue;
      final id = int.tryParse('${item['id'] ?? ''}');
      final name = (item['name'] ?? item['label'] ?? item['title'] ?? item['key'] ?? '')
          .toString()
          .trim();
      if (id == null || name.isEmpty) continue;
      final active = item['is_active'];
      if (active == false || active == 0 || active == '0') continue;
      docs.add(_RequiredDocItem(id: id, name: name));
    }
    return docs;
  }

  Future<void> _loadRequiredDocuments(
    String role, {
    String? vehicleTypeKey,
    String? hubSection,
  }) async {
    final apiRole = role == 'merchant' ? 'vendor' : role;
    setState(() {
      _loadingDocs = true;
      _docsError = null;
      _requiredDocs = const [];
      _docFiles.clear();
    });

    try {
      final query = <String, dynamic>{
        'role': apiRole,
        'audience': apiRole,
      };
      if (role == 'driver' &&
          vehicleTypeKey != null &&
          vehicleTypeKey.trim().isNotEmpty) {
        query['vehicle_type'] = vehicleTypeKey.trim();
      }
      if (role == 'merchant' &&
          hubSection != null &&
          hubSection.trim().isNotEmpty) {
        query['hub_section'] = hubSection.trim();
        query['vendor_hub_section'] = hubSection.trim();
      }

      Response? response;
      for (final url in requiredDocumentsFallbackEPs) {
        try {
          final res = await Dio().get(
            url,
            queryParameters: query,
            options: Options(
              headers: {'Accept': 'application/json'},
              validateStatus: (s) => s != null && s < 600,
              sendTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );
          if (res.statusCode == 200) {
            response = res;
            break;
          }
          response ??= res;
        } catch (_) {}
      }
      if (!mounted) return;

      var docs = const <_RequiredDocItem>[];
      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 404)) {
        docs = _parseRequiredDocuments(response.data);
      }
      if (docs.isEmpty) {
        docs = _fallbackDocsFor(role, hubSection: hubSection);
      }

      setState(() {
        _requiredDocs = docs;
        _loadingDocs = false;
        _docsError = docs.isEmpty ? 'تعذر تحميل المستندات المطلوبة' : null;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback = _fallbackDocsFor(role, hubSection: hubSection);
      setState(() {
        _requiredDocs = fallback;
        _loadingDocs = false;
        _docsError = fallback.isEmpty ? 'تعذر تحميل المستندات المطلوبة' : null;
      });
    }
  }

  List<_RequiredDocItem> _fallbackDocsFor(String role, {String? hubSection}) {
    if (role == 'driver') {
      return const [
        _RequiredDocItem(id: 1900001, name: 'صورة شخصية'),
        _RequiredDocItem(id: 1900002, name: 'صورة البطاقة القومية'),
      ];
    }
    if (role == 'merchant') {
      return const [
        _RequiredDocItem(id: 1900011, name: 'صورة النشاط'),
      ];
    }
    return const [];
  }

  bool _docNameMatches(String name, List<String> needles) {
    final lower = name.toLowerCase();
    return needles.any((needle) => lower.contains(needle.toLowerCase()));
  }

  XFile? _fileMatching(List<String> needles) {
    for (final doc in _requiredDocs) {
      final file = _docFiles[doc.id];
      if (file != null && _docNameMatches(doc.name, needles)) {
        return file;
      }
    }
    return null;
  }

  Future<void> _pickRequiredDocument(int docId) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('التقاط صورة'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (picked == null) {
        return;
      }

      if (!await File(picked.path).exists()) {
        throw Exception('image_not_found');
      }

      setState(() => _docFiles[docId] = picked);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر اختيار الصورة، حاول مرة أخرى')),
      );
    }
  }

  String? _validateDriverRegistration() {
    if (!_needsDocuments) {
      return null;
    }

    if (userType == 'driver' && _selectedVehicleType == null) {
      return 'برجاء اختيار نوع المركبة';
    }
    if (_loadingDocs) {
      return 'انتظر تحميل المستندات المطلوبة';
    }
    if (_docsError != null) {
      return _docsError;
    }
    for (final doc in _requiredDocs) {
      if (!_docFiles.containsKey(doc.id)) {
        return 'برجاء رفع: ${doc.name}';
      }
    }

    return null;
  }

  Future<MultipartFile> _imageToMultipart(XFile file, String fieldName) async {
    final path = file.path;
    final extension = path.split('.').last.toLowerCase();
    final safeExtension =
        ['jpg', 'jpeg', 'png', 'webp'].contains(extension) ? extension : 'jpg';

    return MultipartFile.fromFile(
      path,
      filename: '${fieldName}_${DateTime.now().millisecondsSinceEpoch}.$safeExtension',
    );
  }

  Future<void> _sendOtpAndShowDialog() async {
    setState(() => _isSendingOtp = true);

    try {
      final response = await Dio().post(
        sendOtpEP,
        data: {'email': emailController.text.trim()},
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (!mounted) return;

      if (_isRegisterApiSuccess(response)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إرسال رمز التحقق إلى بريدك الإلكتروني')),
        );
        await _showOtpVerificationDialog();
      } else {
        final message =
            _registerErrorMessage(response.statusCode, response.data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final message = _registerErrorMessage(
        e.response?.statusCode,
        e.response?.data,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر إرسال رمز التحقق إلى البريد الإلكتروني')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _showOtpVerificationDialog() async {
    final messenger = ScaffoldMessenger.maybeOf(context);

    final otp = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _OtpVerificationDialog(
          email: emailController.text.trim(),
        );
      },
    );

    if (otp != null && otp.length == 4) {
      await _verifyAndRegister(otp, messenger);
    }
  }

  Map<String, String> _registrationFields(String otp) {
    return {
      if (kRegistrationOtpEnabled) 'otp': otp,
      'name': nameController.text.trim(),
      'username': _autoUsername(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'mobile': phoneController.text.trim(),
      'password': passwordController.text,
      'password_confirmation': passwordController.text,
      'title': userType ?? 'user',
    };
  }

  FormData _buildRegistrationFormData(String otp) {
    final formData = FormData();
    for (final entry in _registrationFields(otp).entries) {
      formData.fields.add(MapEntry(entry.key, entry.value));
    }
    return formData;
  }

  Future<FormData> _buildRoleFormData(String otp) async {
    final formData = FormData();
    final fields = _registrationFields(otp);

    for (final entry in fields.entries) {
      formData.fields.add(MapEntry(entry.key, entry.value));
    }

    if (userType == 'driver' && _selectedVehicleType != null) {
      formData.fields.add(
        MapEntry('vehicle_type', _selectedVehicleType!.key),
      );
    }
    for (final doc in _requiredDocs) {
      final file = _docFiles[doc.id];
      if (file == null) continue;
      formData.files.add(
        MapEntry(
          'documents[${doc.id}]',
          await _imageToMultipart(file, 'doc_${doc.id}'),
        ),
      );
    }

    // السيرفر القديم يحفظ store() على image و nid_image مباشرة.
    final uploaded = _requiredDocs
        .map((doc) => _docFiles[doc.id])
        .whereType<XFile>()
        .toList();
    final imageFile = _fileMatching(const [
          'شخصي',
          'شخصية',
          'personal',
          'selfie',
          'سائق',
        ]) ??
        (uploaded.isNotEmpty ? uploaded.first : null);
    final nidFile = _fileMatching(const [
          'بطاق',
          'هوي',
          'قومي',
          'nid',
          'national',
        ]) ??
        (uploaded.length > 1 ? uploaded[1] : imageFile);

    if (imageFile != null) {
      formData.files.add(
        MapEntry('image', await _imageToMultipart(imageFile, 'image')),
      );
    }
    if (nidFile != null) {
      formData.files.add(
        MapEntry('nid_image', await _imageToMultipart(nidFile, 'nid')),
      );
    }

    return formData;
  }

  bool _isRegisterApiSuccess(Response response) {
    final httpCode = response.statusCode ?? 0;
    if (httpCode < 200 || httpCode >= 300) {
      return false;
    }

    final data = response.data;
    if (data is! Map) {
      return true;
    }

    final status = data['status']?.toString().toLowerCase();
    if (status == 'error') {
      return false;
    }

    final bodyCode = data['status_code'];
    if (bodyCode is int && bodyCode >= 400) {
      return false;
    }

    return true;
  }

  bool _isRegistrationComplete(Map<String, dynamic> userData) {
    final token = userData['token']?.toString().trim() ?? '';
    if (token.isEmpty) {
      return false;
    }

    if (userType == 'driver') {
      final title = userData['title']?.toString().trim() ?? '';
      return title == 'driver';
    }

    return true;
  }

  Future<void> _verifyAndRegister(
    String otp,
    ScaffoldMessengerState? messenger,
  ) async {
    setState(() => _isRegistering = true);

    try {
      if (userType == null || userType!.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('برجاء اختيار نوع الحساب')),
        );
        return;
      }

      // TEMP: عند تعطيل OTP نسجّل مباشرة عبر /register بدون رمز
      final registerUrl =
          kRegistrationOtpEnabled ? verifyOtpEP : registerRento;

      final Response response;
      if (_needsDocuments) {
        response = await Dio().post(
          registerUrl,
          data: await _buildRoleFormData(otp),
          options: Options(
            headers: {'Accept': 'application/json'},
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
            validateStatus: (status) => status != null && status < 600,
          ),
        );
      } else {
        response = await Dio().post(
          registerUrl,
          data: _buildRegistrationFormData(otp),
          options: Options(
            headers: {'Accept': 'application/json'},
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            validateStatus: (status) => status != null && status < 600,
          ),
        );
      }

      if (_isRegisterApiSuccess(response)) {
        final userData = _parseRegisterResponse(
          response.data,
          fallbackStatus: 'success',
        );
        if (userData == null) {
          print('register unexpected response: ${response.data}');
          messenger?.showSnackBar(
            const SnackBar(content: Text('استجابة غير متوقعة من السيرفر')),
          );
          return;
        }

        if (!_isRegistrationComplete(userData)) {
          print('register incomplete user saved: ${response.data}');
          messenger?.showSnackBar(
            const SnackBar(
              content: Text(
                'تم إنشاء الحساب بدون بيانات كاملة. احذف الحساب من لوحة التحكم وسجّل مرة أخرى بعد تحديث السيرفر.',
              ),
            ),
          );
          return;
        }

        await CacheHelper.saveData(key: 'token', value: userData['token']);
        if (userData['id'] != null) {
          await CacheHelper.saveData(key: 'id', value: userData['id']);
        }
        await CacheHelper.saveData(
          key: 'name',
          value: userData['name']?.toString() ?? '',
        );
        await CacheHelper.saveData(
          key: 'username',
          value: userData['username']?.toString() ?? '',
        );
        await CacheHelper.saveData(
          key: 'email',
          value: userData['email']?.toString() ?? '',
        );
        await CacheHelper.saveData(
          key: 'title',
          value: userData['title']?.toString() ?? userType ?? 'user',
        );
        await CacheHelper.saveData(key: 'status', value: userData['status']);
        final phone = userData['phone']?.toString() ?? '';
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

        if (!mounted) return;

        final registeredTitle =
            userData['title']?.toString() ?? userType ?? 'user';
        final isMerchant = registeredTitle == 'merchant' ||
            registeredTitle == 'vendor' ||
            userType == 'merchant' ||
            userType == 'vendor';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isMerchant
                ? const VendorBusinessTypePage()
                : const RootShell(),
          ),
        );
      } else {
        final message =
            _registerErrorMessage(response.statusCode, response.data);
        print('register error: ${response.data}');
        messenger?.showSnackBar(SnackBar(content: Text(message)));
      }
    } on DioException catch (e) {
      print('register err: $e');
      final message = _registerErrorMessage(
        e.response?.statusCode,
        e.response?.data,
      );
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      print('register err: $e');
      messenger?.showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع أثناء التسجيل')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  String _registerErrorMessage(int? statusCode, dynamic data) {
    if (statusCode == 401) {
      return 'تعذر إرسال رمز التحقق. ارفع ملفات الباكند المحدّثة (AuthController.php و routes/api.php) على السيرفر.';
    }

    if (data is Map) {
      final validationMessage = _validationErrorsMessage(data);
      if (validationMessage != null) {
        return validationMessage;
      }

      final message = data['message']?.toString() ?? data['error']?.toString();
      if (message != null && message.isNotEmpty) {
        if (message.toLowerCase().contains('unauthenticated')) {
          return 'تعذر إرسال رمز التحقق. ارفع ملفات الباكند المحدّثة على السيرفر.';
        }
        if (_isTechnicalMailError(message)) {
          return 'تعذر إرسال رمز التحقق. أضف BREVO_API_KEY في إعدادات السيرفر.';
        }
        return _translateValidationError(message);
      }
    }

    final raw = data?.toString() ?? '';
    if (raw.contains('store() on null') ||
        raw.contains('Call to a member function store')) {
      return 'برجاء رفع صورة شخصية وصورة البطاقة القومية';
    }
    if (raw.contains("Column 'email' cannot be null")) {
      return 'الإيميل مطلوب';
    }
    if (raw.contains('otp') || raw.contains('OTP')) {
      return 'رمز التحقق غير صحيح أو منتهي الصلاحية';
    }
    if (raw.contains('vehicle_types') && raw.contains('is_active')) {
      return 'خطأ في السيرفر: جدول vehicle_types يحتاج تحديث. ارفع AuthController.php المحدّث.';
    }
    if (raw.contains('SQLSTATE')) {
      return 'خطأ في قاعدة البيانات. راجع إعدادات السيرفر.';
    }
    if (statusCode == 422) {
      return 'تحقق من البيانات المدخلة وحاول مرة أخرى';
    }
    if (statusCode == 500) {
      if (_isTechnicalMailError(raw)) {
        return 'تعذر إرسال رمز التحقق. أضف BREVO_API_KEY في إعدادات السيرفر.';
      }
      return 'خطأ في السيرفر أثناء التسجيل';
    }
    return 'فشل التسجيل';
  }

  String? _validationErrorsMessage(Map data) {
    final errors = data['errors'];
    if (errors is! Map || errors.isEmpty) {
      return null;
    }

    final messages = <String>[];
    for (final value in errors.values) {
      if (value is List) {
        for (final item in value) {
          final translated = _translateValidationError(item.toString());
          if (translated.isNotEmpty && !messages.contains(translated)) {
            messages.add(translated);
          }
        }
      }
    }

    if (messages.isEmpty) {
      return null;
    }
    return messages.join('\n');
  }

  String _translateValidationError(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('phone') && lower.contains('already been taken')) {
      return 'رقم الهاتف مسجّل مسبقاً';
    }
    if (lower.contains('email') && lower.contains('already been taken')) {
      return 'البريد الإلكتروني مسجّل مسبقاً';
    }
    if (lower.contains('username') && lower.contains('already been taken')) {
      return 'اسم المستخدم مسجّل مسبقاً';
    }
    if (lower.contains('mobile') && lower.contains('already been taken')) {
      return 'رقم الهاتف مسجّل مسبقاً';
    }
    if (lower.contains('otp') && lower.contains('invalid')) {
      return 'رمز التحقق غير صحيح أو منتهي الصلاحية';
    }
    if (lower.contains('otp') && lower.contains('required')) {
      return 'رمز التحقق مطلوب';
    }
    if (lower.contains('الكود') ||
        lower.contains('كود التفعيل') ||
        lower.contains('رمز التحقق')) {
      return 'رمز التحقق غير صحيح أو منتهي الصلاحية';
    }
    if (lower.contains('password') && lower.contains('confirmation') &&
        lower.contains('match')) {
      return 'كلمة المرور غير متطابقة';
    }
    if (lower.contains('password') && lower.contains('at least')) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    if (lower.contains('email') && lower.contains('valid')) {
      return 'صيغة البريد الإلكتروني غير صحيحة';
    }
    if (lower.contains('store() on null') ||
        lower.contains('call to a member function store')) {
      return 'برجاء رفع صورة شخصية وصورة البطاقة القومية';
    }
    if (lower.contains('title') && lower.contains('invalid')) {
      return 'تسجيل صاحب النشاط غير مفعّل على السيرفر. ارفع ملف AuthController.php المحدّث على twseela.com';
    }
    if (lower.contains('and') && lower.contains('more error')) {
      return 'تحقق من البيانات المدخلة وحاول مرة أخرى';
    }

    return message;
  }

  bool _isTechnicalMailError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('smtp') ||
        lower.contains('gmail.com') ||
        lower.contains('ssl://') ||
        lower.contains('stream_socket') ||
        lower.contains('connection could not be established') ||
        lower.contains('connection timed out') ||
        lower.contains('transportexception');
  }

  Map<String, dynamic>? _parseRegisterResponse(
    dynamic data, {
    required String fallbackStatus,
  }) {
    if (data is! Map) return null;

    final token = data['token']?.toString() ??
        data['access_token']?.toString() ??
        (data['authorisation'] is Map
            ? data['authorisation']['token']?.toString()
            : null);

    if (token == null || token.isEmpty) {
      return null;
    }

    final status = data['status']?.toString() ?? fallbackStatus;
    dynamic userRaw = data['user'];
    if (userRaw is! Map) {
      userRaw = data['message'];
    }
    if (userRaw is! Map) {
      userRaw = data['data'];
    }

    if (userRaw is Map) {
      final user = Map<String, dynamic>.from(userRaw);
      return {
        'token': token,
        'status': status,
        'id': user['id'],
        'name': user['name']?.toString() ?? nameController.text.trim(),
        'username': user['username']?.toString() ?? _autoUsername(),
        'email': user['email']?.toString() ?? emailController.text.trim(),
        'title': user['title']?.toString() ?? userType ?? 'user',
        'phone': user['phone']?.toString() ?? phoneController.text.trim(),
      };
    }

    return {
      'token': token,
      'status': status,
      'id': null,
      'name': nameController.text.trim(),
      'username': _autoUsername(),
      'email': emailController.text.trim(),
      'title': userType ?? 'user',
      'phone': phoneController.text.trim(),
    };
  }
}

class _RequiredDocItem {
  final int id;
  final String name;

  const _RequiredDocItem({required this.id, required this.name});
}

class _OtpVerificationDialog extends StatefulWidget {
  final String email;

  const _OtpVerificationDialog({required this.email});

  @override
  State<_OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<_OtpVerificationDialog> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _confirm() {
    final code = _otpController.text.trim();
    if (code.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل رمز التحقق المكون من 4 أرقام'),
        ),
      );
      return;
    }
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('رمز التحقق'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'أدخل الرمز المرسل إلى ${widget.email}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'رمز التحقق',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _confirm,
          child: const Text('تأكيد'),
        ),
      ],
    );
  }
}
