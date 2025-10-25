<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\URL;

class TrustedProxyMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse)  $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, Closure $next)
    {
        // Tüm proxy'lere güven - Docker container için
        $request->setTrustedProxies('*', [
            \Illuminate\Http\Request::HEADER_FORWARDED => 'FORWARDED',
            \Illuminate\Http\Request::HEADER_CLIENT_IP => 'X_FORWARDED_FOR',
            \Illuminate\Http\Request::HEADER_CLIENT_HOST => 'X_FORWARDED_HOST',
            \Illuminate\Http\Request::HEADER_CLIENT_PROTO => 'X_FORWARDED_PROTO',
            \Illuminate\Http\Request::HEADER_CLIENT_PORT => 'X_FORWARDED_PORT',
        ]);

        // HTTPS zorla - Proxy'den gelen istekler için
        if ($request->header('X-Forwarded-Proto') === 'https' || 
            $request->header('X-Forwarded-For') || 
            $request->header('X-Real-IP')) {
            $request->server->set('HTTPS', 'on');
            $request->server->set('SERVER_PORT', 443);
            URL::forceScheme('https');
        }

        // Host bilgisini proxy'den al
        if ($request->header('X-Forwarded-Host')) {
            $request->server->set('HTTP_HOST', $request->header('X-Forwarded-Host'));
        }

        // Port bilgisini proxy'den al
        if ($request->header('X-Forwarded-Port')) {
            $request->server->set('SERVER_PORT', $request->header('X-Forwarded-Port'));
        }

        return $next($request);
    }
}
