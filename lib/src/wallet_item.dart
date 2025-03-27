import 'dart:convert';

class Address{
  final String address;
  final int index;


  Address({
    required this.address,
    required this.index,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      address: json['address'],
      index: json['index'],
    );
  }

   Map<String, dynamic> toJson() => {
        'address': address,
        'index': index,
      };

}

class WalletItem {
  final String label;
  final bool isImported;
  final bool isDefault;
  final List<Address> addresses;

  WalletItem({
    required this.label,
    required this.isImported,
    required this.isDefault,
    required this.addresses,
  });

  // Factory method for creating a MnemonicItem from a JSON map.
  factory WalletItem.fromJson(Map<String, dynamic> json) {

    var addressesJson = json['addresses'] as List? ?? [];
    List<Address> addresses =
        addressesJson.map((e) => Address.fromJson(e)).toList();


    return WalletItem(
      label: json['label'],
      isImported: json['isImported'],
      isDefault: json['isDefault'],
      addresses: addresses,
    );
  }

  // Convert the MnemonicItem to a JSON map.
  Map<String, dynamic> toJson() => {
        'label': label,
        'isImported': isImported,
        'addresses': addresses.map((e) => e.toJson()).toList(),
      };
}