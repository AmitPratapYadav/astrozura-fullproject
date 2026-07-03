<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class OrderInvoiceController extends Controller
{
    public function userShow(Request $request, Order $order)
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 403);

        return response()->json([
            'status' => 'success',
            'data' => $order->load(['items.product', 'items.variant']),
        ]);
    }

    public function userInvoice(Request $request, Order $order)
    {
        abort_unless((int) $order->user_id === (int) $request->user()->id, 403);
        return $this->download($order);
    }

    public function adminShow(Request $request, Order $order)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        return response()->json([
            'status' => 'success',
            'data' => $order->load(['user', 'items.product', 'items.variant']),
        ]);
    }

    public function adminInvoice(Request $request, Order $order)
    {
        abort_unless($request->user()?->role === 'admin', 403);
        return $this->download($order);
    }

    private function download(Order $order)
    {
        $order->loadMissing(['user', 'items.product', 'items.variant']);
        $pdf = Pdf::loadView('invoices.order', ['order' => $order])
            ->setPaper('a4');

        return $pdf->download("{$order->order_number}-invoice.pdf");
    }
}
