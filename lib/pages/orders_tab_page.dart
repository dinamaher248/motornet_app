import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/pages/customer/order_tracking_page.dart';
import 'package:motorent/pages/ride_book_mid_page.dart';
import 'package:motorent/widgets/app_logo.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  bool isLoading = true;
  String role = 'user';

  int acceptedCount = 0;
  int refusedCount = 0;
  int pendingCount = 0;

  List<OrderItem> orders = [];

  @override
  void initState() {
    super.initState();
    role = CacheHelper.getData(key: 'title')?.toString() ?? 'user';
    if (role != 'user') {
      fetchOrders();
    } else {
      isLoading = false;
    }
  }

  Future<void> fetchOrders() async {
    try {
      final token = await CacheHelper.getData(key: 'token');

      final response = await Dio().get(
        '$BASE_URL/get_orders_data',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 &&
          (response.data['status_code'] == 200 ||
              response.data['status'] == 'success')) {
        final data = response.data;

        final stats = data['stats'] ?? {};

        setState(() {
          role = (data['role'] ?? 'user').toString();

          acceptedCount = stats['accepted_count'] ?? 0;
          refusedCount = stats['refused_count'] ?? 0;
          pendingCount = stats['pending_count'] ?? 0;

          orders = (data['orders'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList();

          isLoading = false;
        });
      } else {
        showError('حدث خطأ، حاول مرة أخرى');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('get_orders_data error: $e');
      showError('فشل الاتصال بالخادم');
      setState(() {
        isLoading = false;
      });
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (role == 'user') {
      return const Directionality(
        textDirection: TextDirection.rtl,
        child: OrderTrackingPage(),
      );
    }

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
            title: const AppLogo(height: 48),
            centerTitle: true,
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              _buildStatsCard(),
              const SizedBox(height: 16),
              Expanded(child: _buildOrdersList()),
            ],
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
            _buildStatItem('المقبولة', acceptedCount, Colors.green),
            _buildStatItem('المرفوضة', refusedCount, Colors.red),
            _buildStatItem('المعلقة', pendingCount, Colors.orange),
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
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersList() {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'لا توجد طلبات حالياً',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    final isDriver = role == 'driver';
    final other = order.otherParty;

    final status = order.status ?? '';
    Color statusColor;
    Color statusBg;
    String statusText;

    switch (status) {
      case 'accepted':
        statusColor = Colors.green;
        statusBg = Colors.green.withOpacity(0.08);
        statusText = 'مقبول';
        break;
      case 'refused':
        statusColor = Colors.red;
        statusBg = Colors.red.withOpacity(0.08);
        statusText = 'مرفوض';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusBg = Colors.orange.withOpacity(0.08);
        statusText = 'معلّق';
        break;
      default:
        statusColor = Colors.grey;
        statusBg = Colors.grey.withOpacity(0.08);
        statusText = status.isEmpty ? 'غير محدد' : status;
        break;
    }

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
            // العنوان + الحالة
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        other.name ?? (isDriver ? 'العميل' : 'السائق'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
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
              'الاستلام: ${order.pickLoc ?? '-'}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'الوصول: ${order.targetLoc ?? '-'}',
              style: const TextStyle(fontSize: 13),
            ),
            if ((order.msg ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                order.msg!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if ((order.createdAt ?? '').isNotEmpty)
                  Text(
                    order.createdAt!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _openDetails(order),
                      child: const Text(
                        'التفاصيل',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    if (role == 'driver' && order.status == 'pending') ...[
                      TextButton(
                        onPressed: () =>
                            _showUpdateStatusDialog(order.id, 'accepted'),
                        child: const Text(
                          'قبول',
                          style:
                          TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            _showUpdateStatusDialog(order.id, 'refused'),
                        child: const Text(
                          'رفض',
                          style:
                          TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(OrderItem order) {
    final isDriver = role == 'driver';
    final other = order.otherParty;

    // نكوّن adapter بنفس فكرة BookingRideAdapter في الـ Home
    final adapter = OrderRideAdapter(
      id: other.id ?? 0,
      bookingId: order.id,
      partnerUserId: other.id ?? 0,
      name: other.name ?? '',
      phone: other.phone ?? '',
      title: isDriver ? 'user' : (other.title ?? 'driver'),
      area:
      '${order.pickLoc ?? ''}///${order.targetLoc ?? ''}///${order.msg ?? ''}',
      vehicleType: other.vehicleType,
      governorate: other.governorate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideBookMidPage(mRide: adapter),
      ),
    );
  }

  void _showUpdateStatusDialog(int bookingId, String newStatus) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            newStatus == 'accepted'
                ? 'تأكيد القبول'
                : 'تأكيد الرفض',
          ),
          content: Text(
            'هل أنت متأكد أنك تريد ${newStatus == 'accepted' ? 'قبول' : 'رفض'} هذا الطلب؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateBookingStatus(bookingId, newStatus);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBookingStatus(int bookingId, String status) async {
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
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم التحديث بنجاح')),
        );
        await fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ، حاول مجدداً')),
        );
      }
    } catch (e) {
      debugPrint('update_booking_status error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الاتصال بالخادم')),
      );
    }
  }
}

/// نموذج الطلب كما يرجع من الـ API
class OrderItem {
  final int id;
  final int? amount;
  final int? seatCount;
  final String? msg;
  final String? pickLoc;
  final String? targetLoc;
  final String? status;
  final String? createdAt;
  final OtherParty otherParty;

  OrderItem({
    required this.id,
    this.amount,
    this.seatCount,
    this.msg,
    this.pickLoc,
    this.targetLoc,
    this.status,
    this.createdAt,
    required this.otherParty,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      amount: json['amount'],
      seatCount: json['seat_count'],
      msg: json['msg'],
      pickLoc: json['pick_loc'],
      targetLoc: json['target_loc'],
      status: json['status'],
      createdAt: json['created_at'],
      otherParty:
      OtherParty.fromJson(json['other_party'] ?? <String, dynamic>{}),
    );
  }
}

class OtherParty {
  final int? id;
  final String? name;
  final String? phone;
  final String? title;
  final String? vehicleType;
  final String? governorate;
  final String? area;

  OtherParty({
    this.id,
    this.name,
    this.phone,
    this.title,
    this.vehicleType,
    this.governorate,
    this.area,
  });

  factory OtherParty.fromJson(Map<String, dynamic> json) {
    return OtherParty(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      title: json['title'],
      vehicleType: json['vehicle_type'],
      governorate: json['governorate'],
      area: json['area'],
    );
  }
}

/// Adapter يجهّز الداتا لـ RideBookMidPage
class OrderRideAdapter {
  final int id;
  final int bookingId;
  final int partnerUserId;
  final String name;
  final String phone;
  final String title; // user / driver
  final String? area; // pick///target///msg
  final String? vehicleType;
  final String? governorate;

  OrderRideAdapter({
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
