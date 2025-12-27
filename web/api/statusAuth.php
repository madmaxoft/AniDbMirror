<?php
require_once __DIR__ . '/../bootstrap.php';
require_once __DIR__ . '/../lib/Auth.php';
requireClientAuth();

$repo = new WorkChunkRepository();

Response::ok([
    'counts' => $repo->getStatusCounts(),
]);
