import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdModService {
  Future<InitializationStatus> initialization;

  AdModService(this.initialization);

  String? get bannerAdUnitId {
      if(Platform.isIOS) {
        return 'ca-app-pub-2220972025301917/8600858091';
      } else if (Platform.isAndroid) {
        return 'ca-app-pub-2220972025301917/4414185163';
      }
      return null;
  }

  String? get interstitialAdUnitId {
    if(Platform.isIOS) {
      return 'ca-app-pub-2220972025301917/6110410212';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-2220972025301917/6162381105';
    }
    return null;
  }

  String? get rewardAdUnitId {
    if(Platform.isIOS) {
      return 'ca-app-pub-2220972025301917/9581067159';
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-2220972025301917/8489161543';
    }
    return null;
  }

  final BannerAdListener bannerListener = BannerAdListener(
    onAdLoaded: (Ad ad) => debugPrint('Ad loaded'),
    onAdFailedToLoad: (Ad ad, LoadAdError error) {
      ad.dispose();
      debugPrint('Ad failed to load: $error');
    },
    onAdOpened: (Ad ad) => debugPrint('Ad opened'),
    onAdClosed: (Ad ad) => debugPrint('Ad closed'),
  );

}