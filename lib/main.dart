import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:decider/models/account_model.dart';
import 'package:decider/services/auth_service.dart';
import 'package:decider/services/firebase_service/firebase_options.dart';
import 'package:decider/views/home_views.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService().getOrCreateUser();
  runApp(MultiProvider(
    providers: [Provider.value(value: AuthService())],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Decider',
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('users').doc(context.read<AuthService>().currentUser?.uid).snapshots(),
        builder: (context, snapshot) {
            if(snapshot.hasData) {
              Account account = Account.fromSnapshot(snapshot.data, context.read<AuthService>().currentUser?.uid);
              return HomeViews(account: account);
            }
            return const CircularProgressIndicator();
        },

     ),
    );
  }
}
