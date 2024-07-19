import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decider/models/account_model.dart';
import 'package:decider/models/question_model.dart';
import 'package:decider/services/ad_mod_service.dart';
import 'package:decider/services/auth_service.dart';
import 'package:decider/views/helpers/question_card.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class HistoryView extends StatefulWidget {
  final Account account;
  const HistoryView({super.key, required this.account});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<Object> _historyList = [];
  late NativeAd? _nativeAd;
  bool _nativeAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.account.adFree == false) {
      _nativeAd = NativeAd(
          adUnitId: context.read<AdModService>().nativeAdUnitId!,
          factoryId: 'listTile',
          listener: NativeAdListener(
            onAdLoaded: (Ad ad) {
              setState(() {
                _nativeAdLoaded = true;
              });
            },
            onAdFailedToLoad: (Ad ad, LoadAdError error) {
              ad.dispose();
            },
          ),
          request: const AdRequest())..load();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getUsersQuestionsList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Decisions'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if(_nativeAdLoaded && widget.account.adFree == false)
              Container(
                height: 50,
                alignment: Alignment.center,
                child: AdWidget(ad: _nativeAd!,),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _historyList.length,
                itemBuilder: (context, index) {
                  if (_historyList[index] is Question) {
                    return QuestionCard(question: _historyList[index] as Question);
                  } else if (_historyList[index] is BannerAd) {
                    return Container(
                      height: 60,
                      color: Colors.white,
                      child: AdWidget(
                        ad: _historyList[index] as BannerAd,
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> getUsersQuestionsList() async {
    var data = await FirebaseFirestore.instance
        .collection('users')
        .doc(context.read<AuthService>().currentUser?.uid)
        .collection('questions')
        .orderBy('created', descending: true)
        .get();

    setState(() {
      _historyList =
          List.from(data.docs.map((doc) => Question.fromSnapshot(doc)));

      // Add Banner ads
      final adModService = context.read<AdModService>();
      adModService.initialization.then((value) {
        for (int i = _historyList.length - 3; i >= 3; i -= 3) {
          _historyList.insert(
            i,
            BannerAd(
                size: AdSize.fullBanner,
                adUnitId: adModService.bannerAdUnitId!,
                listener: adModService.bannerListener,
                request: const AdRequest())
              ..load(),
          );
        }
      });
    });
  }
}
