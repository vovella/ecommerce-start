.PHONY: help setup start stop test clean

help:
	@echo "Available commands:"
	@echo "  make setup    - Initialize project"
	@echo "  make start    - Start all services"
	@echo "  make stop     - Stop all services"
	@echo "  make test     - Run tests"
	@echo "  make clean    - Clean up"

setup:
	./scripts/setup/init_project.sh

start:
	docker-compose -f docker/docker-compose.yml up -d

stop:
	docker-compose -f docker/docker-compose.yml down

test:
	pytest tests/

clean:
	docker-compose -f docker/docker-compose.yml down -v
	rm -rf data/*.csv data/*.json