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
                        NfcService.setUrl(url)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "URL cannot be null", null)
                    }
                }
                "enableHce" -> {
                    try {
                        // Request to become the default service for OTHER category
                        val componentName = android.content.ComponentName(this, NfcService::class.java)
                        val isDefault = cardEmulation?.isDefaultServiceForCategory(
                            componentName,
                            CardEmulation.CATEGORY_OTHER
                        ) ?: false
                        
                        if (!isDefault) {
                            // If not default, request user to set us as default
                            cardEmulation?.let { ce ->
                                // This will prompt user to set our service as default
                                val intent = android.content.Intent(android.provider.Settings.ACTION_NFC_PAYMENT_SETTINGS)
                                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                                try {
                                    startActivity(intent)
                                } catch (e: Exception) {
                                    // Fallback: just return success for now
                                }
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("HCE_ERROR", e.message, null)
                    }
                }
                "isDefaultService" -> {
                    val componentName = android.content.ComponentName(this, NfcService::class.java)
                    val isDefault = cardEmulation?.isDefaultServiceForCategory(
                        componentName,
                        CardEmulation.CATEGORY_OTHER
                    ) ?: false
                    result.success(isDefault)
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
