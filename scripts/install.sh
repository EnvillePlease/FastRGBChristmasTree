#!/bin/bash

#===============================================================================
# FastRGBChristmasTree Installation Script
#
# This script performs the following:
# 1. Verifies the system is a Raspberry Pi running Bookworm or Trixie
# 2. Installs required system dependencies (libopenblas-dev)
# 3. Creates a Python virtual environment
# 4. Updates pip and installs required Python packages
# 5. Creates a disabled systemd service for the Christmas tree
#
# Usage: sudo ./install.sh
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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

#-------------------------------------------------------------------------------
# System Verification Functions
#-------------------------------------------------------------------------------

check_raspberry_pi() {
    print_info "Checking if system is a Raspberry Pi..."
    
    # Check for Raspberry Pi by examining /proc/cpuinfo or device tree
    if [[ -f /proc/device-tree/model ]]; then
        MODEL=$(cat /proc/device-tree/model)
        if [[ "$MODEL" == *"Raspberry Pi"* ]]; then
            print_info "Detected: $MODEL"
            return 0
        fi
    fi
    
    # Alternative check using /proc/cpuinfo for older detection method
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
    
    # Source the os-release file to get VERSION_CODENAME
    source /etc/os-release
    
    # Check for supported versions (Bookworm = Debian 12, Trixie = Debian 13)
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
    
    # Check architecture (supports both 32-bit and 64-bit)
    ARCH=$(uname -m)
    case "$ARCH" in
        armv7l)
            print_info "Architecture: 32-bit ARM"
            ;;
        aarch64)
            print_info "Architecture: 64-bit ARM"
            ;;
        *)
            print_warn "Unexpected architecture: $ARCH (proceeding anyway)"
            ;;
    esac
}

#-------------------------------------------------------------------------------
# Installation Functions
#-------------------------------------------------------------------------------

install_system_dependencies() {
    print_info "Updating package lists..."
    apt-get update
    
    print_info "Installing system dependencies (libopenblas-dev)..."
    apt-get install -y libopenblas-dev python3-venv python3-pip
    
    print_info "System dependencies installed successfully"
}

create_python_environment() {
    print_info "Creating Python virtual environment at $VENV_DIR..."
    
    # Remove existing venv if it exists
    if [[ -d "$VENV_DIR" ]]; then
        print_warn "Existing virtual environment found, removing..."
        rm -rf "$VENV_DIR"
    fi
    
    # Create new virtual environment with system site packages
    # (needed for GPIO access on Raspberry Pi)
    python3 -m venv --system-site-packages "$VENV_DIR"
    
    print_info "Virtual environment created successfully"
}

update_pip_packages() {
    print_info "Updating pip and default packages..."
    
    # Activate virtual environment and update packages
    source "$VENV_DIR/bin/activate"
    
    # Upgrade pip, setuptools, and wheel to latest versions
    pip install --upgrade pip setuptools wheel
    
    print_info "Pip packages updated successfully"
}

install_python_dependencies() {
    print_info "Installing Python dependencies (numpy, gpiozero, colorzero)..."
    
    # Ensure we're in the virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Install required packages with dependencies
    pip install numpy gpiozero colorzero
    
    print_info "Python dependencies installed successfully"
    
    # Display installed packages for verification
    print_info "Installed packages:"
    pip list
    
    deactivate
}

#-------------------------------------------------------------------------------
# Systemd Service Functions
#-------------------------------------------------------------------------------

create_systemd_service() {
    print_info "Creating systemd service: $SERVICE_NAME..."
    
    # Get the user who invoked sudo (for running the service)
    SUDO_USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    
    # Create the systemd service file
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=FastRGB Christmas Tree LED Controller
Documentation=https://github.com/yourrepo/FastRGBChristmasTree
After=network.target

[Service]
Type=simple
# Run as the user who installed the service
User=$SUDO_USER
Group=$SUDO_USER
# Set the working directory to the project folder
WorkingDirectory=$PROJECT_DIR
# Run the Python script using the virtual environment's Python
ExecStart=$VENV_DIR/bin/python3 $PYTHON_SCRIPT
# Restart policy - restart on failure after 10 seconds
Restart=on-failure
RestartSec=10
# Environment variables
Environment=PYTHONUNBUFFERED=1
# GPIO access requires specific permissions
SupplementaryGroups=gpio spi i2c

[Install]
WantedBy=multi-user.target
EOF

    # Set correct permissions on service file
    chmod 644 "$SERVICE_FILE"
    
    print_info "Systemd service file created at $SERVICE_FILE"
}

configure_systemd_service() {
    print_info "Configuring systemd service..."
    
    # Reload systemd to recognise new service
    systemctl daemon-reload
    
    # Ensure service is disabled (as per requirements)
    systemctl disable "$SERVICE_NAME"
    
    print_info "Service '$SERVICE_NAME' created and disabled"
    print_info "To enable and start the service, run:"
    echo "    sudo systemctl enable $SERVICE_NAME"
    echo "    sudo systemctl start $SERVICE_NAME"
}

#-------------------------------------------------------------------------------
# Cleanup and Summary Functions
#-------------------------------------------------------------------------------

set_permissions() {
    print_info "Setting correct permissions on project files..."
    
    # Ensure the sudo user owns the project files
    chown -R "$SUDO_USER:$SUDO_USER" "$PROJECT_DIR"
    
    # Make Python scripts executable
    chmod +x "$PYTHON_SCRIPT"
    
    print_info "Permissions set successfully"
}

print_summary() {
    echo ""
    echo "==============================================================================="
    echo -e "${GREEN}Installation Complete!${NC}"
    echo "==============================================================================="
    echo ""
    echo "Project directory:     $PROJECT_DIR"
    echo "Virtual environment:   $VENV_DIR"
    echo "Systemd service:       $SERVICE_NAME (disabled)"
    echo ""
    echo "Useful commands:"
    echo "  Activate venv:       source $VENV_DIR/bin/activate"
    echo "  Run manually:        $VENV_DIR/bin/python3 $PYTHON_SCRIPT"
    echo "  Enable service:      sudo systemctl enable $SERVICE_NAME"
    echo "  Start service:       sudo systemctl start $SERVICE_NAME"
    echo "  Check status:        sudo systemctl status $SERVICE_NAME"
    echo "  View logs:           sudo journalctl -u $SERVICE_NAME -f"
    echo ""
    echo "==============================================================================="
}

#-------------------------------------------------------------------------------
# Main Installation Flow
#-------------------------------------------------------------------------------

main() {
    echo ""
    echo "==============================================================================="
    echo "FastRGBChristmasTree Installation Script"
    echo "==============================================================================="
    echo ""
    
    # Pre-flight checks
    check_root
    check_raspberry_pi
    check_os_version
    
    # System dependencies
    install_system_dependencies
    
    # Python environment setup
    create_python_environment
    update_pip_packages
    install_python_dependencies
    
    # Systemd service setup
    create_systemd_service
    configure_systemd_service
    
    # Final steps
    set_permissions
    print_summary
}

# Run main function
main "$@"