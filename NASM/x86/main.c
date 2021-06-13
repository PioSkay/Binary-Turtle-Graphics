#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define input_file "input.bin"
#define output_file "output.bmp"
//Declaration of the size of the image
#define WIDTH 600
#define HEIGHT 50
#define BMP_PIXEL_OFFSET 54
#define BMP_HEADER_SIZE 40
#define BMP_PLANES 1
#define BMP_BITCOUNT 24
#define BMP_COMPRESSION 0
#define BMP_H_RES 12000
#define BMP_V_RES 12000
//This is the initialization of the primitive data types for C/C++
//
//Source: http://msdn.microsoft.com/en-us/library/cc230309.aspx.

typedef uint8_t  BYTE;
typedef uint32_t DWORD;
typedef int32_t  LONG;
typedef uint16_t WORD;

// 
// The BITMAPFILEHEADER structure contains information about the type, size,
// and layout of a file that contains a DIB [device-independent bitmap].
//
// Source: http://msdn.microsoft.com/en-us/library/dd183374(VS.85).aspx.
// And : http://msdn.microsoft.com/en-us/library/dd183376(VS.85).aspx.

typedef struct
{
    WORD   bfType;
    DWORD  bfSize;
    WORD   bfReserved1;
    WORD   bfReserved2;
    DWORD  bfOffBits;
    DWORD  biSize;
    LONG   biWidth;
    LONG   biHeight;
    WORD   biPlanes;
    WORD   biBitCount;
    DWORD  biCompression;
    DWORD  biSizeImage;
    LONG   biXPelsPerMeter;
    LONG   biYPelsPerMeter;
    DWORD  biClrUsed;
    DWORD  biClrImportant;
} __attribute__((__packed__))
BITMAPFILEHEADER;

// The BITMAPINFOHEADER structure contains information about the
// dimensions and color format of a DIB [device-independent bitmap].

//
// This structure will later be implemented in the x86 asm
// it describes the commands of the turtle

typedef struct {
    DWORD x;
    DWORD y;
    BYTE R;
    BYTE G;
    BYTE B;
    BYTE penState;
    BYTE direction;
    BYTE setPos;
} __attribute__((__packed__))
TURTLECOMMAND;

//
// I have decided to implement a simple vector container.
// It is automatically resizing itself.

typedef struct {
    WORD*  data;
    int    index;
    int    max_number_of_elements;
}VECTOR;

int init(VECTOR* vec, int max_ele)
{
    vec->data = (WORD*)calloc(max_ele, sizeof(WORD));
    if(vec->data == NULL)
    {
    	return 1;
    }
    vec->max_number_of_elements = max_ele;
    vec->index = 0;
    return 0;
}
 
int add(VECTOR* vec, WORD* ele)
{
    if (vec->index + 1 >= vec->max_number_of_elements)
    {
    	vec->max_number_of_elements = vec->max_number_of_elements*2;
    	vec->data = (WORD*)realloc(vec->data, sizeof(WORD) * vec->max_number_of_elements);
    	if(vec->data == NULL)
    	{
    	    return 1;
    	}
    }
    vec->data[vec->index] = *ele;
    vec->index += 1;
    return 0;
}

//Exporting the asm method.

extern "C" int turtle(BYTE *dest_bitmap,
                      WORD *commands,
                      TURTLECOMMAND *commands_context);
                      
                      
BYTE* create(DWORD* bmpbuffer) 
{
    // bitmap parameters
    DWORD row_size = (600 * 3 + 3) & ~3;
    DWORD bitmap_size = row_size * 50;

    *bmpbuffer = BMP_PIXEL_OFFSET + bitmap_size;

    BYTE *bitmap = (BYTE *)malloc(*bmpbuffer);

    //Creating the bitmap header
    BITMAPFILEHEADER header;

    header.bfType = 0x4D42;
    header.bfSize = *bmpbuffer;
    header.bfReserved1 = 0;
    header.bfReserved2 = 0;
    header.bfOffBits = BMP_PIXEL_OFFSET;
    header.biSize = BMP_HEADER_SIZE;
    header.biWidth = 600;
    header.biHeight = 50;
    header.biPlanes = BMP_PLANES;
    header.biBitCount = BMP_BITCOUNT;
    header.biCompression = BMP_COMPRESSION;
    header.biSizeImage = bitmap_size;
    header.biXPelsPerMeter = BMP_H_RES;
    header.biYPelsPerMeter = BMP_V_RES;
    header.biClrUsed = 0;
    header.biClrImportant = 0;

    memcpy(bitmap, &header, BMP_PIXEL_OFFSET);

    // Now we need to fill the file with the color
    DWORD * tmptr = (DWORD *)(bitmap+BMP_PIXEL_OFFSET);

    for (int cnt = 0; cnt++ < bitmap_size>>2; tmptr++) 
    {
        *tmptr = 0xFFFFFFFF;
    }

    // Returning an adress to the bitmap
    return bitmap;
}

int save(unsigned char *bmpbuffer, unsigned int bmpbuffer_size) 
{

    FILE *file = fopen(output_file, "wb");

    if (file == NULL) 
    {
        printf("Could not open output file!");
        return 0;
    }

    fwrite(bmpbuffer, 1, bmpbuffer_size, file);

    fclose(file);

    return 1;
}

int main(void)
{
    //Opening the commands file.
    FILE* commands = fopen(input_file, "r");
    if (commands == NULL)
    {
    	fclose(commands);
	fprintf(stderr, "Could not find input file!");
	return 1;	
    }
    VECTOR vec;
    if(init(&vec, 10) == 1)
    {
    	printf("Not enough memory!");
    }
    char buf[2];
    while(fread(buf, 1, 2, commands) == 2)
    {
	add(&vec, (WORD*)buf);
    }

    int height = 50;
    int width = 600;
    
    //Allocation of the image.
    DWORD size;
    BYTE* image = create(&size);
    TURTLECOMMAND local_context;

    //Zero the necessary conditions.
    local_context.x = 0;
    local_context.y = 0;
    local_context.setPos = 0;

    //Initialization of the assembly method.
    for (int i = 0; i < vec.index; i++)
    {
        turtle(image, &vec.data[i], &local_context);
        printf("Pos_X = %d, Pos_Y = %d, Direction = %d, Pen State = %d, R = %d, G = %d, B = %d\n", 
        	local_context.x,
        	local_context.y,
        	local_context.direction,
        	local_context.penState,
        	local_context.R,
        	local_context.G,
        	local_context.B);
    }
    save(image, size);
    
    return 0;
}
