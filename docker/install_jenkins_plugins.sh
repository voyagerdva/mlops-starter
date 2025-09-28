#!/bin/bash
set -e

JENKINS_CONTAINER="jenkins"

if [ ! -f plugins.txt ]; then
  echo "❌ Файл plugins.txt не найден!"
  exit 1
fi

echo "📦 Устанавливаем плагины из plugins.txt в контейнер $JENKINS_CONTAINER..."

# Копируем plugins.txt внутрь контейнера
docker cp plugins.txt $JENKINS_CONTAINER:/usr/share/jenkins/ref/plugins.txt

# Запускаем установку через встроенный cli
docker exec -it $JENKINS_CONTAINER bash -c "
  jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
"

echo "✅ Плагины установлены. Перезапускаем Jenkins..."
docker restart $JENKINS_CONTAINER
