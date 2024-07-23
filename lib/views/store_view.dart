import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

// const List<String> _productIds = <String>[
//   'decider_lmp_5',
//   'premium_lmp1',
//   'unlimited_monthly',
//   'umlimited_yearly',
// ];

const Set<String> _kIds = <String>{
  'decider_lmp_5',
  'premium_lmp1',
  'unlimited_monthly',
  'umlimited_yearly',
};

class StoreView extends StatefulWidget {
  const StoreView({super.key});

  @override
  State<StoreView> createState() => _StoreViewState();
}

class _StoreViewState extends State<StoreView> {
  bool _isAvailable = false;
  String? _notice;
  List<ProductDetails> _products = [];

  @override
  void initState() {
    super.initState();
    initStoreInfo();
  }

  Future<void> initStoreInfo() async {
    final isAvailable = await InAppPurchase.instance.isAvailable();
    setState(() {
      _isAvailable = isAvailable;
    });

    if (!_isAvailable) {
      setState(() {
        _notice = 'There are no upgrades at this time';
      });
      return;
    }
    setState(() {
      _notice = 'There is a connection to the store';
    });

    //get IAP
    final ProductDetailsResponse productDetailsResponse =
        await InAppPurchase.instance.queryProductDetails(_kIds);
    setState(() {
      _products = productDetailsResponse.productDetails;
    });

    if (productDetailsResponse.error != null) {
      setState(() {
        _notice = 'There was a problem connecting to the store';
      });
    } else if (productDetailsResponse.productDetails.isEmpty) {
      setState(() {
        _notice = 'There are no upgrades at this time';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_notice!),
                ),
              Expanded(
                child: ListView.separated(
                  itemCount: _products.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(
                      height: 6.0,
                    );
                  },
                  itemBuilder: (context, index) {
                    final ProductDetails productDetails = _products[index];
                    final PurchaseParam purchaseParam =
                        PurchaseParam(productDetails: productDetails);

                    return Card(
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _getIAPIcon(productDetails.id),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productDetails.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  productDetails.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                if (productDetails.id == 'premium_lmp1') {
                                  InAppPurchase.instance.buyNonConsumable(
                                      purchaseParam: purchaseParam);
                                } else {
                                  InAppPurchase.instance.buyConsumable(
                                      purchaseParam: purchaseParam);
                                }
                              },
                              child: _buyText(productDetails),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIAPIcon(productId) {
    switch (productId) {
      case 'premium_lmp1':
        return const Icon(Icons.brightness_7_outlined, size: 50);
      case 'unlimited_monthly':
        return const Icon(Icons.brightness_5, size: 50);
      case 'umlimited_yearly':
        return const Icon(Icons.brightness_7, size: 50);
      default:
        return const Icon(Icons.post_add_outlined, size: 50);
    }
  }

  Widget _buyText(productDetails) {
    switch (productDetails.id) {
      case 'unlimited_monthly':
        return Text('${productDetails.price} / month');
      case 'umlimited_yearly':
        return Text('${productDetails.price} / year');
      default:
        return Text('Buy for ${productDetails.price}');
    }
  }
}
