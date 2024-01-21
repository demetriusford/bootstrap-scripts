# TL;DR: automate every f*cking thing

> Configurations, updates/upgrades, bookkeeping, and business operations will be addressed in this `README.md`.

1. [`new-rails-app.sh`](./new-rails-app.sh): generate a Rails application with a PostgreSQL backend
2. [`check-domains.rb`](./check-domains.rb): alert on domains about to expire using namecheap's API

## Generating encrypted secrets

Using [@joker1007](https://github.com/joker1007/yaml_vault)'s gem:

```bash
$ yaml_vault encrypt example.yml -o secrets.yml
```


## References

[1] Jiao, Alex. "Clean Code Ruby." GitHub, 7 Sept. 2017, github.com/uohzxela/clean-code-ruby#table-of-contents.
