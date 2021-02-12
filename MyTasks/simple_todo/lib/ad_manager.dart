import 'dart:io';

class AdManager {
  static String get appId {
    if (Platform.isAndroid) {
      return "ca-app-pub-8796150055601896~1165102814";
    } else if (Platform.isIOS) {
      return "ca-app-pub-8796150055601896~7468718911";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return "ca-app-pub-8796150055601896/1820984023";
    } else if (Platform.isIOS) {
      return "ca-app-pub-8796150055601896/6155637247";
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }
}
