_default: 
  just --list

# Run the website locally.
run_local:
	bundle exec jekyll serve

# Re-generate all precompiled assets.
asset_generation:
  #!/bin/sh
  # Create venv if it does not yet exist:
  if ! [ -f _asset_generation/env/bin/python ]; then
  	python3 -m venv _asset_generation/env
  	_asset_generation/env/bin/pip install -r _asset_generation/requirements.txt
    touch _asset_generation/env/exists
  fi
  # Delete previous snippets:
  rm _includes/psASM_snippets/* -f
  _asset_generation/env/bin/python _asset_generation/psASM_snippets/run.py

# Clean local site files.
clean:
    rm -rf _site/
