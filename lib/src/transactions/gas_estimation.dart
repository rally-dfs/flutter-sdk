import 'package:web3dart/web3dart.dart' as web3;

class FeeData {
  final BigInt? maxFeePerGas;
  final BigInt? maxPriorityFeePerGas;

  FeeData({this.maxFeePerGas, this.maxPriorityFeePerGas});

  static Future<FeeData> getFeeData(web3.Web3Client client) async {
    web3.BlockInformation blockInformation = await client.getBlockInformation();

    final BigInt maxPriorityFeePerGas =
        await computeMaxPriorityFeePerGas(blockInformation, client);

    BigInt? maxFeePerGas;

    if (blockInformation.baseFeePerGas != null) {
      maxFeePerGas =
          (blockInformation.baseFeePerGas!.getInWei * BigInt.from(2)) +
              maxPriorityFeePerGas;
    }

    return FeeData(
      maxFeePerGas: maxFeePerGas,
      maxPriorityFeePerGas: maxPriorityFeePerGas,
    );
  }

  static Future<BigInt> computeMaxPriorityFeePerGas(
      web3.BlockInformation blockInformation, web3.Web3Client client) async {
    if (blockInformation.baseFeePerGas == null) {
      return BigInt.parse("1500000000");
    }

    final gasPrice = await client.getGasPrice();
    return gasPrice.getInWei - blockInformation.baseFeePerGas!.getInWei;
  }
}
