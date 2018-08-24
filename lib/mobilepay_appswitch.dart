import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

enum Country { DENMARK, NORWAY, FINLAND }

/* 
 * Check out https://github.com/MobilePayDev/MobilePay-AppSwitch-SDK
 * for how to handle these errors
*/
enum MobilePayErrorTypes {
  INVALID_PARAMETERS,
  VALIDATE_MERCHANT_REQUEST_FAIL,
  MOBILEPAY_APP_OUT_OF_DATE,
  INVALID_MERCHANT_ID,
  INVALID_HMAC_PARAMETER,
  MOBILEPAY_TIMEOUT,
  MOBILEPAY_USER_LIMIT_EXCEEDED,
  MERCHANT_APP_TIMEOUT_EXCEEDED,
  INVALID_SIGNATURE,
  APPSWITCH_SDK_OUT_OF_DATE,
  ORDER_ID_ALREADY_USED,
  MOBILEPAY_USER_FRAUD_SCREENING,
  /* Custom error, not MobilePay official */
  TRANSACTION_CANCELLED
}

Map<String, MobilePayErrorTypes> errorTypeMap = {
  "0": MobilePayErrorTypes.TRANSACTION_CANCELLED,
  "1": MobilePayErrorTypes.INVALID_PARAMETERS,
  "2": MobilePayErrorTypes.VALIDATE_MERCHANT_REQUEST_FAIL,
  "3": MobilePayErrorTypes.MOBILEPAY_APP_OUT_OF_DATE,
  "4": MobilePayErrorTypes.INVALID_MERCHANT_ID,
  "5": MobilePayErrorTypes.INVALID_HMAC_PARAMETER,
  "6": MobilePayErrorTypes.MOBILEPAY_TIMEOUT,
  "7": MobilePayErrorTypes.MOBILEPAY_USER_LIMIT_EXCEEDED,
  "8": MobilePayErrorTypes.MERCHANT_APP_TIMEOUT_EXCEEDED,
  "9": MobilePayErrorTypes.INVALID_SIGNATURE,
  "10": MobilePayErrorTypes.APPSWITCH_SDK_OUT_OF_DATE,
  "11": MobilePayErrorTypes.ORDER_ID_ALREADY_USED,
  "12": MobilePayErrorTypes.MOBILEPAY_USER_FRAUD_SCREENING
};

class PaymentError {
  final MobilePayErrorTypes errorType;
  final String errorCode;
  final String errorMessage;

  PaymentError({this.errorType, this.errorCode, this.errorMessage});

  factory PaymentError.fromPlatformException(PlatformException e) {
    return PaymentError(
        errorType: errorTypeMap[e.code],
        errorMessage: e.message,
        errorCode: e.code);
  }
}

class PaymentResponse {
  final double amountWithdrawnFromCard;
  final String orderId;
  final String transactionId;
  final String signature;
  final PaymentError error;

  PaymentResponse(
      {this.amountWithdrawnFromCard,
      this.orderId,
      this.transactionId,
      this.signature,
      this.error});

  bool get success {
    return this.error == null;
  }

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
        amountWithdrawnFromCard: json["amountWithdrawnFromCard"],
        orderId: json["orderId"],
        transactionId: json["transactionId"],
        signature: json["signature"]);
  }
}

class MobilepayAppswitch {
  static Map<Country, String> countryMap = {
    Country.DENMARK: 'DENMARK',
    Country.FINLAND: 'FINLAND',
    Country.NORWAY: 'NORWAY'
  };

  static const MethodChannel _channel =
      const MethodChannel('mobilepay_appswitch');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> init(
      {String merchantId,
      Country country = Country.DENMARK,
      String urlScheme = ''}) async {
    await _channel.invokeMethod('init', <String, dynamic>{
      'merchantId': merchantId,
      'urlScheme': urlScheme,
      'country': countryMap[country]
    });
  }

  static Future<PaymentResponse> makePayment(
      {String orderId, double price}) async {
    try {
      final dynamic result = await _channel.invokeMethod(
          'makePayment', <String, dynamic>{'orderId': orderId, 'price': price});

      final dynamic data = jsonDecode(result);

      return PaymentResponse.fromJson(data);
    } catch (e) {
      if (e is PlatformException) {
        return PaymentResponse(
            orderId: orderId, error: PaymentError.fromPlatformException(e));
      }

      throw e;
    }
  }
}
