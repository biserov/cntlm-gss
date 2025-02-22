#
# You can tweak these three variables to make things install where you
# like, but do not touch more unless you know what you are doing. ;)
#
DESTDIR=
SYSCONFDIR=$(DESTDIR)/etc
BINDIR=$(DESTDIR)/usr/sbin
MANDIR=$(DESTDIR)/usr/share/man

#
# Careful now...
# __BSD_VISIBLE is for FreeBSD AF_* constants
# _ALL_SOURCE is for AIX 5.3 LOG_PERROR constant
#
NAME=cntlm
CC=gcc
VER := $(shell cat VERSION)

VERBOSE ?= 0
ifeq ($(VERBOSE),1)
V:=
else
V:=@
endif


DEBUG ?= 0
ifeq ($(DEBUG),1)
CFLAGS+=$(FLAGS) -O0 -g
else
CFLAGS+=$(FLAGS) -O3
endif

CFLAGS+=$(FLAGS) -std=c99 -Wall -Wno-unused-but-set-variable -pedantic -D__BSD_VISIBLE -D_ALL_SOURCE -D_XOPEN_SOURCE=600 -D_POSIX_C_SOURCE=200112 -D_ISOC99_SOURCE -D_REENTRANT -D_DEFAULT_SOURCE -DVERSION=\"$(VER)\"

OS=$(shell uname -s)
OSLDFLAGS=$(shell [ $(OS) = "SunOS" ] && echo "-lrt -lsocket -lnsl")
LDFLAGS:=-lpthread $(OSLDFLAGS)

ifeq ($(findstring CYGWIN,$(OS)),)
	OBJS=utils.o ntlm.o xcrypt.o config-file.o socket.o acl.o auth.o http.o forward.o direct.o scanner.o pages.o main.o
else
	OBJS=utils.o ntlm.o xcrypt.o config-file.o socket.o acl.o auth.o http.o forward.o direct.o scanner.o pages.o main.o win/resources.o
endif

ENABLE_KERBEROS=$(shell grep -c ENABLE_KERBEROS config.h)
ifeq ($(ENABLE_KERBEROS),1)
	OBJS+=kerberos.o
	LDFLAGS+=-lgssapi_krb5
endif

#CFLAGS+=-g

all: $(NAME)

$(NAME): configure-stamp $(OBJS)
	@echo "Linking $@"
	$(V)$(CC) $(CFLAGS) -o $@ $(OBJS) $(LDFLAGS)

main.o: main.c
	@echo "Compiling $<"
	$(V)if [ -z "$(SYSCONFDIR)" ]; then \
		$(CC) $(CFLAGS) -c main.c -o $@; \
	else \
		$(CC) $(CFLAGS) -DSYSCONFDIR=\"$(SYSCONFDIR)\" -c main.c -o $@; \
	fi

.c.o:
	@echo "Compiling $<"
	$(V)$(CC) $(CFLAGS) -c -o $@ $<

install: $(NAME)
	# Special handling for install(1)
	if [ "`uname -s`" = "AIX" ]; then \
		install -M 755 -S -f $(BINDIR) $(NAME); \
		install -M 644 -f $(MANDIR)/man1 doc/$(NAME).1; \
		install -M 600 -c $(SYSCONFDIR) doc/$(NAME).conf; \
	elif [ "`uname -s`" = "Darwin" ]; then \
		install -d -m 755 -s $(NAME) $(BINDIR)/$(NAME); \
		install -d -m 644 doc/$(NAME).1 $(MANDIR)/man1/$(NAME).1; \
		[ -f $(SYSCONFDIR)/$(NAME).conf -o -z "$(SYSCONFDIR)" ] \
			|| install -d -m 600 doc/$(NAME).conf $(SYSCONFDIR)/$(NAME).conf; \
	else \
		install -D -m 755 -s $(NAME) $(BINDIR)/$(NAME); \
		install -D -m 644 doc/$(NAME).1 $(MANDIR)/man1/$(NAME).1; \
		[ -f $(SYSCONFDIR)/$(NAME).conf -o -z "$(SYSCONFDIR)" ] \
			|| install -D -m 600 doc/$(NAME).conf $(SYSCONFDIR)/$(NAME).conf; \
	fi
	@echo; echo "Cntlm will look for configuration in $(SYSCONFDIR)/$(NAME).conf"

tgz:
	mkdir -p tmp
	rm -rf tmp/$(NAME)-$(VER)
	svn export . tmp/$(NAME)-$(VER)
	tar zcvf $(NAME)-$(VER).tar.gz -C tmp/ $(NAME)-$(VER)
	rm -rf tmp/$(NAME)-$(VER)
	rmdir tmp 2>/dev/null || true

tbz2:
	mkdir -p tmp
	rm -rf tmp/$(NAME)-$(VER)
	svn export . tmp/$(NAME)-$(VER)
	tar jcvf $(NAME)-$(VER).tar.bz2 -C tmp/ $(NAME)-$(VER)
	rm -rf tmp/$(NAME)-$(VER)
	rmdir tmp 2>/dev/null || true

deb: builddeb
builddeb:
	sed -i "s/^\(cntlm *\)([^)]*)/\1($(VER))/g" debian/changelog
	if [ `id -u` = 0 ]; then \
		debian/rules binary; \
		debian/rules clean; \
	else \
		fakeroot debian/rules binary; \
		fakeroot debian/rules clean; \
	fi
	mv ../cntlm_$(VER)*.deb .

rpm: buildrpm
buildrpm:
	sed -i "s/^\(Version:[\t ]*\)\(.*\)/\1$(VER)/g" rpm/cntlm.spec
	if [ `id -u` = 0 ]; then \
		rpm/rules binary; \
		rpm/rules clean; \
	else \
		fakeroot rpm/rules binary; \
		fakeroot rpm/rules clean; \
	fi

win: buildwin
buildwin:
	@echo
	@echo "* This build target must be run from a Cywgin shell on Windows *"
	@echo "* and you also need InnoSetup installed                        *"
	@echo
	rm -f win/cntlm_manual.pdf
	groff -t -e -mandoc -Tps doc/cntlm.1 | ps2pdf - win/cntlm_manual.pdf
	cat doc/cntlm.conf | unix2dos > win/cntlm.ini
	cat COPYRIGHT LICENSE | unix2dos > win/license.txt
	sed "s/\$$VERSION/$(VER)/g" win/setup.iss.in > win/setup.iss
	cp /bin/cygwin1.dll /bin/cyggcc_s-1.dll /bin/cygrunsrv.exe win/
	cp cntlm.exe win/
	strip win/cntlm.exe
	ln -s win $(NAME)-$(VER)
	zip -9 $(NAME)-$(VER).zip $(NAME)-$(VER)/cntlm.exe $(NAME)-$(VER)/cyggcc_s-1.dll $(NAME)-$(VER)/cygwin1.dll $(NAME)-$(VER)/cygrunsrv.exe $(NAME)-$(VER)/cntlm.ini $(NAME)-$(VER)/README.txt $(NAME)-$(VER)/license.txt
	rm -f $(NAME)-$(VER)
	@echo
	@echo Now open folder "win", right-click "setup.iss", then "Compile".
	@echo InnoSetup will generate a new installer cntlm-X.XX-setup.exe
	@echo

win/resources.o: win/resources.rc
	@echo Adding EXE resources
	$(V)windres $^ -o $@

uninstall:
	rm -f $(BINDIR)/$(NAME) $(MANDIR)/man1/$(NAME).1 2>/dev/null || true

clean:
	$(V)rm -f *.o cntlm cntlm.exe configure-stamp build-stamp config.h 2>/dev/null
	$(V)rm -f win/*.exe win/*.dll win/*.iss win/*.pdf win/cntlm.ini win/license.txt win/resouces.o 2>/dev/null
	$(V)rm -f config/big_endian config/have_gethostname config/have_socklen_t config/have_strdup config/*.exe
	$(V)if [ -h Makefile ]; then rm -f Makefile; mv Makefile.gcc Makefile; fi

distclean: clean
	if [ `id -u` = 0 ]; then \
		debian/rules clean; \
		rpm/rules clean; \
	else \
		fakeroot debian/rules clean; \
		fakeroot rpm/rules clean; \
	fi
	$(V)rm -f *.exe *.deb *.rpm *.tgz *.tar.gz *.tar.bz2 tags ctags pid 2>/dev/null
