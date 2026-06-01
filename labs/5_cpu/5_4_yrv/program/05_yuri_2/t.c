#include "stdio.h"

#define MASK_FROM_HI_LO_BIT1(hi, lo)  ((~ 0u >> (31 - (hi))) & (~ 0 << (lo)))
#define MASK_FROM_HI_LO_BIT2(hi, lo)  (~ (~ 0 << ((hi) - (lo) + 1)) << (lo))

void main ()
{
    printf ("%x\n", (~ (~ 0 << ((31) - (0) + 1)) << (0)));

    for (int j = 0; j < 32; j ++)
    {
        for (int i = j; i < 32; i ++)
        {
            printf ("%d %d %x %x\n", i, j, MASK_FROM_HI_LO_BIT1 (i, j), MASK_FROM_HI_LO_BIT2 (i, j));

            if (MASK_FROM_HI_LO_BIT1 (i, j) != MASK_FROM_HI_LO_BIT2 (i, j))
            {
                 printf ("Bad\n");
                 return;
            }
        }
    }
}
