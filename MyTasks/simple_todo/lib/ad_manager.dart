import 'dart:io';

class AdManager {
  static String get appId {
    if (Platform.isAndroid) {
      return "ca-app-pub-8796150055601896~1165102814";
    }

    return null;
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // return "ca-app-pub-8796150055601896/1820984023";
      return "ca-app-pub-3940256099942544/1033173712";
    }

    return null;
  }
}
