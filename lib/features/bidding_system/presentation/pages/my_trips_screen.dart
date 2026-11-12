import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/features/bidding_system/bidding_injection.dart';
import 'package:motorent/features/bidding_system/presentation/bloc/trip_tracking_bloc.dart';
import 'package:motorent/features/bidding_system/presentation/pages/trip_details_screen.dart';
import 'package:motorent/features/bidding_system/presentation/widgets/trip_tracking_card.dart';
import 'package:motorent/widgets/auth/auth_theme.dart';

class MyTripsScreen extends StatelessWidget {
  final bool showAppBar;

  const MyTripsScreen({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BiddingInjection.createTrackingBloc()..add(const FetchMyTripsEvent()),
      child: _MyTripsView(showAppBar: showAppBar),
    );
  }
}

class _MyTripsView extends StatelessWidget {
  final bool showAppBar;

  const _MyTripsView({required this.showAppBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'متابعة الطلبات',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: Container(
        decoration: AuthTheme.screenBackground(),
        child: BlocConsumer<TripTrackingBloc, TripTrackingState>(
          listener: (context, state) {
            if (state is TrackingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is TrackingLoading || state is TrackingInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            final trips = state is TripsLoadedSuccess ? state.trips : const [];

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<TripTrackingBloc>()
                    .add(const FetchMyTripsEvent());
              },
              child: trips.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Center(
                          child: Text(
                            'لا توجد طلبات حالياً',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              color: AuthTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: trips.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final trip = trips[index];
                        return TripTrackingCard(
                          trip: trip,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TripDetailsScreen(tripId: trip.id),
                              ),
                            );
                            if (context.mounted) {
                              context
                                  .read<TripTrackingBloc>()
                                  .add(const FetchMyTripsEvent());
                            }
                          },
                        );
                      },
                    ),
            );
          },
        ),
      ),
    );
  }
}
