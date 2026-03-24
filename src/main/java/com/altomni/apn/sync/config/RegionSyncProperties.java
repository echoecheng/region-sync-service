package com.altomni.apn.sync.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Data
@Component
@ConfigurationProperties(prefix = "region-sync")
public class RegionSyncProperties {

    /**
     * 当前部署所在区域，如 NA / EU
     */
    private String localRegion;

    /**
     * 对端区域，如 EU / NA
     */
    private String remoteRegion;

    /**
     * Kafka topic 前缀，用于订阅远端 CDC topic
     * 例如部署在 NA 时，消费 EU 的 topic，前缀为 "eu.apn_eu."
     */
    private String topicPrefix;

    /**
     * 本地目标数据库 schema 名称
     */
    private String targetDatabase;

    /**
     * 冲突时优先的区域（时间戳相同时以此区域为准）
     */
    private String priorityRegion = "NA";

    /**
     * 需要同步的表名列表，每张表对应一个 Kafka topic
     */
    private List<String> syncTables;

    /**
     * 冲突检测使用的时间戳字段名（全局默认值）
     */
    private String timestampColumn = "updated_at";

    /**
     * 主键字段名（全局默认值）
     */
    private String primaryKeyColumn = "id";

    /**
     * 全局排除的字段列表（不参与同步写入）
     */
    private List<String> excludeColumns = List.of();

    /**
     * 特殊表的覆盖配置（主键、时间戳字段等不同于默认值的表）
     */
    private Map<String, TableOverride> tableOverrides = new HashMap<>();

    @Data
    public static class TableOverride {
        private String primaryKeyColumn;
        private String timestampColumn;
        private List<String> excludeColumns;
    }

    public String getPrimaryKeyColumn(String tableName) {
        TableOverride override = tableOverrides.get(tableName);
        return (override != null && override.getPrimaryKeyColumn() != null)
                ? override.getPrimaryKeyColumn() : primaryKeyColumn;
    }

    public String getTimestampColumn(String tableName) {
        TableOverride override = tableOverrides.get(tableName);
        return (override != null && override.getTimestampColumn() != null)
                ? override.getTimestampColumn() : timestampColumn;
    }

    public List<String> getExcludeColumns(String tableName) {
        TableOverride override = tableOverrides.get(tableName);
        return (override != null && override.getExcludeColumns() != null)
                ? override.getExcludeColumns() : excludeColumns;
    }
}
