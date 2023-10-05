package com.rlynetworkmobilesdk

import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import androidx.security.crypto.MasterKey.Builder
import com.google.android.gms.auth.blockstore.Blockstore
import com.google.android.gms.auth.blockstore.BlockstoreClient
import com.google.android.gms.auth.blockstore.DeleteBytesRequest
import com.google.android.gms.auth.blockstore.RetrieveBytesRequest
import com.google.android.gms.auth.blockstore.RetrieveBytesResponse
import com.google.android.gms.auth.blockstore.StoreBytesData
import kotlin.math.log

class MnemonicStorageHelper(context: Context) {
    private val sharedPreferences: SharedPreferences
    private val blockstoreClient: BlockstoreClient
    private var isEndToEndEncryptionAvailable: Boolean = false;

    init {
        val masterKey: MasterKey = Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        sharedPreferences = EncryptedSharedPreferences.create(
            context,
            "encrypted_mnemonic",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )

        blockstoreClient = Blockstore.getClient(context)
        blockstoreClient.isEndToEndEncryptionAvailable.addOnSuccessListener { isE2EEAvailable ->
            isEndToEndEncryptionAvailable = isE2EEAvailable
        }
    }

    fun save(key: String, mnemonic: String, useBlockStore: Boolean, forceBlockStore: Boolean, onSuccess: () -> Unit, onFailure: (message: String) -> Unit) {
        //Todo: remove hardcoding of this isEndToEndEncryptionAvailable flag
        //original logic form the rly sdk requires that we store on blockstore only if end to end encryption is there
        //figure out how and when this end to end encryption will be available so that we can start storing mnemonic on the block store
        //in case end-to-end encryption isn't available we have a few options:
        // 1. save mnemonic on local storage -> todo: currently shared pref is used, use secure storage instead
        //2. save on block store without end to end encryption
        //3. save mnemonic only on our server
        // discuss all options and decide
        isEndToEndEncryptionAvailable = true
        if (useBlockStore && isEndToEndEncryptionAvailable) {
            Log.i("memonic_storage", "saving on cloud , because useBlockStore = true and isEndToEndEncryptionAvailable = true")
            val storeRequest = StoreBytesData.Builder()
                .setBytes(mnemonic.toByteArray(Charsets.UTF_8))
                .setKey(key)

            storeRequest.setShouldBackupToCloud(true)

            blockstoreClient.storeBytes(storeRequest.build())
                .addOnSuccessListener {
                    Log.i("memonic_storage", "saved on cloud")
                    onSuccess()
                }.addOnFailureListener { e ->
                    Log.i("memonic_storage", "failed to save on cloud")
                    onFailure("Failed to save to cloud $e")
                }
        } else {
            if (forceBlockStore) {
                Log.i("memonic_storage", "forceBlockStore = true")
                onFailure("Failed to save mnemonic. No end to end encryption option is available and force cloud is on");
            } else {
                Log.i("memonic_storage", "saving mnemonic on local")
                saveToSharedPref(key, mnemonic)
                onSuccess()
            }
        }
    }

    private fun saveToSharedPref(key: String, mnemonic: String) {
        val editor = sharedPreferences.edit()
        editor.putString(key, mnemonic)
        editor.commit()
    }

    fun read(key: String, onSuccess: (mnemonic: String?) -> Unit) {

        val retrieveRequest = RetrieveBytesRequest.Builder()
            .setKeys(listOf(key))
            .build()

        blockstoreClient.retrieveBytes(retrieveRequest)
            .addOnSuccessListener { result: RetrieveBytesResponse ->
                val blockstoreDataMap = result.blockstoreDataMap

                if (blockstoreDataMap.isEmpty()) {
                    Log.i("memonic_storage", "got empty from block store, reading from shared prefs")
                    val mnemonic = readFromSharedPref(key)
                    onSuccess(mnemonic)
                } else {
                    val mnemonic = blockstoreDataMap[key]
                    Log.i("memonic_storage", "got non-empty from block store")
                    if (mnemonic !== null) {
                        val strMnemonic = mnemonic.bytes.toString(Charsets.UTF_8)
                        Log.i("memonic_storage", "got non-empty from block store $strMnemonic")
                        onSuccess(strMnemonic)
                    } else {
                        onSuccess(null)
                    }
                }
            }
            .addOnFailureListener {
                val mnemonic = readFromSharedPref(key)
                onSuccess(mnemonic)
            }
    }

    private fun readFromSharedPref(key: String): String? {
        return sharedPreferences.getString(key, null)
    }

    fun delete(key: String) {
        val retrieveRequest = DeleteBytesRequest.Builder()
            .setKeys(listOf(key))
            .build()

        blockstoreClient.deleteBytes(retrieveRequest)

        val editor = sharedPreferences.edit()
        editor.remove(key)
        editor.commit()
    }
}
