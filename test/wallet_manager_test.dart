import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rly_network_flutter_sdk/src/wallet_manager.dart';
import 'package:rly_network_flutter_sdk/src/mnemonic_manager.dart';
import 'package:rly_network_flutter_sdk/src/key_storage_config.dart';

// Create mock class with Mocktail - no code generation needed
class MockMnemonicManager extends Mock implements MnemonicManager {}

void main() {
  late MockMnemonicManager mockMnemonicManager;
  late WalletManager walletManager;

  setUp(() {
    mockMnemonicManager = MockMnemonicManager();
    walletManager = WalletManager(mnemonicManager: mockMnemonicManager);

    registerFallbackValue(
        KeyStorageConfig(saveToCloud: true, rejectOnCloudSaveFailure: true));
  });

  group('createWallet', () {
    const testMnemonic = 'test mnemonic phrase here';
    final testPrivateKey = Uint8List.fromList(List.generate(32, (i) => i));

    test('creates a new wallet successfully', () async {
      // Set up the mock behavior
      when(() => mockMnemonicManager.generateMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.saveMnemonic(any(),
              storageOptions: any(named: 'storageOptions')))
          .thenAnswer((_) async {});
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => null);

      // Call the method under test
      final wallet = await walletManager.createWallet();

      // Verify the expected methods were called
      verify(() => mockMnemonicManager.generateMnemonic()).called(1);
      verify(() => mockMnemonicManager.saveMnemonic(testMnemonic,
          storageOptions: any(named: 'storageOptions'))).called(1);
      verify(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .called(1);

      // Verify the wallet was created properly
      expect(wallet, isNotNull);
    });

    test('creates a new wallet with custom storage options', () async {
      // Set up custom storage options
      final customStorageOptions = KeyStorageConfig(
        saveToCloud: false,
        rejectOnCloudSaveFailure: false,
      );

      // Set up the mock behavior
      when(() => mockMnemonicManager.generateMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.saveMnemonic(any(),
              storageOptions: any(named: 'storageOptions')))
          .thenAnswer((_) async {});
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => null);

      // Call the method under test
      final wallet = await walletManager.createWallet(
          storageOptions: customStorageOptions);

      // Verify the expected methods were called with the correct parameters
      verify(() => mockMnemonicManager.generateMnemonic()).called(1);
      verify(() => mockMnemonicManager.saveMnemonic(testMnemonic,
          storageOptions: customStorageOptions)).called(1);

      // Verify the wallet was created properly
      expect(wallet, isNotNull);
    });

    test('throws an error when wallet exists and overwrite is false', () async {
      // Set up existing wallet scenario
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => 'existing mnemonic');
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(
          'existing mnemonic')).thenAnswer((_) async => testPrivateKey);

      // Set up the mock behavior for creation attempt
      when(() => mockMnemonicManager.generateMnemonic())
          .thenAnswer((_) async => testMnemonic);

      // First, get the existing wallet to populate the cache
      await walletManager.getWallet();

      // Now try to create a new wallet without overwrite
      expect(
          () => walletManager.createWallet(overwrite: false),
          throwsA(isA<String>().having(
              (s) => s, 'error message', contains('Wallet already exists'))));

      // Verify generateMnemonic was called but saveMnemonic was never called
      verify(() => mockMnemonicManager.generateMnemonic()).called(1);
      verifyNever(() => mockMnemonicManager.saveMnemonic(any(),
          storageOptions: any(named: 'storageOptions')));
    });

    test('overwrites existing wallet when overwrite is true', () async {
      // Set up existing wallet scenario
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => 'existing mnemonic');
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(
          'existing mnemonic')).thenAnswer((_) async => testPrivateKey);

      // Set up the mock behavior for creation with overwrite
      when(() => mockMnemonicManager.generateMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.saveMnemonic(any(),
              storageOptions: any(named: 'storageOptions')))
          .thenAnswer((_) async {});
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);

      // First, get the existing wallet to populate the cache
      await walletManager.getWallet();

      // Now try to create a new wallet with overwrite
      final wallet = await walletManager.createWallet(overwrite: true);

      // Verify the methods were called as expected
      verify(() => mockMnemonicManager.generateMnemonic()).called(1);
      verify(() => mockMnemonicManager.saveMnemonic(testMnemonic,
          storageOptions: any(named: 'storageOptions'))).called(1);

      // Verify the wallet was created properly
      expect(wallet, isNotNull);
    });
  });

  group('walletEligibleForCloudSync', () {
    test(
        'returns true when underyling mnemonic storage says mnemonic that underlines the wallet wallet is configured eligible for cloud backup',
        () async {
      // Set up the mock to return true
      when(() => mockMnemonicManager.walletBackedUpToCloud())
          .thenAnswer((_) async => true);

      // Call the method under test
      final result = await walletManager.walletEligibleForCloudSync();

      // Verify that the underlying method was called
      verify(() => mockMnemonicManager.walletBackedUpToCloud()).called(1);

      // Verify the result
      expect(result, isTrue);
    });

    test(
        'returns false when underyling mnemonic storage says mnemonic that underlies the wallet is not configured eligible for cloud backup',
        () async {
      // Set up the mock to return false
      when(() => mockMnemonicManager.walletBackedUpToCloud())
          .thenAnswer((_) async => false);

      // Call the method under test
      final result = await walletManager.walletEligibleForCloudSync();

      // Verify that the underlying method was called
      verify(() => mockMnemonicManager.walletBackedUpToCloud()).called(1);

      // Verify the result
      expect(result, isFalse);
    });

    test(
        'deprecated walletBackedUpToCloud method delegates to walletEligibleForCloudSync',
        () async {
      // Set up the mock to return true
      when(() => mockMnemonicManager.walletBackedUpToCloud())
          .thenAnswer((_) async => true);

      // Call the deprecated method
      final result = await walletManager.walletBackedUpToCloud();

      // Verify that the underlying method was called
      verify(() => mockMnemonicManager.walletBackedUpToCloud()).called(1);

      // Verify the result
      expect(result, isTrue);
    });
  });

  group('getWallet', () {
    final testPrivateKey = Uint8List.fromList(List.generate(32, (i) => i));
    const testMnemonic = 'test mnemonic phrase here';

    test('returns null if no mnemonic exists', () async {
      // Set up the mock behavior - no mnemonic exists
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => null);

      // Call the method under test
      final wallet = await walletManager.getWallet();

      // Verify the expected methods were called
      verify(() => mockMnemonicManager.getMnemonic()).called(1);
      verifyNever(() => mockMnemonicManager.getPrivateKeyFromMnemonic(any()));

      // Verify null is returned when no mnemonic exists
      expect(wallet, isNull);
    });

    test('creates and returns a wallet when mnemonic exists', () async {
      // Set up the mock behavior - mnemonic exists
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);

      // Call the method under test
      final wallet = await walletManager.getWallet();

      // Verify the expected methods were called
      verify(() => mockMnemonicManager.getMnemonic()).called(1);
      verify(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .called(1);

      // Verify a wallet is returned when mnemonic exists
      expect(wallet, isNotNull);
    });

    test(
        'returns cached wallet if it exists to avoid round trip through native storage',
        () async {
      // Set up the mock behavior - mnemonic exists
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);

      // First call to populate the cache
      final firstWallet = await walletManager.getWallet();

      // Reset the mocks to verify they're not called again
      reset(mockMnemonicManager);

      final secondWallet = await walletManager.getWallet();

      verifyNever(() => mockMnemonicManager.getMnemonic());
      verifyNever(() => mockMnemonicManager.getPrivateKeyFromMnemonic(any()));

      expect(secondWallet, equals(firstWallet));
      expect(secondWallet, isNotNull);
    });
  });

  group('getPublicAddress', () {
    final testPrivateKey = Uint8List.fromList(List.generate(32, (i) => i));
    const testMnemonic = 'test mnemonic phrase here';

    test('returns null if no wallet exists', () async {
      // Set up the mock behavior - no wallet exists
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => null);

      // Call the method under test
      final address = await walletManager.getPublicAddress();

      // Verify the expected methods were called
      verify(() => mockMnemonicManager.getMnemonic()).called(1);

      // Verify null is returned when no wallet exists
      expect(address, isNull);
    });

    test('returns wallet address when wallet exists', () async {
      // Set up the mock behavior - wallet exists with test address
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);

      // We need to mock wallet creation to return a wallet with the test address
      // This is done indirectly via the private key

      // Call the method under test
      final address = await walletManager.getPublicAddress();

      // Verify the expected methods were called
      verify(() => mockMnemonicManager.getMnemonic()).called(1);
      verify(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .called(1);

      // Verify an address is returned (we can't easily predict the exact address without
      // mocking the Wallet class, but we can verify it's not null and is a string)
      expect(address, isNotNull);
      expect(address, isA<String>());
    });

    test('uses cached wallet without accessing storage again', () async {
      // Set up the mock behavior - wallet exists
      when(() => mockMnemonicManager.getMnemonic())
          .thenAnswer((_) async => testMnemonic);
      when(() => mockMnemonicManager.getPrivateKeyFromMnemonic(testMnemonic))
          .thenAnswer((_) async => testPrivateKey);

      // First call to populate the cache
      await walletManager.getWallet();

      // Reset the mocks to verify they're not called again
      reset(mockMnemonicManager);

      // Call the method under test
      final address = await walletManager.getPublicAddress();

      // Verify no storage methods were called since we have a cached wallet
      verifyNever(() => mockMnemonicManager.getMnemonic());
      verifyNever(() => mockMnemonicManager.getPrivateKeyFromMnemonic(any()));

      // Verify an address is returned
      expect(address, isNotNull);
      expect(address, isA<String>());
    });
  });
}
