_default:
    @just --list

build:
    zola build

serve:
    zola serve --open

serve_drafts:
    zola serve --drafts --open

check:
    zola check

check_drafts:
    zola check --drafts

clean:
    rm -rf public
    rm -rf static/processed_images

new_post name:
    cp content/blog/x_template content/blog/"$(date +%Y-%m-%d)-{{name}}".md

new_folder_post name:
    mkdir content/blog/"$(date +%Y-%m-%d)-{{name}}"
    cp content/blog/x_template content/blog/"$(date +%Y-%m-%d)-{{name}}"/index.md
