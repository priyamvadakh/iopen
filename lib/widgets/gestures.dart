import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

typedef PinchUpdate = void Function(
  double scale,
  Offset focalDelta,
  Offset focal,
);

/// Claims a gesture only once two fingers are down, like a maps app.
/// A single finger is left for the page (scrolling) or a drag recognizer.
class PinchGestureRecognizer extends OneSequenceGestureRecognizer {
  PinchGestureRecognizer({super.debugOwner});

  VoidCallback? onStart;
  PinchUpdate? onUpdate;
  VoidCallback? onEnd;

  final _points = <int, Offset>{};
  double _initialSpan = 1;
  Offset _lastFocal = Offset.zero;
  bool _active = false;

  Offset get _focal {
    var sum = Offset.zero;
    for (final p in _points.values) {
      sum += p;
    }
    return sum / _points.length.toDouble();
  }

  double get _span {
    final f = _focal;
    var total = 0.0;
    for (final p in _points.values) {
      total += (p - f).distance;
    }
    return total / _points.length;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    _points[event.pointer] = event.localPosition;
    if (_points.length >= 2 && !_active) {
      _active = true;
      resolve(GestureDisposition.accepted);
      _initialSpan = _span <= 0 ? 1 : _span;
      _lastFocal = _focal;
      onStart?.call();
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      _points[event.pointer] = event.localPosition;
      if (_active && _points.length >= 2) {
        final focal = _focal;
        onUpdate?.call(_span / _initialSpan, focal - _lastFocal, focal);
        _lastFocal = focal;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _points.remove(event.pointer);
      stopTrackingPointer(event.pointer);
      if (_active && _points.length < 2) {
        _active = false;
        onEnd?.call();
      }
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _points.clear();
    if (!_active) resolve(GestureDisposition.rejected);
  }

  @override
  String get debugDescription => 'pinch';
}
