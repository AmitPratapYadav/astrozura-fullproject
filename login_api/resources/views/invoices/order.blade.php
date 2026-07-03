<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>{{ $order->order_number }} Invoice</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; color: #1e3557; font-size: 12px; }
        .header { border-bottom: 3px solid #d4a73c; padding-bottom: 14px; margin-bottom: 20px; }
        .brand { font-size: 26px; font-weight: 700; }
        .muted { color: #667085; }
        table { width: 100%; border-collapse: collapse; margin-top: 18px; }
        th { background: #1e3557; color: white; padding: 9px; text-align: left; }
        td { padding: 9px; border-bottom: 1px solid #e5e7eb; }
        .totals { width: 42%; margin-left: auto; margin-top: 18px; }
        .totals td { border: 0; padding: 5px 8px; }
        .grand { background: #fff6d8; font-size: 14px; font-weight: 700; }
        .address { background: #f8f9fc; padding: 12px; margin-top: 12px; line-height: 1.6; }
    </style>
</head>
<body>
    <div class="header">
        <div class="brand">ASTROZURA</div>
        <div class="muted">Tarsh Astrology Solutions</div>
    </div>

    <table>
        <tr>
            <td><strong>Invoice</strong><br>{{ $order->order_number }}</td>
            <td><strong>Date</strong><br>{{ $order->created_at?->format('d M Y') }}</td>
            <td><strong>Status</strong><br>{{ ucfirst($order->status) }}</td>
            <td><strong>Payment</strong><br>{{ ucfirst($order->payment_status) }}</td>
        </tr>
    </table>

    <div class="address">
        <strong>Ship To</strong><br>
        @if($order->shipping_details)
            {{ $order->shipping_details['recipient_name'] ?? $order->user?->name }}<br>
            {{ $order->shipping_details['address_line'] ?? $order->shipping_address }},
            {{ $order->shipping_details['city'] ?? '' }},
            {{ $order->shipping_details['state'] ?? '' }}
            {{ $order->shipping_details['postal_code'] ?? '' }}<br>
            {{ $order->shipping_details['phone'] ?? $order->phone }}
        @else
            {{ $order->user?->name }}<br>{{ $order->shipping_address }}<br>{{ $order->phone }}
        @endif
    </div>

    <table>
        <thead>
            <tr><th>Item</th><th>Option</th><th>Qty</th><th>Price</th><th>Total</th></tr>
        </thead>
        <tbody>
        @foreach($order->items as $item)
            <tr>
                <td>{{ $item->product?->name ?? 'Product' }}</td>
                <td>{{ $item->variant_title ?: '-' }}</td>
                <td>{{ $item->quantity }}</td>
                <td>Rs {{ number_format((float) $item->price, 2) }}</td>
                <td>Rs {{ number_format((float) $item->price * $item->quantity, 2) }}</td>
            </tr>
        @endforeach
        </tbody>
    </table>

    <table class="totals">
        <tr><td>Subtotal</td><td>Rs {{ number_format((float) $order->subtotal_amount, 2) }}</td></tr>
        @foreach(($order->shipping_breakdown ?? []) as $shipping)
            <tr><td>Shipping: {{ $shipping['category_name'] ?? 'Category' }}</td><td>Rs {{ number_format((float) ($shipping['amount'] ?? 0), 2) }}</td></tr>
        @endforeach
        <tr><td>Tax</td><td>Rs {{ number_format((float) $order->tax_amount, 2) }}</td></tr>
        <tr class="grand"><td>Total</td><td>Rs {{ number_format((float) $order->total_amount, 2) }}</td></tr>
    </table>
</body>
</html>
