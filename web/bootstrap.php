<?php
declare(strict_types=1);

error_reporting(E_ALL);
ini_set('display_errors', '0');

require_once __DIR__ . '/lib/Config.php';
require_once __DIR__ . '/lib/Db.php';
require_once __DIR__ . '/lib/Auth.php';
require_once __DIR__ . '/lib/Response.php';
require_once __DIR__ . '/lib/WorkChunkRepository.php';
require_once __DIR__ . '/lib/Validation.php';

set_exception_handler(function (Throwable $e) {
    Response::error('internal error', 500);
});
