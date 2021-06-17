
NAME=tilApp

LISTEN_HOSTNAME=0.0.0.0
LISTEN_PORT=8080

.PHONY: all
all: run

.PHONY: $(NAME)
$(NAME): build
	cp `swift build --show-bin-path`/Run ./$(NAME)

.PHONY: all
build:
	swift build

.PHONY: clean
clean:
	docker-compose down -v --remove-orphans
	docker-compose -f testing.docker-compose.yml down -v --remove-orphans

.PHONY: fclean
fclean: clean
	swift package reset
	rm -f $(NAME)
	docker-compose down --rmi all

.PHONY: run
run: $(NAME)
	docker-compose up -d db
	npx kill-port $(LISTEN_PORT)
	./$(NAME) serve --env development --hostname $(LISTEN_HOSTNAME) --port $(LISTEN_PORT)

.PHONY: test
test: build
	docker-compose -f testing.docker-compose.yml up -d db-test
	swift test
	docker-compose -f testing.docker-compose.yml down -v

.PHONY: test_docker
test_docker:
	docker-compose -f testing.docker-compose.yml up --build --abort-on-container-exit
