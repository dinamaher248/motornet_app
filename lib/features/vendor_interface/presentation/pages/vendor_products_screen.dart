import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/local/auth_prefs.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/vendor_interface/presentation/bloc/vendor_products_bloc.dart';
import 'package:motorent/features/vendor_interface/presentation/pages/vendor_add_product_screen.dart';
import 'package:motorent/features/vendor_interface/vendor_interface_injection.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:shimmer/shimmer.dart';

class VendorProductsScreen extends StatelessWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VendorInterfaceInjection.createProductsBloc()
        ..add(const FetchVendorProductsEvent()),
      child: const _VendorProductsView(),
    );
  }
}

class _VendorProductsView extends StatelessWidget {
  const _VendorProductsView();

  Future<void> _openAdd(BuildContext context, VendorProductsState state) async {
    if (!state.canAddMore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AuthPrefs.isVendorBookingsMode
                ? 'الحد الأقصى 10 صور'
                : 'الحد الأقصى 10 منتجات',
          ),
        ),
      );
      return;
    }
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<VendorProductsBloc>(),
          child: const VendorAddProductScreen(),
        ),
      ),
    );
    if (created == true && context.mounted) {
      context.read<VendorProductsBloc>().add(const FetchVendorProductsEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhotoMode = AuthPrefs.isVendorBookingsMode;
    final addLabel = isPhotoMode
        ? 'إضافة صور للنشاط الخاص بك'
        : 'إضافة منتج';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isPhotoMode ? 'صور النشاط' : 'المنتجات',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          BlocBuilder<VendorProductsBloc, VendorProductsState>(
            builder: (context, state) {
              return IconButton(
                tooltip: 'إضافة صورة',
                onPressed: () => _openAdd(context, state),
                icon: const Icon(Icons.add_circle_outline),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: BlocBuilder<VendorProductsBloc, VendorProductsState>(
        builder: (context, state) {
          return Padding(
            // فوق شريط التنقل السفلي في RootShell
            padding: const EdgeInsets.only(bottom: 88),
            child: FloatingActionButton.extended(
              onPressed: () => _openAdd(context, state),
              backgroundColor: AuthTheme.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                addLabel,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
      body: BlocConsumer<VendorProductsBloc, VendorProductsState>(
        listener: (context, state) {
          if (state.message != null && state.message!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == VendorProductsStatus.loading ||
              state.status == VendorProductsStatus.initial) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context
                  .read<VendorProductsBloc>()
                  .add(const FetchVendorProductsEvent());
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: state.products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: AuthTheme.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          isPhotoMode
                              ? 'لا توجد صور — أضف صوراً لنشاطك'
                              : 'لا توجد منتجات — أضف أول منتج',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            color: AuthTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _openAdd(context, state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuthTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(
                            addLabel,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: state.products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = state.products[index];
                      final img = resolveStorageImageUrl(p.image);
                      final busy =
                          state.status == VendorProductsStatus.deleting;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AuthTheme.fieldBorder),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: img.isNotEmpty
                                  ? Image.network(
                                      img,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _ph(),
                                    )
                                  : _ph(),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontFamily: 'Cairo',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (!isPhotoMode)
                                    Text(
                                      '${p.price.toStringAsFixed(0)} ج.م',
                                      style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        color: AuthTheme.primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        BlocProvider.value(
                                                      value: context.read<
                                                          VendorProductsBloc>(),
                                                      child:
                                                          VendorAddProductScreen(
                                                        product: p,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 18),
                                        label: const Text(
                                          'تعديل',
                                          style: TextStyle(fontFamily: 'Cairo'),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: AuthTheme.primaryDark,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: busy
                                            ? null
                                            : () async {
                                                final ok =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: Text(
                                                      isPhotoMode
                                                          ? 'حذف الصورة'
                                                          : 'حذف المنتج',
                                                      style: const TextStyle(
                                                          fontFamily: 'Cairo'),
                                                    ),
                                                    content: Text(
                                                      'هل تريد حذف «${p.name}»؟',
                                                      style: const TextStyle(
                                                          fontFamily: 'Cairo'),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, false),
                                                        child: const Text(
                                                          'إلغاء',
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  'Cairo'),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                ctx, true),
                                                        child: const Text(
                                                          'حذف',
                                                          style: TextStyle(
                                                            fontFamily: 'Cairo',
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (ok == true &&
                                                    context.mounted) {
                                                  context
                                                      .read<
                                                          VendorProductsBloc>()
                                                      .add(
                                                        DeleteVendorProductEvent(
                                                            p.id),
                                                      );
                                                }
                                              },
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: Colors.red),
                                        label: const Text(
                                          'حذف',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            color: Colors.red,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  p.isActive ? 'متاح' : 'غير متاح',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: p.isActive
                                        ? const Color(0xFF0C9F6A)
                                        : Colors.red,
                                  ),
                                ),
                                Switch.adaptive(
                                  value: p.isActive,
                                  activeThumbColor: const Color(0xFF0C9F6A),
                                  onChanged: busy
                                      ? null
                                      : (_) => context
                                          .read<VendorProductsBloc>()
                                          .add(ToggleVendorProductEvent(p.id)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _ph() => Container(
        width: 64,
        height: 64,
        color: AuthTheme.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.image, color: AuthTheme.primary),
      );
}
