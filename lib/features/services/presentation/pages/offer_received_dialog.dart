import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/custom_order_bloc.dart';
import 'package:motorent/features/services/services_injection.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

/// Dialog / screen for client response to a vendor custom-order offer.
class OfferReceivedDialog extends StatelessWidget {
  final CustomOrder order;
  final CustomOrderBloc? bloc;

  const OfferReceivedDialog({
    super.key,
    required this.order,
    this.bloc,
  });

  static Future<CustomOrder?> show(
    BuildContext context, {
    required CustomOrder order,
    CustomOrderBloc? bloc,
  }) {
    return showDialog<CustomOrder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => OfferReceivedDialog(order: order, bloc: bloc),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownsBloc = bloc == null;
    final body = _OfferReceivedBody(order: order);

    if (ownsBloc) {
      return BlocProvider(
        create: (_) => ServicesInjection.createCustomOrderBloc(),
        child: body,
      );
    }
    return BlocProvider.value(value: bloc!, child: body);
  }
}

class _OfferReceivedBody extends StatelessWidget {
  final CustomOrder order;

  const _OfferReceivedBody({required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomOrderBloc, CustomOrderState>(
      listener: (context, state) {
        if (state.status == CustomOrderStatus.respondSuccess) {
          Navigator.of(context).pop(state.order);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? 'تم')),
          );
        } else if (state.status == CustomOrderStatus.failure &&
            (state.message ?? '').isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        final busy = state.isBusy;
        final price = order.offerPrice;
        final notes = (order.offerNotes ?? '').trim();

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'عرض من المتجر',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AuthTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'السعر الإجمالي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        color: AuthTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price != null
                          ? '${price.toStringAsFixed(0)} ج.م'
                          : 'غير متوفر',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: AuthTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'ملاحظات المتجر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  notes,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AuthTheme.textDark,
                  ),
                ),
              ],
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      context.read<CustomOrderBloc>().add(
                            RespondToVendorOfferEvent(
                              orderId: order.id,
                              action: 'reject',
                            ),
                          );
                    },
              child: Text(
                busy ? '...' : 'رفض',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () {
                      context.read<CustomOrderBloc>().add(
                            RespondToVendorOfferEvent(
                              orderId: order.id,
                              action: 'accept',
                            ),
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0C9F6A),
                foregroundColor: Colors.white,
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'قبول',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Full-screen variant of [OfferReceivedDialog].
class OfferReceivedScreen extends StatelessWidget {
  final CustomOrder order;

  const OfferReceivedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicesInjection.createCustomOrderBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'عرض من المتجر',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
          ),
        ),
        body: BlocConsumer<CustomOrderBloc, CustomOrderState>(
          listener: (context, state) {
            if (state.status == CustomOrderStatus.respondSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'تم')),
              );
              Navigator.pop(context, state.order);
            } else if (state.status == CustomOrderStatus.failure &&
                (state.message ?? '').isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message!)),
              );
            }
          },
          builder: (context, state) {
            final busy = state.isBusy;
            final price = order.offerPrice;
            final notes = (order.offerNotes ?? '').trim();

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AuthTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AuthTheme.fieldBorder),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'السعر الإجمالي',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            color: AuthTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          price != null
                              ? '${price.toStringAsFixed(0)} ج.م'
                              : 'غير متوفر',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            color: AuthTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'ملاحظات المتجر',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notes,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: busy
                              ? null
                              : () {
                                  context.read<CustomOrderBloc>().add(
                                        RespondToVendorOfferEvent(
                                          orderId: order.id,
                                          action: 'reject',
                                        ),
                                      );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'رفض',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: busy
                              ? null
                              : () {
                                  context.read<CustomOrderBloc>().add(
                                        RespondToVendorOfferEvent(
                                          orderId: order.id,
                                          action: 'accept',
                                        ),
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0C9F6A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'قبول',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
