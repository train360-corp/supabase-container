.PHONY: build run stop logs test clean

IMAGE_NAME=supabase-container
CONTAINER_NAME=sb-container

deps:
	test -d bin || ( \
		mkdir bin && cd bin \
		&& git clone --depth=1 --filter=blob:none --sparse --branch 1.25.01 https://github.com/supabase/supabase.git \
		&& cd supabase \
		&& git sparse-checkout set apps/studio \
	)

build: deps
	docker build --platform linux/amd64 -t $(IMAGE_NAME) .

start: run

run:
	docker run -v ./pg_data:/var/lib/postgresql/data --env-file ./.env --platform linux/amd64 --rm -d --name $(CONTAINER_NAME) -p 5432:5432 -p 8000:8000 -p 8443:8443 $(IMAGE_NAME)

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