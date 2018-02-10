require 'mkmf'

$CFLAGS << ' -DFIT_USE_STDINT_H '

create_makefile("rubyfit/rubyfit")
