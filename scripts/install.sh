#!/bin/bash

#===============================================================================
# FastRGBChristmasTree Installation Script
#
# This script performs the following:
# 1. Verifies the system is a Raspberry Pi running Bookworm or Trixie
# 2. Installs required system dependency (libopenblas-dev)
# 3. Creates a Python virtual environment
# 4. Installs required Python packages
# 5. Creates a disabled systemd service for the Christmas tree
#
# Usage: ./install.sh
#===============================================================================

set -e  # Exit immediately if a command exits with a non-zero status

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/venv"
SERVICE_NAME="christmas"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PYTHON_SCRIPT="$PROJECT_DIR/christmastree.py"

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

#-------------------------------------------------------------------------------
# Helper Functions
#-------------------------------------------------------------------------------

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

#-------------------------------------------------------------------------------
# System Verification Functions
#-------------------------------------------------------------------------------

check_sudo_access() {
    print_info "Checking sudo access..."
    
    if ! sudo -v 2>/dev/null; then
        print_error "This script requires sudo access for:"
        print_error "  • Installing system packages (apt-get)"
        print_error "  • Creating systemd service files"
        echo ""
        echo "Please ensure your user has sudo privileges and try again."
        exit 1
    fi
    
    print_info "Sudo access confirmed"
}

check_raspberry_pi() {
    print_info "Checking if system is a Raspberry Pi..."
    
    if [[ -f /proc/device-tree/model ]]; then
        MODEL=$(cat /proc/device-tree/model)
        if [[ "$MODEL" == *"Raspberry Pi"* ]]; then
            print_info "Detected: $MODEL"
            return 0
        fi
    fi
    
    if grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        print_info "Raspberry Pi detected via cpuinfo"
        return 0
    fi
    
    print_error "This script must be run on a Raspberry Pi"
    exit 1
}

check_os_version() {
    print_info "Checking Raspberry Pi OS version..."
    
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS version (/etc/os-release not found)"
        exit 1
    fi
    
    source /etc/os-release
    
    case "$VERSION_CODENAME" in
        bookworm)
            print_info "Detected Raspberry Pi OS Bookworm (Debian 12)"
            ;;
        trixie)
            print_info "Detected Raspberry Pi OS Trixie (Debian 13)"
            ;;
        *)
            print_error "Unsupported OS version: $VERSION_CODENAME"
            print_error "This script requires Raspberry Pi OS Bookworm or Trixie"
            exit 1
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Installation Functions
#-------------------------------------------------------------------------------

install_system_dependencies() {
    print_info "Installing system dependency (libopenblas-dev)..."
    sudo apt-get update
    sudo apt-get install -y libopenblas-dev
    print_info "System dependency installed successfully"
}

create_python_environment() {
    print_info "Creating Python virtual environment at $VENV_DIR..."
    
    if [[ -d "$VENV_DIR" ]]; then
        print_warn "Existing virtual environment found, removing..."
        rm -rf "$VENV_DIR"
    fi
    
    python3 -m venv --system-site-packages "$VENV_DIR"
    print_info "Virtual environment created successfully"
}

install_python_dependencies() {
    print_info "Installing Python dependencies..."
    
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install numpy gpiozero colorzero
    
    print_info "Installed packages:"
    pip list
    deactivate
}

#-------------------------------------------------------------------------------
# Systemd Service Functions
#-------------------------------------------------------------------------------

create_systemd_service() {
    print_info "Creating systemd service: $SERVICE_NAME..."
    
    sudo tee "$SERVICE_FILE" > /dev/null << EOF
[Unit]
Description=FastRGB Christmas Tree LED Controller
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR
ExecStart=$VENV_DIR/bin/python3 $PYTHON_SCRIPT
Restart=on-failure
RestartSec=10
Environment=PYTHONUNBUFFERED=1
SupplementaryGroups=gpio spi i2c

[Install]
WantedBy=multi-user.target
EOF

    sudo chmod 644 "$SERVICE_FILE"
    sudo systemctl daemon-reload
    sudo systemctl disable "$SERVICE_NAME"
    
    print_info "Service '$SERVICE_NAME' created and disabled"
}

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

print_summary() {
    echo ""
    echo "==============================================================================="
    echo -e "${GREEN}Installation Complete!${NC}"
    echo "==============================================================================="
    echo ""
    echo "Useful commands:"
    echo "  Run manually:        $VENV_DIR/bin/python3 $PYTHON_SCRIPT"
    echo "  Enable service:      sudo systemctl enable $SERVICE_NAME"
    echo "  Start service:       sudo systemctl start $SERVICE_NAME"
    echo "  Check status:        sudo systemctl status $SERVICE_NAME"
    echo ""
}

#-------------------------------------------------------------------------------
# Main
#-------------------------------------------------------------------------------

main() {
    echo ""
    echo "FastRGBChristmasTree Installation Script"
    echo "========================================="
    echo ""
    
    check_sudo_access
    check_raspberry_pi
    check_os_version
    install_system_dependencies
    create_python_environment
    install_python_dependencies
    create_systemd_service
    print_summary
}

main "$@"