# FastRGBChristmasTree

A fast and flexible driver for the 3D RGB Xmas Tree from [The Pi Hut](https://thepihut.com/products/3d-rgb-xmas-tree-for-raspberry-pi). This project provides an improved driver with batch LED updates and a systemd service for running lighting effects automatically.

## Why This Driver?

The Pi Hut's [original driver](https://github.com/ThePiHut/rgbxmastree) is slow—it regenerates the entire SPI command buffer for every single LED change. This driver:

- **Batches LED updates** - configure multiple LEDs before committing to SPI
- **Supports numpy-style indexing** - set entire layers or segments at once
- **Allows per-LED brightness control** - not available in the original driver
- **Includes ready-to-use effects** - swirl, spin, sparkle, and random colours
- **Provides a systemd service** - run effects automatically on boot

## Installation

### Prerequisites

- Raspberry Pi (any model with GPIO)
- Raspberry Pi OS Bookworm or Trixie
- 3D RGB Xmas Tree connected via SPI

### Automated Installation

The easiest way to install is using the provided script:

```bash
cd FastRGBChristmasTree
sudo ./scripts/install.sh
```

This script will:
1. Verify you're running on a supported Raspberry Pi OS
2. Install system dependencies (`libopenblas-dev`, `python3-venv`)
3. Create a Python virtual environment with required packages
4. Create a disabled systemd service for automatic startup

### Manual Installation

1. **Install system dependencies:**
   ```bash
   sudo apt-get update
   sudo apt-get install -y libopenblas-dev python3-venv python3-pip
   ```

2. **Create and activate a virtual environment:**
   ```bash
   python3 -m venv --system-site-packages venv
   source venv/bin/activate
   ```

3. **Install Python packages:**
   ```bash
   pip install --upgrade pip setuptools wheel
   pip install numpy gpiozero colorzero
   ```

4. **Run the Christmas tree effects:**
   ```bash
   python3 christmastree.py
   ```

## Running as a Service

The installation script creates a systemd service that runs the lighting effects automatically.

### Enable and Start the Service

```bash
sudo systemctl enable christmas
sudo systemctl start christmas
```

### Useful Service Commands

| Command | Description |
|---------|-------------|
| `sudo systemctl start christmas` | Start the service |
| `sudo systemctl stop christmas` | Stop the service |
| `sudo systemctl restart christmas` | Restart the service |
| `sudo systemctl status christmas` | Check service status |
| `sudo systemctl enable christmas` | Enable on boot |
| `sudo systemctl disable christmas` | Disable on boot |
| `sudo journalctl -u christmas -f` | View live logs |

## Driver Usage

### Basic Setup

```python
from tree import FastRGBChristmasTree
tree = FastRGBChristmasTree()
```

### Setting LEDs

Set a single LED by index (0-24):
```python
tree[22] = [255, 0, 0]  # Red
```

Set with brightness control (0-30):
```python
tree[22] = [10, 255, 0, 0]  # Brightness 10, Red
```

Use layer/segment indexing:
```python
tree[2, 0] = [255, 0, 0]  # Layer 2, Segment 0
```

Set multiple LEDs at once:
```python
tree[:, 0] = [[255, 0, 0], [255, 255, 0], [0, 255, 0]]  # All LEDs in segment 0
```

### Committing Changes

LED changes are buffered until you call `commit()`:
```python
tree[0] = [255, 0, 0]
tree[1] = [0, 255, 0]
tree[2] = [0, 0, 255]
tree.commit()  # Send all changes to the tree
```

## LED Indexing Scheme

The tree has 25 LEDs arranged in 4 layers and 8 segments. Layer 0 is at the bottom, and the star is at index 3.

With the Raspberry Pi facing towards you:

|         |        |    |    |    |        |        |   |   |   |       |
|---------|--------|----|----|----|--------|--------|---|---|---|-------|
|**Layer**|        | 0  | 1  | 2  | 3      | 3      | 2 | 1 | 0 |       |
|         |**Vane**|    |    |    | **0**  | **1**  |   |   |   |       |
| 0       |        |    |    |    | 24     | 19     |   |   |   |       |
| 1       |        |    |    |    | 23     | 20     |   |   |   |       |
| 2       |        |    |    |    | 22     | 21     |   |   |   |       |
| 3       | **7**  | 12 | 11 | 10 | 3      | 3      | 9 | 8 | 7 | **2** |
| 3       | **6**  | 6  | 5  | 4  | 3      | 3      | 2 | 1 | 0 | **3** |
| 2       |        |    |    |    | 13     | 18     |   |   |   |       |
| 1       |        |    |    |    | 14     | 17     |   |   |   |       |
| 0       |        |    |    |    | 15     | 16     |   |   |   |       |
|         |        |    |    |    | **5**  | **4**  |   |   |   |       |

## Included Effects

The `christmastree.py` script cycles through these effects:

- **Swirl** - Rotating colour bands across layers
- **Spin** - Colour wheel spinning around the tree
- **Sparkle** - Random twinkling white lights
- **Random Colour** - Vibrant disco colours on all LEDs

## Example Scripts

- `christmastree.py` - Main effects script (runs as service)
- `random-colour.py` - Simple random colour demo
- `beam-up.py` - Layer-based colour animation

## Troubleshooting

### NumPy installation fails
Ensure you have the OpenBLAS library installed:
```bash
sudo apt-get install libopenblas-dev
```

### Permission denied errors
The user running the script needs access to GPIO/SPI. Add them to the required groups:
```bash
sudo usermod -aG gpio,spi,i2c $USER
```

### Service won't start
Check the logs for errors:
```bash
sudo journalctl -u christmas -n 50
```

## Links

- [The Pi Hut Product Page](https://thepihut.com/products/3d-rgb-xmas-tree-for-raspberry-pi)
- [Original Pi Hut Driver](https://github.com/ThePiHut/rgbxmastree)
- [NumPy Indexing Documentation](https://numpy.org/doc/stable/user/basics.indexing.html)

## Hardware Modifications

For even faster performance, see [issue #2](https://github.com/fangfufu/FastRGBChristmasTree/issues/2) for hardware modification options.
