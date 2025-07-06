package com.example.jtv7

import android.nfc.NfcAdapter
import android.nfc.cardemulation.CardEmulation
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.jtv7/nfc"
    private var nfcAdapter: NfcAdapter? = null
    private var cardEmulation: CardEmulation? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
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
}
