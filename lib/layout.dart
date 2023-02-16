import 'package:flutter/material.dart';

import 'const.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout(
      {super.key, required this.tablet, required this.mobile});
  final Widget Function(BuildContext context, BoxConstraints constraints)
      tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)
      mobile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      //if (constraints.maxWidth > breakpointMScale) {
      if (!context.isMobile()) {
        return tablet(context, constraints);
      } else {
        final m = mobile(context, constraints);
        if (constraints.maxWidth > breakpointM) {
          return Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              child: m,
            ),
          );
        } else {
          return m;
        }
      }
    });
  }
}

extension CheckMobile on BuildContext {
  bool isMobile() {
    return MediaQuery.of(this).size.width - 80 <= breakpointMScale;
  }
}
