prefix=/usr
bindir=$(prefix)/bin
sharedir=$(prefix)/share
localedir=$(sharedir)/locale
launcherdir=$(sharedir)/applications
mandir=$(sharedir)/man
man1dir=$(mandir)/man1
CFLAGS=--std=c99
app_name=indicator-diskman
app_fullname=Disk Manager Indicator

vte_version=$(shell { ((ldconfig -p | grep libvte-2.91*.so) >/dev/null && echo 'vte-2.91') || echo 'vte-2.90'; } )
define_symbols=$(shell { ((ldconfig -p | grep libvte-2.91*.so) >/dev/null && echo '-D VTE_291') || echo ''; } )

all:
	#build binaries
	valac -X -D'GETTEXT_PACKAGE="${app_name}"' --Xcc="-lm" -X -Wl,-rpath,/usr/share/${app_name}/libs ${define_symbols} --thread DiskIndicator.vala Main.vala MainWindow.vala Utility/*.vala App/*.vala -o ${app_name} --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg $(vte_version) --pkg gee-0.8 --pkg json-glib-1.0 --pkg libxml-2.0 --pkg appindicator3-0.1 #--target-glib=2.32

	#helper daemon
	valac -X -D'GETTEXT_PACKAGE="${app_name}"' --Xcc="-lm" -X -Wl,-rpath,/usr/share/${app_name}/libs ${define_symbols} --thread AppDaemon.vala Utility/*.vala App/*.vala -o ${app_name}-daemon --pkg glib-2.0 --pkg gio-unix-2.0 --pkg posix --pkg gtk+-3.0 --pkg $(vte_version) --pkg gee-0.8 --pkg json-glib-1.0 --pkg libxml-2.0 #--target-glib=2.32
	
	#update translation template
	xgettext --language=C --keyword=_ --copyright-holder='Tony George (teejeetech@gmail.com)' --package-name="${app_name}" --package-version='1.6' --msgid-bugs-address='teejeetech@gmail.com' --escape --sort-output -o ../${app_name}.pot *.vala

clean:
	rm -rf *.o ${app_name}

install:
	mkdir -p "$(DESTDIR)$(bindir)"
	mkdir -p "$(DESTDIR)$(sharedir)"
	mkdir -p "$(DESTDIR)$(mandir)"
	mkdir -p "$(DESTDIR)$(man1dir)"
	mkdir -p "$(DESTDIR)$(launcherdir)"
	mkdir -p "$(DESTDIR)$(sharedir)/${app_name}"
	mkdir -p "$(DESTDIR)$(sharedir)/pixmaps"
	mkdir -p "$(DESTDIR)$(localedir)/ca/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/cs/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/es/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/fr/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/it/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/ko/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/nl/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/pl/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/pt_BR/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/ru/LC_MESSAGES"
	mkdir -p "$(DESTDIR)$(localedir)/tr/LC_MESSAGES"

	#binary
	install -m 0755 ${app_name} "$(DESTDIR)$(bindir)"
	install -m 0755 ${app_name}-daemon "$(DESTDIR)$(bindir)"
	install -m 0755 ${app_name}-uninstall "$(DESTDIR)$(bindir)"
	install -m 0755 ${app_name}-launcher "$(DESTDIR)$(bindir)"

	#shared files
	cp -dpr --no-preserve=ownership -t "$(DESTDIR)$(sharedir)/${app_name}" ./share/${app_name}/*
	chmod --recursive 0755 $(DESTDIR)$(sharedir)/${app_name}/*

	#launcher
	install -m 0755 ${app_name}.desktop "$(DESTDIR)$(launcherdir)"

	#app icon
	install -m 0755 ./share/pixmaps/${app_name}.png "$(DESTDIR)$(sharedir)/pixmaps/"

	#translations
	#msgfmt --check --verbose -o "$(DESTDIR)$(localedir)/ca/LC_MESSAGES/${app_name}.mo" ../po/${app_name}-ca.po

uninstall:

	#binary
	rm -f "$(DESTDIR)$(bindir)/${app_name}"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-daemon"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-uninstall"
	rm -f "$(DESTDIR)$(bindir)/${app_name}-launcher"

	#shared files
	rm -rf "$(DESTDIR)$(sharedir)/${app_name}"

	#launcher
	rm -f "$(DESTDIR)$(launcherdir)/${app_name}.desktop"

	#app icon
	rm -f "$(DESTDIR)$(sharedir)/pixmaps/${app_name}.png"

	#translations
	rm -f $(DESTDIR)$(localedir)/*/LC_MESSAGES/${app_name}.mo
