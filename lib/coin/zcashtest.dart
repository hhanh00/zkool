import 'package:flutter/material.dart';

import 'coin.dart';

class ZcashTestCoin extends CoinBase {
  int coin = 0;
  String name = "Zcash";
  String app = "ZKool";
  String symbol = "\u24E9";
  String currency = "zcash";
  int coinIndex = 133;
  String ticker = "ZEC";
  String dbRoot = "zec";
  String? marketTicker = "ZECUSDT";
  AssetImage image = AssetImage('assets/zcash.png');
  List<LWInstance> lwd = [
    LWInstance("Zec Regtest)", "http://172.16.11.208:9168"),
    LWInstance("Zec Regtest)", "http://103.100.225.102:10003"),
  ];
  String? warpUrl = "http://zebra2.zcash-infra.com:8000";
  int warpHeight = 0;
  int defaultAddrMode = 0;
  int defaultUAType = 7; // TSO
  bool supportsUA = true;
  bool supportsMultisig = false;
  bool supportsLedger = true;
  List<double> weights = [0.05, 0.25, 2.50];
  List<String> blockExplorers = [
    "https://blockchair.com/zcash/transaction",
    "https://zecblockexplorer.com/tx"
  ];
}
