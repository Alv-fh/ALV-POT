#!/bin/bash
echo "Esperando a que Kibana esté listo..."
until curl -s http://localhost:5601/api/status | grep -q '"level":"available"'; do
  sleep 5
done

echo "Importando dashboards..."
for file in ./config/kibana/dashboards/*.ndjson; do
  curl -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    -F "file=@$file"
  echo "Importado: $file"
done

echo "✅ Dashboards importados correctamente"
