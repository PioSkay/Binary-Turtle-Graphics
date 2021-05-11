#### MIPS Implementation of turtle graphics.

##### Description 
In the project I have created a command like version of the turtles graphics. Code accepts .bin file format with the commands in a binary form. 

##### input `input.bin`
16/32 bit binary commands in a following form.

###### Set position command. (32-bit)
x and y are the indexes of the binary code of a position.

| i0 | i1 | i2 | i3 | i4 | i5 | i6 | i7 |
| - | - | - | - | - | - | - | - |
| 0 | 1 | - | - | - | - | - | - |
| - | - | - | - | - | - | - | - |
| y5 | y4 | y3 | y2 | y1 | y0 | x9 | x8 |
| x7 | x6 | x5 | x4 | x3 | x2 | x1 | x0 |

###### Set direction command. (16-bit)
d binary form of the direction. (0-up, 1-left, 2-down, 3-right)

| i0 | i1 | i2 | i3 | i4 | i5 | i6 | i7 |
| - | - | - | - | - | - | - | - |
| 0 | 0 | - | - | - | - | - | - |
| - | - | - | - | - | - | d1 | d0 |

###### Move command. (16-bit)
m indexes of the binary form of a number of blocks to move.

| i0 | i1 | i2 | i3 | i4 | i5 | i6 | i7 |
| - | - | - | - | - | - | - | - |
| 1 | 1 | - | - | - | - | m9 | m8 |
| m7 | m6 | m5 | m4 | m3 | m2 | m1 | m0 |

###### Set pen state command. (16-bit)
ud state of the pen (0 - pen lowered, 1 - pen raised).
b/r/g(blue/red/green) binary code of the most significant bits of the colors.

| i0 | i1 | i2 | i3 | i4 | i5 | i6 | i7 |
| - | - | - | - | - | - | - | - |
| 1 | 0 | - | ud | b3 | b2 | b1 | b0 |
| g3 | g2 | g1 | g0 | r3 | r2 | r1 | r0 |


##### output `output.bmp`
600 x 50 image with the implemented changes.