/*
 * COPYRIGHT:   See COPYING in the top level directory
 * PROJECT:     ReactOS system libraries
 * FILE:        lib/msvcrt/mbstring/hanzen.c
 * PURPOSE:     Multibyte conversion routines formerly called hantozen and zentohan
 * PROGRAMER:   Boudewijn Dekker, Taiji Yamada
 * UPDATE HISTORY:
		Modified from Taiji Yamada japanese code system utilities
 *              12/04/99: Created
 */

#include <mbctype.h>

static unsigned short han_to_zen_ascii_table[0x5f] = {
  0x8140, 0x8149, 0x8168, 0x8194, 0x8190, 0x8193, 0x8195, 0x8166,
  0x8169, 0x816a, 0x8196, 0x817b, 0x8143, 0x817c, 0x8144, 0x815e,
  0x824f, 0x8250, 0x8251, 0x8252, 0x8253, 0x8254, 0x8255, 0x8256,
  0x8257, 0x8258, 0x8146, 0x8147, 0x8183, 0x8181, 0x8184, 0x8148,
  0x8197, 0x8260, 0x8261, 0x8262, 0x8263, 0x8264, 0x8265, 0x8266,
  0x8267, 0x8268, 0x8269, 0x826a, 0x826b, 0x826c, 0x826d, 0x826e,
  0x826f, 0x8270, 0x8271, 0x8272, 0x8273, 0x8274, 0x8275, 0x8276,
  0x8277, 0x8278, 0x8279, 0x816d, 0x818f, 0x816e, 0x814f, 0x8151,
  0x8165, 0x8281, 0x8282, 0x8283, 0x8284, 0x8285, 0x8286, 0x8287,
  0x8288, 0x8289, 0x828a, 0x828b, 0x828c, 0x828d, 0x828e, 0x828f,
  0x8290, 0x8291, 0x8292, 0x8293, 0x8294, 0x8295, 0x8296, 0x8297,
  0x8298, 0x8299, 0x829a, 0x816f, 0x8162, 0x8170, 0x8150
};
static unsigned short han_to_zen_kana_table[0x40] = {
  0x8140, 0x8142, 0x8175, 0x8176, 0x8141, 0x8145, 0x8392, 0x8340,
  0x8342, 0x8344, 0x8346, 0x8348, 0x8383, 0x8385, 0x8387, 0x8362,
  0x815b, 0x8341, 0x8343, 0x8345, 0x8347, 0x8349, 0x834a, 0x834c,
  0x834e, 0x8350, 0x8352, 0x8354, 0x8356, 0x8358, 0x835a, 0x835c,
  0x835e, 0x8360, 0x8363, 0x8365, 0x8367, 0x8369, 0x836a, 0x836b,
  0x836c, 0x836d, 0x836e, 0x8371, 0x8374, 0x8377, 0x837a, 0x837d,
  0x837e, 0x8380, 0x8381, 0x8382, 0x8384, 0x8386, 0x8388, 0x8389,
  0x838a, 0x838b, 0x838c, 0x838d, 0x838f, 0x8393, 0x814a, 0x814b
};
static unsigned char zen_to_han_kana_table[0x8396-0x8340+1] = {
  0xa7, 0xb1, 0xa8, 0xb2, 0xa9, 0xb3, 0xaa, 0xb4,
  0xab, 0xb5, 0xb6, 0xb6, 0xb7, 0xb7, 0xb8, 0xb8,
  0xb9, 0xb9, 0xba, 0xba, 0xbb, 0xbb, 0xbc, 0xbc,
  0xbd, 0xbd, 0xbe, 0xbe, 0xbf, 0xbf, 0xc0, 0xc0,
  0xc1, 0xc1, 0xaf, 0xc2, 0xc2, 0xc3, 0xc3, 0xc4,
  0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xca,
  0xca, 0xcb, 0xcb, 0xcb, 0xcc, 0xcc, 0xcc, 0xcd,
  0xcd, 0xcd, 0xce, 0xce, 0xce, 0xcf, 0xd0, 0,
  0xd1, 0xd2, 0xd3, 0xac, 0xd4, 0xad, 0xd5, 0xae,
  0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdc,
  0xb2, 0xb4, 0xa6, 0xdd, 0xb3, 0xb6, 0xb9
};
#define ZTOH_SYMBOLS 9
static unsigned short zen_to_han_symbol_table_1[ZTOH_SYMBOLS] = {
  0x8142, 0x8175, 0x8176, 0x8141, 0x8145, 0x815b, 0x814a, 0x814b
};
static unsigned char zen_to_han_symbol_table_2[ZTOH_SYMBOLS] = {
  0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xb0, 0xde, 0xdf
};
#define ISKANA(c) ((c) >= 0xa1 && (c) <= 0xdf)
#define JISHIRA(c) ((c) >= 0x829f && (c) <= 0x82f1)
#define JISKANA(c) ((c) >= 0x8340 && (c) <= 0x8396 && (c) != 0x837f)
#define JTOKANA(c) ((c) <= 0x82dd ? (c) + 0xa1 : (c) + 0xa2)

 
/*
 * @implemented
 */
unsigned short _mbbtombc(unsigned short c)
{
  if (c >= 0x20 && c <= 0x7e) {
    return han_to_zen_ascii_table[c - 0x20];
  } else if (ISKANA(c)) {
    return han_to_zen_kana_table[c - 0xa0];
  }
  return c;
}


/*
 * @implemented
 */
unsigned short _mbctombb(unsigned short c)
{
  int i;
  unsigned short *p;

  if (JISKANA(c)) {
    return zen_to_han_kana_table[c - 0x8340];
  } else if (JISHIRA(c)) {
    c = JTOKANA(c);
    return zen_to_han_kana_table[c - 0x8340];
  } else if (c <= 0x8396) {
    for (i = 0x20, p = han_to_zen_ascii_table; i <= 0x7e; i++, p++) {
      if (*p == c) {
        return i;
      }
    }
    for (i = 0; i < ZTOH_SYMBOLS; i++) {
      if (zen_to_han_symbol_table_1[i] == c) {
        return zen_to_han_symbol_table_2[i];
      }
    }
  }
  return c;
}



