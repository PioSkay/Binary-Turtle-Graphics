#### Test 2. Draw a 90 pixels of red then 90 pixels of green then 90 pixels of blue.

##### Decoded commands:

Position: 25, 25
Color: Blue
Lenght: 300
Direction: Right
PenState: Down

Position: 115, 25
Color: Green
Lenght: 90
Direction: Right
PenState: Down

Position: 205, 25
Color: Blue
Lenght: 90
Direction: Right
PenState: Down

##### Binary Code:

(start position 25 (x: 0000001101),25 (y: 011001))
01000000
00000000
01100100
00001101

(direction right (11))
00100100
01000011

(color red 111100000000000000000000)
10001111
00000000

(length 90)
11000000
01011010

(color green 1111000000000000)
10000000
11110000

(length 90)
11000000
01011010

(color blue 11110000)
10000000
00001111

(length 90)
11000000
01011010
