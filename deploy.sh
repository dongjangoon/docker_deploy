#!/bin/sh

APP_NAME=backend # app 이름
COMPOSE_FILE_NAME=docker-compose

# blue 컨테이너가 띄워져 있는가
IS_RUN_BLUE=$(docker ps | grep 8081)

echo "> IS BLUE RUN: ${IS_RUN_BLUE}"

# timeout시 에러 
TIME_OUT=60

TEST_API=https://dailytopia2.shop/api/ping

if [ -n "$IS_RUN_BLUE" ]; then
  BEFORE_COLOR="blue"
  AFTER_COLOR="green"
  PORT=8082
else
  BEFORE_COLOR="green"
  AFTER_COLOR="blue"
  PORT=8081
fi

echo "> AFTER_COLOR: ${AFTER_COLOR}"

ENV_REST=$(cat .env | tail -1)

echo "PORT=${PORT}" | tee .env
echo "${ENV_REST}" >> .env

# 도커 이미지 빌드
docker build -t ${APP_NAME} . | exit 1

# 새로운 컨테이너 띄우기
echo "${AFTER_COLOR} container up"
docker-compose -p ${APP_NAME}-${AFTER_COLOR} -f ${COMPOSE_FILE_NAME}.${AFTER_COLOR}.yml up -d || exit 1

RUNNING_TIME=0
while [1 == 1]
do
  START_TIME=`date +%S`
  echo "${START_TIME}"
  sleep 1
  # container 띄워졌는지 확인
  IS_UP_AFTER=$(docker-compose -p ${APP_NAME}-${AFTER_COLOR} -f ${COMPOSE_FILE_NAME}.${AFTER_COLOR}.yml ps | grep Up)

  if [ -n "$IS_UP_AFTER" ]; then
    # WAS 띄워졌는지 확인
    TEST_API_STATUS_CODE=$(docker exec ${APP_NAME}-${AFTER_COLOR} curl -o /dev/null -w "%{http_code}" "${TEST_API}")
    if [ "$TEST_API_STATUS_CODE" == 200 ]; then
      echo "TEST API SUCCESS !! >> ${AFTER_COLOR} Container WAS Running!"
      break
    fi
  fi

  END_TIME=`date +%S`
  echo "> END TIME: ${END_TIME}"

  TIME_DIFF=`echo "$END_TIME - $START_TIME" | bc -l`
  RUNNING_TIME=$(($RUNNING_TIME + $TIME_DIFF))
  echo "> RUNNING_TIME: ${RUNNING_TIME}"

  # timeout시 에러 발생
  if [ $RUNNING_TIME -gt $TIME_OUT ]; then
    echo "ERROR TIMEOUT!!"
    exit 1
  fi
done

# nginx conf 변경 후 nginx reload
sudo cp Nginx/nginx-${AFTER_COLOR}.conf Nginx/nginx.conf || exit 1

# 기존 컨테이너 down
docker-compose -p ${APP_NAME}-${BEFORE_COLOR} -f ${COMPOSE_FILE_NAME}.${BEFORE_COLOR}.yml down || exit 1
echo "${BEFORE_COLOR} container down"
