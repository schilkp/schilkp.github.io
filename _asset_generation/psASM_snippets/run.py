from pygments.lexers import load_lexer_from_file
from pygments import highlight
from pygments.formatters import HtmlFormatter
from os.path import join, basename
import glob

# Settings 
snippets_folder = '_asset_generation/psASM_snippets/snippets'
output_folder = 'assets/snippets'

# Load Lexer
psASM_lexer = load_lexer_from_file('_asset_generation/psASM_snippets/psASMLexer.py', lexer_name="psASMLexer")

snippet_paths = [f for f in glob.glob(join(snippets_folder, '*.psASM'))] 

for snippet_path in snippet_paths:
    output_name = basename(snippet_path).replace('.psASM','.html')
    output_path = join(output_folder, output_name)

    with open(snippet_path,'r') as infile:
        snippet = infile.read()

    output = highlight(snippet, psASM_lexer, HtmlFormatter())

    with open(output_path,'w') as outfile:
        outfile.write(output)

    print("Generated %s from %s ...." % (output_name, basename(snippet_path)))
