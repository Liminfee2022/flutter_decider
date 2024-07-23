import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decider/models/account_model.dart';
import 'package:decider/services/ad_mod_service.dart';
import 'package:decider/services/auth_service.dart';
import 'package:decider/services/firebase_service/firebase_options.dart';
import 'package:decider/services/iap_service.dart';
import 'package:decider/views/home_views.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService().getOrCreateUser();
  final initAdFuture = MobileAds.instance.initialize();
  final adMobService = AdModService(initAdFuture);

  runApp(MultiProvider(
    providers: [
      Provider.value(value: AuthService()),
      Provider.value(value: adMobService),
    ],
    child: const DeciderApp(),
  ));
}

class DeciderApp extends StatefulWidget {
  const DeciderApp({super.key});

  @override
  State<DeciderApp> createState() => _DeciderAppState();
}

class _DeciderAppState extends State<DeciderApp> {
  late StreamSubscription<List<PurchaseDetails>> _iapSubscription;

  @override
  void initState() {
    super.initState();
    final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;

    _iapSubscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        debugPrint('Purchase stream started');
        IAPService().listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _iapSubscription.cancel();
      },
      onError: (error) {
        _iapSubscription.cancel();
      },
    ) as StreamSubscription<List<PurchaseDetails>>;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Decider',
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(context.read<AuthService>().currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Account account = Account.fromSnapshot(
                snapshot.data, context.read<AuthService>().currentUser?.uid);
            return HomeViews(account: account);
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
