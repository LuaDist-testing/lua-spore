
LUA     := lua
VERSION := $(shell cd src && $(LUA) -e "m = require [[Spore]]; print(m._VERSION)")
TARBALL := lua-spore-$(VERSION).tar.gz
ifndef REV
  REV   := 1
endif

LUAVER  := 5.1
PREFIX  := /usr/local
DPREFIX := $(DESTDIR)$(PREFIX)
BINDIR  := $(DPREFIX)/bin
LIBDIR  := $(DPREFIX)/share/lua/$(LUAVER)

all: dist.cmake
	@echo "Nothing to build here, you can just make install"

install:
	mkdir -p $(BINDIR)
	cp src/discovery2spore                          $(BINDIR)
	mkdir -p $(LIBDIR)/Spore/Middleware/Auth
	mkdir -p $(LIBDIR)/Spore/Middleware/Format
	mkdir -p $(LIBDIR)/Spore/Middleware/Parameter
	mkdir -p $(LIBDIR)/Spore/Middleware/Proxy
	cp src/Spore.lua                                $(LIBDIR)
	cp src/Spore/Core.lua                           $(LIBDIR)/Spore
	cp src/Spore/GoogleDiscovery.lua                $(LIBDIR)/Spore
	cp src/Spore/Protocols.lua                      $(LIBDIR)/Spore
	cp src/Spore/Request.lua                        $(LIBDIR)/Spore
	cp src/Spore/Middleware/Cache.lua               $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/DoNotTrack.lua          $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/Logging.lua             $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/Mock.lua                $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/Redirection.lua         $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/Runtime.lua             $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/UserAgent.lua           $(LIBDIR)/Spore/Middleware
	cp src/Spore/Middleware/Auth/AWS.lua            $(LIBDIR)/Spore/Middleware/Auth
	cp src/Spore/Middleware/Auth/Basic.lua          $(LIBDIR)/Spore/Middleware/Auth
	cp src/Spore/Middleware/Auth/Bearer.lua         $(LIBDIR)/Spore/Middleware/Auth
	cp src/Spore/Middleware/Auth/Digest.lua         $(LIBDIR)/Spore/Middleware/Auth
	cp src/Spore/Middleware/Auth/OAuth.lua          $(LIBDIR)/Spore/Middleware/Auth
	cp src/Spore/Middleware/Format/JSON.lua         $(LIBDIR)/Spore/Middleware/Format
	cp src/Spore/Middleware/Format/XML.lua          $(LIBDIR)/Spore/Middleware/Format
	cp src/Spore/Middleware/Format/YAML.lua         $(LIBDIR)/Spore/Middleware/Format
	cp src/Spore/Middleware/Parameter/Default.lua   $(LIBDIR)/Spore/Middleware/Parameter
	cp src/Spore/Middleware/Parameter/Force.lua     $(LIBDIR)/Spore/Middleware/Parameter
	cp src/Spore/Middleware/Proxy/Basic.lua         $(LIBDIR)/Spore/Middleware/Proxy

uninstall:
	rm -f $(LIBDIR)/Spore.lua
	rm -rf $(LIBDIR)/Spore

manifest_pl := \
use strict; \
use warnings; \
my @files = qw{MANIFEST}; \
while (<>) { \
    chomp; \
    next if m{^\.}; \
    next if m{^doc/\.}; \
    next if m{^doc/google}; \
    next if m{^rockspec/}; \
    push @files, $$_; \
} \
print join qq{\n}, sort @files;

rockspec_pl := \
use strict; \
use warnings; \
use Digest::MD5; \
open my $$FH, q{<}, q{$(TARBALL)} \
    or die qq{Cannot open $(TARBALL) ($$!)}; \
binmode $$FH; \
my %config = ( \
    version => q{$(VERSION)}, \
    rev     => q{$(REV)}, \
    md5     => Digest::MD5->new->addfile($$FH)->hexdigest(), \
); \
close $$FH; \
while (<>) { \
    s{@(\w+)@}{$$config{$$1}}g; \
    print; \
}

version:
	@echo $(VERSION)

CHANGES: dist.info
	perl -i.bak -pe "s{^$(VERSION).*}{q{$(VERSION)  }.localtime()}e" CHANGES

dist.info:
	perl -i.bak -pe "s{^version.*}{version = \"$(VERSION)\"}" dist.info

tag:
	git tag -a -m 'tag release $(VERSION)' $(VERSION)

doc:
	git read-tree --prefix=doc/ -u remotes/origin/gh-pages

dist.cmake:
	wget https://raw.github.com/LuaDist/luadist/master/dist.cmake

MANIFEST: doc dist.cmake
	git ls-files | perl -e '$(manifest_pl)' > MANIFEST

$(TARBALL): MANIFEST
	[ -d lua-Spore-$(VERSION) ] || ln -s . lua-Spore-$(VERSION)
	perl -ne 'print qq{lua-Spore-$(VERSION)/$$_};' MANIFEST | \
	    tar -zc -T - -f $(TARBALL)
	rm lua-Spore-$(VERSION)
	rm -rf doc
	git rm doc/*

dist: $(TARBALL)

rockspec: $(TARBALL)
	perl -e '$(rockspec_pl)' rockspec.in > rockspec/lua-spore-$(VERSION)-$(REV).rockspec

install-rock: clean dist rockspec
	perl -pe 's{http://cloud.github.com/downloads/fperrad/lua-Spore/}{};' \
	    rockspec/lua-spore-$(VERSION)-$(REV).rockspec > lua-spore-$(VERSION)-$(REV).rockspec
	luarocks install lua-spore-$(VERSION)-$(REV).rockspec

check: test

export LUA_PATH=;;src/?.lua

test:
	prove --exec=$(LUA) ./test/*.t

test_eg:
	prove --exec=$(LUA) ./eg/*.lua

coverage:
	rm -f ./luacov.stats.out ./luacov.report.out
	-prove --exec="$(LUA) -lluacov" ./test/*.t
	luacov

README.html: README.md
	Markdown.pl README.md > README.html

clean:
	rm -rf doc
	rm -f MANIFEST *.bak src/luacov.*.out *.rockspec README.html

realclean: clean
	rm -f dist.cmake

.PHONY: test rockspec CHANGES dist.info

