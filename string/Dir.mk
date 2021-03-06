# Makefile fragment - requires GNU make
#
# Copyright (c) 2019-2020, Arm Limited.
# SPDX-License-Identifier: MIT

S := $(srcdir)/string
B := build/string

ifeq ($(ARCH),)
all-string bench-string check-string install-string clean-string:
	@echo "*** Please set ARCH in config.mk. ***"
	@exit 1
else

string-lib-srcs := $(wildcard $(S)/$(ARCH)/*.[cS])
string-test-srcs := $(wildcard $(S)/test/*.c)
string-bench-srcs := $(wildcard $(S)/bench/*.c)

string-includes := $(patsubst $(S)/%,build/%,$(wildcard $(S)/include/*.h))

string-libs := \
	build/lib/libstringlib.so \
	build/lib/libstringlib.a \

string-tools := \
	build/bin/test/memcpy \
	build/bin/test/memmove \
	build/bin/test/memset \
	build/bin/test/memchr \
	build/bin/test/memcmp \
	build/bin/test/strcpy \
	build/bin/test/stpcpy \
	build/bin/test/strcmp \
	build/bin/test/strchr \
	build/bin/test/strrchr \
	build/bin/test/strchrnul \
	build/bin/test/strlen \
	build/bin/test/strnlen \
	build/bin/test/strncmp

string-benches := build/bin/bench/memcpy

string-lib-objs := $(patsubst $(S)/%,$(B)/%.o,$(basename $(string-lib-srcs)))
string-test-objs := $(patsubst $(S)/%,$(B)/%.o,$(basename $(string-test-srcs)))
string-bench-objs := $(patsubst $(S)/%,$(B)/%.o,$(basename $(string-bench-srcs)))

string-objs := \
	$(string-lib-objs) \
	$(string-lib-objs:%.o=%.os) \
	$(string-test-objs) \
	$(string-bench-objs)

string-files := \
	$(string-objs) \
	$(string-libs) \
	$(string-tools) \
	$(string-benches) \
	$(string-includes) \

all-string: $(string-libs) $(string-tools) $(string-benches) $(string-includes)

$(string-objs): $(string-includes)
$(string-objs): CFLAGS_ALL += $(string-cflags)

build/lib/libstringlib.so: $(string-lib-objs:%.o=%.os)
	$(CC) $(CFLAGS_ALL) $(LDFLAGS) -shared -o $@ $^

build/lib/libstringlib.a: $(string-lib-objs)
	rm -f $@
	$(AR) rc $@ $^
	$(RANLIB) $@

build/bin/test/%: $(B)/test/%.o build/lib/libstringlib.a
	$(CC) $(CFLAGS_ALL) $(LDFLAGS) -static -o $@ $^ $(LDLIBS)

build/bin/bench/%: $(B)/bench/%.o build/lib/libstringlib.a
	$(CC) $(CFLAGS_ALL) $(LDFLAGS) -static -o $@ $^ $(LDLIBS)

build/include/%.h: $(S)/include/%.h
	cp $< $@

build/bin/%.sh: $(S)/test/%.sh
	cp $< $@

check-string: $(string-tools)
	$(EMULATOR) build/bin/test/memcpy
	$(EMULATOR) build/bin/test/memmove
	$(EMULATOR) build/bin/test/memset
	$(EMULATOR) build/bin/test/memchr
	$(EMULATOR) build/bin/test/memcmp
	$(EMULATOR) build/bin/test/strcpy
	$(EMULATOR) build/bin/test/stpcpy
	$(EMULATOR) build/bin/test/strcmp
	$(EMULATOR) build/bin/test/strchr
	$(EMULATOR) build/bin/test/strrchr
	$(EMULATOR) build/bin/test/strchrnul
	$(EMULATOR) build/bin/test/strlen
	$(EMULATOR) build/bin/test/strnlen
	$(EMULATOR) build/bin/test/strncmp

bench-string: $(string-benches)
	$(EMULATOR) build/bin/bench/memcpy

install-string: \
 $(string-libs:build/lib/%=$(DESTDIR)$(libdir)/%) \
 $(string-includes:build/include/%=$(DESTDIR)$(includedir)/%)

clean-string:
	rm -f $(string-files)
endif

.PHONY: all-string bench-string check-string install-string clean-string
