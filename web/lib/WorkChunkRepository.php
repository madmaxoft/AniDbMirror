<?php
final class WorkChunkRepository
{
    private PDO $db;
    private int $timeout;

    public function __construct()
    {
        $this->db = Db::get();
        $this->timeout = Config::get()['reservationTimeoutSeconds'];
    }

    public function reserveNextChunk(string $clientIp, ?string $clientName): ?int
    {
        $this->db->beginTransaction();

        $stmt = $this->db->prepare(
            "SELECT id FROM Details
             WHERE status = 'pending'
                OR (status = 'reserved' AND reservedAt < NOW() - INTERVAL :t SECOND)
             ORDER BY id DESC
             LIMIT 1
             FOR UPDATE"
        );
        $stmt->execute([':t' => $this->timeout]);
        $row = $stmt->fetch();

        if (!$row) {
            $this->db->rollBack();
            return null;
        }

        $upd = $this->db->prepare(
            "UPDATE Details
             SET status='reserved', reservedByIp=:ci, reservedByName=:cn, reservedAt=NOW()
             WHERE id=:id"
        );
        $upd->execute([
            ':ci' => $clientIp,
			':cn' => $clientName,
            ':id' => $row['id'],
        ]);

        $this->db->commit();
        return (int)$row['id'];
    }





    public function submitResult(
        int $id,
        string $clientIp,
        ?string $clientName,
        string $detailsBlob,
        string $updatedAt
    ): array {
        try {
            $stmt = $this->db->prepare(
                "UPDATE Details
                SET status = 'done',
                    detailsBlob = :blob,
                    updatedAt = :updatedAt,
                    reservedByIp = :ip,
                    reservedByName = :cname
                WHERE id = :id
                AND (
                        updatedAt IS NULL
                        OR updatedAt <= :updatedAt
                    )"
            );

            $stmt->execute([
                ':blob' => $detailsBlob,
                ':updatedAt' => $updatedAt,
                ':id' => $id,
                ':ip' => $clientIp,
                ':cname' => $clientName
            ]);

            return ['ok' => true];

        } catch (PDOException $e) {
            return [
                'ok' => false,
                'error' => 'database error: ' . $e->getMessage(),
            ];
        }
    }





    public function getStatusCounts(): array
    {
        $stmt = $this->db->query(
            "SELECT status, COUNT(*) c FROM Details GROUP BY status"
        );
        $out = ['pending'=>0,'reserved'=>0,'done'=>0];
        foreach ($stmt as $r) {
            $out[$r['status']] = (int)$r['c'];
        }
        return $out;
    }





    public function getResultById(int $id): array
    {
        try {
            $stmt = $this->db->prepare(
                "SELECT status, detailsBlob, updatedAt
                FROM Details
                WHERE id = :id"
            );
            $stmt->execute([':id' => $id]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            if (!$row) {
                return ['ok' => false, 'error' => 'not found'];
            }

            if ($row['status'] !== 'done' || $row['detailsBlob'] === null) {
                return ['ok' => false, 'error' => 'not ready'];
            }

            return [
                'ok' => true,
                'blob' => $row['detailsBlob'],
                'updatedAt' => $row['updatedAt'],
            ];

        } catch (PDOException $e) {
            return [
                'ok' => false,
                'error' => 'database error: ' . $e->getMessage(),
            ];
        }
    }
}
