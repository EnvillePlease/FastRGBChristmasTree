'''
Configure different LED patterns for RGB Christmas Tree
This module provides various lighting effects including swirl, spin, sparkle, and random colour patterns.
'''
from tree import FastRGBChristmasTree
from time import sleep
from random import random
from colorzero import Color
from collections import deque

# Constants for tree configuration
NUM_LEDS = 25
NUM_SEGMENTS = 8
STAR_INDEX = 3
DEFAULT_FRAME_DELAY = 0.5

# Pre-defined colours for reuse (avoids repeated list creation)
WHITE = [255, 255, 255]
RED = [255, 0, 0]
GREEN = [0, 255, 0]
BLUE = [0, 0, 255]
YELLOW = [255, 255, 0]
MAGENTA = [255, 0, 255]
CYAN = [0, 255, 255]
OFF = [0, 0, 0]

# Colour gradients for swirl effect (pre-defined to avoid recreation each frame)
GRADIENT_RYG = [RED, YELLOW, GREEN]        # Red->Yellow->Green
GRADIENT_YGB = [YELLOW, GREEN, BLUE]       # Yellow->Green->Blue
GRADIENT_GBR = [GREEN, BLUE, RED]          # Green->Blue->Red
GRADIENT_BRY = [BLUE, RED, YELLOW]         # Blue->Red->Yellow


def random_colour():
    """
    Generate a random fully saturated, full brightness colour.
    
    Uses HSV colour space with random hue to ensure vibrant colours.
    
    Returns:
        list: RGB values as integers [0-255, 0-255, 0-255]
    """
    # Create colour directly with random hue, full saturation and value
    colour = Color.from_hsv(random(), 1, 1)
    
    # Convert from colorzero's 0-1 RGB range to 0-255 integer range
    return [int(c * 255) for c in colour.rgb]


def swirl(count, delay=DEFAULT_FRAME_DELAY):
    """
    Create a rotating swirl pattern with colour bands across tree layers.
    
    Each layer displays different colours that rotate around the tree,
    creating a candy-cane like swirling effect.
    
    Args:
        count: Number of animation frames to display
        delay: Time in seconds between frames (default: 0.5)
    """
    tree = FastRGBChristmasTree()
    
    # Use deque for efficient rotation of gradient patterns
    gradients = deque([GRADIENT_RYG, GRADIENT_YGB, GRADIENT_GBR, GRADIENT_BRY])
    
    # Set the star/top LED to white (only needs to be set once)
    tree[STAR_INDEX] = WHITE
    
    for _ in range(count):
        # Assign colour gradients to each segment pair
        for segment_pair, gradient in enumerate(gradients):
            tree[:, segment_pair * 2] = gradient
            tree[:, segment_pair * 2 + 1] = gradient

        tree.commit()  # Send the LED data to the tree

        # Rotate gradients for spinning effect (deque rotation is O(1))
        gradients.rotate(-1)
        
        sleep(delay)


def spin(count, delay=DEFAULT_FRAME_DELAY):
    """
    Create a spinning colour wheel effect around the tree.
    
    8 different colours are assigned to 8 segments and rotate
    around the tree creating a spinning wheel appearance.
    
    Args:
        count: Number of animation frames to display
        delay: Time in seconds between frames (default: 0.5)
    """
    tree = FastRGBChristmasTree()
    
    # Use deque for efficient rotation of colours
    colours = deque([WHITE, RED, GREEN, BLUE, WHITE, YELLOW, MAGENTA, CYAN])

    # Set the star/top LED to white (only needs to be set once)
    tree[STAR_INDEX] = WHITE
    
    for _ in range(count):
        # Assign colours to segments around the tree
        for segment, colour in enumerate(colours):
            tree[:, segment] = colour

        tree.commit()  # Send the LED data to the tree

        # Rotate colours for spinning effect (deque rotation is O(1))
        colours.rotate(-1)

        sleep(delay)


def sparkle(count, on_probability=0.66):
    """
    Create a random twinkling/sparkling white light effect.
    
    Each LED has a configurable chance of being on (white) or off each frame,
    creating a twinkling star-like effect.
    
    Args:
        count: Number of animation frames to display
        on_probability: Chance (0-1) that each LED is on (default: 0.66)
    """
    tree = FastRGBChristmasTree()
    
    for _ in range(count):
        for i in range(NUM_LEDS):
            # Determine if LED should be on based on probability
            brightness = 255 if random() < on_probability else 0
            tree[i] = [1, brightness, brightness, brightness]
        tree.commit()


def randomcolour(count):
    """
    Display random vibrant colours on all LEDs.
    
    Each LED gets a randomly generated fully saturated colour,
    creating a colourful disco-like effect.
    
    Args:
        count: Number of animation frames to display
    """
    tree = FastRGBChristmasTree()
    
    for _ in range(count):
        for i in range(NUM_LEDS):
            rgb = random_colour()
            tree[i] = [1, *rgb]  # Unpack RGB values using splat operator
        tree.commit()


if __name__ == '__main__':
    # Main loop - continuously cycle through all lighting effects
    while True:
        swirl(75)          # Swirling colour bands - ~37.5 seconds
        spin(75)           # Spinning colour wheel - ~37.5 seconds
        sparkle(300)       # Twinkling white lights
        randomcolour(300)  # Random disco colours