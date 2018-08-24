import 'package:flutter/material.dart';
import 'package:mobilepay_appswitch/mobilepay_appswitch.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  initState() {
    super.initState();
    initAppSwitch();
  }

  initAppSwitch() async {
    await MobilepayAppswitch.init(
      merchantId: "APPDK0000000000", 
      country: Country.DENMARK,
      urlScheme: 'mobilepayappswitchexample');
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(home: PaymentTest());
  }
}

class PaymentTest extends StatelessWidget {
  makePayment(BuildContext context, double price) async {
    PaymentResponse paymentResponse =
        await MobilepayAppswitch.makePayment(orderId: "TESTINGS_ID", price: price);

    if (paymentResponse.success) {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                content: Text("yay"),
                title: Text("Payment successful"),
              ));
    } else {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text("Failed to complete payment"),
                content: Text(paymentResponse.error.errorMessage),
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text('Plugin example app'),
      ),
      body: new Center(
        child: RaisedButton(
            onPressed: () => makePayment(context, 10.0),
            child: Text("Make payment")),
      ),
    );
  }
}
