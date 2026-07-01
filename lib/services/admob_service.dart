import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // test id
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // test id
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // test id
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // test id
    }
    return '';
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  bool get isBannerLoaded => _isBannerLoaded;
  BannerAd? get bannerAd => _bannerAd;

  Future<void> loadBanner(void Function() onLoaded) async {
    if (Platform.isWindows) return;
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    await _bannerAd!.load();
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerLoaded = false;
  }
}
