PERL  ?= /usr/bin/perl
# Run prove under $(PERL) rather than whatever perl its shebang names, so that
# coverage looks for Devel::Cover in the same perl the tests run under.
PROVE ?= $(PERL) -S prove

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
	@$(PERL) -e 'exit 1 unless grep { -e "$$_/Devel/Cover.pm" } @INC' || { \
		echo "Devel::Cover is not installed for $(PERL)."; \
		echo "  cpan Devel::Cover      # or: cpanm Devel::Cover"; \
		exit 1; \
	}
	rm -rf $(COVER_DB)
	PERL5OPT="-MDevel::Cover=-db,$(COVER_DB),-silent,1,+ignore,^t/,+ignore,^/usr/,+ignore,perl_modules/JSON" \
		$(PROVE) --exec '$(PERL) -Iperl_modules -It/lib' -r t
	$(PERL) -S cover -report text -silent $(COVER_DB)

coverage-html:
	@$(PERL) -e 'exit 1 unless grep { -e "$$_/Devel/Cover.pm" } @INC' || { \
		echo "Devel::Cover is not installed for $(PERL)."; \
		echo "  cpan Devel::Cover      # or: cpanm Devel::Cover"; \
		exit 1; \
	}
	rm -rf $(COVER_DB)
	PERL5OPT="-MDevel::Cover=-db,$(COVER_DB),-silent,1,+ignore,^t/,+ignore,^/usr/,+ignore,perl_modules/JSON" \
		$(PROVE) --exec '$(PERL) -Iperl_modules -It/lib' -r t
	$(PERL) -S cover -report html -silent $(COVER_DB)
	open $(COVER_DB)/coverage.html

clean:
	rm -rf $(COVER_DB) joplin.alfredworkflow
