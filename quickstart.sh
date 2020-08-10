#!/bin/bash

# This script starts up Chorus and runs through the basic setup tasks.

docker-compose down -v
docker-compose up -d
sleep 30 # takes a while to start everything.

if [ ! -f ./icecat-products-150k-20200809.tar.gz ]; then
    wget https://querqy.org/datasets/icecat/icecat-products-150k-20200809.tar.gz
fi
tar xzf icecat-products-150k-20200809.tar.gz --to-stdout | curl 'http://localhost:8983/solr/ecommerce/update?commit=true' --data-binary @- -H 'Content-type:application/json'

SOLR_INDEX_ID=`curl -X PUT -H "Content-Type: application/json" -d '{"name":"ecommerce", "description":"Ecommerce Demo"}' http://localhost:9000/api/v1/solr-index | jq .returnId`
curl -X PUT -H "Content-Type: application/json" -d '{"name":"attr_t_product_type"}' http://localhost:9000/api/v1/{$SOLR_INDEX_ID}/suggested-solr-field
curl -X PUT -H "Content-Type: application/json" -d '{"name":"title"}' http://localhost:9000/api/v1/{$SOLR_INDEX_ID}/suggested-solr-field

docker-compose run --rm quepid bin/rake db:setup
docker-compose run quepid thor user:create -a demo@example.com "Demo User" password

docker-compose run rre mvn rre:evaluate
docker-compose run rre mvn rre-report:report