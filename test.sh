kubectl run netcat-test --image=busybox -it --rm -- /bin/sh -c "echo '<165>Feb 06 13:44:35 TEST_HOST My_test_message_123' | nc -u -w1 syslog-service 514"
log_statements {
    context = "log"
    statements = [
      // 1. ЧИНИМ ХОСТ (HOSTNAME)
      // Берем из ресурса (k8s.pod.name) и кладем в атрибут "hostname" (без точки!)
      // Если пода нет, ставим заглушку.
      "set(attributes[\"hostname\"], resource.attributes[\"k8s.pod.name\"])",
      "set(attributes[\"hostname\"], \"manual-host\") where attributes[\"hostname\"] == nil",

      // 2. ЧИНИМ ИМЯ ПРИЛОЖЕНИЯ (APP-NAME)
      // Берем имя контейнера и кладем в атрибут "appname" (без дефиса!)
      "set(attributes[\"appname\"], resource.attributes[\"k8s.container.name\"])",
      "set(attributes[\"appname\"], \"manual-app\") where attributes[\"appname\"] == nil",

      // 3. ЧИНИМ ТЕЛО СООБЩЕНИЯ (MSG)
      // Экспортер игнорирует Body. Ему нужно, чтобы текст лежал в attributes["message"].
      // Копируем Body туда.
      "set(attributes[\"message\"], body)",
      
      // На всякий случай, если Body пришел сложным объектом (JSON), превращаем в строку
      "set(attributes[\"message\"], Concat([attributes[\"message\"]], \"\"))",
    ]
  }
