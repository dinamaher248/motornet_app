import 'package:motorent/features/services/domain/entities/service_entities.dart';

class StoreModel extends Store {
  const StoreModel({
    required super.id,
    required super.name,
    super.image,
    super.address,
    super.isOpen,
    super.distanceLabel,
    super.distanceM,
    super.lat,
    super.lng,
    super.avgRating,
    super.ratingsCount,
    super.paymentMethods,
    super.walletNumber,
    super.walletOwnerDisplay,
    super.phone,
    super.products,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'] as List? ?? [];
    var methods = (json['payment_methods'] as List? ?? [])
        .whereType<Map>()
        .map((e) => PaymentMethodModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // إزالة تكرار «دفع عند الاستلام» (cash + on_delivery / cod)
    final seenLabels = <String>{};
    var seenCod = false;
    methods = methods.where((m) {
      final key = m.key.toLowerCase().trim();
      final isCod = key == 'cash' ||
          key == 'on_delivery' ||
          key == 'cod' ||
          key == 'cash_on_delivery' ||
          key == 'pay_on_delivery';
      if (isCod) {
        if (seenCod) return false;
        seenCod = true;
        seenLabels.add('دفع عند الاستلام');
        return true;
      }
      final label = m.label.trim();
      if (label.isEmpty || seenLabels.contains(label)) return false;
      seenLabels.add(label);
      return true;
    }).map((m) {
      final key = m.key.toLowerCase().trim();
      final isCod = key == 'cash' ||
          key == 'on_delivery' ||
          key == 'cod' ||
          key == 'cash_on_delivery' ||
          key == 'pay_on_delivery';
      if (isCod) {
        return const PaymentMethodModel(key: 'cash', label: 'دفع عند الاستلام');
      }
      return m;
    }).toList();

    if (methods.isEmpty) {
      final acceptsCash = json['accepts_cash'] == true ||
          json['accepts_cash'] == 1 ||
          json['pay_on_delivery'] == true ||
          json['pay_on_delivery'] == 1;
      final acceptsWallet = json['accepts_wallet'] == true ||
          json['accepts_wallet'] == 1 ||
          json['pay_wallet'] == true ||
          json['pay_wallet'] == 1;
      if (acceptsCash || (!acceptsCash && !acceptsWallet)) {
        methods = const [
          PaymentMethodModel(key: 'cash', label: 'دفع عند الاستلام'),
        ];
      }
      if (acceptsWallet) {
        methods = [
          ...methods,
          const PaymentMethodModel(key: 'wallet', label: 'محفظة إلكترونية'),
        ];
      }
    }
    return StoreModel(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      image: json['image']?.toString(),
      address: json['address']?.toString(),
      isOpen: _asBool(json['is_open'] ?? json['isOpen'], fallback: true),
      distanceLabel: (json['distance_label'] ?? json['distanceLabel'])?.toString(),
      distanceM: _asDouble(json['distance_m'] ?? json['distanceM']),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      avgRating: _asDouble(
            json['avg_rating'] ?? json['rating'] ?? json['avgRating'],
          ) ??
          0,
      ratingsCount: _asInt(
        json['ratings_count'] ?? json['ratingsCount'] ?? 0,
      ),
      paymentMethods: methods,
      walletNumber: (json['wallet_number'] ?? json['walletNumber'])?.toString(),
      walletOwnerDisplay:
          (json['wallet_owner_display'] ??
                  json['walletOwnerDisplay'] ??
                  json['wallet_holder_name'] ??
                  json['wallet_owner_name'])
              ?.toString(),
      phone: json['phone']?.toString(),
      products: productsRaw
          .whereType<Map>()
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static bool _asBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    if (s == '1' || s == 'true') return true;
    if (s == '0' || s == 'false') return false;
    return fallback;
  }
}

class ProductModel extends ServiceProduct {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.description,
    super.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: StoreModel._asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      price: StoreModel._asDouble(json['price']) ?? 0,
      description: json['description']?.toString(),
      image: json['image']?.toString(),
    );
  }
}

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({required super.key, required super.label});

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
    );
  }
}

class ServiceOrderModel extends ServiceOrder {
  const ServiceOrderModel({
    required super.id,
    required super.status,
    required super.message,
  });

  factory ServiceOrderModel.fromJson(Map<String, dynamic> json) {
    return ServiceOrderModel(
      id: StoreModel._asInt(json['id']),
      status: (json['status'] ?? 'pending').toString(),
      message: (json['message'] ?? 'تم إرسال الطلب للمتجر وهو بانتظار المراجعة')
          .toString(),
    );
  }
}

class CustomOrderModel extends CustomOrder {
  const CustomOrderModel({
    required super.id,
    super.orderType,
    super.storeId,
    super.storeName,
    super.requestText,
    super.requestImage,
    super.deliveryAddress,
    super.contactPhone,
    super.notes,
    super.offerPrice,
    super.offerNotes,
    required super.status,
    super.statusLabel,
    super.canAcceptOffer,
    super.canRejectOffer,
    super.message,
  });

  factory CustomOrderModel.fromJson(Map<String, dynamic> json) {
    return CustomOrderModel(
      id: StoreModel._asInt(json['id']),
      orderType: (json['order_type'] ?? 'custom').toString(),
      storeId: json['store_id'] != null
          ? StoreModel._asInt(json['store_id'])
          : (json['merchant_id'] != null
              ? StoreModel._asInt(json['merchant_id'])
              : null),
      storeName: (json['store_name'] ?? json['merchant_name'])?.toString(),
      requestText: json['custom_request_text']?.toString() ??
          json['request_text']?.toString(),
      requestImage: json['custom_request_image']?.toString() ??
          json['request_image']?.toString(),
      deliveryAddress: (json['delivery_address'] ?? '').toString(),
      contactPhone: json['customer_contact_phone']?.toString() ??
          json['contact_phone']?.toString(),
      notes: json['notes']?.toString(),
      offerPrice: StoreModel._asDouble(
        json['merchant_offer_price'] ?? json['offer_price'],
      ),
      offerNotes: json['merchant_offer_notes']?.toString() ??
          json['offer_notes']?.toString() ??
          json['vendor_notes']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      statusLabel: (json['status_label'] ?? json['status'] ?? '').toString(),
      canAcceptOffer: json['can_accept_offer'] == true,
      canRejectOffer: json['can_reject_offer'] == true,
      message: json['message']?.toString(),
    );
  }
}
