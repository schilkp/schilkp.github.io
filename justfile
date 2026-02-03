_default:
    @just --list

build: check_zola
    ./tools/zola build

serve: check_zola
    ./tools/zola serve --open

serve_drafts: check_zola
    ./tools/zola serve --drafts --open

check: check_zola
    ./tools/zola check

check_drafts: check_zola
    ./tools/zola check --drafts

clean:
    rm -rf public
    rm -rf static/processed_images

new_post name:
    cp content/blog/x_template content/blog/"$(date +%Y-%m-%d)-{{name}}".md

new_folder_post name:
    mkdir content/blog/"$(date +%Y-%m-%d)-{{name}}"
    cp content/blog/x_template content/blog/"$(date +%Y-%m-%d)-{{name}}"/index.md

check_zola:
    #!/usr/bin/env bash
    if [[ -x tools/zola ]]; then
      exit 0
    else
      echo "Zola is NOT present in ./tools or not executable."
      exit 1
    fi

download_zola:
    ./tools/download_zola.bash

strip_metadata:
    rm -rf **/*exiftool_tmp
    exiftool -all= -r -ext jpg -ext jpeg -ext png -overwrite_original .
    rm -rf **/*exiftool_tmp
