import './eip712Transaction.dart';
import '../wallet.dart' as rly_wallet;
import '../gsn/utils.dart';
import 'package:rlp/rlp.dart';

import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

Future<String> sendEip712Transaction(Eip712Transaction transaction,
    rly_wallet.Wallet wallet, ClientConfig clientConfig) async {
  final eip712Data = {
    'domain': clientConfig.domainSeperator.toMap(),
    'types': Eip712Transaction.types,
    'primaryType': Eip712Transaction.primaryType,
    'message': transaction.toMap(),
  };

  final String customSignature = wallet.signTypedData(eip712Data);
  final serializedTx = transaction.toList(customSignature);
  final rawTx =
      hexToUint8List(concatHex(["0x71", bytesToHex(Rlp.encode(serializedTx))]));
  Web3Client client = getEthClient(clientConfig.rpcUrl);

  final String hash = await client.sendRawTransaction(rawTx);

  return hash;
}
