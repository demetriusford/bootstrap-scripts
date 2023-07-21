.PHONY: check-all rails-app

check-all:
	@find . -type f -name '*.sh' | xargs shellcheck --shell=sh

rails-app:
	@/bin/sh ./new-rails-app.sh $(name)
