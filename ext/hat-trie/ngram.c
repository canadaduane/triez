#include "ngram.h"
#include <stdio.h>
#include <string.h>
#include <assert.h>

static inline void _incr_value(
  hattrie_t* trie,
  char* buffer,
  char* buffer_pre,
  char* key,
  size_t len,
  size_t suffix_len,
  uint8_t incr_existing_keys_only)
{
  value_t* value = NULL;

  assert(buffer_pre - len >= buffer);
  
  if (incr_existing_keys_only) {
    value = hattrie_tryget(trie, key, len);
    if (value) {
      memcpy(buffer_pre - len, key, len);
      value = hattrie_get(trie, buffer_pre - len, len + suffix_len);
      (*value)++;
    }
  } else {
    memcpy(buffer_pre - len, key, len);
    value = hattrie_get(trie, buffer_pre - len, len + suffix_len);
    (*value)++;
  }

}

void ngram_add_from_text_with_suffix(hattrie_t* trie, int upto_n, char* text, size_t text_len, char* suffix, size_t suffix_len, uint8_t incr_existing_keys_only)
{
  char* head = text;
  char* tail = text;
  char* next_head = text;
  char* next_tail = text;
  int word_count = 0;

  if (text_len == 0) return;

  char buffer[NGRAM_BUFFER_SIZE];
  size_t buffer_offset = NGRAM_BUFFER_SIZE - suffix_len - 1;
  char* buffer_pre = buffer + buffer_offset;
  memcpy(buffer_pre, suffix, suffix_len);

  do {
    if (*tail == ' ' || *tail == '.' || tail >= head+text_len) {
      word_count++;
      if (word_count == 1 || upto_n == 1) {
        next_head = next_tail = tail + 1;
      } else if (word_count == 2) {
        next_tail = tail;
      }
      if (word_count <= upto_n) {
        _incr_value(trie, buffer, buffer_pre,
          head, tail - head, suffix_len,
          incr_existing_keys_only);
      }
      if (word_count == upto_n) {
        head = next_head;
        tail = next_tail;
        word_count = 0;
      } else {
        tail++;
      }
    } else {
      tail++;
    }
  } while(*tail);

  // add the last ngram of size upto_n
  _incr_value(trie, buffer, buffer_pre, 
    head, tail - head, suffix_len,
    incr_existing_keys_only);

  // add the 1..(upto_n-1) sized ngrams at the tail
  if (upto_n > 1) {
    while(head < text+text_len) {
      if(*head == ' ' || *head == '.') {
        _incr_value(trie, buffer, buffer_pre,
          head + 1, tail - head - 1, suffix_len,
          incr_existing_keys_only);
      }
      head++;
    }
  }
}
