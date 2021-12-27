#
# A very basic pygments lexer for psASM
#

#
# Usage example:
#
#   from pygments.lexers import load_lexer_from_file
#   from pygments import highlight
#   from pygments.formatters import HtmlFormatter
#   
#   psASM_lexer = load_lexer_from_file('psASMLexer.py', lexer_name="psASMLexer")
#   with open('snippets/test.psASM','r') as infile:
#       txt = infile.read()
#       print(highlight(txt, psASM_lexer, HtmlFormatter()))


from pygments.lexer import RegexLexer
from pygments.token import String, Comment, Keyword, Text, Name


class CustomLexer(RegexLexer):
    name = 'psASM'
    aliases = ['psasm']
    filenames = ['*.psASM']


    tokens = {
        'root': [
            (r'(NOP)|(HALT)|(JMP)|(CALL)|(IFSA)|(IFRA)|(IFSM)|(IFRM)|(RTRN)|(RTRNI)', Keyword.Type),
            (r'(ANDL)|(AND)|(ORL)|(OR)|(XORL)|(XOR)|(SHFTRL)|(SHFTR)|(SHFTLL)|(SHFTL)', Keyword.Type),
            (r'(COMPBC)|(COMPB)|(ADDC)|(ADDLAC)|(ADDLA)|(ADDLBC)|(ADDLB)|(ADD)|(NOTA)', Keyword.Type),
            (r'(SUBLC)|(SUBC)|(SUBL)|(SUB)|(LITA)|(LITB)|(CPY)|(SWP)|(SVA)|(SVB)|(LDA)',Keyword.Type),
            (r'(LDB)|(SVDP)|(SVDR)|(LDDP)|(LDDR)|(POPA)|(PUSHA)|(POPB)|(PUSHB)|(POPM)', Keyword.Type),
            (r'(PUSHM)|(GROW)|(SHRINK)|(STSA)|(STSB)|(STLA)|(STLB)', Keyword.Type),
            (r'@define', Name.Function),
            (r'@include_once', Name.Function),
            (r'@include', Name.Function),
            (r'@print', Name.Function),
            (r'@error', Name.Function),
            (r'@ifdef', Name.Function),
            (r'@ifndef', Name.Function),
            (r'@if', Name.Function),
            (r'@elif', Name.Function),
            (r'@else', Name.Function),
            (r'@for', Name.Function),
            (r'@macro', Name.Function),
            (r'@end', Name.Function),
            (r'#.*$', Comment),
            (r'^\s*(,?\s*[\._\$]?[a-zA-Z0-9_]+\s*)+\s*:', String),
            (r'.', Text)
        ]
    }
