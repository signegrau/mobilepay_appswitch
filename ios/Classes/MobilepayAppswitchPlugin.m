#import "MobilepayAppswitchPlugin.h"
#import <mobilepay_appswitch/mobilepay_appswitch-Swift.h>

@implementation MobilepayAppswitchPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [SwiftMobilepayAppswitchPlugin registerWithRegistrar:registrar];
}
@end
