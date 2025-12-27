<?php
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../auth.php';
requireClientAuth();

$repo = new WorkChunkRepository();

Response::ok([
    'counts' => $repo->getStatusCounts(),
]);
