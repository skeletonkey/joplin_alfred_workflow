PERL  ?= /usr/bin/perl
PROVE ?= prove

# Devel::Cover writes here and it needs clearing between runs.
COVER_DB := cover_db

.PHONY: alfredworkflow test coverage clean

alfredworkflow:
	zip -r joplin.alfredworkflow . -x@.excluded-files

# Test::More and prove both ship with the perl Apple installs, so this needs
# nothing installed first.
test:
	$(PROVE) --exec '$(PERL) -Iperl_modules -It/lib' -r t

# Devel::Cover is not part of a default perl, so say so plainly rather than
# failing with a module error.
coverage:
	@$(PERL) -MDevel::Cover -e1 2>/dev/null || { \
		echo "Devel::Cover is not installed."; \
		echo "  cpan Devel::Cover      # or: cpanm Devel::Cover"; \
		exit 1; \
	}
	rm -rf $(COVER_DB)
	PERL5OPT="-MDevel::Cover=-db,$(COVER_DB),-silent,1,+ignore,^t/,+ignore,^/usr/,+ignore,perl_modules/JSON" \
		$(PROVE) --exec '$(PERL) -Iperl_modules -It/lib' -r t
	$(PERL) -S cover -report text -silent $(COVER_DB)

clean:
	rm -rf $(COVER_DB) joplin.alfredworkflow
