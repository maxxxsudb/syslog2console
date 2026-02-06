kubectl run netcat-test --image=busybox -it --rm -- /bin/sh -c "echo '<165>Feb 06 13:44:35 TEST_HOST My_test_message_123' | nc -u -w1 syslog-service 514"
