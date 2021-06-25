#!/bin/bash
docker-compose --profile testing exec db-test psql -U vapor_username vapor-test
