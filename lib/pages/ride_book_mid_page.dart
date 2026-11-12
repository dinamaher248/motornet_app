import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:motorent/widgets/app_logo.dart';

class RideBookMidPage extends StatefulWidget {
  /// يستقبل أي object:
  /// - Driver
  /// - BookingRideAdapter
  /// - OrderRideAdapter
  final dynamic mRide;

  const RideBookMidPage({required this.mRide, Key? key}) : super(key: key);

  @override
  State<RideBookMidPage> createState() => _RideBookMidPageState();
}

class _RideBookMidPageState extends State<RideBookMidPage> {
  late final dynamic ride;

  String? pickLoc;
  String? targetLoc;
  String? details;

  @override
  void initState() {
    super.initState();
    ride = widget.mRide;

    // لو العنوان user → نتوقع area = "pick///target///msg"
    try {
      if (ride.title == 'user' && ride.area != null) {
        final parts = (ride.area as String).split('///');
        pickLoc = parts.isNotEmpty ? parts[0] : null;
        targetLoc = parts.length > 1 ? parts[1] : null;
        details = parts.length > 2 ? parts[2] : null;
      }
    } catch (_) {
      // لو حصل أي مشكلة في الـ dynamic، نتجاهل تقسيم الـ area
    }
  }

  Future<void> _callPhone() async {
    final phone = (ride.phone ?? '').toString().trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد رقم هاتف متاح')),
      );
      return;
    }

    final Uri callUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح تطبيق الاتصال')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBooking = (ride.title?.toString() ?? '') == 'user';
    final roleTitle = (ride.title?.toString() ?? '').toLowerCase() == 'driver'
        ? 'سائق'
        : 'عميل';

    final vehicleType = _safeString(() => ride.vehicleType);
    final governorate = _safeString(() => ride.governorate);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfff6f6f6),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            bottomOpacity: 0.0,
            elevation: 0.0,
            shadowColor: Colors.transparent,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            leadingWidth: 56,
            title: const AppLogo(height: 40),
            centerTitle: true,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderCard(roleTitle),
                const SizedBox(height: 16),
                if (isBooking) _buildBookingDetailsCard() else _buildDriverDetailsCard(vehicleType, governorate),
                if (isBooking && (details != null && details!.trim().isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  _buildNotesCard(),
                ],
                const SizedBox(height: 24),
                _buildActionsRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String roleTitle) {
    final name = _safeString(() => ride.name, fallback: 'بدون اسم');
    final phone = _safeString(() => ride.phone);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xffe6910a),
            Color(0xff0c9f6a),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withOpacity(0.16),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleTitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (phone.isNotEmpty)
                      Expanded(
                        child: Text(
                          phone,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              InkWell(
                onTap: _callPhone,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Color(0xff0c9f6a),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل الطلب',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xff272727),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.my_location,
              label: 'مكان البدايه',
              value: pickLoc ?? 'غير محدد',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.location_on,
              label: 'مكان النهايه',
              value: targetLoc ?? 'غير محدد',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverDetailsCard(String? vehicleType, String? governorate) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل السائق والمركبة',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xff272727),
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoRow(
              icon: Icons.delivery_dining,
              label: 'نوع المركبة',
              value: vehicleType?.isNotEmpty == true
                  ? vehicleType!
                  : 'غير محدد',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.map_outlined,
              label: 'المحافظة',
              value: governorate?.isNotEmpty == true
                  ? governorate!
                  : 'غير محددة',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تفاصيل إضافية',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xff272727),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              details ?? '',
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xff555555),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xffe6910a),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff272727),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.red,
              size: 18,
            ),
            label: const Text(
              'رجوع',
              style: TextStyle(color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _callPhone,
            icon: const Icon(
              Icons.phone,
              size: 18,
            ),
            label: const Text('اتصال'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffe6910a),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // helper آمن للتعامل مع dynamic
  String _safeString(String? Function() getter, {String fallback = ''}) {
    try {
      final v = getter();
      if (v == null) return fallback;
      return v.toString();
    } catch (_) {
      return fallback;
    }
  }
}
