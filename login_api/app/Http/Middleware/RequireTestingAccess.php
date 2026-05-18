<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RequireTestingAccess
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! config('app.test_access_enabled')) {
            return $next($request);
        }

        if ($request->isMethod('OPTIONS')) {
            return $next($request);
        }

        if ($request->is('api/auth/google', 'api/auth/google/callback')) {
            return $next($request);
        }

        $expected = (string) config('app.test_access_password');
        $provided = (string) $request->header('X-Astrozura-Test-Password', '');

        if ($expected !== '' && hash_equals($expected, $provided)) {
            return $next($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'Testing access password required.',
        ], 423);
    }
}
