#include "stdio.h"
#include "string.h"
#include "ruby.h"
#include "math.h"

#include "rf_parser.h"
#include "rf_crc.h"

void Init_rubyfit() {
    VALUE ruby_fit_module = rb_define_module("RubyFit");

    VALUE fit_parser_class = rb_define_class_under(ruby_fit_module, "FitParser", rb_cObject);
    rf_parser_define(fit_parser_class);

    rf_crc_define(ruby_fit_module);
}
