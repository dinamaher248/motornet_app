import 'package:motorent/features/services/domain/entities/service_entities.dart';

/// توحيد وإزالة تكرار طرق الدفع (خصوصاً دفع عند الاستلام).
List<PaymentMethod> normalizePaymentMethods(Iterable<PaymentMethod> raw) {
  final out = <PaymentMethod>[];
  final seenLabels = <String>{};
  var seenCod = false;

  for (final m in raw) {
    final key = m.key.toLowerCase().trim();
    final label = m.label.trim();
    final isCod = key == 'cash' ||
        key == 'on_delivery' ||
        key == 'cod' ||
        key == 'cash_on_delivery' ||
        key == 'pay_on_delivery' ||
        label.contains('الاستلام') ||
        label.contains('كاش') ||
        label.toLowerCase().contains('cash');

    if (isCod) {
      if (seenCod) continue;
      seenCod = true;
      const cod = PaymentMethod(key: 'cash', label: 'دفع عند الاستلام');
      out.add(cod);
      seenLabels.add(cod.label);
      continue;
    }

    if (label.isEmpty || seenLabels.contains(label)) continue;
    seenLabels.add(label);

    if (key == 'wallet' || key == 'e_wallet' || label.contains('محفظة')) {
      out.add(const PaymentMethod(key: 'wallet', label: 'محفظة إلكترونية'));
    } else {
      out.add(PaymentMethod(key: key.isEmpty ? label : key, label: label));
    }
  }

  if (out.isEmpty) {
    return const [
      PaymentMethod(key: 'cash', label: 'دفع عند الاستلام'),
    ];
  }
  return out;
}
