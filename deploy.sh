#!/bin/sh

APP_NAME=backend # app 이름
COMPOSE_FILE_NAME=docker-compose

# blue 컨테이너가 띄워져 있는가
IS_BLUE_RUN=$(docker ps | grep 8081 | grep blue)

# redis
IS_REDIS_RUN=$(docker ps | grep 16701 | grep redis)

echo "> IS BLUE RUN: ${IS_BLUE_RUN}"
echo "> IS REDIS RUN: ${IS_REDIS_RUN}"

# timeout시 에러 
TIME_OUT=60

TEST_API=https://dailytopia2.shop/api/ping

# redis가 꺼져 있으면 동작
if [ -z "$IS_REDIS_RUN" ]; then
  echo "redis container up"
  docker-compose -f ${COMPOSE_FILE_NAME}.redis.yml up -d || exit 1
fi

# color switch
if [ -n "$IS_BLUE_RUN" ]; then
  BEFORE_COLOR="blue"
  AFTER_COLOR="green"
  PORT=8082
else
  BEFORE_COLOR="green"
  AFTER_COLOR="blue"
  PORT=8081
fi

echo "> AFTER_COLOR: ${AFTER_COLOR}"

# .env port switch
ENV_REST=$(tail -n+2 .env)
echo "PORT=${PORT}" | tee .env
echo "${ENV_REST}" >> .env

# 도커 이미지 빌드
docker build -t ${APP_NAME}-${AFTER_COLOR} . | exit 1

# 새로운 컨테이너 띄우기
echo "${AFTER_COLOR} container up"
docker-compose -p ${APP_NAME}-${AFTER_COLOR} -f ${COMPOSE_FILE_NAME}.${AFTER_COLOR}.yml up -d || exit 1

# 컨테이가 띄워졌는지 확인하는 반복문
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
sudo cp Nginx/nginx-${AFTER_COLOR}.conf /etc/nginx/nginx.conf || exit 1
nginx -s reload || exit 1

# 기존 컨테이너 down
docker-compose -p ${APP_NAME}-${BEFORE_COLOR} -f ${COMPOSE_FILE_NAME}.${BEFORE_COLOR}.yml down || exit 1
echo "${BEFORE_COLOR} container down"
