import Flutter
import UIKit

public class SwiftMobilepayAppswitchPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mobilepay_appswitch", binaryMessenger: registrar.messenger())
        let instance = SwiftMobilepayAppswitchPlugin()
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
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
        if let args = call.arguments as? Dictionary<String, Any> {
            switch call.method {
            case "init":
                if let merchantId = args["merchantId"] as? String, let country = (args["country"] as? String).flatMap({countryMap[$0]}), let merchantUrlScheme = args["urlScheme"] as? String {
                    MobilePayManager.sharedInstance().setup(withMerchantId: merchantId, merchantUrlScheme: merchantUrlScheme, country: country)
                } else {
                    result(FlutterError(code: "255", message: "Invalid arguments for init", details: args))
                }
                break
            case "makePayment":
                if let orderId = args["orderId"] as? String, let price = args["price"] as? Float {
                    if let payment = MobilePayPayment.init(orderId: orderId, productPrice: price) {
                        print("hi")
                        SwiftMobilepayAppswitchPlugin.setResult(result: result)
                        MobilePayManager.sharedInstance().beginMobilePayment(with: payment, error: { (error: NSError) -> Void in
                            print("wat")
                            result(FlutterError.init(code: String(error.code), message: error.localizedDescription, details: error))
                            } as? MobilePayPaymentErrorBlock)
                    }
                } else {
                    result(FlutterError(code: "255", message: "Invalid arguments for makePayment", details: args))
                }
                break
            default:
                result(FlutterMethodNotImplemented)
                break;
            }
        }
    }
    
    public static func application(_ application: UIApplication, handleOpen url: URL) -> Bool {
        SwiftMobilepayAppswitchPlugin.handleMobilePayPayment(with: url)
        return true
    }
    
    public static func handleMobilePayPayment(with url: URL) {
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
