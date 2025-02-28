.PHONY: build run stop logs test clean

IMAGE_NAME=supabase-container
CONTAINER_NAME=sb-container

dep-bin:
	test -d bin || mkdir bin

dep-auth:
	test -d bin/auth || ( \
		git clone --depth=1 --branch v2.169.0 https://github.com/supabase/auth.git bin/auth \
	)

dep-meta: bin
	test -d bin/postgres-meta || ( \
		git clone --depth=1 --branch v0.84.2 https://github.com/supabase/postgres-meta.git bin/postgres-meta \
	)

deps: dep-bin dep-meta dep-auth

build: deps
	docker build -t $(IMAGE_NAME) .

start: run

run: stop
	docker run \
		--add-host=realtime-dev.supabase-realtime:127.0.0.1 \
		-v ./test/supabase/migrations:/supabase/migrations \
		-v ./pg_data:/var/lib/postgresql/data \
		--env-file ./.env \
		--rm -d \
		--name $(CONTAINER_NAME) \
		-p 5432:5432 \
		-p 8000:8000 \
		-p 8443:8443 \
		$(IMAGE_NAME)

stop:
	docker stop $(CONTAINER_NAME) || true
	docker rm $(CONTAINER_NAME) || true

logs:
	docker logs -f $(CONTAINER_NAME)

test:
	@echo "Checking Kong health..."
	docker exec $(CONTAINER_NAME) kong health || (echo "Kong health check failed!" && exit 1)
	@echo "Kong is running successfully!"

clean: stop
	docker rmi -f $(IMAGE_NAME)
	rm -rf bin