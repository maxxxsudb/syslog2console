kubectl run netcat-test --image=busybox -it --rm -- /bin/sh -c "echo '<165>Feb 06 13:44:35 TEST_HOST My_test_message_123' | nc -u -w1 syslog-service 514"
otelcol.processor.transform "fix_syslog_headers" {
  error_mode = "ignore"

  // 1. ЧИНИМ ЗАГОЛОВКИ (Resource Context)
  log_statements {
    context = "resource"
    statements = [
      // Экспортер ищет именно host.name. Если его нет - он шлет дичь.
      // Берем имя пода или ноды, или ставим заглушку
      "set(attributes[\"host.name\"], attributes[\"k8s.pod.name\"]) where attributes[\"host.name\"] == nil",
      "set(attributes[\"host.name\"], \"unknown-host\") where attributes[\"host.name\"] == nil",

      // То же самое для имени приложения (AppName)
      "set(attributes[\"service.name\"], attributes[\"k8s.container.name\"]) where attributes[\"service.name\"] == nil",
      "set(attributes[\"service.name\"], \"unknown-app\") where attributes[\"service.name\"] == nil",
      
      // На всякий случай задаем PID (PROCID)
      "set(attributes[\"proc_id\"], \"1\")",
    ]
  }

  // 2. ГАРАНТИРУЕМ ТЕЛО СООБЩЕНИЯ (Log Context)
  log_statements {
    context = "log"
    statements = [
        // Если Body вдруг пустое, но есть message в атрибутах - переносим
        "set(body, attributes[\"message\"]) where body == nil and attributes[\"message\"] != nil",
    ]
  }

  output {
    logs = [otelcol.exporter.syslog.arcsight_debug.input]
  }
}
