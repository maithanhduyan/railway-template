FROM redis:7-alpine

CMD [ "redis-server", "--maxmemory", "256mb", "--maxmemory-policy", "allkeys-lru" ]