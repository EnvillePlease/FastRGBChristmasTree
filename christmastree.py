'''
Configure different LED patterns
'''
from tree import FastRGBChristmasTree
from time import sleep

def random_colour():
    h = random()
    s = 1
    v = 1
    hsv = Color.from_hsv(h,s,v)
    rgb = list(hsv.rgb)
    rgb = [int(rgb[0]*255), int(rgb[1]*255), int(rgb[2]*255)]
    return (rgb)

def swirl(count):
    x=0
    
    tree = FastRGBChristmasTree()
    i = 0
    j = 1
    k = 2
    l = 3
    
    tree[3] = [255,255,255]
    while x < count:
        tree[:,i*2]   = [[255, 0, 0], [255, 255, 0], [0, 255, 0]]
        tree[:,i*2+1] = [[255, 0, 0], [255, 255, 0], [0, 255, 0]]
        tree[:,j*2]   = [[255, 255, 0], [0, 255, 0], [0, 0, 255]]
        tree[:,j*2+1] = [[255, 255, 0], [0, 255, 0], [0, 0, 255]]
        tree[:,k*2]   = [[0, 255, 0], [0, 0, 255], [255, 0, 0]]
        tree[:,k*2+1] = [[0, 255, 0], [0, 0, 255], [255, 0, 0]]
        tree[:,l*2]   = [[0, 0, 255], [255, 0, 0], [255, 255, 0]]
        tree[:,l*2+1] = [[0, 0, 255], [255, 0, 0], [255, 255, 0]]

        tree.commit()

        t = i
        i = j
        j = k
        k = l
        l = t
        
        x = x +1
        
        sleep(0.5)
    return()

def spin(count):
    return()

def sparkle(count):
    return()

def random(count):
    return()


if __name__ == '__main__':

    
    swirl(10)
    