NAME = inception
COMPOSE_FILE = srcs/docker-compose.yml
DATA_PATH = /home/ana-lda-/data

all: up

up:
	@echo "Creating data directories..."
	@mkdir -p $(DATA_PATH)/mariadb
	@mkdir -p $(DATA_PATH)/wordpress
	@echo "Starting containers..."
	@docker compose -f $(COMPOSE_FILE) up -d --build

down:
	@echo "Stopping containers..."
	@docker compose -f $(COMPOSE_FILE) down

stop:
	@docker compose -f $(COMPOSE_FILE) stop

start:
	@docker compose -f $(COMPOSE_FILE) start

status:
	@docker compose -f $(COMPOSE_FILE) ps

logs:
	@docker compose -f $(COMPOSE_FILE) logs -f

clean: down
	@echo "Removing Docker resources..."
	@docker system prune -af
	@docker volume rm -f mariadb_data wordpress_data 2>/dev/null || true

fclean: clean
	@echo "Removing data directories..."
	@sudo rm -rf $(DATA_PATH)/mariadb
	@sudo rm -rf $(DATA_PATH)/wordpress
	@docker network rm inception 2>/dev/null || true
	@echo "Full cleanup complete!"

re: fclean all

.PHONY: all up down stop start status logs clean fclean re