import 'package:airsonic/utils/const.dart';
import 'package:airsonic/utils/navigation.dart';
import 'package:airsonic/views/setup/source.dart';
import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Text(
              "Welcome To $appName",
              style: textTheme.headlineMedium,
            ),
            const Spacer(),
            FilledButton.icon(
                onPressed: () {
                  Navigator.of(context)
                      .push(createRoute(const PageSourceSelection()));
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text("Next")),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
