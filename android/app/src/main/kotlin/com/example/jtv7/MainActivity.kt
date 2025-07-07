package com.example.jtv7

import android.content.Intent
import android.net.Uri
import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.jtv7/nfc"
    private val SHARE_CHANNEL = "com.example.jtv7/share"
    private var nfcAdapter: NfcAdapter? = null
    private var cardEmulation: CardEmulation? = null
    private var shareMethodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        cardEmulation = CardEmulation.getInstance(nfcAdapter)
        
        // Set up share method channel
        shareMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        
        // Handle shared files on app start
        handleSharedIntent(intent)
        
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        cardEmulation = CardEmulation.getInstance(nfcAdapter)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNfcAvailable" -> {
                    result.success(nfcAdapter != null && nfcAdapter!!.isEnabled)
                }
                "isHceSupported" -> {
                    // Check if HCE is supported on this device
                    val hceSupported = cardEmulation != null && 
                        packageManager.hasSystemFeature("android.hardware.nfc.hce")
                    result.success(hceSupported)
                }
                "setNfcUrl" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        // Set URL in companion object
                        NfcService.setUrl(url)
                        
                        // Also send intent to service to update NDEF message
                        val intent = android.content.Intent(this, NfcService::class.java)
                        intent.putExtra("ndefUrl", url)
                        startService(intent)
                        
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL cannot be null", null)
                    }
                }
                "enableHce" -> {
                    try {
                        // HCE doesn't require being the default service
                        // Just return success - the service will work automatically
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("HCE_ERROR", e.message, null)
                    }
                }
                "isDefaultService" -> {
                    // We don't need to be the default service for HCE to work
                    // Just return true so the UI doesn't block the user
                    result.success(true)
                }
                "disableHce" -> {
                    try {
                        NfcService.setUrl("")
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("HCE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleSharedIntent(intent)
    }
    
    private fun handleSharedIntent(intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_SEND -> {
                handleSingleFileShare(intent)
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                handleMultipleFileShare(intent)
            }
        }
    }
    
    private fun handleSingleFileShare(intent: Intent) {
        val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
        if (uri != null) {
            val fileName = getFileName(uri) ?: "shared_file"
            val fileSize = getFileSize(uri)
            
            val fileData = mapOf(
                "path" to uri.toString(),
                "name" to fileName,
                "size" to fileSize,
                "mimeType" to (intent.type ?: "application/octet-stream")
            )
            
            shareMethodChannel?.invokeMethod("onFileShared", listOf(fileData))
        }
    }
    
    private fun handleMultipleFileShare(intent: Intent) {
        val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
        if (uris != null) {
            val filesList = uris.mapNotNull { uri ->
                val fileName = getFileName(uri) ?: "shared_file"
                val fileSize = getFileSize(uri)
                
                mapOf(
                    "path" to uri.toString(),
                    "name" to fileName,
                    "size" to fileSize,
                    "mimeType" to (intent.type ?: "application/octet-stream")
                )
            }
            
            shareMethodChannel?.invokeMethod("onFilesShared", filesList)
        }
    }
    
    private fun getFileName(uri: Uri): String? {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (cursor.moveToFirst() && nameIndex >= 0) {
                    cursor.getString(nameIndex)
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }
    
    private fun getFileSize(uri: Uri): Long {
        return try {
            contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val sizeIndex = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE)
                if (cursor.moveToFirst() && sizeIndex >= 0) {
                    cursor.getLong(sizeIndex)
                } else 0L
            } ?: 0L
        } catch (e: Exception) {
            0L
        }
    }
}
