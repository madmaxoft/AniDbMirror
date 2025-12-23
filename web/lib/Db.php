<?php
final class Db
{
    private static ?PDO $pdo = null;

    public static function get(): PDO
    {
        if (self::$pdo === null) {
            $cfg = Config::get()['db'];
            self::$pdo = new PDO(
                $cfg['dsn'],
                $cfg['user'],
                $cfg['pass'],
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
            self::$pdo->exec("SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED");
        }
        return self::$pdo;
    }
}
