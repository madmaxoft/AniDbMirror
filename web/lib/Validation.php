<?php
final class Validation
{
    public static function requirePostJson(): array
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            Response::error('POST required', 405);
        }

        $raw = file_get_contents('php://input');
        if ($raw === false || $raw === '') {
            Response::error('empty body');
        }

        $data = json_decode($raw, true);
        if (!is_array($data)) {
            Response::error('invalid json');
        }

        return $data;
    }
}
