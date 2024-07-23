import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  increaseDecision({uid, quantity}) {
    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'bank': FieldValue.increment(quantity),
      'nextFreeQuestion': DateTime.now(),
    });
  }
}