<?php
final class Auth
{
    public static function requireClientId(): string
    {
        $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
        if (!preg_match('/^Bearer\s+(.+)$/', $header, $m)) {
            Response::error('missing authorization', 401);
        }

        $token = $m[1];
        if (!in_array($token, Config::get()['apiKeys'], true)) {
            Response::error('invalid authorization', 403);
        }

        return hash('sha256', $token);
    }
}
