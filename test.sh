kubectl run netcat-test --image=busybox -it --rm -- /bin/sh -c "echo '<165>Feb 06 13:44:35 TEST_HOST My_test_message_123' | nc -u -w1 syslog-service 514"
otelcol.processor.transform "fix_logs" {
  error_mode = "ignore"

  // БЛОК 1: ЗАПОЛНЯЕМ ШАПКУ (Resource Context)
  // Это уберет прочерки в начале строки. Экспортер смотрит только сюда!
  log_statements {
    context = "resource"
    statements = [
      // Жестко задаем хост и имя программы, чтобы исключить ошибки переменных
      "set(attributes[\"host.name\"], \"k8s-fixed-node\")",
      "set(attributes[\"service.name\"], \"my-fixed-app\")",
    ]
  }

  // БЛОК 2: ЗАПОЛНЯЕМ ТЕЛО И ID (Log Context)
  log_statements {
    context = "log"
    statements = [
      // ProcID - это свойство лога
      "set(attributes[\"proc_id\"], \"1\")",

      // ГЛАВНОЕ: Если Body вдруг пустое, пишем туда текст
      // В твоем логе (скрин 3) текст уже есть, но на всякий случай:
      "set(body, \"DEBUG: MESSAGE BODY WAS NIL\") where body == nil",
    ]
  }

  output {
    logs = [
        otelcol.exporter.syslog.arcsight_debug.input,
        otelcol.exporter.debug.inspector.input, // Чтобы ты видел в UI результат
    ]
  }
}
