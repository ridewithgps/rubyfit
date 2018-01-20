
#if !defined(RF_WRITER_H)
#define RF_WRITER_H

extern VALUE writer_init(VALUE self, VALUE handler);
extern VALUE writer_write_header(VALUE self, VALUE original_str);

#endif