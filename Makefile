
NAME=tilApp ##

LISTEN_HOSTNAME=0.0.0.0
LISTEN_PORT=8080

UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S), Linux)
	KILLCMD := sudo kill -9 `sudo lsof -t -i:$(LISTEN_PORT)` 2> /dev/null || :
endif
ifeq ($(UNAME_S), Darwin)
	KILLCMD := npx kill-port $(LISTEN_PORT)
endif

help:                   ## This help dialog.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

build:                  ## Build the package using correct tools
	swift build

$(NAME): build          ## Build the package and put the executable at current level
	cp `swift build --show-bin-path`/Run ./$(NAME)

clean:                  ## Clean generated resources
	docker-compose down -v
	rm -rf Public/dynamic

fclean: clean           ## Clean and reset the whole package
	swift package reset
	rm -f $(NAME)
	docker-compose down --rmi all

run: $(NAME) kill       ## Build and run the package with the services dependencies
	docker-compose up -d db
	./$(NAME) serve --env development --hostname $(LISTEN_HOSTNAME) --port $(LISTEN_PORT)

kill:                   ## Release the port that used our port and stop containers
	docker-compose down
	$(KILLCMD)

test: build             ## Execute the unit tests with the services dependencies
	docker-compose --profile testing up -d db-test
	swift test && echo TEST SUCCESS || echo TEST FAILED
	docker-compose --profile testing down -v

build_docker:           ## Build the docker image
	docker-compose build app

run_docker:             ## Run the docker image with the services dependencies
	docker-compose up --build app

test_docker:            ## Execute the unit tests in a docker image with services dependencies
	docker-compose --profile testing up --build --abort-on-container-exit app-test

.PHONY: all help build $(NAME) clean fclean run kill test test_docker
