.PHONY: check-all rails-app

good-code:
	@find . -type f -name '*.sh' | xargs shellcheck --shell=sh
	@rubocop --autocorrect

rails-app:
	@/bin/sh ./new-rails-app.sh $(name)
