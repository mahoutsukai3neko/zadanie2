Część dodatkowa:

docker buildx create --driver docker-container --name zadanie1 --use --bootstrap  #tworzymy builder

docker buildx build -q -f Dockerfile \
--platform linux/arm64,linux/amd64 \
--cache-to type=registry,ref=docker.io/iol4/cache,mode=max \
--cache-from type=registry,ref=docker.io/iol4/cache -t docker.io/iol4/lab:zadanie1_multiplatform --push  . 
#budujemy obrazy dla architektur linux/arm64 oraz linux/amd64
