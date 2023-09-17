#!/bin/sh

APP_NAME=backend # app 이름
COMPOSE_FILE_NAME=docker-compose

# blue 컨테이너가 띄워져 있는가
IS_BLUE_RUN=$(docker ps | grep 8081 | grep blue)

# redis
IS_REDIS_RUN=$(docker ps | grep some-redis)

# rabbit
IS_RABBIT_RUN=$(docker ps | grep some-rabbit)

echo "> IS BLUE RUN: ${IS_BLUE_RUN}"
echo "> IS REDIS RUN: ${IS_REDIS_RUN}"
echo "> IS RABBIT RUN: ${IS_RABBIT_RUN}"

# timeout시 에러 
TIME_OUT=60

TEST_API=https://dailytopia2.shop/api/ping

# redis가 꺼져 있으면 동작
if [ -z "$IS_REDIS_RUN" ]; then
  echo "redis container up"
	docker run -d --hostname my-redis --name some-redis -p 16701:16701 redis:latest || exit 1 
fi

# rabbit이 꺼져 있으면 동작
if [ -z "$IS_RABBIT_RUN" ]; then
  echo "rabbit container up"
  docker run -d --hostname my-rabbit --name some-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:3-management || exit 1
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
docker build -t ${APP_NAME} . || exit 1

# 새로운 컨테이너 띄우기
echo "${AFTER_COLOR} container up"
docker-compose -f ${COMPOSE_FILE_NAME}.${AFTER_COLOR}.yml up -d || exit 1

# 컨테이가 띄워졌는지 확인하는 반복문
RUNNING_TIME=0
while [1 == 1]
do
  START_TIME=`date +%S`
  echo "${START_TIME}"
  sleep 1
  # container 띄워졌는지 확인
  IS_UP_AFTER=$(docker ps -f "name=${APP_NAME}-${AFTER_COLOR}")

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

# 기존 컨테이너 down
docker stop ${APP_NAME}-${BEFORE_COLOR} || exit 1
docker rm ${APP_NAME}-${BEFORE_COLOR} || exit 1
echo "${BEFORE_COLOR} container down"
