## Pd library template version 1.0.4
# For instructions on how to use this template, see:
#  http://puredata.info/docs/developer/MakefileTemplate
LIBRARY_NAME = plugin~

# add your .c source files, one object per file, to the SOURCES
# variable, help files will be included automatically
SOURCES = plugin~.c

# list all pd objects (i.e. myobject.pd) files here, and their helpfiles will
# be included automatically
PDOBJECTS =

# example patches and related files, in the 'examples' subfolder
EXAMPLES =

# manuals and related files, in the 'manual' subfolder
MANUAL =

# if you want to include any other files in the source and binary tarballs,
# list them here.  This can be anything from header files, test patches,
# documentation, etc.  README.txt and LICENSE.txt are required and therefore
# automatically included
EXTRA_DIST = plugin~-gui.pd ChangeLog SConstruct jutils.h plugin~.h

# NOTE: modified to build jload.c and jsearch.c and link it into plugin~
EXTRA_SOURCES = jsearch.c jload.c


#------------------------------------------------------------------------------#
#
# things you might need to edit if you are using other C libraries
#
#------------------------------------------------------------------------------#

CFLAGS = -DPD -I"$(PD_INCLUDE)" -Wall -W -g
LDFLAGS =
LIBS =

#------------------------------------------------------------------------------#
#
# you shouldn't need to edit anything below here, if we did it right :)
#
#------------------------------------------------------------------------------#

# get library version from meta file
LIBRARY_VERSION = $(shell sed -n 's|^\#X text [0-9][0-9]* [0-9][0-9]* VERSION \(.*\);|\1|p' $(LIBRARY_NAME)-meta.pd)

CFLAGS += -DVERSION='"$(LIBRARY_VERSION)"'

PD_INCLUDE = $(PD_PATH)/include
# where to install the library, overridden below depending on platform
prefix = /usr/
libdir = $(prefix)/lib
pkglibdir = $(libdir)/pd/extra
objectsdir = $(pkglibdir)

INSTALL = install
INSTALL_PROGRAM = $(INSTALL) -p -m 644
INSTALL_DATA = $(INSTALL) -p -m 644
INSTALL_DIR     = $(INSTALL) -p -m 755 -d

ALLSOURCES := $(SOURCES) $(SOURCES_android) $(SOURCES_cygwin) $(SOURCES_macosx) \
	         $(SOURCES_iphoneos) $(SOURCES_linux) $(SOURCES_windows)

DISTDIR=$(LIBRARY_NAME)-$(LIBRARY_VERSION)
ORIGDIR=pd-$(LIBRARY_NAME:~=)_$(LIBRARY_VERSION)

UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
  CPU := $(shell uname -p)
  ifeq ($(CPU),arm) # iPhone/iPod Touch
    SOURCES += $(SOURCES_iphoneos)
    EXTENSION = pd_darwin
    OS = iphoneos
    PD_PATH = /Applications/Pd-extended.app/Contents/Resources
    IPHONE_BASE=/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin
    CC=$(IPHONE_BASE)/gcc
    CPP=$(IPHONE_BASE)/cpp
    CXX=$(IPHONE_BASE)/g++
    ISYSROOT = -isysroot /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS3.0.sdk
    IPHONE_CFLAGS = -miphoneos-version-min=3.0 $(ISYSROOT) -arch armv6
    OPT_CFLAGS = -fast -funroll-loops -fomit-frame-pointer
	CFLAGS := $(IPHONE_CFLAGS) $(OPT_CFLAGS) $(CFLAGS)
    LDFLAGS += -arch armv6 -bundle -undefined dynamic_lookup $(ISYSROOT)
    LIBS += -lc
    STRIP = strip -x
    DISTBINDIR=$(DISTDIR)-$(OS)
  else # Mac OS X
    SOURCES += $(SOURCES_macosx)
    EXTENSION = pd_darwin
    OS = macosx
    PD_PATH = /Applications/Pd-extended.app/Contents/Resources
    OPT_CFLAGS = -ftree-vectorize -ftree-vectorizer-verbose=2 -fast
# build universal 32-bit on 10.4 and 32/64 on newer
    ifeq ($(shell uname -r | sed 's|\([0-9][0-9]*\)\.[0-9][0-9]*\.[0-9][0-9]*|\1|'), 8)
      FAT_FLAGS = -arch ppc -arch i386 -mmacosx-version-min=10.4
    else
      FAT_FLAGS = -arch ppc -arch i386 -arch x86_64 -mmacosx-version-min=10.4
      SOURCES += $(SOURCES_iphoneos)
    endif
    CFLAGS += $(FAT_FLAGS) -fPIC -I/sw/include
    LDFLAGS += $(FAT_FLAGS) -bundle -undefined dynamic_lookup -L/sw/lib
    # if the 'pd' binary exists, check the linking against it to aid with stripping
    LDFLAGS += $(shell test -e $(PD_PATH)/bin/pd && echo -bundle_loader $(PD_PATH)/bin/pd)
    LIBS += -lc
    STRIP = strip -x
    DISTBINDIR=$(DISTDIR)-$(OS)
# install into ~/Library/Pd on Mac OS X since /usr/local isn't used much
    pkglibdir=$(HOME)/Library/Pd
  endif
endif
ifeq ($(UNAME),Linux)
  CPU := $(shell uname -m)
  SOURCES += $(SOURCES_linux)
  EXTENSION = pd_linux
  OS = linux
  PD_PATH = /usr
  OPT_CFLAGS = -O6 -funroll-loops -fomit-frame-pointer
  CFLAGS += -fPIC
  LDFLAGS += -Wl,--export-dynamic  -shared -fPIC
  LIBS += -lc
  STRIP = strip --strip-unneeded -R .note -R .comment
  DISTBINDIR=$(DISTDIR)-$(OS)-$(shell uname -m)
endif
ifeq (CYGWIN,$(findstring CYGWIN,$(UNAME)))
  CPU := $(shell uname -m)
  SOURCES += $(SOURCES_cygwin)
  EXTENSION = dll
  OS = cygwin
  PD_PATH = $(cygpath $(PROGRAMFILES))/pd
  OPT_CFLAGS = -O6 -funroll-loops -fomit-frame-pointer
  CFLAGS +=
  LDFLAGS += -Wl,--export-dynamic -shared -L"$(PD_PATH)/src" -L"$(PD_PATH)/bin"
  LIBS += -lc -lpd
  STRIP = strip --strip-unneeded -R .note -R .comment
  DISTBINDIR=$(DISTDIR)-$(OS)
endif
ifeq (MINGW,$(findstring MINGW,$(UNAME)))
  CPU := $(shell uname -m)
  SOURCES += $(SOURCES_windows)
  EXTENSION = dll
  OS = windows
  PD_PATH = $(shell cd "$(PROGRAMFILES)"/pd && pwd)
  OPT_CFLAGS = -O3 -funroll-loops -fomit-frame-pointer -march=i686 -mtune=pentium4
  CFLAGS += -mms-bitfields
  LDFLAGS += -s -shared -Wl,--enable-auto-import
  LIBS += -L"$(PD_PATH)/src" -L"$(PD_PATH)/bin" -L"$(PD_PATH)/obj" -lpd -lwsock32 -lkernel32 -luser32 -lgdi32
  STRIP = strip --strip-unneeded -R .note -R .comment
  DISTBINDIR=$(DISTDIR)-$(OS)
endif

# in case somebody manually set the HELPPATCHES above
HELPPATCHES ?= $(SOURCES:.c=-help.pd) $(PDOBJECTS:.c=-help.pd)

CFLAGS += $(OPT_CFLAGS)


.PHONY = install libdir_install single_install install-doc install-exec install-examples install-manual clean dist etags $(LIBRARY_NAME)

all: $(SOURCES:.c=.$(EXTENSION))

%.o: %.c
	$(CC) $(CFLAGS) -o "$*.o" -c "$*.c"

plugin~.$(EXTENSION): plugin~.o $(EXTRA_SOURCES:.c=.o)
	$(CC) $(LDFLAGS) -o plugin~.$(EXTENSION) plugin~.o $(EXTRA_SOURCES:.c=.o) $(LIBS)
	chmod a-x plugin~.$(EXTENSION)

# this links everything into a single binary file
$(LIBRARY_NAME): $(SOURCES:.c=.o) $(LIBRARY_NAME).o
	$(CC) $(LDFLAGS) -o $(LIBRARY_NAME).$(EXTENSION) $(SOURCES:.c=.o) $(LIBRARY_NAME).o $(LIBS)
	chmod a-x $(LIBRARY_NAME).$(EXTENSION)

install: libdir_install

# The meta and help files are explicitly installed to make sure they are
# actually there.  Those files are not optional, then need to be there.
libdir_install: $(SOURCES:.c=.$(EXTENSION)) install-doc install-examples install-manual
	$(INSTALL_DIR) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)
	$(INSTALL_DATA) $(LIBRARY_NAME)-meta.pd \
		$(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)
	test -z "$(strip $(SOURCES))" || (\
		$(INSTALL_PROGRAM) $(SOURCES:.c=.$(EXTENSION)) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME) && \
		$(STRIP) $(addprefix $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/,$(SOURCES:.c=.$(EXTENSION))))
	test -z "$(strip $(PDOBJECTS))" || \
		$(INSTALL_DATA) $(PDOBJECTS) \
			$(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)

# install library linked as single binary
single_install: $(LIBRARY_NAME) install-doc install-exec
	$(INSTALL_DIR) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)
	$(INSTALL_PROGRAM) $(LIBRARY_NAME).$(EXTENSION) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)
	$(STRIP) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/$(LIBRARY_NAME).$(EXTENSION)

install-doc:
	$(INSTALL_DIR) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)
	test -z "$(strip $(SOURCES) $(PDOBJECTS))" || \
		$(INSTALL_DATA) $(HELPPATCHES) \
			$(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)
	$(INSTALL_DATA) README.txt $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/README.txt
	$(INSTALL_DATA) LICENSE.txt $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/LICENSE.txt

install-examples:
	test -z "$(strip $(EXAMPLES))" || \
		$(INSTALL_DIR) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/examples && \
		for file in $(EXAMPLES); do \
			$(INSTALL_DATA) examples/$$file $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/examples; \
		done

install-manual:
	test -z "$(strip $(MANUAL))" || \
		$(INSTALL_DIR) $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/manual && \
		for file in $(MANUAL); do \
			$(INSTALL_DATA) manual/$$file $(DESTDIR)$(objectsdir)/$(LIBRARY_NAME)/manual; \
		done


clean:
	-rm -f -- $(EXTRA_SOURCES:.c=.o)
	-rm -f -- $(SOURCES:.c=.o) $(SOURCES_LIB:.c=.o)
	-rm -f -- $(SOURCES:.c=.$(EXTENSION))
	-rm -f -- $(LIBRARY_NAME).o
	-rm -f -- $(LIBRARY_NAME).$(EXTENSION)

distclean: clean
	-rm -f -- $(DISTBINDIR).tar.gz
	-rm -rf -- $(DISTBINDIR)
	-rm -f -- $(DISTDIR).tar.gz
	-rm -rf -- $(DISTDIR)
	-rm -f -- $(ORIGDIR).tar.gz
	-rm -rf -- $(ORIGDIR)


$(DISTBINDIR):
	$(INSTALL_DIR) $(DISTBINDIR)

libdir: all $(DISTBINDIR)
	$(INSTALL_DATA) $(LIBRARY_NAME)-meta.pd  $(DISTBINDIR)
	$(INSTALL_DATA) $(SOURCES)  $(DISTBINDIR)
	$(INSTALL_DATA) $(HELPPATCHES) $(DISTBINDIR)
	test -z "$(strip $(EXTRA_DIST))" || \
		$(INSTALL_DATA) $(EXTRA_DIST)    $(DISTBINDIR)
#	tar --exclude-vcs -czpf $(DISTBINDIR).tar.gz $(DISTBINDIR)

$(DISTDIR):
	$(INSTALL_DIR) $(DISTDIR)

$(ORIGDIR):
	$(INSTALL_DIR) $(ORIGDIR)

dist: $(DISTDIR)
	$(INSTALL_DATA) Makefile  $(DISTDIR)
	$(INSTALL_DATA) README.txt $(DISTDIR)
	$(INSTALL_DATA) LICENSE.txt $(DISTDIR)
	$(INSTALL_DATA) $(EXTRA_SOURCES) $(DISTDIR)
	$(INSTALL_DATA) $(LIBRARY_NAME)-meta.pd  $(DISTDIR)
	test -z "$(strip $(ALLSOURCES))" || \
		$(INSTALL_DATA) $(ALLSOURCES)  $(DISTDIR)
	test -z "$(strip $(PDOBJECTS))" || \
		$(INSTALL_DATA) $(PDOBJECTS)  $(DISTDIR)
	test -z "$(strip $(HELPPATCHES))" || \
		$(INSTALL_DATA) $(HELPPATCHES) $(DISTDIR)
	test -z "$(strip $(EXTRA_DIST))" || \
		$(INSTALL_DATA) $(EXTRA_DIST)    $(DISTDIR)
	test -z "$(strip $(EXAMPLES))" || \
		$(INSTALL_DIR) $(DISTDIR)/examples && \
		for file in $(EXAMPLES); do \
			$(INSTALL_DATA) examples/$$file $(DISTDIR)/examples; \
		done
	test -z "$(strip $(MANUAL))" || \
		$(INSTALL_DIR) $(DISTDIR)/manual && \
		for file in $(MANUAL); do \
			$(INSTALL_DATA) manual/$$file $(DISTDIR)/manual; \
		done
	tar --exclude-vcs -czpf $(DISTDIR).tar.gz $(DISTDIR)

# make a Debian source package
dpkg-source:
	debclean
	make distclean dist
	mv $(DISTDIR) $(ORIGDIR)
	tar --exclude-vcs -czpf ../$(ORIGDIR).orig.tar.gz $(ORIGDIR)
	rm -f -- $(DISTDIR).tar.gz
	rm -rf -- $(DISTDIR) $(ORIGDIR)
	cd .. && dpkg-source -b $(LIBRARY_NAME)

etags:
	etags *.h $(SOURCES) ../../pd/src/*.[ch] /usr/include/*.h /usr/include/*/*.h

showsetup:
	@echo "CFLAGS: $(CFLAGS)"
	@echo "LDFLAGS: $(LDFLAGS)"
	@echo "LIBS: $(LIBS)"
	@echo "PD_INCLUDE: $(PD_INCLUDE)"
	@echo "PD_PATH: $(PD_PATH)"
	@echo "objectsdir: $(objectsdir)"
	@echo "LIBRARY_NAME: $(LIBRARY_NAME)"
	@echo "LIBRARY_VERSION: $(LIBRARY_VERSION)"
	@echo "SOURCES: $(SOURCES)"
	@echo "PDOBJECTS: $(PDOBJECTS)"
	@echo "ALLSOURCES: $(ALLSOURCES)"
	@echo "UNAME: $(UNAME)"
	@echo "CPU: $(CPU)"
	@echo "pkglibdir: $(pkglibdir)"
	@echo "DISTDIR: $(DISTDIR)"
	@echo "ORIGDIR: $(ORIGDIR)"
