PORT ?= 9080
PID_FILE = server.pid
LOG_FILE = server.log

SERVICE_NAME = dgx-spark-status
SERVICE_FILE = /etc/systemd/system/$(SERVICE_NAME).service
WORKING_DIR = $(shell pwd)
USER ?= $(shell echo $${SUDO_USER:-$$(whoami)})

.PHONY: start stop restart status install systemd-install systemd-uninstall

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

systemd-install: install
	@echo "Creating systemd service file..."
	@echo "[Unit]" > $(SERVICE_NAME).service
	@echo "Description=DGX Spark Status Monitor" >> $(SERVICE_NAME).service
	@echo "After=network.target" >> $(SERVICE_NAME).service
	@echo "" >> $(SERVICE_NAME).service
	@echo "[Service]" >> $(SERVICE_NAME).service
	@echo "Type=simple" >> $(SERVICE_NAME).service
	@echo "User=$(USER)" >> $(SERVICE_NAME).service
	@echo "WorkingDirectory=$(WORKING_DIR)" >> $(SERVICE_NAME).service
	@echo "Environment=PORT=$(PORT)" >> $(SERVICE_NAME).service
	@if command -v bun >/dev/null 2>&1; then \
		echo "ExecStart=$$(which bun) server.js" >> $(SERVICE_NAME).service; \
	else \
		echo "ExecStart=$$(which node) server.js" >> $(SERVICE_NAME).service; \
	fi
	@echo "Restart=always" >> $(SERVICE_NAME).service
	@echo "" >> $(SERVICE_NAME).service
	@echo "[Install]" >> $(SERVICE_NAME).service
	@echo "WantedBy=multi-user.target" >> $(SERVICE_NAME).service
	@echo "Installing service unit to $(SERVICE_FILE)..."
	sudo cp $(SERVICE_NAME).service $(SERVICE_FILE)
	rm -f $(SERVICE_NAME).service
	@echo "Reloading systemd daemon..."
	sudo systemctl daemon-reload
	@echo "Enabling and starting $(SERVICE_NAME) service..."
	sudo systemctl enable $(SERVICE_NAME)
	sudo systemctl start $(SERVICE_NAME)
	@echo "systemd service installed and started successfully!"

systemd-uninstall:
	@echo "Stopping $(SERVICE_NAME) service..."
	-sudo systemctl stop $(SERVICE_NAME)
	@echo "Disabling $(SERVICE_NAME) service..."
	-sudo systemctl disable $(SERVICE_NAME)
	@echo "Removing service unit file..."
	-sudo rm -f $(SERVICE_FILE)
	@echo "Reloading systemd daemon..."
	sudo systemctl daemon-reload
	@echo "systemd service uninstalled successfully!"
