#!/bin/sh
# @author: Demetrius Ford
# @date: 20 Jul 2023

readonly ALNUMS='^[[:alnum:]]+$'

usage        () { printf '%s\n' "Usage: ${0##*/} <APP_NAME>" >&2; exit 2; }
to_uppercase () { echo "${1}" | perl -n -e 'print "\U$_"'; }
abort        () { printf '%s\n' "Error: ${1}" >&2; exit 1; }

! command -v psql > /dev/null 2>&1 && abort 'PostgreSQL is not installed.'
[ -z "${1}" ] || [ $# != 1 ] && usage
echo "${1}" | grep -qE "${ALNUMS}" || abort 'received illegal characters.'

app_name="${1}"
app_path="/Users/demetriusford/Develop/Business/${app_name}"

{ pg_isready -q; exit_code="$?"; }

case "${exit_code}" in
  1) abort 'PostgreSQL server is rejecting any/all connections (1).' ;;
  2) abort 'PostgreSQL server did not receive a valid response (2).' ;;
  3) abort 'PostgreSQL server failed to make an attempted call (3).' ;;
esac

LC_ALL=C < /dev/urandom tr -dc '[:alnum:]' | head -c 16 | xargs | pbcopy

createuser --pwprompt \
           --createdb "${app_name}"

var_name="$(to_uppercase "${app_name}")"
var_name="${var_name}_DATABASE_PASSWORD"

echo "export ${var_name}=\"$(pbpaste)\"" >> ~/.bash_profile
. ~/.bash_profile && pbcopy < /dev/null

rails new "${app_path}" --database=postgresql && \
       cd "${app_path}" || exit 1

yq --inplace "
  .default.username = \"${app_name}\" |
  .default.password = \"<%= ENV['${var_name}'] %>\"
" config/database.yml

bin/rails db:create
bin/rails server --binding=127.0.0.1
