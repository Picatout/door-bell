/* 
Conversion de fichier binaire
en représentation hexadécimale
USAGE: convert addr file 
addr  adresse de départ en hexadecimal 
file  nom du fichier 
*/

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>   /* File Control Definitions           */
#include <termios.h> /* POSIX Terminal Control Definitions */
#include <unistd.h>  /* UNIX Standard Definitions 	   */ 
#include <time.h>
#include <string.h>
#include <stdint.h>

static void usage(){
	puts("Command line tool to convert binary file to hexadecimal representation");
    puts("each line in the form '6X: 2X...'  with 64 bytes per line.");
	puts("USAGE: convert address in out.");
	puts("  'address' is start address in hexadecimal.");
	puts("  'in' is input file name.");
	puts("   'out' is output file name.");
	exit(0);
}

#define LF (10)
#define CR (13)

char* in_file;
char* out_file;
int addr;

FILE* in,*out;

int main(int argc , char** argv ){
uint8_t b; 

    if (argc<4) usage() ;
    in_file=argv[2];
    out_file=argv[3];
    addr=(int)strtol(argv[1], NULL, 16); 
    in=fopen(in_file,"rb");
    if (!in) {printf("%s file not found\n",in_file);exit(0);}
    out=fopen(out_file,"wb");
    while (!feof(in)) {
         fprintf(out,"%06X: ",addr);
         for (int i=0;i<16;i++){
            fread(&b,1,1,in);
            fprintf(out,"%02X ",b);
         }
         fprintf(out,"\n");
         addr+=64;   
    }
}



