<?php
final class Response
{
    public static function ok(array $data = []): void
    {
        self::send(['ok' => true] + $data, 200);
    }

    public static function error(string $msg, int $code = 400): void
    {
        self::send(['ok' => false, 'error' => $msg], $code);
    }

    private static function send(array $data, int $httpCode): void
    {
        http_response_code($httpCode);
        header('Content-Type: text/plain; charset=utf-8');
        echo self::toLua($data);
        exit;
    }

    private static function toLua($value): string
    {
        if (is_array($value)) {
            $items = [];
            foreach ($value as $k => $v) {
                $items[] = self::luaKey($k) . ' = ' . self::toLua($v);
            }
            return '{ ' . implode(', ', $items) . ' }';
        }

        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }

        if (is_numeric($value)) {
            return (string)$value;
        }

        return '"' . addcslashes((string)$value, "\\\"\n\r\t") . '"';
    }

    private static function luaKey($k): string
    {
        return is_int($k) ? '[' . $k . ']' : $k;
    }
}
