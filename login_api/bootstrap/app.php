<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;

return tap(
    Application::configure(basePath: dirname(__DIR__))
        ->withRouting(
            web: __DIR__ . '/../routes/web.php',
            api: __DIR__ . '/../routes/api.php',
            commands: __DIR__ . '/../routes/console.php',
            health: '/up',
        )
        ->withMiddleware(function (Middleware $middleware): void {
            //
        })
        ->withExceptions(function (Exceptions $exceptions): void {
            //
        })
        ->create(),
    function (Application $app): void {
        $publicPath = base_path(is_dir(base_path('public_html')) ? 'public_html' : 'public');
        $app->usePublicPath($publicPath);
    }
);
