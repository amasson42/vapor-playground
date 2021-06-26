
NAME=tilApp

LISTEN_HOSTNAME=0.0.0.0
LISTEN_PORT=8080

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S), Linux)
	KILLCMD := sudo kill -9 `sudo lsof -t -i:$(LISTEN_PORT)` || :
endif
ifeq ($(UNAME_S), Darwin)
	KILLCMD := npx kill-port $(LISTEN_PORT)
endif

# By default run the program
all: run

# Build the package using correct tools
build:
	swift build

# Build the package and put the executable at current level
$(NAME): build
	cp `swift build --show-bin-path`/Run ./$(NAME)

# Clean the resource consuming generated services
clean:
	docker-compose down -v
	rm -rf Public/dynamic

# Clean and reset the whole package
fclean: clean
	swift package reset
	rm -f $(NAME)
	docker-compose down --rmi all

# Build and run the package with the services dependencies
run: $(NAME) kill
	docker-compose up -d db
	./$(NAME) serve --env development --hostname $(LISTEN_HOSTNAME) --port $(LISTEN_PORT)

# Release the port that used our port
kill:
	docker-compose down
	$(KILLCMD)

# Execute the unit tests with the services dependencies
test: build
	docker-compose --profile testing up -d db-test
	swift test && echo TEST SUCCESS || echo TEST FAILED
	docker-compose --profile testing down -v

# Execute the unit tests in a docker image with services dependencies
test_docker:
	docker-compose --profile testing up --build --abort-on-container-exit app-test

.PHONY: all build $(NAME) clean fclean run kill test test_docker
