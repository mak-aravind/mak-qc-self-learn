SHELL := /bin/bash

# Windows Docker Course Platform Makefile
# Usage: make <target>

.PHONY: help start stop restart down clean status logs shell update pull up

# Default target
help:
	@echo "Windows Docker Course Platform Commands:"
	@echo ""
	@echo "🚀 CONTAINER MANAGEMENT:"
	@echo "  make up          - Start the Windows container (with logs)"
	@echo "  make up-detached - Start the container in background"
	@echo "  make start       - Start the container in background"
	@echo "  make stop        - Stop the container gracefully"
	@echo "  make restart     - Restart the container"
	@echo "  make down        - Stop and remove container (keeps data)"
	@echo "  make clean       - Stop and remove everything including volumes (⚠️  DELETES Windows installation)"
	@echo ""
	@echo "📊 MONITORING & DEBUGGING:"
	@echo "  make status      - View container status"
	@echo "  make ps          - Alias for status"
	@echo "  make logs        - View container logs (follow mode)"
	@echo "  make follow-logs - Alias for logs"
	@echo "  make shell       - Execute bash shell inside container"
	@echo "  make inspect     - View detailed container information"
	@echo "  make stats       - Show real-time container resource usage"
	@echo ""
	@echo "🔄 UPDATES & MAINTENANCE:"
	@echo "  make update      - Update to latest image and restart"
	@echo "  make pull        - Pull latest image without restarting"
	@echo ""
	@echo "📁 VOLUME & FILE MANAGEMENT:"
	@echo "  make check-volumes      - Check volume contents and structure"
	@echo "  make share-file         - Copy a file to shared course materials"
	@echo "  make monitor-activity   - Monitor real-time file changes"
	@echo "  make mount-disk         - Mount Windows disk image (advanced)"
	@echo "  make unmount-disk       - Unmount Windows disk image"
	@echo ""
	@echo "🌐 ACCESS & CONNECTIVITY:"
	@echo "  make web         - Open web interface in browser"
	@echo "  make rdp         - Show RDP connection details and open client"
	@echo "  make check-ports - Check if required ports are available"
	@echo ""
	@echo "⚙️ SYSTEM CHECKS:"
	@echo "  make prepare         - Create necessary directories and check prerequisites"
	@echo "  make check-resources - Check system resources (RAM, disk, KVM)"
	@echo ""
	@echo "🔧 DEVELOPMENT HELPERS:"
	@echo "  make dev-reset   - Quick restart for development"
	@echo "  make dev-clean   - Clean and restart everything"
	@echo "  make start-bg    - Alias for up-detached"
	@echo ""

# Start container in background
start:
	@echo "Starting Windows container..."
	docker-compose start

# Start container with logs (useful for first run)
up:
	@echo "Starting Windows container with logs..."
	docker-compose up

# Start container in background (detached)
up-detached:
	@echo "Starting Windows container in background..."
	docker-compose up -d

# Stop container gracefully
stop:
	@echo "Stopping Windows container gracefully..."
	docker-compose stop

# Restart container
restart:
	@echo "Restarting Windows container..."
	docker-compose restart

# Stop and remove container (keeps data in volumes)
down:
	@echo "Stopping and removing container (data preserved)..."
	docker-compose down

# Stop and remove everything including volumes (WARNING: deletes Windows installation)
clean:
	@echo "⚠️  WARNING: This will delete the Windows installation!"
	@echo "Are you sure? [y/N]"
	@read answer; \
	if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ] || [ "$$answer" = "yes" ] || [ "$$answer" = "YES" ]; then \
		echo "Removing container and volumes..."; \
		docker-compose down -v; \
	else \
		echo "Operation cancelled"; \
	fi

# View container status
status:
	@echo "Container status:"
	docker-compose ps

# View container logs
logs:
	@echo "Following container logs (Ctrl+C to exit)..."
	docker-compose logs -f windows

# Execute bash shell inside container
shell:
	@echo "Opening shell in Windows container..."
	docker exec -it qpi-ai-course /bin/bash

# View detailed container information
inspect:
	@echo "Container details:"
	docker inspect qpi-ai-course

# Update to latest image and restart
update:
	@echo "Updating to latest image..."
	docker-compose pull
	docker-compose up -d

# Pull latest image without restarting
pull:
	@echo "Pulling latest image..."
	docker-compose pull

# Show real-time resource usage
stats:
	@echo "Real-time container resource usage (Ctrl+C to exit)..."
	docker stats qpi-ai-course

# Prepare environment and check prerequisites
prepare:
	@echo "Preparing environment..."
	@echo "Creating necessary directories..."
	mkdir -p windows-data course-materials student-scripts
	@echo "Checking KVM availability..."
	@if command -v kvm-ok >/dev/null 2>&1; then \
		sudo kvm-ok; \
	else \
		echo "kvm-ok not found. Installing cpu-checker..."; \
		sudo apt update && sudo apt install -y cpu-checker; \
		sudo kvm-ok; \
	fi
	@echo "Checking Docker Compose..."
	@docker-compose version
	@echo "Environment prepared!"

# Quick access shortcuts
ps: status
start-bg: up-detached
follow-logs: logs

# Development helpers
dev-reset: down up-detached
dev-clean: clean prepare up-detached

# Network and troubleshooting
check-ports:
	@echo "Checking if required ports are available..."
	@echo "Port 8006 (Web interface):"
	@netstat -tulpn | grep :8006 || echo "  ✓ Port 8006 is available"
	@echo "Port 3389 (RDP):"
	@netstat -tulpn | grep :3389 || echo "  ✓ Port 3389 is available"

check-resources:
	@echo "System resources:"
	@echo "Memory:"
	@free -h
	@echo ""
	@echo "Disk space:"
	@df -h .
	@echo ""
	@echo "KVM status:"
	@ls -la /dev/kvm 2>/dev/null || echo "KVM device not found"

# Web interface shortcut
web:
	@echo "Opening web interface..."
	@echo "URL: http://localhost:8006"
	@if command -v xdg-open >/dev/null 2>&1; then \
		xdg-open http://localhost:8006; \
	elif command -v open >/dev/null 2>&1; then \
		open http://localhost:8006; \
	else \
		echo "Please open http://localhost:8006 in your browser"; \
	fi

# RDP connection helper
rdp:
	@echo "RDP connection details:"
	@echo "Host: localhost:3389"
	@echo "Username: student"
	@echo "Password: Course2024!"
	@if command -v remmina >/dev/null 2>&1; then \
		echo "Opening Remmina..."; \
		remmina; \
	else \
		echo "Install remmina for GUI RDP client: sudo apt install remmina"; \
	fi

# Volume management commands
check-volumes:
	@echo "Volume contents:"
	@echo "Windows system storage:"
	@ls -la ./windows-data/ 2>/dev/null || echo "  Windows not yet initialized"
	@echo ""
	@echo "Course materials:"
	@ls -la ./course-materials/ 2>/dev/null || echo "  No course materials yet"
	@echo ""
	@echo "course workspace files"
	@ls -la ./qpi-course-workspace-win/ 2>/dev/null || echo "  No files yet"

share-file:
	@read -p "Enter file path to share: " filepath; \
	if [ -f "$$filepath" ]; then \
		cp "$$filepath" ./course-materials/ && \
		echo "✓ File shared! Access it in Windows at \\\\host.lan\\Data"; \
	else \
		echo "✗ File not found: $$filepath"; \
	fi

# Disk image file access
mount-disk:
	@echo "⚠️  Advanced: Mounting Windows disk image"
	@echo "This requires stopping the container first!"
	@sudo ./volumeSyncup.sh

unmount-disk:
	@echo "Unmounting Windows disk..."
	@sudo umount /mnt/windows-disk 2>/dev/null || echo "Nothing to unmount"
	@sudo qemu-nbd --disconnect /dev/nbd0 2>/dev/null || echo "NBD device not connected"
	@sudo rmdir /mnt/windows-disk 2>/dev/null || echo "Mount point already removed"
	@echo "✓ Cleanup completed. You can now start the container."
	@echo "To start: make start"