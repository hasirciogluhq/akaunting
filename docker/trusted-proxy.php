<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Trusted Proxies
    |--------------------------------------------------------------------------
    |
    | The trusted proxies setting is used to identify proxies that should
    | be trusted when determining the client's IP address. This is useful
    | when your application is behind a proxy like Cloudflare.
    |
    */

    'proxies' => '*', // Trust all proxies

    /*
    |--------------------------------------------------------------------------
    | Trusted Headers
    |--------------------------------------------------------------------------
    |
    | The trusted headers setting is used to specify which headers should
    | be trusted when determining the client's IP address and protocol.
    |
    */

    // Disabled, the default value will be used
    // 'headers' => [
    //     \Illuminate\Http\Request::HEADER_FORWARDED => 'FORWARDED',
    //     \Illuminate\Http\Request::HEADER_CLIENT_IP => 'X_FORWARDED_FOR',
    //     \Illuminate\Http\Request::HEADER_CLIENT_HOST => 'X_FORWARDED_HOST',
    //     \Illuminate\Http\Request::HEADER_CLIENT_PROTO => 'X_FORWARDED_PROTO',
    //     \Illuminate\Http\Request::HEADER_CLIENT_PORT => 'X_FORWARDED_PORT',
    // ],
];
