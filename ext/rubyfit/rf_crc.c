#define _CRT_SECURE_NO_WARNINGS

#include "rf_crc.h"

#include "fit_example.h"
#include "fit_crc.h"

#include "string.h"

static VALUE update_crc(VALUE self, VALUE r_crc, VALUE r_data) {
    FIT_UINT16 crc = NUM2USHORT(r_crc);
    const char* data = StringValuePtr(r_data);
    const FIT_UINT16 byte_count = RSTRING_LEN(r_data);
    return UINT2NUM(FitCRC_Update16(crc, data, byte_count));
}

void rf_crc_define(VALUE rubyfit_module) {
    VALUE writer_module = rb_define_module_under(rubyfit_module, "CRC");

    rb_define_singleton_method(writer_module, "update_crc", update_crc, 2);
}

