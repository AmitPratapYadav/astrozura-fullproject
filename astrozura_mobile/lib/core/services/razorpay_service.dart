import '../contants/api_constants.dart';
import 'api_client.dart';

class RazorpayOrderInit {
  final String keyId;
  final String orderId;
  final int amount;
  final String currency;

  const RazorpayOrderInit({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
  });
}

class RazorpayService {
  RazorpayService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<RazorpayOrderInit> createProductOrder(int orderId) async {
    return createOrder(purpose: 'product', recordId: orderId);
  }

  Future<RazorpayOrderInit> createOrder({
    required String purpose,
    required int recordId,
  }) async {
    final data = await _api.post(
      ApiConstants.razorpayOrder,
      auth: true,
      body: {
        'purpose': purpose,
        'record_id': recordId,
      },
    );

    final order = data['order'];
    if (order is! Map) {
      throw const ApiException('Razorpay order response was invalid.');
    }

    return RazorpayOrderInit(
      keyId: data['key_id']?.toString() ?? '',
      orderId: order['id']?.toString() ?? '',
      amount: int.tryParse(order['amount']?.toString() ?? '') ?? 0,
      currency: order['currency']?.toString() ?? 'INR',
    );
  }

  Future<void> verifyProductPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return verifyPayment(
      purpose: 'product',
      recordId: orderId,
      razorpayOrderId: razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
    );
  }

  Future<void> verifyPayment({
    required String purpose,
    required int recordId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    await _api.post(
      ApiConstants.razorpayVerify,
      auth: true,
      body: {
        'purpose': purpose,
        'record_id': recordId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
  }
}
