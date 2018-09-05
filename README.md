# Flutter plugin for MobilePay AppSwitch SDK

This is an unofficial Flutter plugin wrapping the MobilePay AppSwitch libraries for iOS and Android to enable Flutter apps to use the MobilePay AppSwitch SDK.

> This plugin is not developed, published or otherwise affiliated with Danske Bank or MobilePay, but is a private project released "as-is" to the public by the author.  

## iOS

For iOS support add the following to your `info.plist`. Replace  `mobilepayappswitchexample` with your own URL Scheme.

```xml
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>mobilepayappswitchexample</string>
        </array>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    </dict>
</array>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>mobilepay</string>
    <string>mobilepayno</string>
    <string>mobilepayfi</string>
</array>
```

## Limitations

Some pararmeters are not supported like accepted url. But the essentials should work well.

And iOS is not supported... yet.
