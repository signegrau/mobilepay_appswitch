package dk.grauit.mobilepayappswitch

import android.app.Activity
import android.content.Context
import dk.danskebank.mobilepay.sdk.Country
import dk.danskebank.mobilepay.sdk.MobilePay
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.math.BigDecimal
import android.content.Intent
import android.os.Bundle
import dk.danskebank.mobilepay.sdk.model.Payment
import io.flutter.app.FlutterActivity
import dk.danskebank.mobilepay.sdk.model.FailureResult
import dk.danskebank.mobilepay.sdk.model.SuccessResult
import android.R.attr.data
import android.util.Base64
import dk.danskebank.mobilepay.sdk.CaptureType
import dk.danskebank.mobilepay.sdk.ResultCallback
import java.util.*


class MobilepayAppswitchPlugin(private val mRegistrar: Registrar) : MethodCallHandler {
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar): Unit {
      val channel = MethodChannel(registrar.messenger(), "mobilepay_appswitch")
      channel.setMethodCallHandler(MobilepayAppswitchPlugin(registrar))
    }
  }

  var latestRequestCode = 1000

  val requestMap: MutableMap<Int, Result> = mutableMapOf()

  init {
    mRegistrar.addActivityResultListener { requestCode: Int, resultCode: Int, data: Intent? ->
      if (requestMap.containsKey(requestCode)) {
        // The request code matches our MobilePay Intent
        MobilePay.getInstance().handleResult(resultCode, data, object : ResultCallback {
          override fun onSuccess(result: SuccessResult) {
            requestMap[requestCode]?.success("""{
              |"amountWithdrawnFromCard": ${result.amountWithdrawnFromCard},
              |"orderId": "${result.orderId}",
              |"signature": "${result.signature}",
              |"transactionId": "${result.transactionId}"
              |}""".trimMargin())
          }

          override fun onFailure(result: FailureResult) {
            // The payment failed - show an appropriate error message to the user. Consult the MobilePay class documentation for possible error codes.
            requestMap[requestCode]?.error(result.errorCode.toString(), result.errorMessage, result.orderId)
          }

          override fun onCancel() {
            requestMap[requestCode]?.error("0", "Order cancelled", null)
          }
        })
      }

      true
    }
  }

  private fun getActiveContext(): Context {
    return if (mRegistrar.activity() != null) mRegistrar.activity() else mRegistrar.context()
  }

  private val countryMap: Map<String, Country> = hashMapOf(
          "DENMARK" to Country.DENMARK,
          "NORWAY" to Country.NORWAY,
          "FINLAND" to Country.FINLAND)

  override fun onMethodCall(call: MethodCall, result: Result): Unit {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "init" -> {
        val country = countryMap[call.argument<String>("country")]
        val merchantId = call.argument<String>("merchantId")
        if (country == null) {
          result.error("Invalid country", "Country is invalid", call.argument<String>("country"))
        } else if (merchantId == null) {
          result.error("Invalid merchant id", "Merchant id is invalid", call.argument<String>("merchantId"))
        } else {
          init(merchantId, country)
          result.success("Success")
        }
      }
      "makePayment" -> {
        val orderId = call.argument<String>("orderId")!!
        val price = BigDecimal(call.argument<Double>("price")!!)
        val captureType = call.argument<String?>("captureType")

        makePayment(orderId, price,captureType ?: "Y", result)
      }
      else -> result.notImplemented()
    }
  }

  fun init(merchantId: String, country: Country = Country.DENMARK) {
    MobilePay.getInstance().init(merchantId, country)
  }

  fun makePayment(orderId: String, price: BigDecimal, captureType: String, result: Result) {
    latestRequestCode++

    requestMap[latestRequestCode] = result

    val captureType = when(captureType) {
      "Y" -> CaptureType.CAPTURE
      "N" -> CaptureType.RESERVE
      "P" -> CaptureType.RESERVE
      else -> CaptureType.CAPTURE
    }

    MobilePay.getInstance().captureType = captureType

    val context = getActiveContext()

    // Check if the MobilePay app is installed on the device.
    val isMobilePayInstalled = MobilePay.getInstance().isMobilePayInstalled(context)

    if (isMobilePayInstalled) {
      // MobilePay is present on the system. Create a Payment object.
      val payment = Payment()
      payment.productPrice = price
      payment.orderId = orderId

      // Create a payment Intent using the Payment object from above.
      val paymentIntent = MobilePay.getInstance().createPaymentIntent(payment)

      // We now jump to MobilePay to complete the transaction. Start MobilePay and wait for the result using an unique result code of your choice.
      mRegistrar.activity().startActivityForResult(paymentIntent, latestRequestCode)

    } else {
      // MobilePay is not installed. Use the SDK to create an Intent to take the user to Google Play and download MobilePay.
      val intent = MobilePay.getInstance().createDownloadMobilePayIntent(context)
      context.startActivity(intent)
    }
  }
}
