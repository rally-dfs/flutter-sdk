import 'package:eth_sig_util/model/typed_data.dart';

import '../utils.dart';

class TypedGsnRequestData {
  late GsnPrimaryType types;
  late EIP712Domain? domain;
  late String primaryType;
  late Map<String,dynamic> message;

  TypedGsnRequestData(
      String name, int chainId, Address verifier, Map<String, dynamic> relayRequest) {
    types = GsnPrimaryType(relayData:RelayDataType,
        relayRequest: RelayRequestType);
    domain = getDomainSeparator(name, verifier, chainId);
    primaryType = 'RelayRequest';
    // In the signature, all "request" fields are flattened out at the top structure.
    // Other params are inside "relayData" sub-type.
    message = {
      ...relayRequest['request'],
      /*
      "from": relayRequest['request']['from'],
      "to": relayRequest['request']['to'],
      ....
       */
      'relayData': relayRequest['relayData'],
    };
  }

  dynamic getFormattedData(){
    return TypedMessage(types: types.getTypesMap(), primaryType: primaryType, domain: domain, message: message);
  }


}

Map<String, dynamic> GsnDomainSeparatorType = {
  'prefix': 'string name,string version',
  'version': '3',
};

EIP712Domain? getDomainSeparator(String name, Address verifier, int chainId) {
  return EIP712Domain(
    chainId: chainId,
    name: name,
    version: GsnDomainSeparatorType['version'],
    verifyingContract: verifier, salt: '',
  );
}

List<TypedDataField> EIP712DomainType1 = [
  TypedDataField(name: 'name', type: 'string'),
  TypedDataField(name: 'version', type: 'string'),
  TypedDataField(name: 'chainId', type: 'uint256'),
  TypedDataField(name: 'verifyingContract', type: 'address'),
];

List<TypedDataField> EIP712DomainTypeWithoutVersion = [
  TypedDataField(name: 'name', type: 'string'),
  TypedDataField(name: 'chainId', type: 'uint256'),
  TypedDataField(name: 'verifyingContract', type: 'address'),
];

List<TypedDataField> RelayDataType = [
  TypedDataField(name: 'maxFeePerGas', type: 'uint256'),
  TypedDataField(name: 'maxPriorityFeePerGas', type: 'uint256'),
  TypedDataField(name: 'transactionCalldataGasUsed', type: 'uint256'),
  TypedDataField(name: 'relayWorker', type: 'address'),
  TypedDataField(name: 'paymaster', type: 'address'),
  TypedDataField(name: 'forwarder', type: 'address'),
  TypedDataField(name: 'paymasterData', type: 'bytes'),
  TypedDataField(name: 'clientId', type: 'uint256'),
];

List<TypedDataField> ForwardRequestType = [
  TypedDataField(name: 'from', type: 'address'),
  TypedDataField(name: 'to', type: 'address'),
  TypedDataField(name: 'value', type: 'uint256'),
  TypedDataField(name: 'gas', type: 'uint256'),
  TypedDataField(name: 'nonce', type: 'uint256'),
  TypedDataField(name: 'data', type: 'bytes'),
  TypedDataField(name: 'validUntilTime', type: 'uint256'),
];

List<TypedDataField> RelayRequestType = [
  ...ForwardRequestType,
  TypedDataField(name: 'relayData', type: 'RelayData'),
];

class MessageTypes {
  List<TypedDataField> EIP712Domain = EIP712DomainType1;
  Map<String, TypedDataField> additionalProperties = {};
}

class GsnPrimaryType {
  List<TypedDataField> relayRequest;
  List<TypedDataField> relayData;

  GsnPrimaryType({
    required this.relayRequest,
    required this.relayData,
  });

  Map<String,List<TypedDataField>> getTypesMap(){
    return {
      "domain":EIP712DomainType1,
      'RelayRequest': relayRequest,
      'RelayData': relayData,
    };
  }

}
