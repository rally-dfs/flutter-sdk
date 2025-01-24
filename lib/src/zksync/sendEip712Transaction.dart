

import './eip712Transaction.dart'; 
import '../wallet.dart' as rlyWallet;
import '../gsn/utils.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;


import 'package:eth_sig_util/eth_sig_util.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/src/utils/rlp.dart' as rlp;
import 'package:convert/convert.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:rly_network_flutter_sdk/src/gsn/utils.dart';
import 'package:rlp/rlp.dart';
import 'package:pointycastle/digests/keccak.dart';

 
 Future<String> sendEip712Transaction(Eip712Transaction transaction,  rlyWallet.Wallet wallet, ClientConfig clientConfig) async {  

    final eip712Data = {
      'domain': clientConfig.domainSeperator.toMap(),
      'types': Eip712Transaction.types,
      'primaryType': Eip712Transaction.primaryType,
      'message': transaction.toMap(),
    };

    final String customSignature = wallet.signTypedData(eip712Data);
    final serializedTx = transaction.toList(customSignature);
    final rawTx =  hexToBytes(concatHex(["0x71", bytesToHex(rlp.encode(serializedTx))]));
    Web3Client client = getEthClient(clientConfig.rpcUrl);

    final String hash = await client.sendRawTransaction(rawTx);

    return hash;

 }