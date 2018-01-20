

#include "stdio.h"
#include "string.h"
#include "ruby.h"
#include "math.h"

VALUE mRubyFit;
VALUE cFitParser;
VALUE cFitWriter;

#include "rf_parser.h"
#include "rf_writer.h"

void Init_rubyfit() {
    mRubyFit = rb_define_module("RubyFit");
    cFitParser = rb_define_class_under(mRubyFit, "FitParser", rb_cObject);
//    cFitWriter = rb_define_class_under(mRubyFit, "FitWriter", rb_cObject);

    rf_parser_define(cFitParser);

//	rb_define_method(cFitWriter, "initialize", writer_init, 1);
//	rb_define_method(cFitWriter, "writeHeader", writer_write_header, 1);

}
