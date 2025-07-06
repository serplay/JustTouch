import 'package:flutter/services.dart';

class NfcService {
  static const MethodChannel _channel = MethodChannel('com.example.jtv7/nfc');

  static Future<bool> isNfcAvailable() async {
    try {
      final bool isAvailable = await _channel.invokeMethod('isNfcAvailable');
      return isAvailable;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isHceSupported() async {
    try {
      final bool isSupported = await _channel.invokeMethod('isHceSupported');
      return isSupported;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isDefaultService() async {
    try {
      final bool isDefault = await _channel.invokeMethod('isDefaultService');
      return isDefault;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> setNfcUrl(String url) async {
    try {
      final bool success = await _channel.invokeMethod('setNfcUrl', {'url': url});
      return success;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> enableHce() async {
    try {
      final bool success = await _channel.invokeMethod('enableHce');
      return success;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> disableHce() async {
    try {
      final bool success = await _channel.invokeMethod('disableHce');
      return success;
    } on PlatformException {
      return false;
    }
  }
}
