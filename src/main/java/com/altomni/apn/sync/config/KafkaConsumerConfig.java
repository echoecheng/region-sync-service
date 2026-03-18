package com.altomni.apn.sync.config;

import com.altomni.apn.sync.consumer.GenericCdcConsumer;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.boot.autoconfigure.kafka.KafkaProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;
import org.springframework.kafka.listener.ConcurrentMessageListenerContainer;
import org.springframework.kafka.listener.ContainerProperties;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Configuration
public class KafkaConsumerConfig {

    private final KafkaProperties kafkaProperties;
    private final RegionSyncProperties syncProperties;
    private final GenericCdcConsumer genericCdcConsumer;

    public KafkaConsumerConfig(KafkaProperties kafkaProperties,
                               RegionSyncProperties syncProperties,
                               GenericCdcConsumer genericCdcConsumer) {
        this.kafkaProperties = kafkaProperties;
        this.syncProperties = syncProperties;
        this.genericCdcConsumer = genericCdcConsumer;
    }

    @Bean
    public ConsumerFactory<String, String> consumerFactory() {
        Map<String, Object> props = new HashMap<>(kafkaProperties.buildConsumerProperties());
        props.put(ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        props.put(ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
        return new DefaultKafkaConsumerFactory<>(props);
    }

    /**
     * 根据 region-sync.sync-tables 配置，动态创建一个 Listener Container，
     * 订阅所有远端区域的 CDC topic（每张表一个 topic）。
     *
     * topic 命名规则: {topicPrefix}{tableName}
     * 例如 NA 消费 EU 的数据: eu.apn_eu.talent, eu.apn_eu.talent_contact ...
     */
    @Bean
    public ConcurrentMessageListenerContainer<String, String> regionSyncListenerContainer() {
        List<String> topics = syncProperties.getSyncTables().stream()
                .map(table -> syncProperties.getTopicPrefix() + table)
                .collect(Collectors.toList());

        log.info("[RegionSync] Local region: {}, subscribing to {} CDC topics from remote region {}",
                syncProperties.getLocalRegion(), topics.size(), syncProperties.getRemoteRegion());
        topics.forEach(t -> log.info("[RegionSync]   topic: {}", t));

        ContainerProperties containerProps = new ContainerProperties(topics.toArray(new String[0]));
        containerProps.setMessageListener(genericCdcConsumer);
        containerProps.setAckMode(ContainerProperties.AckMode.RECORD);
        containerProps.setGroupId(kafkaProperties.getConsumer().getGroupId());

        ConcurrentMessageListenerContainer<String, String> container =
                new ConcurrentMessageListenerContainer<>(consumerFactory(), containerProps);

        container.setConcurrency(Math.min(topics.size(), 10));
        container.setAutoStartup(true);

        return container;
    }
}
