#include<stdint.h>

uint32_t divide(uint32_t n, uint32_t d) {
    // n is dividend, d is divisor
    // store the result in q: q = n / d
    uint32_t q = 0;

    // as long as the divisor fits into the remainder there is something to do
    while (n >= d) {
        uint32_t i = 0, d_t = d;
        // determine to which power of two the divisor still fits the dividend
        //
        // i.e.: we intend to subtract the divisor multiplied by powers of two
        // which in turn gives us a one in the binary representation 
        // of the result
        while (n >= (d_t << 1)) {
            i++;
            d_t <<= 1;
        }
        // set the corresponding bit in the result
        q |= 1 << i;
        // subtract the multiple of the divisor to be left with the remainder
        n = n - d_t;
        // repeat until the divisor does not fit into the remainder anymore
    }
    return q;
}

uint32_t multiply(uint32_t a, uint32_t b) {
    uint32_t result = 0;

   if (a == 0)
     return 0;

  while (b != 0)
    {
      if (b & 1)
    result += a;
      a <<= 1;
      b >>= 1;
    }

  return result;
}

uint32_t mod(uint32_t a, uint32_t b) {
    uint32_t r = divide(a, b); // truncated division
    return a - multiply(r, b);
}


uint32_t mul10(uint32_t a)
{
    return a<<3+a<<1;
}

unsigned divu10(unsigned n)
{
    unsigned q, r;
    q = (n >> 1) + (n >> 2);
    q = q + (q >> 4);
    q = q + (q >> 8);
    q = q + (q >> 16);
    q = q >> 3;
    r = n - ((q<<3)+(q<<1));
    return q + ((r + 6) >> 4);
}

uint32_t mod10(uint32_t a) {
    uint32_t r = divu10(a); // truncated division
    return a - mul10(r);
}


unsigned int strlen(const char *s)
{
    unsigned int count = 0;
    while(*s!='\0')
    {
        count++;
        s++;
    }
    return count;
}


void reverse(char s[])
{
     int i, j;
     char c;
 
     for (i = 0, j = strlen(s)-1; i<j; i++, j--) {
         c = s[i];
         s[i] = s[j];
         s[j] = c;
     }
}




/* (c) K&R itoa */
void itoa(int n, char s[])
{
     int i, sign;
     s[0] = 48;
     s[1] = 48;
     s[2] = 48;
     s[3] = 0;
     i=0;
     do
     {
	s[i++] = n%10 + '0';
     }
     while((n = divide(n,10)) > 0);
     s[i] = 0;
    reverse(s);

}

