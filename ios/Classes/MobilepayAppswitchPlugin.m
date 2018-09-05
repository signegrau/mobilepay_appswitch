#import "MobilepayAppswitchPlugin.h"

@implementation MobilepayAppswitchPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"mobilepay_appswitch"
                                     binaryMessenger:[registrar messenger]];
    MobilepayAppswitchPlugin* instance = [[MobilepayAppswitchPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

static FlutterResult currentResult = nil;
static MobilePayCountry *mobilePayCountry = nil;

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSDictionary *countryMap = @{
                                 @"DENMARK" : [NSNumber numberWithInt:MobilePayCountry_Denmark],
                                 @"NORWAY" : [NSNumber numberWithInt:MobilePayCountry_Norway],
                                 @"FINLAND" : [NSNumber numberWithInt:MobilePayCountry_Finland]
                                 };
    
    NSString *method = [call method];
    NSDictionary *arguments = [call arguments];
    
    if ([method isEqualToString:@"getPlatformVersion"]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    }
    else if ([method isEqualToString:@"init"]) {
        NSString *merchantId = arguments[@"merchantId"];
        NSString *countryString = arguments[@"country"];
        NSString *merchantUrlScheme = arguments[@"urlScheme"];
        MobilePayCountry country = [[countryMap valueForKey:countryString] intValue];
        mobilePayCountry = &country;
        
        [[MobilePayManager sharedInstance] setupWithMerchantId:merchantId merchantUrlScheme:merchantUrlScheme country:country];
        
        result(@YES);
    } else if ([method isEqualToString:@"makePayment"]) {
        NSString *orderId = arguments[@"orderId"];
        float price = [arguments[@"price"] floatValue];
        
        MobilePayPayment *payment = [[MobilePayPayment alloc] initWithOrderId:orderId productPrice:price];
        
        if (payment && (payment.orderId.length > 0) && (payment.productPrice >= 0)) {
            currentResult = result;
            [[MobilePayManager sharedInstance]beginMobilePaymentWithPayment:payment error:^(NSError * _Nonnull error) {
                result([FlutterError errorWithCode:[@([error code]) stringValue] message:[error localizedDescription] details:[error localizedFailureReason]]);
            }];
        }
    } else if ([method isEqualToString:@"appInstalled"]) {
        result(@([[MobilePayManager sharedInstance] isMobilePayInstalled:*mobilePayCountry]));
    } else {
        result(FlutterMethodNotImplemented);
    }
}

+ (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [MobilepayAppswitchPlugin handleMobilePayPaymentWithUrl:url];
}

+ (BOOL)handleMobilePayPaymentWithUrl:(NSURL *)url {
    [[MobilePayManager sharedInstance] handleMobilePayPaymentWithUrl:url success:^(MobilePaySuccessfulPayment * _Nullable mobilePaySuccessfulPayment) {
        NSString *orderId = mobilePaySuccessfulPayment.orderId;
        NSString *transactionId = mobilePaySuccessfulPayment.transactionId;
        NSString *signature = mobilePaySuccessfulPayment.signature;
        NSString *amountWithdrawnFromCard = [NSString stringWithFormat:@"%f",mobilePaySuccessfulPayment.amountWithdrawnFromCard];
        currentResult([NSString stringWithFormat:@"{\"amountWithdrawnFromCard\": %@, \"orderId\": \"%@\", \"signature\": \"%@\",\"transactionId\": \"%@\"}", amountWithdrawnFromCard, orderId, signature, transactionId]);
    } error:^(NSError * _Nonnull error) {
        NSString *errorCode = [NSString stringWithFormat:@"%ld", [error code]];
        currentResult([FlutterError errorWithCode:errorCode message:[error localizedDescription] details:error]);
    } cancel:^(MobilePayCancelledPayment * _Nullable mobilePayCancelledPayment) {
        currentResult([FlutterError errorWithCode:@"100" message:@"Order cancelled" details:mobilePayCancelledPayment]);
    }];
    return YES;
}

@end
