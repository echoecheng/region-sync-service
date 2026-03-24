package com.altomni.apn.sync.service;

import com.altomni.apn.sync.config.RegionSyncProperties;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.annotation.PostConstruct;
import java.sql.Timestamp;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class GenericSyncService {

    private final JdbcTemplate jdbcTemplate;
    private final RegionSyncProperties syncProperties;

    public GenericSyncService(JdbcTemplate jdbcTemplate, RegionSyncProperties syncProperties) {
        this.jdbcTemplate = jdbcTemplate;
        this.syncProperties = syncProperties;
    }

    @PostConstruct
    public void verifySqlLogBinDisabled() {
        try {
            jdbcTemplate.execute("SET sql_log_bin = 0");
            log.info("[AntiLoop] sql_log_bin = 0 verified at startup");
        } catch (Exception e) {
            log.error("[AntiLoop] Cannot SET sql_log_bin = 0. Sync writes will produce binlog events and may cause loops! {}", e.getMessage());
        }
    }

    /**
     * 在当前事务连接上强制关闭 binlog，防止同步写入被 CDC 再次捕获导致回环。
     * 如果设置失败则抛出异常，中止本次同步操作。
     */
    private void ensureSqlLogBinDisabled() {
        try {
            jdbcTemplate.execute("SET sql_log_bin = 0");
        } catch (Exception e) {
            throw new IllegalStateException(
                    "Failed to SET sql_log_bin = 0, aborting sync to prevent CDC loop", e);
        }
    }

    @SuppressWarnings("unchecked")
    @Transactional
    public void handleUpsert(Map<String, Object> envelope, String tableName, String op) {
        ensureSqlLogBinDisabled();

        Map<String, Object> after = (Map<String, Object>) envelope.get("after");
        if (after == null) {
            log.warn("[{}] No 'after' field in {} event", tableName, op);
            return;
        }

        String pkCol = syncProperties.getPrimaryKeyColumn(tableName);
        Object id = after.get(pkCol);
        String tsCol = syncProperties.getTimestampColumn(tableName);

        if ("u".equals(op) && after.containsKey(tsCol)) {
            if (!resolveConflict(tableName, pkCol, id, tsCol, after)) {
                return;
            }
        }

        Map<String, Object> filteredColumns = filterColumns(after, tableName);
        if (filteredColumns.isEmpty()) {
            log.warn("[{}] No columns to sync for id={}", tableName, id);
            return;
        }

        executeUpsert(tableName, pkCol, filteredColumns);
        log.info("[{}] Synced {}: id={}, columns={}", tableName, op, id, filteredColumns.size());
    }

    @SuppressWarnings("unchecked")
    @Transactional
    public void handleDelete(Map<String, Object> envelope, String tableName) {
        ensureSqlLogBinDisabled();

        Map<String, Object> before = (Map<String, Object>) envelope.get("before");
        if (before == null) {
            log.warn("[{}] No 'before' field in delete event", tableName);
            return;
        }

        String pkCol = syncProperties.getPrimaryKeyColumn(tableName);
        Object id = before.get(pkCol);

        String sql = String.format("DELETE FROM %s.%s WHERE %s = ?",
                syncProperties.getTargetDatabase(), tableName, pkCol);
        int affected = jdbcTemplate.update(sql, id);
        log.info("[{}] Synced delete: id={}, affected={}", tableName, id, affected);
    }

    /**
     * 冲突检测：比较本地与远端的时间戳，决定是否执行同步。
     * 返回 true 表示远端胜出（继续同步），false 表示本地胜出（跳过）。
     */
    private boolean resolveConflict(String tableName, String pkCol, Object id,
                                    String tsCol, Map<String, Object> after) {
        long remoteTs = toEpochMillis(after.get(tsCol));
        try {
            String querySql = String.format("SELECT %s FROM %s.%s WHERE %s = ?",
                    tsCol, syncProperties.getTargetDatabase(), tableName, pkCol);
            Map<String, Object> localRow = jdbcTemplate.queryForMap(querySql, id);
            long localTs = toEpochMillis(localRow.get(tsCol));

            if (localTs > remoteTs) {
                log.warn("[{}] Conflict: id={}, local_ts={} > remote_ts={}, local wins",
                        tableName, id, localTs, remoteTs);
                return false;
            }

            if (localTs == remoteTs) {
                String priority = syncProperties.getPriorityRegion();
                if (!priority.equalsIgnoreCase(syncProperties.getRemoteRegion())) {
                    log.warn("[{}] Tie-break: id={}, ts={}, {} wins -> skip",
                            tableName, id, localTs, priority);
                    return false;
                }
                log.info("[{}] Tie-break: id={}, ts={}, {} wins -> sync",
                        tableName, id, localTs, priority);
            } else {
                log.info("[{}] Conflict resolved: id={}, remote_ts={} > local_ts={}, remote wins",
                        tableName, id, remoteTs, localTs);
            }
        } catch (EmptyResultDataAccessException e) {
            log.info("[{}] Record id={} not found locally, treating update as insert", tableName, id);
        }
        return true;
    }

    /**
     * 构建并执行通用 UPSERT (INSERT ... ON DUPLICATE KEY UPDATE) SQL。
     * 所有字段从 CDC 消息中动态获取，无需为每张表硬编码。
     */
    private void executeUpsert(String tableName, String pkCol, Map<String, Object> columns) {
        List<String> columnNames = new ArrayList<>(columns.keySet());
        List<Object> values = columns.values().stream()
                .map(this::convertValue)
                .collect(Collectors.toList());

        String placeholders = columnNames.stream().map(c -> "?").collect(Collectors.joining(", "));
        String updateClause = columnNames.stream()
                .filter(c -> !c.equals(pkCol))
                .map(c -> c + " = VALUES(" + c + ")")
                .collect(Collectors.joining(", "));

        String sql = String.format("INSERT INTO %s.%s (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s",
                syncProperties.getTargetDatabase(),
                tableName,
                String.join(", ", columnNames),
                placeholders,
                updateClause);

        jdbcTemplate.update(sql, values.toArray());
    }

    private Map<String, Object> filterColumns(Map<String, Object> data, String tableName) {
        Set<String> excludes = new HashSet<>(syncProperties.getExcludeColumns(tableName));
        LinkedHashMap<String, Object> result = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entry : data.entrySet()) {
            if (!excludes.contains(entry.getKey())) {
                result.put(entry.getKey(), entry.getValue());
            }
        }
        return result;
    }

    /**
     * Debezium 时间类型转换:
     * - ZonedTimestamp (ISO 8601 string, e.g. "2026-03-17T08:25:40Z") -> java.sql.Timestamp
     * - epoch millis (long) -> java.sql.Timestamp
     * - days since epoch (int for DATE) -> java.sql.Date
     * - 其他类型直接透传
     */
    private Object convertValue(Object value) {
        if (value == null) {
            return null;
        }
        if (value instanceof String) {
            String str = (String) value;
            if (str.length() >= 20 && str.contains("T") && str.endsWith("Z")) {
                try {
                    return Timestamp.from(java.time.Instant.parse(str));
                } catch (Exception ignored) {
                }
            }
        }
        if (value instanceof Number) {
            long num = ((Number) value).longValue();
            if (num > 1_000_000_000_000L) {
                return new Timestamp(num);
            }
        }
        return value;
    }

    private long toEpochMillis(Object value) {
        if (value instanceof Number) return ((Number) value).longValue();
        if (value instanceof Timestamp) return ((Timestamp) value).getTime();
        if (value instanceof String) {
            try {
                return java.time.Instant.parse((String) value).toEpochMilli();
            } catch (Exception ignored) {
            }
        }
        return 0L;
    }
}
