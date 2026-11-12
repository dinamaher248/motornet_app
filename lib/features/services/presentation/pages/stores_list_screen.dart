import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:motorent/features/services/domain/entities/service_entities.dart';
import 'package:motorent/features/services/presentation/bloc/service_bloc.dart';
import 'package:motorent/features/services/presentation/pages/store_details_screen.dart';
import 'package:motorent/features/services/services_injection.dart';
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
    double? lat;
    double? lng;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }
    } catch (_) {}

    if (!mounted) return;
    context.read<ServiceBloc>().add(
          FetchStoresEvent(
            widget.category.slug,
            lat: lat,
            lng: lng,
            listingKind: widget.listingKind,
          ),
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

            final stores = state is StoresLoaded ? state.stores : const <Store>[];

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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StoreDetailsScreen(
                                  storeId: store.id,
                                  openMode: widget.openMode,
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
