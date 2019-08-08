#!/bin/bash
echo "Creating kibana index."

while [ "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/api/status)" != "200" ] ; do
  sleep 10
done
curl -f -XPOST -H "Content-Type: application/json" -H "kbn-xsrf: anything" "http://localhost:5601/api/saved_objects/index-pattern/logstash-*" -d "{\"attributes\":{\"title\":\"logstash-*\",\"timeFieldName\":\"@timestamp\"}}"
curl -XPOST -H "Content-Type: application/json" -H "kbn-xsrf: anything"   "http://localhost:5601/api/kibana/settings/defaultIndex" -d "{\"value\":\"logstash-*\"}"
echo "Kibana index created."
exit 0
