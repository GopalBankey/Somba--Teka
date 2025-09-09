import 'dart:async';
import 'package:SombaTeka/utils/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// EVENTS
abstract class KelpayPaymentEvent {}

class StartKelpayPayment extends KelpayPaymentEvent {
  final String txId;
  StartKelpayPayment(this.txId);
}

class _CheckStatus extends KelpayPaymentEvent {}

class _Tick extends KelpayPaymentEvent {}

/// STATE
class KelpayPaymentState {
  final String status; // pending, succeed, failed, timeout
  final Duration elapsed; // total time elapsed
  final Duration remaining; // countdown timer

  KelpayPaymentState({
    required this.status,
    required this.elapsed,
    required this.remaining,
  });

  KelpayPaymentState copyWith({
    String? status,
    Duration? elapsed,
    Duration? remaining,
  }) {
    return KelpayPaymentState(
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      remaining: remaining ?? this.remaining,
    );
  }
}

/// BLOC
class KelpayPaymentBloc extends Bloc<KelpayPaymentEvent, KelpayPaymentState> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  //  checkpoints: 35s, 2:05, 5:05
  final List<int> _checkPoints = [35, 125, 305];
  int _currentCheckIndex = 0;
  late String _txId;

  static const int _timeoutSeconds = 305; // total time before timeout

  KelpayPaymentBloc()
      : super(KelpayPaymentState(
    status: "pending",
    elapsed: Duration.zero,
    remaining: Duration(seconds: _timeoutSeconds),
  )) {
    on<StartKelpayPayment>(_onStart);
    on<_Tick>(_onTick);
    on<_CheckStatus>(_onCheckStatus);
  }

  void _onStart(StartKelpayPayment event, Emitter<KelpayPaymentState> emit) {
    _txId = event.txId;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(_Tick());
    });
  }

  void _onTick(_Tick event, Emitter<KelpayPaymentState> emit) {
    _elapsed = _elapsed + const Duration(seconds: 1);

    // calculate remaining time
    final remaining = Duration(seconds: _timeoutSeconds - _elapsed.inSeconds);

    // trigger API check at defined checkpoints
    if (_currentCheckIndex < _checkPoints.length &&
        _elapsed.inSeconds == _checkPoints[_currentCheckIndex]) {
      add(_CheckStatus());
      _currentCheckIndex++;
    }

    emit(state.copyWith(elapsed: _elapsed, remaining: remaining));
  }

  Future<void> _onCheckStatus(
      _CheckStatus event, Emitter<KelpayPaymentState> emit) async {
    try {
      final response = await Api.get(url: "payment-status/$_txId");


      if (response["error"] == false && response["data"] is String) {
        final paymentStatus = (response["data"] as String).toLowerCase();

        if (paymentStatus == "succeed" || paymentStatus == "failed") {
          _timer?.cancel();
          emit(state.copyWith(status: paymentStatus));
          return;
        }
      }

      // If timeout reached
      if (_elapsed.inSeconds >= _timeoutSeconds) {
        _timer?.cancel();
        emit(state.copyWith(status: "timeout"));
      } else {
        emit(state.copyWith(status: "pending"));
      }
    } catch (e) {
      // On error, also timeout after last checkpoint
      if (_elapsed.inSeconds >= _timeoutSeconds) {
        _timer?.cancel();
        emit(state.copyWith(status: "timeout"));
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
