import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/services/core/utils/location_util.dart';
import 'package:motorent/features/services/data/datasources/service_remote_data_source.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/service_bloc.dart';
import 'package:motorent/features/services/presentation/pages/store_details_screen.dart';
import 'package:motorent/features/services/services_injection.dart';
import 'package:motorent/services/place_booking_service.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';
import 'package:motorent/widgets/services/nearby_store_card.dart';

enum StoreListOpenMode { order, booking, profession }

class StoresListScreen extends StatelessWidget {
  final ServiceCategory category;
  final String? listingKind;
  final StoreListOpenMode openMode;

  const StoresListScreen({
    super.key,
    required this.category,
    this.listingKind,
    this.openMode = StoreListOpenMode.order,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ServicesInjection.createBloc(),
      child: _StoresListView(
        category: category,
        listingKind: listingKind,
        openMode: openMode,
      ),
    );
  }
}

class _StoresListView extends StatefulWidget {
  final ServiceCategory category;
  final String? listingKind;
  final StoreListOpenMode openMode;

  const _StoresListView({
    required this.category,
    this.listingKind,
    required this.openMode,
  });

  @override
  State<_StoresListView> createState() => _StoresListViewState();
}

class _StoresListViewState extends State<_StoresListView> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final location = await getUserLatLng();

    if (!mounted) return;
    context.read<ServiceBloc>().add(
          FetchStoresEvent(
            widget.category.slug,
            lat: location?.lat,
            lng: location?.lng,
            listingKind: widget.listingKind,
          ),
        );
  }

  /// الأقرب أولاً (السيرفر يرتّب لو وصله lat/lng — وهنا نضمن الترتيب عند العميل).
  List<Store> _sortedNearestFirst(List<Store> stores) {
    final sorted = List<Store>.of(stores);
    sorted.sort((a, b) {
      final da = a.distanceM;
      final db = b.distanceM;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return sorted;
  }

  /// خدمات الصنايعيه والحرفيين: الضغط على الصنايعي يتصل به مباشرة.
  Future<void> _callCraftsman(Store store) async {
    var phone = store.phone;
    if (PlaceBookingService.normalizePhone(phone) == null) {
      // قائمة الصنايعية قد لا تحتوي الهاتف — نجلبه من تفاصيل الصنايعي.
      try {
        final full = await ServiceRemoteDataSourceImpl().fetchStoreDetails(
          store.id,
        );
        phone = full.phone;
      } catch (_) {}
    }

    final ok = await PlaceBookingService.callAndBook(
      phone: phone,
      storeId: store.id,
      kind: 'profession',
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('لا يوجد رقم اتصال لهذا الصنايعي')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AuthTheme.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.category.nearbyTitle,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AuthTheme.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ServiceBloc, ServiceState>(
          listener: (context, state) {
            if (state is ServiceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is ServiceLoading || state is ServiceInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final stores = state is StoresLoaded
                ? _sortedNearestFirst(state.stores)
                : const <Store>[];

            return RefreshIndicator(
              onRefresh: _load,
              child: stores.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 140),
                        Center(
                          child: Text(
                            widget.openMode == StoreListOpenMode.profession
                                ? 'لا توجد مهن متاحة حالياً'
                                : widget.openMode == StoreListOpenMode.booking
                                    ? 'لا توجد أماكن متاحة حالياً'
                                    : 'لا توجد متاجر متاحة حالياً',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AuthTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: stores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final store = stores[index];
                        return NearbyStoreCard(
                          store: store,
                          onTap: () {
                            if (widget.openMode ==
                                StoreListOpenMode.profession) {
                              _callCraftsman(store);
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreDetailsScreen(
                                  storeId: store.id,
                                  openMode: widget.openMode,
                                  categoryId: widget.category.id,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            );
          },
        ),
    );
  }
}
