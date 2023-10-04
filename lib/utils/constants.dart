import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const int kChainId = 80001;
const String kMnemonic =
    "viicous until tail chair involve evolve miracle scan table swarm swing toy";
bool isStringEmpty(String? str) {
  if (str == null || str.trim().isEmpty) {
    return true;
  }
  return false;
}

printLog(String msg) {
  print("###@@@###---> $msg");
}

Web3Client getEthClient(String apiUrl) {
  var httpClient = Client();
  return Web3Client(apiUrl, httpClient);
}
