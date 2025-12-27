<?php
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../auth.php';
requireClientAuth();

header('Content-Type: text/plain; charset=utf-8');

try {

    $clientIp = $_SERVER['REMOTE_ADDR'];
    $clientName = isset($_SERVER['HTTP_CLIENT_NAME']) ? $_SERVER['HTTP_CLIENT_NAME'] : null;

    $repo = new WorkChunkRepository();
    $id = $repo->reserveNextChunk($clientIp, $clientName);

    if ($id === null) {
        Response::ok(['available' => false]);
        exit;
    }

    Response::ok([
        'available' => true,
        'id' => $id,
    ]);

} catch (Throwable $e) {
    // Output error as Lua table so client can see it
    echo "{ ok = false, error = " . var_export($e->getMessage(), true) . " }";
}
