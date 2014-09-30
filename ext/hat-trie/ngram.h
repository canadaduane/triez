#ifndef NGRAM_H
#define NGRAM_H

#include <stdbool.h>
#include "pstdint.h"
#include "hat-trie.h"

#ifdef __cplusplus
extern "C" {
#endif

#define NGRAM_BUFFER_SIZE 4096

void ngram_add_from_text_with_suffix(
  hattrie_t* trie, int upto_n, 
  char* text, size_t text_len, 
  char* suffix, size_t suffix_len, 
  uint8_t incr_existing_keys_only);

#ifdef __cplusplus
}
#endif

#endif
