<?php
require_once __DIR__ . '/../bootstrap.php';

try {
    if (!isset($_GET['id'])) {
        http_response_code(400);
        echo "missing id";
        exit;
    }

    $id = (int)$_GET['id'];

    $repo = new WorkChunkRepository();
    $res = $repo->getResultById($id);

    if (!$res['ok']) {
        if ($res['error'] === 'not found') {
            http_response_code(404);
            echo "not found";
        } elseif ($res['error'] === 'not ready') {
            http_response_code(409);
            echo "not ready";
        } else {
            http_response_code(500);
            echo $res['error'];
        }
        exit;
    }

    // Success path: raw binary output
    $blob = $res['blob'];
    $updatedAt = strtotime($res['updatedAt']);

    header('Content-Type: application/octet-stream');
    header('Content-Length: ' . strlen($blob));
    header('Last-Modified: ' . gmdate('D, d M Y H:i:s', $updatedAt) . ' GMT');
    header('X-Chunk-Id: ' . $id);

    echo $blob;

} catch (Throwable $e) {
    http_response_code(500);
    echo "internal error";
}
