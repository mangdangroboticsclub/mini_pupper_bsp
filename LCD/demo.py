import os
import sys
import time
from PIL import Image
from ST7789 import ST7789

def main():
    """ The demo for picture show
    """
    #init st7789 device
    time.sleep(1)
    disp = ST7789()
    disp.begin()
    disp.clear()
    image=Image.open("/home/ubuntu/Pictures/logo.png")
    image.resize((320,240))
    disp.display(image)
try:
    main()
except KeyboardInterrupt:
    pass

