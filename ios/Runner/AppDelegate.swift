import Flutter
import UIKit
import CoreNFC

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller = window?.rootViewController as! FlutterViewController
    let nfcChannel = FlutterMethodChannel(name: "com.hackclub.justtouch/nfc", binaryMessenger: controller.binaryMessenger)
    
    nfcChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "isNfcAvailable":
        if #available(iOS 11.0, *) {
          result(NFCNDEFReaderSession.readingAvailable)
        } else {
          result(false)
        }
      case "isHceSupported":
        // iOS doesn't support HCE in the same way as Android
        // But we can use NFC writing capabilities
        if #available(iOS 13.0, *) {
          result(NFCNDEFReaderSession.readingAvailable)
        } else {
          result(false)
        }
      case "setNfcUrl":
        // For iOS, we'll need to handle NFC differently
        // This is a placeholder for iOS NFC writing functionality
        result(true)
      case "enableHce":
        result(true)
      case "disableHce":
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
