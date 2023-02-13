import 'dart:io';

import 'package:flutter/foundation.dart';

var desktop = !kIsWeb && !Platform.isAndroid && !Platform.isIOS;

const breakpointM = 600.0;
const breakpointMScale = 905;
const breakpointL = 1440.0;
