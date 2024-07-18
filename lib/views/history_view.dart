import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decider/models/question_model.dart';
import 'package:decider/services/ad_mod_service.dart';
import 'package:decider/services/auth_service.dart';
import 'package:decider/views/helpers/question_card.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  List<Object> _historyList = [];

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
        child: ListView.builder(
          itemCount: _historyList.length,
          itemBuilder: (context, index) {
            if(_historyList[index] is Question) {
              return QuestionCard(question: _historyList[index] as Question);
            } else if(_historyList[index] is BannerAd) {
              return Container(
                height: 60,
                color: Colors.white,
                child: AdWidget(ad: _historyList[index] as BannerAd,),
              );
            } else {
              return Container();
            }
          },
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
                  request: AdRequest())..load(),
          );
        }
      });
    });
  }
}
