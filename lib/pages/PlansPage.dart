import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/pages/splash_page.dart';
import 'package:motorent/pages/subscription_pending_page.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({Key? key}) : super(key: key);

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List plans = [];
  bool loading = true;
  bool plansEnabled = true;

  File? paymentImage;
  int? selectedPlanId;
  Map? subscription;
  String transferNumber = "";
  bool transferNumberLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Options _authOptions(String? token) {
    return Options(
      headers: {
        'Accept': 'application/json',
        if (token != null && token.toString().isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      sendTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      validateStatus: (status) => status != null && status < 600,
    );
  }

  Future<void> _loadPageData() async {
    await Future.wait([fetchPlans(), fetchTransferNumber()]);
  }

  List<Map<String, dynamic>> _parsePlansList(dynamic rawPlans) {
    if (rawPlans is List) {
      return rawPlans
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (rawPlans is Map) {
      return rawPlans.values
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  int _planId(Map plan) {
    final id = plan['id'];
    if (id is int) return id;
    if (id is num) return id.toInt();
    return int.tryParse('$id') ?? 0;
  }

  int _planDays(Map plan) {
    final days = plan['days'];
    if (days is int) return days;
    if (days is num) return days.toInt();
    return int.tryParse('$days') ?? 0;
  }

  String? _extractWalletNumber(Map data) {
    final topLevel = data['wallet_number']?.toString();
    if (topLevel != null && topLevel.isNotEmpty) {
      return topLevel;
    }

    final message = data['message'];
    if (message is Map) {
      for (final key in ['wallet_number', 'phone', 'value']) {
        final value = message[key]?.toString();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  Future<void> fetchPlans() async {
    final token = CacheHelper.getData(key: 'token')?.toString();
    if (token == null || token.isEmpty) {
      setState(() => loading = false);
      showToast('انتهت الجلسة. سجّل الدخول مرة أخرى.');
      return;
    }

    try {
      final response = await Dio().get(
        getPlansEP,
        options: _authOptions(token),
      );

      if (response.statusCode == 401) {
        setState(() => loading = false);
        showToast('انتهت الجلسة. سجّل الدخول مرة أخرى.');
        return;
      }

      if (response.statusCode != 200 || response.data is! Map) {
        setState(() => loading = false);
        showToast('تعذر تحميل الباقات من السيرفر.');
        print('get_plans error (${response.statusCode}): ${response.data}');
        return;
      }

      final data = response.data as Map;
      final enabledRaw = data['plans_enabled'];
      final enabled = enabledRaw != false &&
          enabledRaw != 0 &&
          enabledRaw != '0' &&
          enabledRaw != 'false';
      final parsedPlans = _parsePlansList(data['plans'] ?? data['message']);
      setState(() {
        plansEnabled = enabled;
        plans = parsedPlans;
        subscription = data['subscription'] is Map
            ? Map<String, dynamic>.from(data['subscription'] as Map)
            : null;
        loading = false;
      });

      if (!enabled) {
        print('get_plans: plans disabled for this audience');
      } else if (parsedPlans.isEmpty) {
        print('get_plans returned empty list: ${response.data}');
      }
    } on DioException catch (e) {
      setState(() => loading = false);
      print('fetchPlans DioException: $e');
      showToast(
        e.error is SocketException ||
                e.type == DioExceptionType.connectionTimeout
            ? 'تعذر الاتصال بالخادم. تحقق من الإنترنت'
            : 'حدث خطأ أثناء تحميل الباقات.',
      );
    } catch (e) {
      setState(() => loading = false);
      print('fetchPlans error: $e');
      showToast('حدث خطأ أثناء تحميل الباقات.');
    }
  }

  Future<void> fetchTransferNumber() async {
    final token = CacheHelper.getData(key: 'token')?.toString();

    try {
      final response = await Dio().get(
        getKoshyAppEP,
        options: _authOptions(token),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final phone = _extractWalletNumber(data);

        setState(() {
          transferNumber =
              (phone != null && phone.isNotEmpty) ? phone : 'غير متوفر حالياً';
          transferNumberLoading = false;
        });
        return;
      }

      setState(() {
        transferNumber = 'غير متوفر حالياً';
        transferNumberLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        transferNumber = 'غير متوفر حالياً';
        transferNumberLoading = false;
      });
      print('fetchTransferNumber DioException: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.error is SocketException ||
                      e.type == DioExceptionType.connectionTimeout
                  ? 'تعذر الاتصال بالخادم، تحقق من الإنترنت'
                  : 'فشل في تحميل رقم المحفظة',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        transferNumber = 'غير متوفر حالياً';
        transferNumberLoading = false;
      });
      print('fetchTransferNumber error: $e');
    }
  }

  void showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _logout() async {
    await CacheHelper.removeData(key: 'token');
    await CacheHelper.removeData(key: 'id');
    await CacheHelper.removeData(key: 'firstName');
    await CacheHelper.removeData(key: 'lastName');
    await CacheHelper.removeData(key: 'username');
    await CacheHelper.removeData(key: 'email');

    Timer(const Duration(milliseconds: 400), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SplashPage()),
      );
    });
  }

  void showUploadDialog(int planId) async {
    paymentImage = null;
    selectedPlanId = planId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        "إثبات التحويل البنكي",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "قم برفع صورة إيصال التحويل ليتم مراجعة اشتراكك خلال 24 ساعة.",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),

                    // منطقة اختيار الصورة
                    GestureDetector(
                      onTap: () async {
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (picked != null) {
                          setModalState(() {
                            paymentImage = File(picked.path);
                          });
                        }
                      },
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade400,
                            style: BorderStyle.solid,
                            width: 1,
                          ),
                        ),
                        child:
                            paymentImage == null
                                ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.upload_file, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      "اضغط لاختيار صورة الإيصال",
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "صيغة مدعومة: JPG / PNG",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                  ],
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    paymentImage!,
                                    height: 170,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            paymentImage != null ? sendSubscription : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff19c50d),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text(
                          "إرسال طلب الاشتراك",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> sendSubscription() async {
    Navigator.pop(context); // إغلاق الـ BottomSheet

    try {
      if (paymentImage == null || selectedPlanId == null) {
        showToast("برجاء اختيار صورة الإيصال أولاً.");
        return;
      }

      FormData formData = FormData.fromMap({
        'plan_id': selectedPlanId,
        'payment_image': await MultipartFile.fromFile(paymentImage!.path),
      });

      final token = await CacheHelper.getData(key: 'token');

      final response = await Dio().post(
        subscribeEP,
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        await CacheHelper.saveData(key: 'status', value: 'subSent');
        showToast("تم إرسال طلب الاشتراك بنجاح، وسيتم المراجعة خلال 24 ساعة.");

        Timer(const Duration(milliseconds: 400), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SubscriptionPendingPage(
                message:
                    'تم إرسال طلب الاشتراك بنجاح، بانتظار موافقة الإدارة.',
              ),
            ),
          );
        });
      } else {
        showToast("فشل إرسال طلب الاشتراك، حاول مرة أخرى.");
      }
    } catch (e) {
      showToast("تعذر إرسال الطلب، تحقق من الاتصال بالإنترنت.");
    }
  }

  Widget _buildTransferCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff7f7f7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "خطوة الدفع",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            "قم بتحويل قيمة الاشتراك إلى رقم المحفظة التالي، ثم ارفع صورة إيصال الدفع.",
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.numbers, color: Color(0xffe6910a)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transferNumberLoading
                        ? "جاري تحميل الرقم..."
                        : transferNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      transferNumberLoading ||
                              transferNumber == 'غير متوفر حالياً'
                          ? null
                          : () {
                            Clipboard.setData(
                              ClipboardData(text: transferNumber),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("تم نسخ رقم التحويل"),
                              ),
                            );
                          },
                  icon: const Icon(Icons.copy),
                  color: Colors.blue,
                  tooltip: "نسخ",
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ملاحظة: التحويل عبر InstaPay (انستا باي) فقط.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBanner() {
    if (subscription == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffe8f5e9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffa5d6a7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xff2e7d32)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "لديك اشتراك نشط أو قيد المراجعة. يمكن تغيير الباقة بعد انتهاء الاشتراك الحالي.",
              style: TextStyle(color: Colors.green[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map plan) {
    final dynamic price = plan['price'];
    final dynamic offer = plan['offer'];
    final bool hasOffer =
        offer != null &&
        offer is num &&
        price != null &&
        price is num &&
        offer < price;

    final int days = _planDays(plan);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // اسم الباقة
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan['name']?.toString() ?? 'باقة',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffe6910a).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Color(0xffe6910a),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$days يوم",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xffe6910a),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // السعر
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasOffer) ...[
                  Text(
                    "${price.toString()} EGP",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  "${(hasOffer ? offer : price).toString()} EGP",
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  "/ اشتراك",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // وصف بسيط
            Text(
              "استمتع بالوصول الكامل للتطبيق خلال مدة الباقة المختارة مع أولوية في استقبال الطلبات.",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // زر الاشتراك
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => showUploadDialog(_planId(plan)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffe6910a),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "اشتراك في هذه الباقة",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // للتأكد من RTL في هذه الصفحة
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("اختيار الباقة المناسبة"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xffd34949)),
              tooltip: "تسجيل الخروج",
              onPressed: _logout,
            ),
          ],
        ),
        body:
            loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _loadPageData,
                  child: Column(
                    children: [
                      _buildTransferCard(),
                      const SizedBox(height: 4),
                      _buildSubscriptionBanner(),
                      const SizedBox(height: 8),
                      Expanded(
                        child:
                            plans.isEmpty
                                ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 120),
                                    Center(
                                      child: Text(
                                        plansEnabled
                                            ? 'لا توجد باقات مفعّلة حالياً.\nمن لوحة التحكم → الخطط: أضف باقة وفعّلها للسائقين.\nثم اسحب للتحديث.'
                                            : 'الاشتراكات معطّلة من إعدادات النظام.\nمن لوحة التحكم → الخطط: فعّل «الخطط للسائقين» واضغط حفظ.\nثم اسحب للتحديث هنا.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    16,
                                  ),
                                  itemCount: plans.length,
                                  itemBuilder: (context, index) {
                                    final plan = Map<String, dynamic>.from(
                                      plans[index] as Map,
                                    );
                                    return _buildPlanCard(plan);
                                  },
                                ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
