import 'package:flutter/material.dart';

class TRoute<T> extends PageRoute<T> with MaterialRouteTransitionMixin<T> {
  final WidgetBuilder builder;

  final String? title;

  /// Builds the primary contents of the route.
  @override
  final bool maintainState;

  @override
  final Duration transitionDuration = Duration.zero;

  @override
  final Duration reverseTransitionDuration = Duration.zero;

  TRoute({
    required this.builder,
    this.title,
    RouteSettings? settings,
    this.maintainState = true,
    bool fullscreenDialog = true,
  }) : super(settings: settings, fullscreenDialog: fullscreenDialog);

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';

  @override
  bool get barrierDismissible => true;

  @override
  bool get opaque => false;
}
