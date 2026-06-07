PORT ?= 9080
PID_FILE = server.pid
LOG_FILE = server.log

.PHONY: start stop restart status install

install:
	@echo "Installing dependencies..."
	@if command -v bun >/dev/null 2>&1; then \
		bun install --production; \
	else \
		npm install --omit=dev; \
	fi

start: install
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "Server is already running (PID: $$(cat $(PID_FILE)))"; \
	else \
		echo "Starting server on port $(PORT)..."; \
		if command -v bun >/dev/null 2>&1; then \
			PORT=$(PORT) bun server.js > $(LOG_FILE) 2>&1 & echo $$! > $(PID_FILE); \
		else \
			PORT=$(PORT) node server.js > $(LOG_FILE) 2>&1 & echo $$! > $(PID_FILE); \
		fi; \
		sleep 1; \
		if kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
			echo "Server started successfully (PID: $$(cat $(PID_FILE)))"; \
		else \
			echo "Failed to start server. Check $(LOG_FILE) for details."; \
			rm -f $(PID_FILE); \
		fi; \
	fi

stop:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		PID=$$(cat $(PID_FILE)); \
		echo "Stopping server (PID: $$PID)..."; \
		kill $$PID; \
		for i in 1 2 3 4 5; do \
			if ! kill -0 $$PID 2>/dev/null; then \
				rm -f $(PID_FILE); \
				echo "Server stopped."; \
				exit 0; \
			fi; \
			sleep 1; \
		done; \
		echo "Server did not stop, killing forcefully..."; \
		kill -9 $$PID; \
		rm -f $(PID_FILE); \
		echo "Server forcefully stopped."; \
	else \
		echo "Server is not running."; \
		rm -f $(PID_FILE); \
	fi

restart: stop start

status:
	@if [ -f $(PID_FILE) ] && kill -0 $$(cat $(PID_FILE)) 2>/dev/null; then \
		echo "Server is running (PID: $$(cat $(PID_FILE))) on port $(PORT)."; \
	else \
		echo "Server is stopped."; \
	fi
