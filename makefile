.PHONY: all, run_local, asset_generation

all: asset_generation 

asset_generation: _asset_generation/env/exists
	rm _includes/psASM_snippets/* -f
	@(\
	   . _asset_generation/env;\
	   python3	_asset_generation/psASM_snippets/run.py\
	)

_asset_generation/env/exists:
	@echo "Creating venv, installing dependencies..."
	( \
		python3 -m venv _asset_generation/env;\
		. _asset_generation/env/bin/activate;\
		pip install -r _asset_generation/requirements.txt\
    )
	touch _asset_generation/env/exists

run_local: asset_generation
	bundle exec jekyll serve


clean:
	rm _site -rf
