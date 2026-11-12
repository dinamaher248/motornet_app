import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/constants/app_support.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/ApiService.dart';
import 'package:motorent/features/my_account/domain/entities/profile_data.dart';
import 'package:motorent/features/my_account/my_account_injection.dart';
import 'package:motorent/features/my_account/presentation/bloc/profile_bloc.dart';
import 'package:motorent/features/my_account/presentation/widgets/profile_image_picker_widget.dart';
import 'package:motorent/models/vehicle_type_model.dart';
import 'package:motorent/pages/Privacy_policy_page.dart';
import 'package:motorent/pages/splash_page.dart';
import 'package:motorent/services/place_booking_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  final int refreshToken;
  final Widget? topSection;
  final bool showAppBar;

  const ProfileScreen({
    super.key,
    this.refreshToken = 0,
    this.topSection,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MyAccountInjection.createBloc()..add(const FetchProfileEvent()),
      child: _ProfileView(
        refreshToken: refreshToken,
        topSection: topSection,
        showAppBar: showAppBar,
      ),
    );
  }
}

class _ProfileView extends StatefulWidget {
  final int refreshToken;
  final Widget? topSection;
  final bool showAppBar;

  const _ProfileView({
    required this.refreshToken,
    this.topSection,
    this.showAppBar = true,
  });

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _governorateController = TextEditingController();
  final _areaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  File? _pickedImage;
  bool _fieldsSeeded = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  List<VehicleTypeModel> _vehicleTypes = const [];
  VehicleTypeModel? _selectedVehicleType;
  bool _loadingVehicleTypes = false;
  String? _vehicleTypesError;

  @override
  void didUpdateWidget(covariant _ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      context.read<ProfileBloc>().add(const FetchProfileEvent());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _governorateController.dispose();
    _areaController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  bool get _cachedIsDriver {
    final title = CacheHelper.getData(key: 'title')?.toString().toLowerCase();
    return title == 'driver' || title == 'سائق';
  }

  void _seedFields(ProfileUser user) {
    if (_fieldsSeeded) return;
    _nameController.text = user.name;
    _phoneController.text = user.phone;
    _emailController.text = user.email ??
        CacheHelper.getData(key: 'email')?.toString() ??
        '';
    _governorateController.text = user.governorate ?? '';
    _areaController.text = user.area ?? '';
    _fieldsSeeded = true;
    final isDriver = user.isDriver || _cachedIsDriver;
    if (isDriver) {
      final key = (user.vehicleType ?? '').trim().isNotEmpty
          ? user.vehicleType
          : CacheHelper.getData(key: 'vehicle_type')?.toString();
      _loadVehicleTypes(currentKey: key);
    }
  }

  Future<void> _loadVehicleTypes({String? currentKey}) async {
    setState(() {
      _loadingVehicleTypes = true;
      _vehicleTypesError = null;
    });
    try {
      final types = await ApiService().fetchVehicleTypes();
      if (!mounted) return;
      VehicleTypeModel? selected;
      if (currentKey != null && currentKey.isNotEmpty) {
        for (final t in types) {
          if (t.key == currentKey) {
            selected = t;
            break;
          }
        }
      }
      setState(() {
        _vehicleTypes = types;
        _selectedVehicleType = selected;
        _loadingVehicleTypes = false;
        if (types.isEmpty) {
          _vehicleTypesError = 'لا توجد أنواع مركبات متاحة حالياً';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingVehicleTypes = false;
        _vehicleTypesError = 'تعذر تحميل أنواع المركبات';
      });
    }
  }

  Future<void> _openPrivacy(ProfileSettings settings) async {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
    );
  }

  Future<void> _openSupport(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return;

    final whatsappDigits =
        cleaned.startsWith('0') ? '2$cleaned' : cleaned;
    final wa = Uri.parse('https://wa.me/$whatsappDigits');
    if (await canLaunchUrl(wa)) {
      await launchUrl(wa, mode: LaunchMode.externalApplication);
      return;
    }

    final tel = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
    }
  }

  Future<void> _logout() async {
    await CacheHelper.removeData(key: 'token');
    await CacheHelper.removeData(key: 'id');
    await CacheHelper.removeData(key: 'title');
    await CacheHelper.removeData(key: 'status');
    await CacheHelper.putBoolean(
      key: AuthPrefs.registrationCompletedKey,
      value: true,
    );
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'حسابي',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ProfileUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            setState(() {
              _pickedImage = null;
              _passwordController.clear();
              _passwordConfirmController.clear();
            });
            final updated = state.data.user;
            if ((updated.isDriver || _cachedIsDriver) &&
                (updated.vehicleType ?? '').isNotEmpty) {
              unawaited(_loadVehicleTypes(currentKey: updated.vehicleType));
            }
          } else if (state is ProfileLoadedSuccess) {
            _seedFields(state.data.user);
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          ProfileData? data;
          var updating = false;
          if (state is ProfileLoadedSuccess) {
            data = state.data;
          } else if (state is ProfileUpdateLoading) {
            data = state.data;
            updating = true;
          } else if (state is ProfileUpdateSuccess) {
            data = state.data;
          } else if (state is ProfileError && state.data != null) {
            data = state.data;
          }

          if (data == null) {
            return Center(
              child: TextButton(
                onPressed: () => context
                    .read<ProfileBloc>()
                    .add(const FetchProfileEvent()),
                child: const Text('إعادة المحاولة'),
              ),
            );
          }

          final user = data.user;
          final settings = data.settings;
          // رقم الدعم الرسمي الثابت للتطبيق
          const supportPhone = AppSupport.phone;
          final isDriver = user.isDriver || _cachedIsDriver;

          return Stack(
            children: [
              Container(
                decoration: AuthTheme.screenBackground(),
                child: RefreshIndicator(
                  onRefresh: () async {
                    _fieldsSeeded = false;
                    context
                        .read<ProfileBloc>()
                        .add(const FetchProfileEvent());
                  },
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      // مساحة إضافية تحت الشريط السفلي عشان زر تسجيل الخروج يفضل سهل الضغط
                      padding: EdgeInsets.fromLTRB(
                        20,
                        16,
                        20,
                        40 +
                            MediaQuery.of(context).padding.bottom +
                            140,
                      ),
                      children: [
                        if (widget.topSection != null) ...[
                          widget.topSection!,
                          const SizedBox(height: 16),
                        ] else ...[
                          _BookingsCountCard(
                            count: data.bookingsCount > 0
                                ? data.bookingsCount
                                : PlaceBookingService.localCount(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        ProfileImagePickerWidget(
                          networkImagePath: user.image,
                          localImage: _pickedImage,
                          enabled: !updating,
                          onImagePicked: (file) {
                            setState(() => _pickedImage = file);
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'اضغط على الصورة لتغييرها',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AuthTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _field(
                          controller: _nameController,
                          label: 'الاسم',
                          icon: Icons.person_outline,
                          enabled: !updating,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'برجاء إدخال الاسم';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _phoneController,
                          label: 'رقم الهاتف',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          enabled: !updating,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'برجاء إدخال رقم الهاتف';
                            }
                            if (v.trim().length < 9) {
                              return 'رقم الهاتف غير صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _emailController,
                          label: 'البريد الإلكتروني (اختياري)',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !updating,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return null;
                            if (!value.contains('@')) {
                              return 'بريد إلكتروني غير صحيح';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _governorateController,
                          label: 'المحافظة',
                          icon: Icons.location_city_outlined,
                          enabled: !updating,
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _areaController,
                          label: 'المنطقة / الحي',
                          icon: Icons.map_outlined,
                          enabled: !updating,
                          validator: (_) => null,
                        ),
                        if (isDriver) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'بيانات السائق',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AuthTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_loadingVehicleTypes)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_vehicleTypesError != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _vehicleTypesError!,
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Colors.red,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _loadVehicleTypes(
                                    currentKey: user.vehicleType,
                                  ),
                                  child: const Text('إعادة المحاولة'),
                                ),
                              ],
                            )
                          else
                            DropdownButtonFormField<VehicleTypeModel>(
                              value: _selectedVehicleType,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'نوع المركبة',
                                prefixIcon: const Icon(
                                  Icons.two_wheeler_outlined,
                                  color: AuthTheme.primary,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AuthTheme.fieldBorder,
                                  ),
                                ),
                              ),
                              items: _vehicleTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(
                                        t.displayName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: updating
                                  ? null
                                  : (val) {
                                      setState(
                                        () => _selectedVehicleType = val,
                                      );
                                    },
                              validator: (val) {
                                if (val == null) {
                                  return 'اختر نوع المركبة';
                                }
                                return null;
                              },
                            ),
                        ],
                        const SizedBox(height: 18),
                        const Text(
                          'تغيير كلمة المرور (اختياري)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AuthTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _field(
                          controller: _passwordController,
                          label: 'كلمة مرور جديدة',
                          icon: Icons.lock_outline,
                          enabled: !updating,
                          obscureText: _obscurePassword,
                          toggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return null;
                            if (value.length < 6) {
                              return 'كلمة المرور 6 أحرف على الأقل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _passwordConfirmController,
                          label: 'تأكيد كلمة المرور',
                          icon: Icons.lock_person_outlined,
                          enabled: !updating,
                          obscureText: _obscureConfirm,
                          toggleObscure: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                          validator: (v) {
                            final pass = _passwordController.text.trim();
                            final confirm = (v ?? '').trim();
                            if (pass.isEmpty && confirm.isEmpty) return null;
                            if (confirm != pass) {
                              return 'كلمتا المرور غير متطابقتين';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: updating
                                ? null
                                : () {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    final password =
                                        _passwordController.text.trim();
                                    context.read<ProfileBloc>().add(
                                          UpdateProfileEvent(
                                            name: _nameController.text.trim(),
                                            phone:
                                                _phoneController.text.trim(),
                                            email:
                                                _emailController.text.trim(),
                                            governorate:
                                                _governorateController.text
                                                    .trim(),
                                            area: _areaController.text.trim(),
                                            vehicleType: isDriver
                                                ? _selectedVehicleType?.key
                                                : null,
                                            password: password.isEmpty
                                                ? null
                                                : password,
                                            passwordConfirmation: password
                                                    .isEmpty
                                                ? null
                                                : _passwordConfirmController
                                                    .text
                                                    .trim(),
                                            imageFile: _pickedImage,
                                          ),
                                        );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AuthTheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'الإعدادات والدعم',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AuthTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _settingsTile(
                          icon: Icons.privacy_tip_outlined,
                          title: 'سياسة الخصوصية',
                          subtitle: 'اطّلع على سياسة استخدام البيانات',
                          onTap: () => _openPrivacy(settings),
                        ),
                        const SizedBox(height: 10),
                        _settingsTile(
                          icon: Icons.support_agent_outlined,
                          title: 'الدعم الفني',
                          subtitle: 'تواصل معنا: $supportPhone',
                          onTap: () => _openSupport(supportPhone),
                        ),
                        const SizedBox(height: 22),
                        OutlinedButton.icon(
                          onPressed: updating ? null : _logout,
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              if (updating)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              'جاري حفظ التعديلات...',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool enabled = true,
    bool obscureText = false,
    VoidCallback? toggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AuthTheme.primary),
        suffixIcon: toggleObscure == null
            ? null
            : IconButton(
                onPressed: toggleObscure,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AuthTheme.textMuted,
                ),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AuthTheme.fieldBorder),
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuthTheme.fieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AuthTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AuthTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AuthTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsCountCard extends StatelessWidget {
  final int count;

  const _BookingsCountCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AuthTheme.primary.withValues(alpha: 0.16),
            const Color(0xFF0C9F6A).withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(color: AuthTheme.fieldBorder),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'عدد الحجوزات',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
              fontSize: 28,
              color: AuthTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
