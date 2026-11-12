import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:motorent/data/local/cache_helper.dart';
import 'package:motorent/features/driver_interface/domain/entities/driver_entities.dart';
import 'package:motorent/features/driver_interface/domain/repositories/driver_repository.dart';
import 'package:motorent/services/notification_store.dart';
import 'package:motorent/utils/notification_kind.dart';

part 'driver_home_event.dart';
part 'driver_home_state.dart';

class DriverHomeBloc extends Bloc<DriverHomeEvent, DriverHomeState> {
  final DriverRepository repository;
  Timer? _pollTimer;
  StreamSubscription<void>? _notificationSub;
  bool _loading = false;
  DateTime? _lastNotifRefresh;

  DriverHomeBloc({required this.repository})
      : super(
          DriverHomeState(
            isOnline: CacheHelper.getData(key: 'is_online') == 1 ||
                CacheHelper.getData(key: 'is_online') == true,
          ),
        ) {
    on<LoadDriverHomeEvent>(_onLoad);
    on<ToggleOnlineEvent>(_onToggle);
    on<MakeOfferEvent>(_onMakeOffer);
    on<DeclineTripEvent>(_onDeclineTrip);
    on<RefreshAvailableBidsEvent>(_onRefresh);
    _notificationSub =
        NotificationStore.instance.changes.listen((_) => _onInboxChanged());
  }

  static bool _isActiveTrip(DriverTrip trip) {
    final status = trip.status ?? '';
    return trip.showContact ||
        status == 'in_progress' ||
        status == 'driver_assigned' ||
        status == 'handed_to_driver' ||
        status == 'in_delivery';
  }

  static int _createdDesc(DriverTrip a, DriverTrip b) {
    final ac = a.createdAt ?? '';
    final bc = b.createdAt ?? '';
    if (ac.isEmpty && bc.isEmpty) return b.id.compareTo(a.id);
    return bc.compareTo(ac);
  }

  void _syncPoll() {
    _pollTimer?.cancel();
    if (!state.isOnline || isClosed) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (isClosed || !state.isOnline || _loading) return;
      add(const LoadDriverHomeEvent(silent: true));
    });
  }

  Future<void> _onInboxChanged() async {
    if (isClosed || !state.isOnline) return;
    final now = DateTime.now();
    if (_lastNotifRefresh != null &&
        now.difference(_lastNotifRefresh!) < const Duration(seconds: 3)) {
      return;
    }
    try {
      final items = await NotificationStore.instance.getAll();
      if (items.isEmpty) return;
      final latest = items.first;
      if (latest.isRead) return;
      final action = NotificationKind.normalize(latest.action);
      final isTripRelated = action == NotificationKind.newTrip ||
          action == NotificationKind.biddingTrip ||
          action == NotificationKind.offerAccepted ||
          action == NotificationKind.tripAccepted;
      if (!isTripRelated) return;
      _lastNotifRefresh = now;
      add(const LoadDriverHomeEvent(silent: true));
    } catch (_) {}
  }

  Future<void> _onLoad(
    LoadDriverHomeEvent event,
    Emitter<DriverHomeState> emit,
  ) async {
    if (_loading) return;
    _loading = true;
    if (!event.silent) {
      emit(state.copyWith(status: DriverHomeStatus.loading, clearMessage: true));
    }

    try {
      final myResult = await repository.fetchMyTrips();
      var active = <DriverTrip>[];
      String? myError;
      myResult.fold(
        (failure) => myError = failure.message,
        (trips) {
          active = trips.where(_isActiveTrip).toList()..sort(_createdDesc);
        },
      );

      var available = <DriverTrip>[];
      String? availableError;
      if (state.isOnline) {
        final availResult = await repository.fetchAvailableBids();
        availResult.fold(
          (failure) => availableError = failure.message,
          (trips) {
            available = List<DriverTrip>.from(trips)..sort(_createdDesc);
          },
        );
      }

      final hasActive = active.isNotEmpty;
      // طول ما في طلب شغال: منع تقديم عرض على أي طلب جديد
      if (hasActive) {
        available = available
            .map((t) => t.copyWith(canOffer: false))
            .toList(growable: false);
      }

      // الطلب/الإشعار الجديد أولاً في الصفحة، ثم الجاري
      final merged = <DriverTrip>[...available, ...active];

      if (merged.isEmpty && (myError != null || availableError != null)) {
        // أثناء التحديث الصامت: احتفظ بالقائمة الحالية لو فشل الشبكة مؤقتاً
        if (event.silent && state.status == DriverHomeStatus.loaded) {
          return;
        }
        emit(state.copyWith(
          status: DriverHomeStatus.failure,
          hasActiveTrip: false,
          trips: const [],
          message: availableError ?? myError,
        ));
        return;
      }

      emit(state.copyWith(
        status: DriverHomeStatus.loaded,
        hasActiveTrip: hasActive,
        trips: merged,
      ));
    } finally {
      _loading = false;
      _syncPoll();
    }
  }

  Future<void> _onRefresh(
    RefreshAvailableBidsEvent event,
    Emitter<DriverHomeState> emit,
  ) async {
    add(LoadDriverHomeEvent(silent: event.silent));
  }

  Future<void> _onToggle(
    ToggleOnlineEvent event,
    Emitter<DriverHomeState> emit,
  ) async {
    emit(state.copyWith(togglingOnline: true, clearMessage: true));
    final result = await repository.toggleOnline(event.online);
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          togglingOnline: false,
          message: failure.message,
          status: DriverHomeStatus.failure,
        ));
      },
      (online) async {
        emit(state.copyWith(
          isOnline: online,
          togglingOnline: false,
          message: online ? 'أنت متاح الآن' : 'تم إيقاف التوفر',
        ));
        _syncPoll();
        add(const LoadDriverHomeEvent());
      },
    );
  }

  Future<void> _onMakeOffer(
    MakeOfferEvent event,
    Emitter<DriverHomeState> emit,
  ) async {
    if (state.hasActiveTrip) {
      emit(state.copyWith(
        message: 'لديك طلب قيد التنفيذ. أنهِه أولاً قبل قبول طلب جديد.',
        status: DriverHomeStatus.failure,
      ));
      return;
    }
    emit(state.copyWith(submittingOffer: true, clearMessage: true));
    final result = await repository.makeOffer(
      tripId: event.tripId,
      type: event.type,
      amount: event.amount,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        submittingOffer: false,
        message: failure.message,
        status: DriverHomeStatus.failure,
      )),
      (started) {
        emit(state.copyWith(
          submittingOffer: false,
          message: started
              ? 'تم قبول سعر العميل وبدء الرحلة'
              : 'تم إرسال السعر الجديد — بانتظار قبول العميل',
          offerSuccess: true,
          tripStarted: started,
        ));
        add(const LoadDriverHomeEvent(silent: true));
      },
    );
  }

  Future<void> _onDeclineTrip(
    DeclineTripEvent event,
    Emitter<DriverHomeState> emit,
  ) async {
    emit(state.copyWith(submittingOffer: true, clearMessage: true));
    final result = await repository.declineTrip(
      tripId: event.tripId,
      type: event.type,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        submittingOffer: false,
        message: failure.message,
        status: DriverHomeStatus.failure,
      )),
      (_) {
        emit(state.copyWith(
          submittingOffer: false,
          message: 'تم رفض الطلب',
          trips: state.trips
              .where((t) => !(t.id == event.tripId && t.type == event.type))
              .toList(),
        ));
      },
    );
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _notificationSub?.cancel();
    return super.close();
  }
}
