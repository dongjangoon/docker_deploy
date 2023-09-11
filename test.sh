git pull origin develop
docker system prune -a -f
docker build -t backend .
docker-compose -f docker-compose.yml up -d
