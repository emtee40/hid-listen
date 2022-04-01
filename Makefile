PROG = hid_listen

# Target OS (default Linux):
# LINUX / FREEBSD / DARWIN / WINDOWS
OS ?= WINDOWS

# Defaults
TARGET ?= $(PROG)
CC ?= cc
CFLAGS ?= -O2 -Wall -D$(OS)
STRIP ?= strip
LIBS ?=

# Potential per-OS overrides
ifeq ($(OS), LINUX)
else ifeq ($(OS), FREEBSD)
else ifeq ($(OS), DARWIN)
CC = gcc
ifeq ($(shell uname -m),arm64)
	CFLAGS += -arch arm64
else
	CFLAGS += -arch x86_64
endif
LIBS = -framework IOKit -framework CoreFoundation

else ifeq ($(OS), WINDOWS)
# mingw-w64 on Linux
TARGET = $(PROG).exe
CC = i686-w64-mingw32-gcc
STRIP = i686-w64-mingw32-strip
WINDRES = i686-w64-mingw32-windres
LIBS = -lhid -lsetupapi
KEY_SPC = ~/bin/cert/mykey.spc
KEY_PVK = ~/bin/cert/mykey.pvk
KEY_TS = http://timestamp.comodoca.com/authenticode

else ifeq ($(OS), Windows_NT)
# mingw-w64 on Windows
TARGET = $(PROG).exe
CC = gcc
STRIP = strip
WINDRES = windres
LIBS = -lhid -lsetupapi
endif


MAKEFLAGS = --jobs=2
OBJS = hid_listen.o rawhid.o

all: $(TARGET)

$(PROG): $(OBJS)
	$(CC) -o $(PROG) $(OBJS) $(LIBS)
	$(STRIP) $(PROG)

$(PROG).app: $(PROG) Info.plist
	mkdir -p $(PROG).app/Contents/MacOS
	mkdir -p $(PROG).app/Contents/Resources/English.lproj
	cp Info.plist $(PROG).app/Contents/
	echo -n 'APPL????' > $(PROG).app/Contents/PkgInfo
	cp $(PROG) $(PROG).app/Contents/MacOS/$(PROG)
	cp icons/$(PROG).icns $(PROG).app/Contents/Resources/$(PROG).icns
	touch $(PROG).app

$(PROG).dmg: $(PROG).app
	hdiutil create -ov -srcfolder $(PROG).app $(PROG).dmg

$(PROG).exe: $(OBJS)
	$(CC) $(OBJS) -o $(PROG).exe $(LIBS)
	$(STRIP) $(PROG).exe
	#-signcode -spc $(KEY_SPC) -v $(KEY_PVK) -t $(KEY_TS) $(PROG).exe

resource.o: resource.rs icons/$(PROG).ico
	$(WINDRES) -o resource.o resource.rs

clean:
	rm -f *.o $(PROG) $(PROG).exe $(PROG).exe.bak $(PROG).dmg
	rm -rf $(PROG).app

