#include "hexdump.h"

void hexdump(void* data, int size)
{
  /* dumps size bytes of *data to stdout. Looks like:
   * [0000] 75 6E 6B 6E 6F 77 6E 20
   *                  30 FF 00 00 00 00 39 00 unknown 0.....9.
   * (in a single line of course)
   */
  unsigned char *p = data;
  unsigned char c;
  int n;
  char bytestr[4] = {0};
  char addrstr[10] = {0};
  char hexstr[ 16*3 + 5] = {0};
  char charstr[16*1 + 5] = {0};
  printf("BEGIN HEX DUMP\n");
  for (n=1;n<=size;n++)
  {
    if (n%16 == 1)
    {
      /* store address for this line */
      snprintf(addrstr, sizeof(addrstr), "%.8x",
               ((unsigned int)p-(unsigned int)data));
    }
    c = *p;
    if (isalnum(c) == 0)
    {
      c = '.';
    }
    /* store hex str (for left side) */
    snprintf(bytestr, sizeof(bytestr), "%02X ", *p);
    strncat(hexstr, bytestr, sizeof(hexstr)-strlen(hexstr)-1);
    /* store char str (for right side) */
    snprintf(bytestr, sizeof(bytestr), "%c", c);
    strncat(charstr, bytestr, sizeof(charstr)-strlen(charstr)-1);
    if (n%16 == 0)
    {
      /* line completed */
      //if (strlen(addrstr) <= 4)
        printf("[%8.8s]   %-50.50s  %s (%d)\n", addrstr, hexstr, charstr, n);
      hexstr[0] = 0;
      charstr[0] = 0;
    }
    else if (n%8 == 0)
    {
      /* half line: add whitespaces */
      strncat(hexstr, "  ", sizeof(hexstr)-strlen(hexstr)-1);
      strncat(charstr, " ", sizeof(charstr)-strlen(charstr)-1);
    }
    p++; /* next byte */
  }
  if (strlen(hexstr) > 0)
  {
    /* print rest of buffer if not empty */
    printf("[%8.8s]   %-50.50s  %s (%d)\n", addrstr, hexstr, charstr, n);
  }
  printf("END HEX DUMP\n");
}
