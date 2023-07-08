import 'package:airsonic/utils/sources/local.dart';
import 'package:flutter/material.dart';

class PageSetupLocalScan extends StatefulWidget {
  const PageSetupLocalScan({super.key});

  @override
  State<PageSetupLocalScan> createState() => _PageSetupLocalScanState();
}

class _PageSetupLocalScanState extends State<PageSetupLocalScan> {
  final c = medeia();

  @override
  void initState() {
    super.initState();

    c.a();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            ListenableBuilder(
              listenable: c,
              builder: (context, child) {
                return Text("${c.mediaCount}");
              },
            )
          ],
        ),
      ),
    );
  }
}
