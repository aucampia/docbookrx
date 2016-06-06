#!/bin/bash

script_basename=$( basename -- "${0}" )
script_dirname=$( dirname -- "${0}" )

output_path="${1}"
input_file="${2}"
input_file_basename="$( basename -- "${input_file}" )"

set -x
cp "${input_file}" "${script_dirname}/" || exit 1
( cd "${script_dirname}" && bundle exec docbookrx "${input_file_basename}" ) || exit 1
mv "${script_dirname}/${input_file_basename%.*}.adoc" "${output_path}/${input_file_basename%.*}.asciidoc" || exit 1
