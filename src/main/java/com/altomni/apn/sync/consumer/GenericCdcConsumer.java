package com.altomni.apn.sync.consumer;

import com.altomni.apn.sync.config.RegionSyncProperties;
import com.altomni.apn.sync.service.GenericSyncService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.kafka.listener.MessageListener;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
public class GenericCdcConsumer implements MessageListener<String, String> {

    private static final ObjectMapper MAPPER = new ObjectMapper();
    private static final TypeReference<Map<String, Object>> MAP_TYPE = new TypeReference<>() {};

    private final RegionSyncProperties syncProperties;
    private final GenericSyncService syncService;

    public GenericCdcConsumer(RegionSyncProperties syncProperties, GenericSyncService syncService) {
        this.syncProperties = syncProperties;
        this.syncService = syncService;
    }

    @SuppressWarnings("unchecked")
    @Override
    public void onMessage(ConsumerRecord<String, String> record) {
        String tableName = extractTableName(record.topic());
        try {
            if (record.value() == null) {
                log.debug("[{}] Tombstone record, topic={}, offset={}", tableName, record.topic(), record.offset());
                return;
            }

            Map<String, Object> raw = MAPPER.readValue(record.value(), MAP_TYPE);

            // Debezium JsonConverter with schemas.enable=true wraps in {schema, payload}
            Map<String, Object> envelope = raw.containsKey("payload")
                    ? (Map<String, Object>) raw.get("payload")
                    : raw;

            String op = (String) envelope.get("op");
            if (op == null) {
                log.debug("[{}] No 'op' field, skipping: topic={}, offset={}", tableName, record.topic(), record.offset());
                return;
            }

            log.info("[{}] CDC event: op={}, topic={}, partition={}, offset={}",
                    tableName, op, record.topic(), record.partition(), record.offset());

            switch (op) {
                case "d":
                    syncService.handleDelete(envelope, tableName);
                    break;
                case "c":
                case "u":
                case "r":
                    syncService.handleUpsert(envelope, tableName, op);
                    break;
                default:
                    log.debug("[{}] Ignoring CDC op={}", tableName, op);
            }
        } catch (Exception e) {
            log.error("[{}] Failed to process CDC event: topic={}, partition={}, offset={}",
                    tableName, record.topic(), record.partition(), record.offset(), e);
        }
    }

    /**
     * 从 topic 名中提取表名。
     * topic 格式: {topicPrefix}{tableName}
     * 例如: "eu.apn_eu.talent_contact" -> "talent_contact"
     */
    private String extractTableName(String topic) {
        String prefix = syncProperties.getTopicPrefix();
        if (topic.startsWith(prefix)) {
            return topic.substring(prefix.length());
        }
        int lastDot = topic.lastIndexOf('.');
        return lastDot >= 0 ? topic.substring(lastDot + 1) : topic;
    }
}
