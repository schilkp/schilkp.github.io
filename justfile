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
