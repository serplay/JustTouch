package com.example.jtv7

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import java.util.*

class NfcService : HostApduService() {
    
    companion object {
        private const val TAG = "NfcService"
        
        // NDEF Type 4 Tag Application Name
        private val SELECT_APDU = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte(), 
            0x07.toByte(), 0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 
            0x00.toByte(), 0x85.toByte(), 0x01.toByte(), 0x01.toByte()
        )
        
        // Select Capability Container file
        private val SELECT_CC_FILE = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x00.toByte(), 0x0C.toByte(), 
            0x02.toByte(), 0xE1.toByte(), 0x03.toByte()
        )
        
        // Select NDEF file
        private val SELECT_NDEF_FILE = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x00.toByte(), 0x0C.toByte(), 
            0x02.toByte(), 0xE1.toByte(), 0x04.toByte()
        )
        
        // Read Binary Command
        private val READ_BINARY = byteArrayOf(0x00.toByte(), 0xB0.toByte())
        
        // Status codes
        private val STATUS_OK = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val STATUS_FAILED = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        
        // Capability Container
        private val CC_FILE = byteArrayOf(
            0x00.toByte(), 0x0F.toByte(), // CC file length
            0x20.toByte(), // Version 2.0
            0x00.toByte(), 0x3B.toByte(), // Max read size
            0x00.toByte(), 0x34.toByte(), // Max write size  
            0x04.toByte(), // T field
            0x06.toByte(), // L field
            0xE1.toByte(), 0x04.toByte(), // NDEF file ID
            0x0B.toByte(), 0xDF.toByte(), // NDEF file size
            0x00.toByte(), // Read access
            0x00.toByte()  // Write access
        )
        
        private var ndefUrl = ""
        
        fun setUrl(url: String) {
            ndefUrl = url
        }
    }
    
    private var ndefMessage: ByteArray? = null
    
    private fun createNdefMessage() {
        if (ndefUrl.isEmpty()) {
            ndefMessage = byteArrayOf(0x00, 0x00) // Empty NDEF
            return
        }
        
        // Create NDEF URI Record
        val urlBytes = ndefUrl.toByteArray()
        val payload = ByteArray(urlBytes.size + 1)
        payload[0] = 0x00 // No URI identifier code
        System.arraycopy(urlBytes, 0, payload, 1, urlBytes.size)
        
        // NDEF Record header
        val flags = 0xD1.toByte() // MB=1, ME=1, CF=0, SR=1, IL=0, TNF=001
        val type = "U".toByteArray()
        
        // Build NDEF message
        val messageLength = 1 + 1 + 1 + payload.size // flags + type_length + payload_length + payload
        ndefMessage = ByteArray(messageLength + 2) // +2 for length prefix
        
        ndefMessage!![0] = ((messageLength shr 8) and 0xFF).toByte()
        ndefMessage!![1] = (messageLength and 0xFF).toByte()
        ndefMessage!![2] = flags
        ndefMessage!![3] = type.size.toByte()
        ndefMessage!![4] = payload.size.toByte()
        System.arraycopy(payload, 0, ndefMessage!!, 5, payload.size)
    }
    
    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        if (commandApdu == null) {
            return STATUS_FAILED
        }
        
        // Create NDEF message if URL is set
        createNdefMessage()
        
        // SELECT AID
        if (Arrays.equals(commandApdu, SELECT_APDU)) {
            return STATUS_OK
        }
        
        // SELECT CC FILE
        if (Arrays.equals(commandApdu, SELECT_CC_FILE)) {
            return STATUS_OK
        }
        
        // SELECT NDEF FILE
        if (Arrays.equals(commandApdu, SELECT_NDEF_FILE)) {
            return STATUS_OK
        }
        
        // READ BINARY
        if (commandApdu.size >= 4 && 
            commandApdu[0] == READ_BINARY[0] && 
            commandApdu[1] == READ_BINARY[1]) {
            
            val offset = ((commandApdu[2].toInt() and 0xFF) shl 8) or (commandApdu[3].toInt() and 0xFF)
            val length = if (commandApdu.size > 4) (commandApdu[4].toInt() and 0xFF) else 256
            
            // Read CC file
            if (offset < CC_FILE.size) {
                val readLength = minOf(length, CC_FILE.size - offset)
                val response = ByteArray(readLength + 2)
                System.arraycopy(CC_FILE, offset, response, 0, readLength)
                System.arraycopy(STATUS_OK, 0, response, readLength, 2)
                return response
            }
            
            // Read NDEF file (offset adjusted for CC file)
            val ndefOffset = offset - CC_FILE.size
            if (ndefOffset >= 0 && ndefMessage != null && ndefOffset < ndefMessage!!.size) {
                val readLength = minOf(length, ndefMessage!!.size - ndefOffset)
                val response = ByteArray(readLength + 2)
                System.arraycopy(ndefMessage!!, ndefOffset, response, 0, readLength)
                System.arraycopy(STATUS_OK, 0, response, readLength, 2)
                return response
            }
        }
        
        return STATUS_FAILED
    }
    
    override fun onDeactivated(reason: Int) {
        // Called when NFC link is lost
    }
}
