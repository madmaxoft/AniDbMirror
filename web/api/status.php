<?php
require_once __DIR__ . '/../bootstrap.php';

$repo = new WorkChunkRepository();

Response::ok([
    'counts' => $repo->getStatusCounts(),
]);
