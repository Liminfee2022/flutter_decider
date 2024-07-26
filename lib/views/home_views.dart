import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decider/extensions/string_extensions.dart';
import 'package:decider/models/account_model.dart';
import 'package:decider/models/question_model.dart';
import 'package:decider/services/ad_mod_service.dart';
import 'package:decider/services/auth_service.dart';
import 'package:decider/views/history_view.dart';
import 'package:decider/views/store_view.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timer_count_down/timer_controller.dart';
import 'package:timer_count_down/timer_count_down.dart';

enum AppStatus { ready, waiting }

class HomeViews extends StatefulWidget {
  const HomeViews({super.key, required this.account});
  final Account account;

  @override
  State<HomeViews> createState() => _HomeViewsState();
}

class _HomeViewsState extends State<HomeViews> {
  String _answer = '';
  bool _askBtnActive = false;
  final TextEditingController _questionController = TextEditingController();
  final Question _question = Question();
  AppStatus? _appStatus;
  int _timeTillNextFree = 0;
  final CountdownController _countDownController = CountdownController();

  //Ad Related
  late AdModService _adModService;
  BannerAd? _banner;
  InterstitialAd? _interstitial;
  RewardedAd? _reward;
  bool _showReward = false;

  @override
  void initState() {
    super.initState();
    _timeTillNextFree = widget.account.nextFreeQuestion
            ?.difference((DateTime.now()))
            .inSeconds ??
        0;
    _giveFreeDecision(widget.account.bank, _timeTillNextFree);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if(widget.account.adFree == false) {
      _adModService = context.read<AdModService>();
      _adModService.initialization.then((value) {
        setState(() {
          _banner = BannerAd(
              size: AdSize.fullBanner,
              adUnitId: _adModService.bannerAdUnitId!,
              listener: _adModService.bannerListener,
              request: const AdRequest())
            ..load();
          _createInterstitialAd();
          _createRewardAd();
        });
      });
    } else {
      setState(() {
        _banner = null;
        _interstitial = null;
        _reward = null;
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setAppStatus();
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            'Decider',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const StoreView()),
                  );
                },
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => HistoryView(
                        account: widget.account,
                      ),
                    ),
                  );
                },
                child: const Icon(
                  Icons.history,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Decision Left: ${widget.account.bank}'),
                ),
                _nextFreeCountdown(context),
                const Spacer(),
                if(widget.account.adFree == false) _buildRewardPrompt(),
                const Spacer(),
                _buildQuestionForm(context),
                const Spacer(
                  flex: 3,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _showPlan(),
                ),
                Text('${context.read<AuthService>().currentUser?.uid}'),
                if (_banner == null)
                  const SizedBox(
                    height: 10,
                  )
                else
                  SizedBox(
                    height: 60,
                    child: AdWidget(
                      ad: _banner!,
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionForm(BuildContext context) {
    if (_appStatus == AppStatus.ready) {
      return Column(
        children: [
          Text(
            'Should I',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 10.0,
              left: 30.0,
              right: 30.0,
            ),
            child: TextField(
              decoration: const InputDecoration(helperText: 'Enter A Question'),
              keyboardType: TextInputType.multiline,
              controller: _questionController,
              textInputAction: TextInputAction.done,
              onChanged: (value) {
                setState(() {
                  _askBtnActive = value.isNotEmpty;
                });
              },
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            onPressed: _askBtnActive == true ? _answerQuestion : null,
            child: const Text(
              'Ask',
              style: TextStyle(color: Colors.white),
            ),
          ),
          _questionAndAnswer(context),
        ],
      );
    } else {
      return _questionAndAnswer(context);
    }
  }

  Widget _questionAndAnswer(BuildContext context) {
    if (_answer.isEmpty) return Container();

    return Column(
      children: [
        Text('Should I ${_question.query} ?'),
        Text(
          'Answer: ${_answer.capitalize()}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _nextFreeCountdown(context) {
    if (_appStatus == AppStatus.waiting) {
      _countDownController.start();
      var f = NumberFormat('00', 'en_US');
      return Column(
        children: [
          const Text('You wil get one free decision in'),
          Countdown(
            controller: _countDownController,
            seconds: 0 - _timeTillNextFree,
            build: (BuildContext context, double time) => Text(
                "${f.format(time ~/ 3600)}:${f.format((time % 3600) ~/ 60)}:${f.format(time.toInt() % 60)}"),
            interval: const Duration(seconds: 1),
            onFinished: () {
              _giveFreeDecision(widget.account.bank, 0);
              setState(() {
                _timeTillNextFree = 0;
                _appStatus = AppStatus.ready;
              });
            },
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  Widget _buildRewardPrompt() {
    if (_reward == null && _showReward == true) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.exposure_plus_2,
              size: 50.0,
              color: Colors.orange,
            ),
          ),
          Text(
            'You Receive 2 new decision',
            style: Theme.of(context).textTheme.headlineMedium,
          )
        ],
      );
    } else if (_reward != null) {
      return ElevatedButton(
          onPressed: _showRewardAd, child: const Text('Get 2 Free Decision'));
    } else {
      return Container();
    }
  }

  Widget _showPlan() {
    if (widget.account.unlimited == true) {
      return const Text('Account Type: Unlimited');
    } else if (widget.account.premium == true) {
      return const Text('Account Type: Premium');
    }
    return const Text('Account Type: Free');
  }

  void _answerQuestion() async {
    _showInterstitialAd();
    setState(() {
      _answer = _getAnswer();
    });
    _question.query = _questionController.text;
    _question.answer = _answer;
    _question.created = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.account.uid)
        .collection('questions')
        .add(_question.toJson());

    //Update the document
    widget.account.bank -= 1;
    widget.account.nextFreeQuestion =
        DateTime.now().add(const Duration(seconds: 5));
    setState(() {
      _timeTillNextFree = widget.account.nextFreeQuestion
              ?.difference(DateTime.now())
              .inSeconds ??
          0;
      if (widget.account.bank == 0) {
        _appStatus = AppStatus.waiting;
      }
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.account.uid)
        .update(widget.account.toJson());

    _questionController.text = '';
  }

  void _setAppStatus() {
    if (widget.account.bank > 0) {
      setState(() {
        _appStatus = AppStatus.ready;
      });
    } else {
      setState(() {
        _appStatus = AppStatus.waiting;
      });
    }
  }

  void _giveFreeDecision(currentBank, timeTillNextFree) {
    if (currentBank <= 0 && timeTillNextFree <= 0) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.account.uid)
          .update({'bank': 1});
    }
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: _adModService.interstitialAdUnitId!,
        request: const AdRequest(),
        adLoadCallback:
            InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          _interstitial = ad;
        }, onAdFailedToLoad: (LoadAdError error) {
          _interstitial = null;
        }));
  }

  void _showInterstitialAd() {
    if (_interstitial != null) {
      _interstitial!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _createInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _createInterstitialAd();
        },
      );
      _interstitial!.show();
      _interstitial = null;
    }
  }

  void _increaseDecision(int quantity) {
    final newBankValue = widget.account.bank + quantity;
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.account.uid)
        .update({'bank': newBankValue});
  }

  void _createRewardAd() {
    RewardedAd.load(
        adUnitId: _adModService.rewardAdUnitId!,
        request: const AdRequest(),
        rewardedAdLoadCallback:
            RewardedAdLoadCallback(onAdLoaded: (RewardedAd ad) {
          setState(() {
            _reward = ad;
          });
        }, onAdFailedToLoad: (LoadAdError error) {
          setState(() {
            _reward = null;
          });
        }));
  }

  void _showRewardAd() {
    if (_reward != null) {
      _reward!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          _createRewardAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          _createRewardAd();
        },
      );
      _reward!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        _increaseDecision(2);
        setState(() {
          _reward = null;
          _showReward = true;
        });
      });
    }
  }
}

String _getAnswer() {
  var answerOptions = ['yes', 'no', 'definitely', 'not right now'];
  return answerOptions[Random().nextInt(answerOptions.length)];
}
