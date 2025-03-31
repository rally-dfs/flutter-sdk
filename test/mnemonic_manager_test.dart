import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rly_network_flutter_sdk/src/key_storage_config.dart';
import 'package:rly_network_flutter_sdk/src/mnemonic_manager.dart';

class MockMethodChannel extends Mock implements MethodChannel {}

// Test helper class to inject mock MethodChannel
class _TestMnemonicManager extends MnemonicManager {
  final MethodChannel _mockMethodChannel;

  _TestMnemonicManager(this._mockMethodChannel,
      {required super.mnemonicIdentifier, required super.keyIndex});

  @override
  MethodChannel get methodChannel => _mockMethodChannel;
}

void main() {
  const testMnemonicIdentifier = 'test_mnemonic_identifier';
  const testKeyIndex = 1;
  late MnemonicManager mnemonicManager;
  late MockMethodChannel mockMethodChannel;
  const testMnemonic =
      'test mnemonic with twelve words for wallet creation test';

  setUp(() {
    mockMethodChannel = MockMethodChannel();
    mnemonicManager = _TestMnemonicManager(mockMethodChannel,
        mnemonicIdentifier: testMnemonicIdentifier, keyIndex: testKeyIndex);
  });

  group('deleteMnemonic', () {
    test('completes successfully when native code via channel succeeds',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => true);

      await expectLater(mnemonicManager.deleteMnemonic(), completes);

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test(
        'completes successfully even when native code via channel returns false',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => false);

      await expectLater(mnemonicManager.deleteMnemonic(), completes);

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test('completes successfully when native code via channel returns null',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => null);

      await expectLater(mnemonicManager.deleteMnemonic(), completes);

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test('propagates platform exceptions from native code via channel',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              }))
          .thenThrow(PlatformException(
              code: 'DELETE_ERROR', message: 'Cannot delete mnemonic'));

      expect(
        () => mnemonicManager.deleteMnemonic(),
        throwsA(isA<PlatformException>()),
      );

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });
  });
  group('deleteCloudMnemonic', () {
    test('completes successfully when native code via channel returns true',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => true);

      await expectLater(mnemonicManager.deleteCloudMnemonic(), completes);

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test('throws exception when native code via channel returns false',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => false);

      expect(
        () => mnemonicManager.deleteCloudMnemonic(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Unable to delete mnemonic from cloud storage'))),
      );

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test('throws exception when native code via channel returns null',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => null);

      expect(
        () => mnemonicManager.deleteCloudMnemonic(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Unable to delete mnemonic from cloud storage'))),
      );

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test('propagates platform exceptions from native code via channel',
        () async {
      when(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              }))
          .thenThrow(PlatformException(
              code: 'DELETE_ERROR', message: 'Cannot access cloud storage'));

      expect(
        () => mnemonicManager.deleteCloudMnemonic(),
        throwsA(isA<PlatformException>()),
      );

      verify(() => mockMethodChannel.invokeMethod<bool>('deleteCloudMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });
  });

  group('generateMnemonic', () {
    test('returns mnemonic from native code via channel successfully',
        () async {
      when(() => mockMethodChannel.invokeMethod<String>('generateNewMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => testMnemonic);

      final result = await mnemonicManager.generateMnemonic();

      verify(
          () => mockMethodChannel.invokeMethod<String>('generateNewMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              })).called(1);

      expect(result, equals(testMnemonic));
    });

    test('throws exception when native code via channel returns null',
        () async {
      when(() => mockMethodChannel.invokeMethod<String>('generateNewMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => null);

      expect(
        () => mnemonicManager.generateMnemonic(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Unable to generate mnemonic'),
        )),
      );

      verify(
          () => mockMethodChannel.invokeMethod<String>('generateNewMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              })).called(1);
    });

    test('throws exception when native code via channel throws', () async {
      when(() => mockMethodChannel.invokeMethod<String>('generateNewMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              }))
          .thenThrow(
              PlatformException(code: 'TEST_ERROR', message: 'Test error'));

      expect(
        () => mnemonicManager.generateMnemonic(),
        throwsA(isA<PlatformException>()),
      );

      verify(
          () => mockMethodChannel.invokeMethod<String>('generateNewMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              })).called(1);
    });
  });

  group('getMnemonic', () {
    const testMnemonic = 'test existing mnemonic from secure storage';

    test('returns mnemonic when it exists', () async {
      when(() => mockMethodChannel.invokeMethod<String>('getMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => testMnemonic);

      final result = await mnemonicManager.getMnemonic();

      verify(() => mockMethodChannel.invokeMethod<String>('getMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
      expect(result, equals(testMnemonic));
    });

    test('returns null when no mnemonic exists', () async {
      when(() => mockMethodChannel.invokeMethod<String>('getMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => null);

      final result = await mnemonicManager.getMnemonic();

      verify(() => mockMethodChannel.invokeMethod<String>('getMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
      expect(result, isNull);
    });

    test('propagates platform exceptions', () async {
      when(() => mockMethodChannel.invokeMethod<String>('getMnemonic', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              }))
          .thenThrow(PlatformException(
              code: 'STORAGE_ERROR', message: 'Cannot access secure storage'));

      expect(
        () => mnemonicManager.getMnemonic(),
        throwsA(isA<PlatformException>()),
      );

      verify(() => mockMethodChannel.invokeMethod<String>('getMnemonic', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });
  });

  group('walletBackedUpToCloud', () {
    test(
        'returns true when wallet is written natively in a way that makes it eligible for clould backup / sync',
        () async {
      when(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => true);

      final result = await mnemonicManager.walletBackedUpToCloud();

      verify(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
      expect(result, isTrue);
    });

    test(
        'returns false when wallet is not written to native layer in a way that makes it eligible for cloudl backup / sync',
        () async {
      when(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => false);

      final result = await mnemonicManager.walletBackedUpToCloud();

      verify(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
      expect(result, isFalse);
    });

    test('throws exception when native code via channel returns null',
        () async {
      when(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).thenAnswer((_) async => null);

      expect(
        () => mnemonicManager.walletBackedUpToCloud(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Unable to get wallet backup status'))),
      );

      verify(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });

    test('propagates platform exceptions from native code via channel',
        () async {
      when(() =>
              mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
                'mnemonicIdentifier': testMnemonicIdentifier,
              }))
          .thenThrow(PlatformException(
              code: 'BACKUP_ERROR',
              message: 'Cannot access cloud backup status'));

      expect(
        () => mnemonicManager.walletBackedUpToCloud(),
        throwsA(isA<PlatformException>()),
      );

      verify(() =>
          mockMethodChannel.invokeMethod<bool>('mnemonicBackedUpToCloud', {
            'mnemonicIdentifier': testMnemonicIdentifier,
          })).called(1);
    });
  });

  group('getPrivateKeyFromMnemonic', () {
    const testMnemonic = 'test mnemonic for private key generation';

    test('returns private key bytes when native code via channel succeeds',
        () async {
      final mockBytes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
      final mockResponse = mockBytes.map((e) => e.toString()).toList();

      when(() => mockMethodChannel
              .invokeMethod<List<Object?>>('getPrivateKeyFromMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'keyIndex': testKeyIndex,
          })).thenAnswer((_) async => mockResponse);

      final result =
          await mnemonicManager.getPrivateKeyFromMnemonic(testMnemonic);

      verify(() => mockMethodChannel
              .invokeMethod<List<Object?>>('getPrivateKeyFromMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'keyIndex': testKeyIndex,
          })).called(1);
      expect(result, isA<Uint8List>());
      expect(result.length, equals(mockBytes.length));

      for (int i = 0; i < mockBytes.length; i++) {
        expect(result[i], equals(mockBytes[i]));
      }
    });

    test('throws exception when native code via channel returns null',
        () async {
      when(() => mockMethodChannel
              .invokeMethod<List<Object?>>('getPrivateKeyFromMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'keyIndex': testKeyIndex,
          })).thenAnswer((_) async => null);

      expect(
        () => mnemonicManager.getPrivateKeyFromMnemonic(testMnemonic),
        throwsA(isA<Error>()),
      );

      verify(() => mockMethodChannel
              .invokeMethod<List<Object?>>('getPrivateKeyFromMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'keyIndex': testKeyIndex,
          })).called(1);
    });

    test('propagates platform exceptions from native code via channel',
        () async {
      when(
          () => mockMethodChannel
                  .invokeMethod<List<Object?>>('getPrivateKeyFromMnemonic', {
                'mnemonic': testMnemonic,
                'mnemonicIdentifier': testMnemonicIdentifier,
                'keyIndex': testKeyIndex,
              })).thenThrow(
          PlatformException(code: 'KEY_ERROR', message: 'Invalid mnemonic'));

      expect(
        () => mnemonicManager.getPrivateKeyFromMnemonic(testMnemonic),
        throwsA(isA<PlatformException>()),
      );

      verify(() => mockMethodChannel
              .invokeMethod<List<Object?>>('getPrivateKeyFromMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'keyIndex': testKeyIndex,
          })).called(1);
    });
  });

  group('saveMnemonic', () {
    test(
        'calls native code via channel with correct parameters when cloud storage enabled',
        () async {
      final storageOptions =
          KeyStorageConfig(saveToCloud: true, rejectOnCloudSaveFailure: true);

      when(() => mockMethodChannel.invokeMethod('saveMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'saveToCloud': true,
            'rejectOnCloudSaveFailure': true,
          })).thenAnswer((_) async => null);

      await mnemonicManager.saveMnemonic(testMnemonic,
          storageOptions: storageOptions);

      verify(() => mockMethodChannel.invokeMethod('saveMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'saveToCloud': true,
            'rejectOnCloudSaveFailure': true,
          })).called(1);
    });

    test(
        'calls native code via channel with correct parameters when cloud storage disabled',
        () async {
      final storageOptions =
          KeyStorageConfig(saveToCloud: false, rejectOnCloudSaveFailure: false);

      when(() => mockMethodChannel.invokeMethod('saveMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'saveToCloud': false,
            'rejectOnCloudSaveFailure': false,
          })).thenAnswer((_) async => null);

      await mnemonicManager.saveMnemonic(testMnemonic,
          storageOptions: storageOptions);

      verify(() => mockMethodChannel.invokeMethod('saveMnemonic', {
            'mnemonic': testMnemonic,
            'mnemonicIdentifier': testMnemonicIdentifier,
            'saveToCloud': false,
            'rejectOnCloudSaveFailure': false,
          })).called(1);
    });

    test('propagates platform exceptions from native code via channel',
        () async {
      final storageOptions =
          KeyStorageConfig(saveToCloud: true, rejectOnCloudSaveFailure: true);

      when(() => mockMethodChannel.invokeMethod('saveMnemonic', any()))
          .thenThrow(PlatformException(
              code: 'SAVE_ERROR', message: 'Could not save mnemonic'));

      expect(
        () => mnemonicManager.saveMnemonic(testMnemonic,
            storageOptions: storageOptions),
        throwsA(isA<PlatformException>()),
      );

      verify(() => mockMethodChannel.invokeMethod('saveMnemonic', any()))
          .called(1);
    });
  });
}
