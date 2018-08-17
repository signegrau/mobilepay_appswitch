import Flutter
import UIKit

public class SwiftMobilepayAppswitchPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mobilepay_appswitch", binaryMessenger: registrar.messenger())
        let instance = SwiftMobilepayAppswitchPlugin()
        
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private static var currentResult: FlutterResult? = nil
    
    static func setResult(result: @escaping FlutterResult) {
        currentResult = result
    }
    
    static func getResult() -> FlutterResult? {
        return currentResult
    }
    
    let countryMap = ["DENMARK": MobilePayCountry.denmark,
                      "FINLAND": MobilePayCountry.finland,
                      "NORWAY": MobilePayCountry.norway]
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        (call.arguments as? Dictionary<String, String>).map { args in
            switch call.method {
            case "init":
                
                if let merchantId = args["merchantId"], let country = args["country"].flatMap({countryMap[$0]}), let merchantUrlScheme = args["urlScheme"] {
                    MobilePayManager.sharedInstance().setup(withMerchantId: merchantId, merchantUrlScheme: merchantUrlScheme, country: country)
                }
                break
            case "makepayment":
                if let orderId = args["orderId"], let price = args["price"].flatMap({Float($0)}) {
                    if let payment = MobilePayPayment.init(orderId: orderId, productPrice: price) {
                        SwiftMobilepayAppswitchPlugin.setResult(result: result)
                        MobilePayManager.sharedInstance().beginMobilePayment(with: payment, error: { (error: NSError) -> Void in
                            result(FlutterError.init(code: String(error.code), message: error.localizedDescription, details: error))
                            } as? MobilePayPaymentErrorBlock)
                    }
                }
                break
            default:
                break;
            }
        }
        result(FlutterMethodNotImplemented)
    }
    
    public func handleMobilePayPaymentWithUrl(url: URL) {
        MobilePayManager.sharedInstance().handleMobilePayPayment(with: url, success: { (successfulPayment) in
            if let res = successfulPayment {
                if let result = SwiftMobilepayAppswitchPlugin.getResult() {
                    result(
                        """
                        {"amountWithdrawnFromCard": \(res.amountWithdrawnFromCard),
                        "orderId": "\(res.orderId)",
                        "signature": "\(res.signature)",
                        "transactionId": "\(res.transactionId)"}
                        """)
                }
            }
        }, error: { (error: NSError) -> Void in
            if let result = SwiftMobilepayAppswitchPlugin.getResult() {
                result(FlutterError(code: String(error.code), message: error.localizedDescription, details: error))
            }} as? MobilePayPaymentErrorBlock)
        { (cancelledPayment) in
            if let res = cancelledPayment {
                if let result = SwiftMobilepayAppswitchPlugin.getResult() {
                    result(FlutterError(code: "0", message: "Order cancelled", details: res))
                }
            }
        }
    }
}
