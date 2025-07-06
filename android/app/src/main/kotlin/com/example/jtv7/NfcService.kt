package com.example.jtv7

import android.content.Intent
import android.nfc.NdefMessage
import android.nfc.NdefRecord
import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.util.*

class NfcService : HostApduService() {
    
    companion object {
        private const val TAG = "NfcService"
        
        // SELECT APPLICATION command
        private val SELECT_APPLICATION = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte(), 
            0x07.toByte(), 0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 
            0x00.toByte(), 0x85.toByte(), 0x01.toByte(), 0x01.toByte(),
            0x00.toByte()
        )
        
        // SELECT CAPABILITY CONTAINER
        private val SELECT_CAPABILITY_CONTAINER = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x00.toByte(), 0x0C.toByte(), 
            0x02.toByte(), 0xE1.toByte(), 0x03.toByte()
        )
        
        // SELECT NDEF FILE
        private val SELECT_NDEF_FILE = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x00.toByte(), 0x0C.toByte(), 
            0x02.toByte(), 0xE1.toByte(), 0x04.toByte()
        )
        
        // Status codes
        private val SUCCESS_SW = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val FAILURE_SW = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        
        // Capability Container File
        private val CAPABILITY_CONTAINER_FILE = byteArrayOf(
            0x00.toByte(), 0x0F.toByte(), // CCLEN
            0x20.toByte(), // Mapping Version 2.0
            0x00.toByte(), 0x3B.toByte(), // Maximum R-APDU data size
            0x00.toByte(), 0x34.toByte(), // Maximum C-APDU data size
            0x04.toByte(), 0x06.toByte(), // Tag & Length
            0xE1.toByte(), 0x04.toByte(), // NDEF File Identifier
            0x00.toByte(), 0xFF.toByte(), // Maximum NDEF size
            0x00.toByte(), // NDEF file read access granted
            0xFF.toByte()  // NDEF File write access denied
        )
        
        private var ndefUrl = ""
        
        fun setUrl(url: String) {
            Log.d(TAG, "Setting NFC URL: $url")
            ndefUrl = url
        }
    }
    
    private var mNdefRecordFile: ByteArray? = null
    private var mAppSelected = false
    private var mCcSelected = false
    private var mNdefSelected = false
    
    override fun onCreate() {
        super.onCreate()
        
        mAppSelected = false
        mCcSelected = false
        mNdefSelected = false
        
        // Default NDEF message
        val defaultMessage = "JustTouch - Touch to Share Files"
        val ndefDefaultMessage = getNdefUrlMessage(defaultMessage)
        if (ndefDefaultMessage != null) {
            val nlen = ndefDefaultMessage.byteArrayLength
            mNdefRecordFile = ByteArray(nlen + 2)
            mNdefRecordFile!![0] = ((nlen shr 8) and 0xFF).toByte()
            mNdefRecordFile!![1] = (nlen and 0xFF).toByte()
            System.arraycopy(ndefDefaultMessage.toByteArray(), 0, mNdefRecordFile!!, 2, ndefDefaultMessage.byteArrayLength)
        }
        
        Log.d(TAG, "NFC Service created")
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent != null) {
            // Handle URL from intent
            if (intent.hasExtra("ndefUrl")) {
                val url = intent.getStringExtra("ndefUrl")
                if (!url.isNullOrEmpty()) {
                    val ndefMessage = getNdefUrlMessage(url)
                    if (ndefMessage != null) {
                        val nlen = ndefMessage.byteArrayLength
                        mNdefRecordFile = ByteArray(nlen + 2)
                        mNdefRecordFile!![0] = ((nlen shr 8) and 0xFF).toByte()
                        mNdefRecordFile!![1] = (nlen and 0xFF).toByte()
                        System.arraycopy(ndefMessage.toByteArray(), 0, mNdefRecordFile!!, 2, ndefMessage.byteArrayLength)
                        Log.d(TAG, "Updated NDEF URL from intent: $url")
                    }
                }
            }
        }
        
        // Update with current URL if available
        if (ndefUrl.isNotEmpty()) {
            val ndefMessage = getNdefUrlMessage(ndefUrl)
            if (ndefMessage != null) {
                val nlen = ndefMessage.byteArrayLength
                mNdefRecordFile = ByteArray(nlen + 2)
                mNdefRecordFile!![0] = ((nlen shr 8) and 0xFF).toByte()
                mNdefRecordFile!![1] = (nlen and 0xFF).toByte()
                System.arraycopy(ndefMessage.toByteArray(), 0, mNdefRecordFile!!, 2, ndefMessage.byteArrayLength)
                Log.d(TAG, "Updated NDEF URL: $ndefUrl")
            }
        }
        
        return super.onStartCommand(intent, flags, startId)
    }
    
    private fun getNdefUrlMessage(url: String): NdefMessage? {
        if (url.isEmpty()) return null
        
        val ndefRecord = NdefRecord.createUri(url)
        return NdefMessage(ndefRecord)
    }
    
    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            Log.d(TAG, "Command APDU is null")
            return FAILURE_SW
        }
        
        Log.d(TAG, "Command APDU: ${bytesToHex(commandApdu)}")
        
        // SELECT APPLICATION
        if (Arrays.equals(SELECT_APPLICATION, commandApdu)) {
            mAppSelected = true
            mCcSelected = false
            mNdefSelected = false
            Log.d(TAG, "Application selected")
            return SUCCESS_SW
        }
        
        // SELECT CAPABILITY CONTAINER
        if (mAppSelected && Arrays.equals(SELECT_CAPABILITY_CONTAINER, commandApdu)) {
            mCcSelected = true
            mNdefSelected = false
            Log.d(TAG, "Capability Container selected")
            return SUCCESS_SW
        }
        
        // SELECT NDEF FILE
        if (mAppSelected && Arrays.equals(SELECT_NDEF_FILE, commandApdu)) {
            mCcSelected = false
            mNdefSelected = true
            Log.d(TAG, "NDEF file selected")
            return SUCCESS_SW
        }
        
        // READ BINARY
        if (commandApdu.size >= 4 && 
            commandApdu[0] == 0x00.toByte() && 
            commandApdu[1] == 0xB0.toByte()) {
            
            val offset = ((commandApdu[2].toInt() and 0xFF) shl 8) or (commandApdu[3].toInt() and 0xFF)
            val le = if (commandApdu.size > 4) (commandApdu[4].toInt() and 0xFF) else 256
            
            Log.d(TAG, "Read Binary - offset: $offset, length: $le")
            
            val responseApdu = ByteArray(le + SUCCESS_SW.size)
            
            // Read Capability Container
            if (mCcSelected && offset == 0 && le == CAPABILITY_CONTAINER_FILE.size) {
                System.arraycopy(CAPABILITY_CONTAINER_FILE, offset, responseApdu, 0, le)
                System.arraycopy(SUCCESS_SW, 0, responseApdu, le, SUCCESS_SW.size)
                Log.d(TAG, "Returning CC file")
                return responseApdu
            }
            
            // Read NDEF file
            if (mNdefSelected && mNdefRecordFile != null) {
                if (offset + le <= mNdefRecordFile!!.size) {
                    System.arraycopy(mNdefRecordFile!!, offset, responseApdu, 0, le)
                    System.arraycopy(SUCCESS_SW, 0, responseApdu, le, SUCCESS_SW.size)
                    Log.d(TAG, "Returning NDEF data")
                    return responseApdu
                }
            }
        }
        
        Log.d(TAG, "Command not handled, returning failure")
        return FAILURE_SW
    }
    
    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "NFC deactivated, reason: $reason")
        mAppSelected = false
        mCcSelected = false
        mNdefSelected = false
    }
    
    private fun bytesToHex(bytes: ByteArray): String {
        val sb = StringBuilder()
        for (b in bytes) {
            sb.append(String.format("%02X", b))
        }
        return sb.toString()
    }
}
