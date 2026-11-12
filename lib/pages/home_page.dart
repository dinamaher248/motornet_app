import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:motorent/models/driver_model.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/models/api_response.dart';
import 'package:motorent/models/location_models.dart';
import 'package:motorent/models/ride_book_model.dart';
import 'package:motorent/models/home_response.dart';
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
import 'package:motorent/widgets/app_logo.dart';
import 'package:motorent/widgets/customer/customer_home_section.dart';
import 'package:motorent/widgets/customer/driver_trip_requests_section.dart';
import 'package:motorent/widgets/storage_network_avatar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unicons/unicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/ride_model.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
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
  bool _onlineSyncRequested = false;
  bool _profileLoadRequested = false;
  bool _isUpdatingOnlineStatus = false;
  late HomeProvider mProvider;
  List<LocationMatch> _locationSuggestions = [];
  bool _showLocationSuggestions = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    getUserName();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (title == 'driver' && isOnline) {
      _setDriverOnlineStatus(
        false,
        showFeedback: false,
        skipStateUpdates: true,
      );
    }
    searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (title != 'driver') return;

    if (state == AppLifecycleState.resumed) {
      _setDriverOnlineStatus(true, showFeedback: false);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setDriverOnlineStatus(false, showFeedback: false);
    }
  }

  Future<bool> _setDriverOnlineStatus(
    bool online, {
    bool showFeedback = true,
    bool skipStateUpdates = false,
  }) async {
    if (!skipStateUpdates) {
      if (_isUpdatingOnlineStatus) return false;
      if (mounted) {
        setState(() => _isUpdatingOnlineStatus = true);
      }
    }

    try {
      final token = await CacheHelper.getData(key: 'token');
      final response = await Dio().post(
        toggleOnlineEP,
        data: {'is_online': online ? 1 : 0},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 600,
        ),
      );

      if (response.statusCode == 200) {
        if (!skipStateUpdates && mounted) {
          setState(() => isOnline = online);
          mProvider.loadHomeData();
        }
        if (showFeedback && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                online ? 'أنت الآن متصل وتستقبل الطلبات' : 'تم إيقاف استقبال الطلبات',
              ),
            ),
          );
        }
        return true;
      }

      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث حالة الاتصال')),
        );
      }
      return false;
    } catch (e) {
      print('toggle_online error: $e');
      if (showFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الاتصال بالسيرفر')),
        );
      }
      return false;
    } finally {
      if (!skipStateUpdates && mounted) {
        setState(() => _isUpdatingOnlineStatus = false);
      }
    }
  }

  void getUserName() async {
    final name = await CacheHelper.getData(key: 'name');
    setState(() {
      userName = name;
    });
  }

  Future<void> _checkLocationPermission() async {
    await Geolocator.requestPermission();
    await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _ensureLocationsLoaded(HomeProvider provider) async {
    if (provider.governorates.isEmpty) {
      await provider.loadLocations();
    }
  }

  Future<void> _onDestinationSearchChanged(
    String query,
    HomeProvider provider,
  ) async {
    if (query.trim().length < 2) {
      setState(() {
        _locationSuggestions = [];
        _showLocationSuggestions = false;
      });
      return;
    }

    await _ensureLocationsLoaded(provider);
    final matches = await provider.searchLocations(query);

    if (!mounted) return;
    setState(() {
      _locationSuggestions = matches.take(8).toList();
      _showLocationSuggestions = _locationSuggestions.isNotEmpty;
    });
  }

  Future<void> _searchDestination(String query, HomeProvider provider) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    setState(() => _showLocationSuggestions = false);
    await _ensureLocationsLoaded(provider);

    final matches = await provider.searchLocations(trimmed);
    if (!mounted) return;

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم العثور على هذه الوجهة في قائمة المناطق'),
        ),
      );
      return;
    }

    if (matches.length == 1) {
      _applyLocationMatch(matches.first, provider);
      return;
    }

    final selected = await showModalBottomSheet<LocationMatch>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'اختر الوجهة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(match.displayName),
                      onTap: () => Navigator.pop(sheetContext, match),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      _applyLocationMatch(selected, provider);
    }
  }

  void _applyLocationMatch(LocationMatch match, HomeProvider provider) {
    provider.applyLocationMatch(match);
    setState(() {
      searchController.text = match.displayName;
      _locationSuggestions = [];
      _showLocationSuggestions = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم اختيار: ${match.displayName}')),
    );
  }

  Future<void> _openChatbot() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatbotPage(),
      ),
    );
  }

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '01551998707',
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeData = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => HomeProvider()..loadHomeData(),
      child: WillPopScope(
        onWillPop: () async {
          return await showExitConfirmDialog(context) ?? false;
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xfff6f6f6),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60.0),
              child: AppBar(
                bottomOpacity: 0.0,
                elevation: 0.0,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                titleSpacing: 0,
                leadingWidth: size.width * 0.15,
                title: const AppLogo(height: 48),
                centerTitle: true,
              ),
            ),
            extendBody: true,
            extendBodyBehindAppBar: true,

            /*floatingActionButton: FloatingActionButton(
              onPressed: _openChatbot,
              backgroundColor: const Color(0xffe6910a),
              child: const Icon(UniconsLine.comment_dots),
            ),*/
            body: Consumer<HomeProvider>(
              builder: (context, provider, _) {
                mProvider = provider;
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.errorMessage.isNotEmpty) {
                  return Center(child: Text(provider.errorMessage));
                }

                final home = provider.homeData;
                if (home == null) {
                  return const Center(child: Text('لا توجد بيانات للعرض'));
                }
                final profile = home.profile;

                final role = home.role ?? profile?.title ?? 'user';
                title = role;

                if (isInit) {
                  if (profile != null) {
                    isOnline = profile.isOnline;
                  }
                  if (role == 'driver' && !_onlineSyncRequested) {
                    _onlineSyncRequested = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!isOnline) {
                        _setDriverOnlineStatus(true, showFeedback: false);
                      }
                    });
                  }
                  isInit = false;
                }
                if (!_profileLoadRequested) {
                  _profileLoadRequested = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    provider.ensureProfileLoaded();
                  });
                }

                final drivers = home.data?.drivers ?? [];
                final bookingRequests = home.data?.bookingRequests ?? [];
                final orders = home.data?.orders ?? [];

                if (role == 'user') {
                  return const SafeArea(
                    child: CustomerHomeSection(),
                  );
                }

                return SafeArea(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await provider.loadHomeData();
                    },
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.height * 0.01,
                      ),
                      children: [
                        _buildHeaderCard(
                          size,
                          role,
                          provider.driver?.message.image,
                        ),
                        const SizedBox(height: 14),
                        if (role == 'driver') ...[
                          _buildDriverOnlineCard(),
                          const SizedBox(height: 12),
                        ],
                        _buildSearchRow(size, provider),
                        const SizedBox(height: 12),


                        const SizedBox(height: 20),

                        if (role == 'driver') ...[
                          _buildSectionTitle(
                            icon: Icons.campaign_outlined,
                            title: 'طلبات العملاء الجديدة',
                          ),
                          const SizedBox(height: 8),
                          const DriverTripRequestsSection(),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            icon: Icons.list_alt_outlined,
                            title: 'الطلبات الجديدة',
                          ),
                          const SizedBox(height: 8),
                          bookingRequests.isEmpty
                              ? _buildEmptyState(
                            'لا توجد طلبات حالياً للسائق.',
                          )
                              : _buildBookingList(bookingRequests),
                          const SizedBox(height: 24),
                          _buildSectionTitle(
                            icon: Icons.history,
                            title: 'سجل الطلبات',
                          ),
                          const SizedBox(height: 8),
                          orders.isEmpty
                              ? _buildEmptyState('لا يوجد سجل للطلبات.')
                              : _buildDriverOrders(orders),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ===================== UI SECTIONS =====================

  Widget _buildDriverOnlineCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi_tethering : Icons.wifi_tethering_off,
              color: isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'أنت متصل الآن' : 'أنت غير متصل',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isOnline ? Colors.green.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isOnline
                        ? 'يظهر حسابك للعملاء ويمكنهم إرسال طلبات'
                        : 'لن يظهر حسابك للعملاء حتى تفعّل الاتصال',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (_isUpdatingOnlineStatus)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Switch(
                value: isOnline,
                activeColor: Colors.green,
                onChanged: (value) => _setDriverOnlineStatus(value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Size size, String role, String? imagePath) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xffe6910a),
            Colors.green,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          StorageNetworkAvatar(
            imagePath: imagePath,
            initial: (userName != null && userName!.isNotEmpty)
                ? userName![0].toUpperCase()
                : '...',
            size: 56,
            backgroundColor: Colors.white.withOpacity(0.18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName != null ? 'أهلاً، $userName' : 'أهلاً بك في موترنت',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role == 'driver'
                      ? 'استقبل الطلبات، ونظّم رحلاتك بسهولة.'
                      : 'اختر السائق المناسب، وحدّد مشوارك في ثواني.',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow(Size size, HomeProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ابحث عن وجهتك (مدينة نصر، المعادي...)',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onTap: () => _ensureLocationsLoaded(provider),
                onChanged: (value) => _onDestinationSearchChanged(value, provider),
                onSubmitted: (value) => _searchDestination(value, provider),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  UniconsLine.location_point,
                  size: 22,
                ),
                tooltip: 'مسح البحث',
                onPressed: () {
                  provider.clearFilters();
                  setState(() {
                    searchController.clear();
                    _locationSuggestions = [];
                    _showLocationSuggestions = false;
                  });
                },
              ),
            ),
          ],
        ),
        if (_showLocationSuggestions) ...[
          const SizedBox(height: 6),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _locationSuggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final match = _locationSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    match.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => _applyLocationMatch(match, provider),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionsCard(String role) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            QuickActionButton(
              icon: Icons.support_agent_outlined,
              label: 'دعم فني',
              onTap: _callSupport,
            ),
            if (role == 'driver') ...[
              OnlineToggleButton(
                isOnline: isOnline,
                onToggle: (newStatus) async {
                  setState(() {
                    isOnline = newStatus;
                  });

                  try {
                    final token = await CacheHelper.getData(key: 'token');

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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث حالتك بنجاح'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('حدث خطأ، حاول مرة أخرى'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تعذر الاتصال بالخادم'),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xffe6910a), size: 20),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xff272727),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          msg,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  // ===================== DRIVER SIDE =====================

  Widget _buildBookingList(List<HomeBookingRequest> bookingRequests) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookingRequests.length,
      itemBuilder: (context, index) {
        final booking = bookingRequests[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.customerName ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "الهاتف: ${booking.customerPhone ?? ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  "الاستلام: ${booking.pickLoc}",
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  "الوصول: ${booking.targetLoc}",
                  style: const TextStyle(fontSize: 13),
                ),
                if (booking.msg != null && booking.msg!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "التفاصيل: ${booking.msg}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                if (booking.createdAt != null)
                  Text(
                    booking.createdAt!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (booking.status != 'accepted') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showConfirmationDialog(
                              context,
                              booking.id!,
                              "accepted",
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("قبول"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            showConfirmationDialog(
                              context,
                              booking.id!,
                              "refused",
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("رفض"),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideBookMidPage(
                                  mRide: BookingRideAdapter(
                                    id: booking.id ?? 0,
                                    bookingId: booking.id ?? 0,
                                    partnerUserId: booking.customerId ?? 0,
                                    name: booking.customerName ?? '',
                                    phone: booking.customerPhone ?? '',
                                    title: 'user',
                                    area:
                                    '${booking.pickLoc ?? ''}///${booking.targetLoc ?? ''}///${booking.msg ?? ''}',
                                  ),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffe6910a),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("إكمال الرحلة"),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverOrders(List<HomeOrder> orders) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final o = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xffe6910a),
              child: Icon(
                Icons.history,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              '${o.pickLoc ?? ''} → ${o.targetLoc ?? ''}',
              style: const TextStyle(fontSize: 13.5),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (o.msg != null && o.msg!.isNotEmpty)
                  Text(
                    o.msg!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 2),
                Text(
                  'الحالة: ${o.status ?? ''}',
                  style: const TextStyle(fontSize: 11),
                ),
                if (o.createdAt != null)
                  Text(
                    o.createdAt!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===================== USER SIDE =====================

  Widget _buildDriversList(List<HomeDriver> drivers) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xffe6910a).withOpacity(0.12),
                  child: const Icon(
                    Icons.delivery_dining,
                    color: Color(0xffe6910a),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "هاتف: ${driver.phone}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "مركبة: ${driver.vehicleType ?? 'غير محدد'}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      if ((driver.governorate ?? '').isNotEmpty ||
                          (driver.area ?? '').isNotEmpty)
                        Text(
                          '${driver.governorate ?? ''} - ${driver.area ?? ''}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!driver.isBooked) ...[
                  ElevatedButton(
                    onPressed: () {
                      showBookDialog(context, driver.id!, driver);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffe6910a),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(80, 38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'إرسال طلب',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'لديك طلب قائم',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserOrders(List<HomeOrder> orders) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final o = orders[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 1.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green,
              child: Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: Text(
              '${o.pickLoc ?? ''} → ${o.targetLoc ?? ''}',
              style: const TextStyle(fontSize: 13.5),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (o.msg != null && o.msg!.isNotEmpty)
                  Text(
                    o.msg!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                const SizedBox(height: 2),
                Text(
                  'الحالة: ${o.status ?? ''}',
                  style: const TextStyle(fontSize: 11),
                ),
                if (o.createdAt != null)
                  Text(
                    o.createdAt!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                if (o.driver != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'السائق: ${o.driver!.name ?? ''}',
                    style: const TextStyle(fontSize: 11.5),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================== COMMON WIDGETS & HELPERS =====================

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xffe6910a).withOpacity(0.12),
            child: Icon(
              icon,
              color: const Color(0xffe6910a),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class OnlineToggleButton extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggle;

  const OnlineToggleButton({
    Key? key,
    required this.isOnline,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Switch(
          value: isOnline,
          activeColor: Colors.green,
          onChanged: onToggle,
        ),
        Text(
          isOnline ? 'متصل' : 'غير متصل',
          style: const TextStyle(fontSize: 11.5),
        ),
      ],
    );
  }
}

Future<bool?> showExitConfirmDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('تأكيد الخروج'),
      content: const Text('هل تريد الخروج من التطبيق؟'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('لا'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('نعم'),
        ),
      ],
    ),
  );
}

void showConfirmationDialog(
    BuildContext context,
    int bookingId,
    String status,
    ) {
  final parentContext = context;
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('تأكيد'),
        content: Text(
          status == 'accepted'
              ? 'هل تريد قبول هذا الطلب؟'
              : 'هل تريد رفض هذا الطلب؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await updateBookingStatus(parentContext, bookingId, status);
            },
            child: const Text('تأكيد'),
          ),
        ],
      );
    },
  );
}

Future<void> updateBookingStatus(
    BuildContext context, int bookingId, String status) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final homeProvider = Provider.of<HomeProvider>(context, listen: false);

  try {
    final token = await CacheHelper.getData(key: 'token');

    final response = await Dio().post(
      updateBookingStatusEP,
      data: {
        'id': bookingId,
        'status': status,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    if (response.statusCode == 200) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'تم قبول الطلب بنجاح'
                : 'تم رفض الطلب بنجاح',
          ),
        ),
      );
      homeProvider.loadHomeData();
    } else {
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('حدث خطأ، حاول مرة أخرى'),
        ),
      );
    }
  } catch (e) {
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('تعذر الاتصال بالخادم'),
      ),
    );
  }
}

void showBookDialog(BuildContext context, int rideId, dynamic ride) {
  final homeProvider = Provider.of<HomeProvider>(context, listen: false);
  final messenger = ScaffoldMessenger.maybeOf(context);
  TextEditingController pickLocationController = TextEditingController();
  TextEditingController targetLocationController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text(
              'بيانات الحجز',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'السائق: ${ride.name ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pickLocationController,
                        decoration: const InputDecoration(
                          labelText: 'مكان البدايه',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: targetLocationController,
                        decoration: const InputDecoration(
                          labelText: 'مكان النهايه',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: detailsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'تفاصيل إضافية',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (pickLocationController.text.isEmpty ||
                      targetLocationController.text.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content:
                        Text('من فضلك أدخل مكان البدايه ومكان النهايه'),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(dialogContext);

                  try {
                    final token = await CacheHelper.getData(key: 'token');

                    final response = await Dio().post(
                      '$BASE_URL/ridebook',
                      data: {
                        'driver_id': rideId,
                        'pick_loc': pickLocationController.text,
                        'target_loc': targetLocationController.text,
                        'msg': detailsController.text,
                      },
                      options: Options(
                        headers: {
                          'Authorization': 'Bearer $token',
                        },
                      ),
                    );

                    if (response.statusCode == 200) {
                      messenger?.showSnackBar(
                        const SnackBar(
                          content: Text('تم إرسال الطلب بنجاح'),
                        ),
                      );
                      homeProvider.loadHomeData();
                    } else {
                      messenger?.showSnackBar(
                        const SnackBar(
                          content: Text('حدث خطأ، حاول مرة أخرى'),
                        ),
                      );
                    }
                  } catch (e) {
                    messenger?.showSnackBar(
                      const SnackBar(
                        content: Text('تعذر الاتصال بالخادم'),
                      ),
                    );
                  }
                },
                child: const Text('إرسال'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _openGovernorateDialog(BuildContext context) {
  // هنا ممكن لاحقاً تربط المحافظات / المدن من الـ backend
}

class BookingRideAdapter {
  final int id;
  final int bookingId;
  final int partnerUserId;
  final String name;
  final String phone;
  final String title; // هنا بنستخدمها 'user'
  final String? area; // pick///target///msg
  final String? vehicleType;
  final String? governorate;

  BookingRideAdapter({
    required this.id,
    required this.bookingId,
    required this.partnerUserId,
    required this.name,
    required this.phone,
    required this.title,
    this.area,
    this.vehicleType,
    this.governorate,
  });
}
