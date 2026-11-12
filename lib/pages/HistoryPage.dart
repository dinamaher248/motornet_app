import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/bidding_system/presentation/pages/trip_details_screen.dart';
import 'package:motorent/pages/order_tracking/active_order_tracking_page.dart';
import 'package:motorent/pages/ride_book_mid_page.dart';
import 'package:motorent/widgets/app_logo.dart';

class HistoryPage extends StatefulWidget {
  final int refreshToken;

  const HistoryPage({Key? key, this.refreshToken = 0}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool isLoading = true;
  String role = 'user';

  String statusFilter = 'all';

  int totalCount = 0;
  int acceptedCount = 0;
  int refusedCount = 0;
  int pendingCount = 0;
  int completedCount = 0;

  List<HistoryItem> history = [];

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      fetchHistory();
    }
  }

  Future<void> fetchHistory() async {
    try {
      final token = await CacheHelper.getData(key: 'token');

      final queryParameters =
          statusFilter == 'all' ? null : {'status': statusFilter};

      final response = await Dio().get(
        '$BASE_URL/history',
        queryParameters: queryParameters,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          validateStatus: (s) => s != null && s < 600,
        ),
      );

      final body = response.data;
      final ok = response.statusCode == 200 &&
          body is Map &&
          (body['status_code'] == 200 ||
              body['status'] == 'success' ||
              body['status'] == true ||
              body['history'] is List);

      if (ok) {
        final data = Map<String, dynamic>.from(body as Map);

        final stats = data['stats'] is Map
            ? Map<String, dynamic>.from(data['stats'] as Map)
            : <String, dynamic>{};
        final list = data['history'] ?? data['data'];

        setState(() {
          role = (data['role'] ?? 'user').toString();

          totalCount = int.tryParse('${stats['total_count'] ?? 0}') ?? 0;
          acceptedCount = int.tryParse('${stats['accepted_count'] ?? 0}') ?? 0;
          refusedCount = int.tryParse('${stats['refused_count'] ?? 0}') ?? 0;
          pendingCount = int.tryParse('${stats['pending_count'] ?? 0}') ?? 0;
          completedCount = int.tryParse('${stats['completed_count'] ?? 0}') ?? 0;

          history = list is List
              ? list
                  .whereType<Map>()
                  .map((e) =>
                      HistoryItem.fromJson(Map<String, dynamic>.from(e)))
                  .where((e) => e.id > 0)
                  .toList()
              : [];

          isLoading = false;
        });
      } else {
        final msg = body is Map && body['message'] is String
            ? body['message'] as String
            : 'حدث خطأ، حاول مرة أخرى';
        showError(msg);
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('history error: $e');
      showError('فشل الاتصال بالخادم');
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final themeData = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  setState(() => isLoading = true);
                  await fetchHistory();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  child: Column(
                    children: [
                      _buildStatsCard(),
                      const SizedBox(height: 12),
                      _buildFilterRow(),
                      const SizedBox(height: 12),
                      Expanded(child: _buildHistoryList()),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('الكل', totalCount, Colors.blueGrey),
            _buildStatItem('مقبولة', acceptedCount, Colors.green),
            _buildStatItem('مرفوضة', refusedCount, Colors.red),
            _buildStatItem('معلقة', pendingCount, Colors.orange),
            _buildStatItem('مكتملة', completedCount, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      {'label': 'الكل', 'value': 'all'},
      {'label': 'مقبولة', 'value': 'accepted'},
      {'label': 'مرفوضة', 'value': 'refused'},
      {'label': 'معلقة', 'value': 'pending'},
      {'label': 'مكتملة', 'value': 'completed'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final v = f['value'] as String;
          final isSelected = statusFilter == v;
          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: ChoiceChip(
              label: Text(
                f['label'] as String,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xffe6910a),
              backgroundColor: Colors.grey.shade200,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  statusFilter = v;
                  isLoading = true;
                });
                fetchHistory();
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryList() {
    if (history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Text(
              'لا يوجد سجل للرحلات حتى الآن',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(HistoryItem item) {
    final isDriver = role == 'driver';
    final other = item.otherParty;

    final status = item.status ?? '';
    Color statusColor;
    Color statusBg;
    final statusText = (item.statusLabel ?? '').isNotEmpty
        ? item.statusLabel!
        : _fallbackStatusText(status);

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusBg = Colors.green.withOpacity(0.08);
        break;
      case 'refused':
        statusColor = Colors.red;
        statusBg = Colors.red.withOpacity(0.08);
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusBg = Colors.orange.withOpacity(0.08);
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusBg = Colors.blue.withOpacity(0.08);
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey.withOpacity(0.08);
        break;
    }

    final titleName = (item.title ?? '').isNotEmpty
        ? item.title!
        : (other.name ?? (isDriver ? 'العميل' : 'السائق'));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if ((other.name ?? '').isNotEmpty &&
                          other.name != titleName)
                        Text(
                          other.name!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if ((other.phone ?? '').isNotEmpty)
                        Text(
                          'الهاتف: ${other.phone}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'الاستلام: ${item.pickLoc ?? '-'}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'الوصول: ${item.targetLoc ?? '-'}',
              style: const TextStyle(fontSize: 13),
            ),
            if ((item.msg ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.msg!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if ((item.createdAt ?? '').isNotEmpty)
                  Text(
                    item.createdAt!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                TextButton(
                  onPressed: () => _openDetails(item),
                  child: const Text(
                    'التفاصيل',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'مقبول';
      case 'refused':
        return 'مرفوض';
      case 'pending':
        return 'معلق';
      case 'completed':
        return 'مكتمل';
      default:
        return status.isEmpty ? 'غير محدد' : status;
    }
  }

  Future<void> _openDetails(HistoryItem item) async {
    final type = (item.type ?? 'ride_book').toLowerCase();
    final raw = (item.rawStatus ?? item.status ?? '').toLowerCase();

    if (type == 'bidding_trip' &&
        (raw == 'pending' || raw == 'awaiting_offers')) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailsScreen(tripId: item.id),
        ),
      );
    } else if (type == 'ride_book') {
      final isDriver = role == 'driver';
      final other = item.otherParty;
      final adapter = HistoryRideAdapter(
        id: other.id ?? 0,
        bookingId: item.id,
        partnerUserId: other.id ?? 0,
        name: other.name ?? '',
        phone: other.phone ?? '',
        title: isDriver ? 'user' : (other.title ?? 'driver'),
        area:
            '${item.pickLoc ?? ''}///${item.targetLoc ?? ''}///${item.msg ?? ''}',
        vehicleType: other.vehicleType,
        governorate: other.governorate,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RideBookMidPage(mRide: adapter),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveOrderTrackingPage(
            type: type,
            id: item.id,
            isDriverView: role == 'driver',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => isLoading = true);
      await fetchHistory();
    }
  }
}

// ====== Models ======

class HistoryItem {
  final int id;
  final String? type;
  final String? title;
  final dynamic amount;
  final int? seatCount;
  final String? msg;
  final String? pickLoc;
  final String? targetLoc;
  final String? status;
  final String? rawStatus;
  final String? statusLabel;
  final String? createdAt;
  final HistoryOtherParty otherParty;

  HistoryItem({
    required this.id,
    this.type,
    this.title,
    this.amount,
    this.seatCount,
    this.msg,
    this.pickLoc,
    this.targetLoc,
    this.status,
    this.rawStatus,
    this.statusLabel,
    this.createdAt,
    required this.otherParty,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? 0,
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      amount: json['amount'],
      seatCount: json['seat_count'],
      msg: json['msg']?.toString(),
      pickLoc: json['pick_loc']?.toString(),
      targetLoc: json['target_loc']?.toString(),
      status: json['status']?.toString(),
      rawStatus: json['raw_status']?.toString(),
      statusLabel: json['status_label']?.toString(),
      createdAt: json['created_at']?.toString(),
      otherParty: HistoryOtherParty.fromJson(
        json['other_party'] is Map
            ? Map<String, dynamic>.from(json['other_party'] as Map)
            : <String, dynamic>{},
      ),
    );
  }
}

class HistoryOtherParty {
  final int? id;
  final String? name;
  final String? phone;
  final String? title;
  final String? vehicleType;
  final String? governorate;
  final String? area;

  HistoryOtherParty({
    this.id,
    this.name,
    this.phone,
    this.title,
    this.vehicleType,
    this.governorate,
    this.area,
  });

  factory HistoryOtherParty.fromJson(Map<String, dynamic> json) {
    return HistoryOtherParty(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id'] ?? ''}'),
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      title: json['title']?.toString(),
      vehicleType: json['vehicle_type']?.toString(),
      governorate: json['governorate']?.toString(),
      area: json['area']?.toString(),
    );
  }
}

/// Adapter يجهز الداتا لصفحة RideBookMidPage
class HistoryRideAdapter {
  final int id;
  final int bookingId;
  final int partnerUserId;
  final String name;
  final String phone;
  final String title; // user / driver
  final String? area; // pick///target///msg
  final String? vehicleType;
  final String? governorate;

  HistoryRideAdapter({
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
