import Foundation


public class RlyNetworkMobileSdk: NSObject {
    let MNEMONIC_STRENGTH = 24
    let SERVICE_KEY = "WALLET_STORAGE"
    let MNEMONIC_ACCOUNT_KEY = "BIP39_MNEMONIC"

    public func hello() -> String {
        return "Hello World"
    }

    public func getBundleId() -> String {
        return Bundle.main.bundleIdentifier!
    }

    public func getMnemonic() -> String? {
        let mnemonicData = KeychainHelper.standard.read(service: SERVICE_KEY, account: MNEMONIC_ACCOUNT_KEY)

        if (mnemonicData == nil) {
            return nil
        } else {
            let mnemonicString = String(data: mnemonicData!, encoding: .utf8)
            return mnemonicString
        }
    }

    public func mnemonicBackedUpToCloud() -> Bool {
        let mnemonicAttributes = KeychainHelper.standard.readAttributes(service: SERVICE_KEY, account: MNEMONIC_ACCOUNT_KEY)

        if (mnemonicAttributes == nil) {
            return false
        }

        let keyAccessibility = mnemonicAttributes?[kSecAttrAccessible as String] as? String

        return keyAccessibility == (kSecAttrAccessibleWhenUnlocked as String)
    }

    public func generateMnemonic() -> String {
        var data = [UInt8](repeating: 0, count: MNEMONIC_STRENGTH)
        let result = SecRandomCopyBytes(kSecRandomDefault, data.count, &data)

        if result == errSecSuccess {
            let mnemonicString = String(cString: mnemonic_from_data(&data, CInt(MNEMONIC_STRENGTH)))

            if (mnemonic_check(mnemonicString) == 0) {
                return "failure";

            }

            return mnemonicString
        } else {
            return "failure";
            // reject("mnemonic_generation_failure", "failed to generate secure bytes", nil);
        }
    }

    public func saveMnemonic(
      _ mnemonic: String,
      saveToCloud: Bool,
      rejectOnCloudSaveFailure: Bool
    ) -> Bool {
        KeychainHelper.standard.save(
            mnemonic.data(using: .utf8)!,
            service: SERVICE_KEY,
            account: MNEMONIC_ACCOUNT_KEY,
            saveToCloud: saveToCloud
        );
        return true
    }

    public func deleteMnemonic() -> Bool {
        KeychainHelper.standard.delete(service: SERVICE_KEY, account: MNEMONIC_ACCOUNT_KEY)

        return true
    }

    public func getPrivateKeyFromMnemonic(
      _ mnemonic: String
    ) -> Any{
        if (mnemonic_check(mnemonic) == 0) {
            return "failure";
            // reject("mnemonic_verification_failure", "mnemonic failed to pass check", nil);
            // return;
        }

        var seed = [UInt8](repeating: 0, count: (512 / 8));
        seed.withUnsafeMutableBytes { destBytes in
            mnemonic_to_seed(mnemonic, "", destBytes.baseAddress!.assumingMemoryBound(to: UInt8.self), nil)
        }

        var node = HDNode();
        hdnode_from_seed(&seed, CInt(seed.count), "secp256k1", &node);

        hdnode_private_ckd(&node, (0x80000000 | (44)));   // 44' - BIP 44 (purpose field)
        hdnode_private_ckd(&node, (0x80000000 | (60)));   // 60' - Ethereum (see SLIP 44)
        hdnode_private_ckd(&node, (0x80000000 | (0)));    // 0'  - Account 0
        hdnode_private_ckd(&node, 0);                     // 0   - External
        hdnode_private_ckd(&node, 0);                     // 0   - Slot #0

        var pkey : [UInt8] = []

        let reflection = Mirror(reflecting: node.private_key)
        for i in reflection.children {
            pkey.append(i.value as! UInt8)
        }

        return pkey
    }
}
