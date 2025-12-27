<?php
// lib/auth.php

require_once __DIR__ . '/Config.php';

/**
 * Requires client authentication using headers:
 * - Client-Name
 * - Client-Auth
 *
 * Exits with 401 if unauthorized.
 */
function requireClientAuth(): void
{
    $config = Config::get();
    $secrets = $config['clientSecrets'] ?? [];

    $clientName  = $_SERVER['HTTP_CLIENT_NAME'] ?? null;
    $clientToken = $_SERVER['HTTP_CLIENT_AUTH'] ?? null;

    if (!$clientName || !$clientToken || !isset($secrets[$clientName]) || $secrets[$clientName] !== $clientToken) {
        http_response_code(401);
        header('Content-Type: text/plain; charset=utf-8');
        echo 'unauthorized';
        exit;
    }

    // Optionally store for later use
    $GLOBALS['authClientName'] = $clientName;
}
