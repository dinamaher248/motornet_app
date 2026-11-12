import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/remote/url_api.dart';
import 'package:motorent/features/admin_dashboard/admin_dashboard_injection.dart';
import 'package:motorent/features/admin_dashboard/presentation/bloc/admin_products_bloc.dart';
import 'package:motorent/features/admin_dashboard/presentation/widgets/admin_widgets.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class AdminProductsScreen extends StatelessWidget {
  final int vendorId;
  final String vendorName;

  const AdminProductsScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminDashboardInjection.createProductsBloc()
        ..add(FetchAdminProductsEvent(vendorId: vendorId)),
      child: _View(vendorName: vendorName),
    );
  }
}

class _View extends StatelessWidget {
  final String vendorName;

  const _View({required this.vendorName});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminProductsBloc, AdminProductsState>(
      listener: (context, state) {
        if (state.message != null && state.message!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.message!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AdminColors.contentBg,
          appBar: AppBar(
            title: Text(
              'منتجات $vendorName',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: state.status == AdminProductsStatus.loading
              ? const AdminTableLoader()
              : state.products.isEmpty
                  ? Center(
                      child: Text(
                        'لم ينشر $vendorName أي منتجات بعد.',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: AuthTheme.textMuted,
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        context.read<AdminProductsBloc>().add(
                              FetchAdminProductsEvent(
                                vendorId: state.vendorId,
                              ),
                            );
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 280,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: state.products.length,
                        itemBuilder: (context, i) {
                          final p = state.products[i];
                          final busy = state.actingId == p.id;
                          final img = resolveStorageImageUrl(p.image);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: AuthTheme.fieldBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                    child: img.isNotEmpty
                                        ? Image.network(img, fit: BoxFit.cover)
                                        : Container(
                                            color: AuthTheme.primary
                                                .withValues(alpha: 0.08),
                                            child: const Icon(
                                              Icons.image_outlined,
                                              size: 40,
                                            ),
                                          ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${p.price.toStringAsFixed(0)} ج.م',
                                        style: const TextStyle(
                                          fontFamily: 'Cairo',
                                          fontWeight: FontWeight.w700,
                                          color: AuthTheme.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: busy
                                                  ? null
                                                  : () => context
                                                      .read<
                                                          AdminProductsBloc>()
                                                      .add(
                                                        ToggleAdminProductEvent(
                                                          p.id,
                                                        ),
                                                      ),
                                              child: Text(
                                                p.isVisible ? 'تعطيل' : 'تفعيل',
                                                style: const TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: busy
                                                ? null
                                                : () async {
                                                    final ok =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                          'حذف المنتج؟',
                                                        ),
                                                        content: const Text(
                                                          'سيتم حذف المنتج لمخالفة الشروط.',
                                                          style: TextStyle(
                                                            fontFamily: 'Cairo',
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                            child: const Text(
                                                              'إلغاء',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                            child: const Text(
                                                              'حذف',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
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
                                                              AdminProductsBloc>()
                                                          .add(
                                                            DeleteAdminProductEvent(
                                                              p.id,
                                                            ),
                                                          );
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: AdminColors.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
