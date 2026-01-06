<?php
require_once __DIR__ . '/../bootstrap.php';

header('Content-Type: text/plain; charset=utf-8');

try {

    $afterId = isset($_GET['afterId']) ? intval($_GET['afterId']) : 0;
    $limit   = isset($_GET['limit'])   ? intval($_GET['limit'])   : 500;

    if ($limit <= 0 || $limit > 5000) {
        $limit = 500;
    }

    $db = Db::get();

    $stmt = $db->prepare(
        "SELECT
            id,
            updatedAt,
            detailsBlob
         FROM Details
         WHERE status = 'done'
           AND id > :afterId
         ORDER BY id
         LIMIT :limit"
    );

    $stmt->bindValue(':afterId', $afterId, PDO::PARAM_INT);
    $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
    $stmt->execute();

    echo "{ ok = true, items = {\n";

    $first = true;

    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!$first) {
            echo ",\n";
        }
        $first = false;

        $b64 = base64_encode($row['detailsBlob']);

        echo "  { "
            . "id = " . (int)$row['id'] . ", "
            . "updatedAt = " . var_export($row['updatedAt'], true) . ", "
            . "resultB64 = " . var_export($b64, true)
            . " }";
    }

    echo "\n} }";

} catch (Throwable $e) {
    echo "{ ok = false, error = " . var_export($e->getMessage(), true) . " }";
}
