<?php
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../auth.php';
requireClientAuth();

header('Content-Type: text/plain; charset=utf-8');

try {

    $clientIp = $_SERVER['REMOTE_ADDR'];
    $clientName = isset($_SERVER['HTTP_CLIENT_NAME']) ? $_SERVER['HTTP_CLIENT_NAME'] : null;

    $id = isset($_POST['id']) ? intval($_POST['id']) : null;
    $detailsBlobB64 = isset($_POST['detailsBlobB64']) ? $_POST['detailsBlobB64'] : '';
    $lastMod = isset($_POST['lastMod']) ? $_POST['lastMod'] : null;

    if (!$id || $detailsBlobB64 === '') {
        echo "{ ok = false, error = 'missing parameters' }";
        exit;
    }

    // Decode Base64 blob
    $decodedBlob = base64_decode($detailsBlobB64, true);
    if ($decodedBlob === false) {
        echo "{ ok = false, error = 'invalid base64 data' }";
        exit;
    }

    // Parse lastMod if present
    if ($lastMod !== null && ctype_digit($lastMod)) {
        $updatedAt = date('Y-m-d H:i:s', (int)$lastMod);
    } else {
        $updatedAt = date('Y-m-d H:i:s');
    }

    $repo = new WorkChunkRepository();
    $result = $repo->submitResult(
        (int)$id,
        $clientIp,
        $clientName,
        $decodedBlob,
        $updatedAt
    );

    if (!$result['ok']) {
        echo "{ ok = false, error = " . var_export($result['error'], true) . " }";
        exit;
    }

    echo "{ ok = true }";

} catch (Throwable $e) {
    echo "{ ok = false, error = " . var_export($e->getMessage(), true) . " }";
}
