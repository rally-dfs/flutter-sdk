import 'package:eth_sig_util/util/utils.dart';
import 'package:web3dart/web3dart.dart' as web3;

import '../../wallet.dart';
import '../../contracts/erc20.dart';
import '../../network_config/network_config.dart';
import '../utils.dart';

class Permit {
  String name;
  String version;
  int chainId;
  String verifyingContract;
  String owner;
  String spender;
  dynamic value;
  dynamic nonce;
  dynamic deadline;
  String salt;

  Permit({
    required this.name,
    required this.version,
    required this.chainId,
    required this.verifyingContract,
    required this.owner,
    required this.spender,
    required this.value,
    required this.nonce,
    required this.deadline,
    required this.salt,
  });
}

Map<String, dynamic> getTypedPermitTransaction(Permit permit) {
  final types = {
    'EIP712Domain': [
      {'name': 'name', 'type': 'string'},
      {'name': 'version', 'type': 'string'},
      {'name': 'chainId', 'type': 'uint256'},
      {'name': 'verifyingContract', 'type': 'address'},
    ],
    'Permit': [
      {'name': 'owner', 'type': 'address'},
      {'name': 'spender', 'type': 'address'},
      {'name': 'value', 'type': 'uint256'},
      {'name': 'nonce', 'type': 'uint256'},
      {'name': 'deadline', 'type': 'uint256'},
    ],
  };

  const primaryType = "Permit";

  final domain = {
    'name': permit.name,
    'version': permit.version,
    'chainId': permit.chainId,
    'verifyingContract': permit.verifyingContract,
  };

  if (permit.salt !=
          '0x0000000000000000000000000000000000000000000000000000000000000000' &&
      permit.salt.isNotEmpty) {
    domain['salt'] = permit.salt;
    types['EIP712Domain']!.add({'name': 'salt', 'type': 'bytes32'});
  }

  final message = {
    'owner': permit.owner,
    'spender': permit.spender,
    'value': permit.value.toString(),
    'nonce': permit.nonce.toString(),
    'deadline': permit.deadline.toInt(),
  };

  return {
    'types': types,
    'primaryType': primaryType,
    'domain': domain,
    'message': message,
  };
}

Future<Map<String, dynamic>> getPermitEIP712Signature(
    Wallet wallet,
    String contractName,
    String contractAddress,
    NetworkConfig config,
    int nonce,
    BigInt amount,
    BigInt deadline,
    String salt,
    {String? version}) async {
  // chainId to be used in EIP712
  final chainId = int.parse(config.gsn.chainId);

  // typed data for signing
  final eip712Data = getTypedPermitTransaction(
    Permit(
      name: contractName,
      version: version ?? '1',
      chainId: chainId,
      verifyingContract: contractAddress,
      owner: wallet.address.hex,
      spender: config.gsn.paymasterAddress,
      value: amount,
      nonce: nonce,
      deadline: deadline,
      salt: salt,
    ),
  );

  // signature for metatransaction
  final String signature = wallet.signTypedData(eip712Data);

  final cleanedSignature =
      signature.startsWith('0x') ? signature.substring(2) : signature;
  // get r,s,v from signature
  final signatureBytes = hexToBytes(cleanedSignature);

  Map<String, dynamic> rsv = {
    'r': signatureBytes.sublist(0, 32),
    's': signatureBytes.sublist(32, 64),
    'v': signatureBytes[64],
  };

  return rsv;
}

Future<GsnTransactionDetails> getPermitTx(
    Wallet wallet,
    web3.EthereumAddress destinationAddress,
    BigInt amount,
    NetworkConfig config,
    String contractAddress,
    web3.Web3Client provider,
    {String? eip712Salt,
    String? eip712Version}) async {
  final token = erc20(web3.EthereumAddress.fromHex(contractAddress));
  final noncesCallResult = await provider.call(
      contract: token,
      function: token.function("nonces"),
      params: [web3.EthereumAddress.fromHex(wallet.address.hex)]);

  final nameCall = await provider
      .call(contract: token, function: token.function('name'), params: []);
  final name = nameCall[0];
  final nonce = noncesCallResult[0];

  final deadline = await getPermitDeadline(provider);

  var salt = eip712Salt;
  if (eip712Salt == null) {
    salt = await fetchEip712SaltFromChain(provider, token);
  }

  final signature = await getPermitEIP712Signature(
    wallet,
    name,
    contractAddress,
    config,
    nonce.toInt(),
    amount,
    deadline,
    salt ?? '',
    version: eip712Version,
  );

  final r = signature['r'];
  final s = signature['s'];
  final v = signature['v'];

  final fromTx = token.function('transferFrom').encodeCall([
    web3.EthereumAddress.fromHex(wallet.address.hex),
    destinationAddress,
    amount,
  ]);

  final tx = web3.Transaction.callContract(
    contract: token,
    function: token.function('permit'),
    parameters: [
      web3.EthereumAddress.fromHex(wallet.address.hex),
      web3.EthereumAddress.fromHex(config.gsn.paymasterAddress),
      amount,
      deadline,
      BigInt.from(v),
      r,
      s,
    ],
  );

  final gas = await provider.estimateGas(
    to: token.address,
    data: tx.data,
    sender: wallet.address,
  );

  final paymasterData =
      '0x${token.address.hex.replaceFirst('0x', '')}${bytesToHex(fromTx)}';
  //following code is inspired from getFeeData method of
  //abstract-provider of ethers js library
  final info = await provider.getBlockInformation();

  final BigInt maxPriorityFeePerGas = BigInt.parse("1500000000");
  final maxFeePerGas =
      info.baseFeePerGas!.getInWei * BigInt.from(2) + (maxPriorityFeePerGas);

  final gsnTx = GsnTransactionDetails(
    from: wallet.address.hex,
    data: "0x${bytesToHex(tx.data!)}",
    value: "0",
    to: tx.to!.hex,
    gas: "0x${gas.toRadixString(16)}",
    maxFeePerGas: maxFeePerGas.toString(),
    maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
    paymasterData: paymasterData,
  );

  return gsnTx;
}

Future<String> fetchEip712SaltFromChain(
    web3.Web3Client provider, web3.DeployedContract token) async {
  try {
    final eip712DomainCallResult = await provider.call(
        contract: token, function: token.function('eip712Domain'), params: []);
    return "0x${bytesToHex(eip712DomainCallResult[5])}";
  } catch (e) {
    // ignore: avoid_print
    print(
        'Error fetching EIP712 salt, contract is likely missing eip712Domain function: $e');
    return '';
  }
}

// get timestamp that will always be included in the next 3 blocks
Future<BigInt> getPermitDeadline(web3.Web3Client provider) async {
  final block = await provider.getBlockInformation();
  return BigInt.from(
      block.timestamp.add(const Duration(seconds: 45)).millisecondsSinceEpoch);
}
