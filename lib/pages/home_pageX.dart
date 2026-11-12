import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:motorent/models/driver_model.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/api_response.dart';
import 'package:motorent/models/ride_book_model.dart';
import 'package:motorent/pages/HistoryPage.dart';
import 'package:motorent/pages/Rides_page.dart';
import 'package:motorent/pages/chatbot_page.dart';
import 'package:motorent/pages/chatbot_pageB.dart';
import 'package:motorent/pages/find_rides_in_map_page.dart';
import 'package:motorent/pages/ride_book_mid_R_page.dart';
import 'package:motorent/pages/ride_book_mid_page.dart';
import 'package:motorent/pages/set_trip_page.dart';
import 'package:motorent/pages/trip_ride_page.dart';

import 'package:motorent/providers/home_provider.dart';
import 'package:motorent/widgets/bottom_nav_bar.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ride_model.dart';
import 'map_page.dart';
import 'package:motorent/widgets/app_logo.dart';

class HomePageX extends StatefulWidget {
  const HomePageX({Key? key}) : super(key: key);

  @override
  _HomePageStateX createState() => _HomePageStateX();
}

class _HomePageStateX extends State<HomePageX> {
  TextEditingController searchController = TextEditingController();
  LatLng? startPoint;
  LatLng? endPoint;
  String? startPlaceName;
  String? endPlaceName;
  List<LatLng> points = [];
  String? nearestPoint;
  double? distanceToNearest;
  String? userName;
  String title = 'user';
  bool isOnline = false;
  bool isInit = true;
  late HomeProvider mProvider;
  final List<String> governorates = [
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الدقهلية',
    'البحيرة',
    'الشرقية',
    'المنوفية',
    'القليوبية',
    'كفر الشيخ',
    'الغربية',
    'الفيوم',
    'بني سويف',
    'المنيا',
    'أسيوط',
    'سوهاج',
    'قنا',
    'الأقصر',
    'أسوان',
    'الوادي الجديد',
    'البحر الأحمر',
    'شمال سيناء',
    'جنوب سيناء',
    'مطروح',
    'البحيرة',
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    getUserName();
  }

  void getUserName() async {
    final name = await CacheHelper.getData(key: 'name');
    setState(() {
      userName = name;
    });
  }

  Future<void> _checkLocationPermission() async {
    await Geolocator.requestPermission();
    await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size; //check the size of device
    ThemeData themeData = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) => HomeProvider()..loadHomeData(),
      child: WillPopScope(
        onWillPop: () async {
          return await showExitConfirmDialog(context) ?? false;
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60.0), //appbar size
            child: AppBar(
              bottomOpacity: 0.0,
              elevation: 0.0,
              shadowColor: Colors.transparent,
              backgroundColor: themeData.scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              titleSpacing: 0,
              leadingWidth: size.width * 0.15,
              title: const AppLogo(height: 40),
              centerTitle: true,
            ),
          ),
          extendBody: true,
          extendBodyBehindAppBar: true,
          bottomNavigationBar: buildBottomNavBar(0, size, themeData),
          backgroundColor: themeData.scaffoldBackgroundColor,
          body: Consumer<HomeProvider>(
            builder: (context, provider, _) {
              mProvider = provider;
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.errorMessage.isNotEmpty) {
                return Center(child: Text(provider.errorMessage));
              }
              if (isInit) {
                isOnline =
                    provider.driver?.message.is_online == 1 ? true : false;
                isInit = false;
              }
              return SafeArea(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      provider.loadHomeData();
                    },
                    child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: size.height * 0.01,
                        left: size.width * 0.05,
                        right: size.width * 0.05,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                  colors: [Color(0xffe6910a), Colors.green],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      12.0,
                                      0.0,
                                      12.0,
                                      0.0,
                                    ),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Color(0xffe6910a),
                                      child: Text(
                                        userName?[0] ?? '...',
                                        style: TextStyle(
                                          fontSize: 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'مرحبا',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          userName ?? '...',
                                          style: TextStyle(
                                            overflow: TextOverflow.ellipsis,
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                QuickActionButton(
                                  icon: Icons.support_agent_outlined,
                                  label: 'دعم فني',
                                ),
                                if (provider.driver?.message.title == 'driver') ...{
                                  OnlineToggleButton(
                                  isOnline: isOnline,
                                  onToggle: (newStatus) async {
                                    setState(() {
                                      isOnline = newStatus;
                                    });

                                    try {
                                      final token = await CacheHelper.getData(
                                        key: 'token',
                                      );

                                      final response = await Dio().post(
                                        toggleOnlineEP,
                                        data: {'is_online': newStatus ? 1 : 0},
                                        options: Options(
                                          headers: {
                                            'Authorization': 'Bearer $token',
                                          },
                                        ),
                                      );

                                      if (response.statusCode == 200) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'تم تحديث حالتك بنجاح',
                                            ),
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'حدث خطأ، حاول مرة أخرى',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('تعذر الاتصال بالخادم'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                }
                              ],
                            ),
                          ),

                          if (provider.driver?.message.title == 'driver') ...{
                            provider.rideBookDto?.message == null ||
                                provider.rideBookDto!.message.isEmpty
                                ? Center(
                              child: Text("لا توجد بيانات للعرض"),
                            )
                                : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(8),
                              itemCount: provider.rideBookDto?.message.length,
                              itemBuilder: (context, index) {
                                final booking =
                                    provider.rideBookDto?.message[index];
                                return Card(
                                  margin: EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          booking?.customerName ?? '',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text("الهاتف: ${booking?.customerPhone ?? ''}",),
                                        Text("الاستلام: ${booking?.pickLoc}"),
                                        Text("الوصول: ${booking?.targetLoc}"),
                                        Text("التفاصيل: ${booking?.msg}"),
                                        Text("التاريخ: ${booking?.createdAt}"),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (booking?.status !=
                                                'accepted') ...{
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    showConfirmationDialog(
                                                      context,
                                                      booking!.id,
                                                      "accepted",
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: Text("قبول"),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            } else ...{
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (_,) => RideBookMidPage(
                                                              mRide: Driver(id: booking?.id??0, name: booking?.customerName??'', username: '', type: '', title: 'user', coins: 0, email: '', isPaid: 0, isApproved: 0, isAdmin: 0, phone: booking?.customerPhone, area: '${booking?.pickLoc}///${booking?.targetLoc}///${booking?.msg}')
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                  child: Text("التفاصيل"),
                                                ),
                                              ),
                                            },
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  showConfirmationDialog(
                                                    context,
                                                    booking!.id,
                                                    "refused",
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: Text("رفض"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          },

                          if (provider.driver?.message.title == 'user') ...{
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'السائقين',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff272727),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              color: Colors.white,
                              child:
                                  provider.drivers?.message == null ||
                                          provider.drivers!.message.isEmpty
                                      ? Center(
                                        child: Text("لا توجد بيانات للعرض"),
                                      )
                                      : ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(8),
                                        scrollDirection: Axis.vertical,
                                        // padding: EdgeInsets.all(8),
                                        itemCount:
                                            provider.drivers!.message.length,
                                        itemBuilder: (context, index) {
                                          final driver =
                                              provider.drivers!.message[index];
                                          bool showImage = false;
                                          return Card(
                                            elevation: 4,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          driver.name ?? '',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                        Text(
                                                          "Phone: ${driver.phone}",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                        ),
                                                        Text(
                                                          "Vehicle Type: ${driver.vehicleType ?? 'N/A'}",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (driver.is_booked ==
                                                      false) ...{
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        showBookDialog(
                                                          context,
                                                          driver!.id,
                                                          driver,
                                                        );
                                                      },
                                                      child: Text('إرسال طلب'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(
                                                          0xffe6910a,
                                                        ),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                            ),
                                                      ),
                                                    ),
                                                  } else ...{
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => RideBookMidPage(
                                                                  mRide: driver
                                                                      // provider
                                                                      //     .driver
                                                                      //     ?.message,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text('التفاصيل'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                            ),
                                                      ),
                                                    ),
                                                  },
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          },
                        ],
                      ),
                    ),
                  ],
                ),
              )
              );
            },
          ),
        ),
      ),
    );
  }

  void showConfirmationDialog(
    BuildContext context,
    int bookingId,
    String newStatus,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(newStatus == "accepted" ? "تأكيد القبول" : "تأكيد الرفض"),
          content: Text(
            "هل أنت متأكد أنك تريد ${newStatus == "accepted" ? "قبول" : "رفض"} هذا الطلب؟",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateBookingStatus(bookingId, newStatus);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("تأكيد"),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
    try {
      String? token = await CacheHelper.getData(key: 'token');
      final response = await Dio().post(
        updateBookingStatusEP,
        data: {'id': bookingId, 'status': status},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        SnackBar(content: Text('تم قبول الطلب'));
        // showToastApp(text: "تم التحديث بنجاح", color: Colors.green);
        // إعادة تحميل البيانات
        mProvider.loadHomeData();
        // Provider.of<HomeProvider>(context, listen: false).loadHomeData();
      } else {
        SnackBar(content: Text('حدث خطأ، حاول مجددا'));
        // showToastApp(text: "حدث خطأ، حاول مجدداً", color: Colors.red);
      }
    } catch (e) {
      SnackBar(content: Text('فشل الاتصال بالخادم'));
      // showToastApp(text: "فشل الاتصال بالخادم", color: Colors.red);
      print("Error updating status: $e");
    }
  }

  void showBookDialog(BuildContext context, int rideId, Driver ride) {
    // TextEditingController priceController = TextEditingController();
    TextEditingController pickLocationController = TextEditingController();
    TextEditingController targetLocationController = TextEditingController();
    TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'بيانات الحجز',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          "إرسال طلب",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        /*SizedBox(height: 12),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "إقترح سعرك",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),*/
                        SizedBox(height: 12),
                        TextField(
                          controller: pickLocationController,
                          decoration: InputDecoration(
                            labelText: "عنوان الإستلام",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: targetLocationController,
                          decoration: InputDecoration(
                            labelText: "وجهة الوصول",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: detailsController,
                          decoration: InputDecoration(
                            labelText: "تفاصيل إضافية",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (
                    // priceController.text.isEmpty ||
                    pickLocationController.text.isEmpty ||
                        targetLocationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('برجاء ملء جميع الحقول المطلوبة'),
                        ),
                      );
                      return;
                    }

                    try {
                      var formData = {
                        'driver_id': rideId,
                        'amount': 0,
                        'pick_loc': pickLocationController.text,
                        'target_loc': targetLocationController.text,
                        'msg': detailsController.text,
                      };

                      var response = await Dio().post(
                        rideBook, // رابط الـ API الخاص بالحجز
                        data: formData,
                        options: Options(
                          headers: {
                            'Authorization':
                                'Bearer ${CacheHelper.getData(key: 'token')}',
                          },
                        ),
                      );

                      if (response.statusCode == 200) {
                        Navigator.pop(context); // إغلاق الـ Dialog

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم إرسال طلب الحجز بنجاح')),
                        );

                        // إذا أردت فتح صفحة الرحلة بعد الحجز، فعّل الكود التالي:
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => TripRidePage(mRide: ride),
                        //   ),
                        // );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')),
                        );
                      }
                    } catch (e) {
                      if (e is DioException && e.error is SocketException) {
                        print('err DioException: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('لا يوجد اتصال بالإنترنت')),
                        );
                      } else {
                        print('err: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('حدث خطأ، حاول مرة أخرى')),
                        );
                      }
                    }
                  },
                  child: Text("إرسال الطلب"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showGovernorateDialog(BuildContext context, List<String> governorates, Function(String) onSelect) {
    String? selectedGovernorate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'اختر المحافظة',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                height: 300, // ارتفاع مناسب للحوار مع تمرير
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: governorates.length,
                  itemBuilder: (context, index) {
                    final governorate = governorates[index];
                    return RadioListTile<String>(
                      title: Text(governorate),
                      value: governorate,
                      groupValue: selectedGovernorate,
                      onChanged: (value) {
                        setState(() {
                          selectedGovernorate = value;
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("إلغاء"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedGovernorate != null) {
                      Navigator.pop(context);
                      onSelect(selectedGovernorate!);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('برجاء اختيار محافظة')),
                      );
                    }
                  },
                  child: Text("تأكيد"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> bookRide(int rideId, String seats, Ride ride) async {
    try {
      var formData = json.encode({'ride_id': rideId, 'seat_count': seats});

      var response = await Dio().post(
        rideBook, // Your API endpoint
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${CacheHelper.getData(key: 'token')}',
          },
        ),
      );

      if (response.statusCode == 200) {
        ApiResponse<RideBook> userModel = ApiResponse<RideBook>.fromJson(
          response.data,
          (data) => RideBook.fromJson(data),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripRidePage(mRide: ride)),
        );
      } else {
        // showToastApp(text: 'Error: Try again later.', color: Colors.red);
      }
    } catch (e) {
      if (e is DioException && e.error is SocketException) {
        print('err DioException: ${e}');
        // showToastApp(text: 'No Internet connection.${e}', color: Colors.red);
      } else {
        print('err: ${e}');
        // showToastApp(text: 'Error: Try again later please.${e}', color: Colors.red);
      }
    }
  }

  Future<String> myname() async {
    return await CacheHelper.getData(key: 'name');
  }


  Future<bool?> showExitConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Exit App"),
            content: Text("Are you sure you want to exit the app?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text("Exit"),
              ),
            ],
          ),
    );
  }

  OutlineInputBorder textFieldBorder() {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(15.0)),
      borderSide: BorderSide(color: Colors.grey.withOpacity(0.5), width: 1.0),
    );
  }

  Widget QuickActionButton({
    required IconData icon,
    required String label,
    List<Ride>? rides,
  }) {
    return GestureDetector(
      onTap: () {
        if (label == "Offer Ride") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RidesPage()),
          );
        } else if (label == "المحافظة") {
          showGovernorateDialog(context, governorates, (selected) {
            print('تم اختيار: $selected');
            // هنا تنادي أي دالة تجيب بيانات مثلاً بناءً على المحافظة المختارة
            fetchDrivers(governorate: selected);
          });
        }  else if (label == "دعم فني" || label == "تواصل معنا") {
          _callDriver('01551998707');
        } else if (label == "History") {
          /*Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Historypage()),
          );*/
        } else if (label == "Find Ride") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FindRidesInMapPage(remoteRides: rides),
            ),
          );
        } else if (label == "Schedule") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SetTripPage()),
          );
        }
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xfffffaf3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(0xffe68e0a)),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget OnlineToggleButton({
    required bool isOnline,
    required Function(bool) onToggle,
  }) {
    return GestureDetector(
      onTap: () {
        onToggle(!isOnline);
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOnline ? Color(0xffe8f9f1) : Color(0xfffff4f4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOnline ? Icons.toggle_on : Icons.toggle_off,
              color: isOnline ? Colors.green : Colors.grey,
              size: 32,
            ),
          ),
          SizedBox(height: 4),
          Text(
            isOnline ? "متاح للطلبات" : "غير متاح",
            style: TextStyle(
              fontSize: 12,
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchDrivers({String? governorate}) async {
    try {
      final token = await CacheHelper.getData(key: 'token');

      final response = await Dio().get(
        getAvailableDriversEP,
        queryParameters: {if (governorate != null) 'governorate': governorate},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        ApiResponse<List<Driver>> rr = ApiResponse<List<Driver>>.fromJson(response.data, (data) => List<Driver>.from(data.map((x) => Driver.fromJson(x))));
        setState((){
          mProvider.drivers = rr;
        });
      } else {
        print('حدث خطأ، حاول مرة أخرى');
        // showError("حدث خطأ، حاول مرة أخرى");
      }
    } catch (e) {
      // showError("فشل الاتصال بالخادم");
      print(' :فشل الاتصال بالخادم$e');
    }
  }

  void _callDriver(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }
}

class PopularPlace {
  final String name;
  final String imageUrl;

  String departureDate;
  String departureTime;
  final String startLat;
  final String startLng;
  final String startName;
  final String destLat;
  final String destLng;
  final String destName;
  int seats;
  final int price;
  String description;

  PopularPlace({
    required this.name,
    required this.imageUrl,
    required this.departureDate,
    required this.departureTime,
    required this.startLat,
    required this.startLng,
    required this.startName,
    required this.destLat,
    required this.destLng,
    required this.destName,
    required this.seats,
    required this.price,
    required this.description,
  });

  // PopularPlace({required this.name, required this.imageUrl});
}
