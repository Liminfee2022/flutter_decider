import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IAPService {
  void listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if(purchaseDetails.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchaseDetails);
        debugPrint('Purchase marked complete');
      }
    });
  }
}