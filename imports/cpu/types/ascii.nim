const CHAR_NEWLINE* = 10
const CHAR_CR = 13 # will always be converted to CHAR_NEWLINE. other programs will not be able to use this.
const CHAR_SPACE* = 32
const CHAR_EXLMARK* = 33
const CHAR_DQUOTE* = 34
const CHAR_OCTOTHORPE* = 35
const CHAR_DOLLAR* = 36
const CHAR_PERCENT* = 37
const CHAR_AMPERSAND* = 38
const CHAR_SQUOTE* = 39
const CHAR_OPENPARENTHESIS* = 40
const CHAR_CLOSEPARENTHESIS* = 41
const CHAR_ASTERISK* = 42
const CHAR_PLUS* = 43
const CHAR_COMMA* = 44
const CHAR_HYPHEN* = 45
const CHAR_PERIOD* = 46
const CHAR_SLASH* = 47
const CHAR_ZERO* = 48
const CHAR_ONE* = 49
const CHAR_TWO* = 50
const CHAR_THREE* = 51
const CHAR_FOUR* = 52
const CHAR_FIVE* = 53
const CHAR_SIX* = 54
const CHAR_SEVEN* = 55
const CHAR_EIGHT* = 56
const CHAR_NINE* = 57
const CHAR_COLON* = 58
const CHAR_SEMICOLON* = 59
const CHAR_LEFTBRACKET* = 60
const CHAR_EQUALS* = 61
const CHAR_RIGHTBRACKET* = 62
const CHAR_QUSTMARK* = 63
const CHAR_ATSYMBOL* = 64
const CHAR_CAPITAL_A* = 65
const CHAR_CAPITAL_B* = 66
const CHAR_CAPITAL_C* = 67
const CHAR_CAPITAL_D* = 68
const CHAR_CAPITAL_E* = 69
const CHAR_CAPITAL_F* = 70
const CHAR_CAPITAL_G* = 71
const CHAR_CAPITAL_H* = 72
const CHAR_CAPITAL_I* = 73
const CHAR_CAPITAL_J* = 74
const CHAR_CAPITAL_K* = 75
const CHAR_CAPITAL_L* = 76
const CHAR_CAPITAL_M* = 77
const CHAR_CAPITAL_N* = 78
const CHAR_CAPITAL_O* = 79
const CHAR_CAPITAL_P* = 80
const CHAR_CAPITAL_Q* = 81
const CHAR_CAPITAL_R* = 82
const CHAR_CAPITAL_S* = 83
const CHAR_CAPITAL_T* = 84
const CHAR_CAPITAL_U* = 85
const CHAR_CAPITAL_V* = 86
const CHAR_CAPITAL_W* = 87
const CHAR_CAPITAL_X* = 88
const CHAR_CAPITAL_Y* = 89
const CHAR_CAPITAL_Z* = 90
const CHAR_LEFTSQBRACKET* = 91
const CHAR_BACKSLASH* = 92
const CHAR_RIGHTSQBRACKET* = 93
const CHAR_CARET* = 94
const CHAR_UNDERSCORE* = 95
const CHAR_GRAVE* = 96
const CHAR_SMALL_A* = 97
const CHAR_SMALL_B* = 98
const CHAR_SMALL_C* = 99
const CHAR_SMALL_D* = 100
const CHAR_SMALL_E* = 101
const CHAR_SMALL_F* = 102
const CHAR_SMALL_G* = 103
const CHAR_SMALL_H* = 104
const CHAR_SMALL_I* = 105
const CHAR_SMALL_J* = 106
const CHAR_SMALL_K* = 107
const CHAR_SMALL_L* = 108
const CHAR_SMALL_M* = 109
const CHAR_SMALL_N* = 110
const CHAR_SMALL_O* = 111
const CHAR_SMALL_P* = 112
const CHAR_SMALL_Q* = 113
const CHAR_SMALL_R* = 114
const CHAR_SMALL_S* = 115
const CHAR_SMALL_T* = 116
const CHAR_SMALL_U* = 117
const CHAR_SMALL_V* = 118
const CHAR_SMALL_W* = 119
const CHAR_SMALL_X* = 120
const CHAR_SMALL_Y* = 121
const CHAR_SMALL_Z* = 122
const CHAR_LEFTCURLYBRACKET* = 123
const CHAR_PIPE* = 124
const CHAR_RIGHTCURLYBRACKET* = 125
const CHAR_TILDE* = 126

const CHAR_INVALID = CHAR_QUSTMARK

proc ToChar*(numb: int): char =
    case numb
    of CHAR_NEWLINE: '\n'
    of CHAR_CR: '\n'
    of CHAR_SPACE: ' '
    of CHAR_EXLMARK: '!'
    of CHAR_DQUOTE: '"'
    of CHAR_OCTOTHORPE: '#'
    of CHAR_DOLLAR: '$'
    of CHAR_PERCENT: '%'
    of CHAR_AMPERSAND: '&'
    of CHAR_SQUOTE: '\''
    of CHAR_OPENPARENTHESIS: '('
    of CHAR_CLOSEPARENTHESIS: ')'
    of CHAR_ASTERISK: '*'
    of CHAR_PLUS: '+'
    of CHAR_COMMA: ','
    of CHAR_HYPHEN: '-'
    of CHAR_PERIOD: '.'
    of CHAR_SLASH: '/'
    of CHAR_ZERO: '0'
    of CHAR_ONE: '1'
    of CHAR_TWO: '2'
    of CHAR_THREE: '3'
    of CHAR_FOUR: '4'
    of CHAR_FIVE: '5'
    of CHAR_SIX: '6'
    of CHAR_SEVEN: '7'
    of CHAR_EIGHT: '8'
    of CHAR_NINE: '9'
    of CHAR_COLON: ':'
    of CHAR_SEMICOLON: ';'
    of CHAR_LEFTBRACKET: '<'
    of CHAR_EQUALS: '='
    of CHAR_RIGHTBRACKET: '>'
    of CHAR_QUSTMARK: '?'
    of CHAR_ATSYMBOL: '@'
    of CHAR_CAPITAL_A: 'A'
    of CHAR_CAPITAL_B: 'B'
    of CHAR_CAPITAL_C: 'C'
    of CHAR_CAPITAL_D: 'D'
    of CHAR_CAPITAL_E: 'E'
    of CHAR_CAPITAL_F: 'F'
    of CHAR_CAPITAL_G: 'G'
    of CHAR_CAPITAL_H: 'H'
    of CHAR_CAPITAL_I: 'I'
    of CHAR_CAPITAL_J: 'J'
    of CHAR_CAPITAL_K: 'K'
    of CHAR_CAPITAL_L: 'L'
    of CHAR_CAPITAL_M: 'M'
    of CHAR_CAPITAL_N: 'N'
    of CHAR_CAPITAL_O: 'O'
    of CHAR_CAPITAL_P: 'P'
    of CHAR_CAPITAL_Q: 'Q'
    of CHAR_CAPITAL_R: 'R'
    of CHAR_CAPITAL_S: 'S'
    of CHAR_CAPITAL_T: 'T'
    of CHAR_CAPITAL_U: 'U'
    of CHAR_CAPITAL_V: 'V'
    of CHAR_CAPITAL_W: 'W'
    of CHAR_CAPITAL_X: 'X'
    of CHAR_CAPITAL_Y: 'Y'
    of CHAR_CAPITAL_Z: 'Z'
    of CHAR_LEFTSQBRACKET: '['
    of CHAR_BACKSLASH: '\\'
    of CHAR_RIGHTSQBRACKET: ']'
    of CHAR_CARET: '^'
    of CHAR_UNDERSCORE: '_'
    of CHAR_GRAVE: '`'
    of CHAR_SMALL_A: 'a'
    of CHAR_SMALL_B: 'b'
    of CHAR_SMALL_C: 'c'
    of CHAR_SMALL_D: 'd'
    of CHAR_SMALL_E: 'e'
    of CHAR_SMALL_F: 'f'
    of CHAR_SMALL_G: 'g'
    of CHAR_SMALL_H: 'h'
    of CHAR_SMALL_I: 'i'
    of CHAR_SMALL_J: 'j'
    of CHAR_SMALL_K: 'k'
    of CHAR_SMALL_L: 'l'
    of CHAR_SMALL_M: 'm'
    of CHAR_SMALL_N: 'n'
    of CHAR_SMALL_O: 'o'
    of CHAR_SMALL_P: 'p'
    of CHAR_SMALL_Q: 'q'
    of CHAR_SMALL_R: 'r'
    of CHAR_SMALL_S: 's'
    of CHAR_SMALL_T: 't'
    of CHAR_SMALL_U: 'u'
    of CHAR_SMALL_V: 'v'
    of CHAR_SMALL_W: 'w'
    of CHAR_SMALL_X: 'x'
    of CHAR_SMALL_Y: 'y'
    of CHAR_SMALL_Z: 'z'
    of CHAR_LEFTCURLYBRACKET: '{'
    of CHAR_PIPE: '|'
    of CHAR_RIGHTCURLYBRACKET: '}'
    of CHAR_TILDE: '~'
    else: chr(CHAR_INVALID)

proc ToCode*(chars: char): int =
    case chars
    of '\n': CHAR_NEWLINE
    of '\r': CHAR_NEWLINE
    of ' ': CHAR_SPACE
    of '!': CHAR_EXLMARK
    of '"': CHAR_DQUOTE
    of '#': CHAR_OCTOTHORPE
    of '$': CHAR_DOLLAR
    of '%': CHAR_PERCENT
    of '&': CHAR_AMPERSAND
    of '\'': CHAR_SQUOTE
    of '(': CHAR_OPENPARENTHESIS
    of ')': CHAR_CLOSEPARENTHESIS
    of '*': CHAR_ASTERISK
    of '+': CHAR_PLUS
    of ',': CHAR_COMMA
    of '-': CHAR_HYPHEN
    of '.': CHAR_PERIOD
    of '/': CHAR_SLASH
    of '0': CHAR_ZERO
    of '1': CHAR_ONE
    of '2': CHAR_TWO
    of '3': CHAR_THREE
    of '4': CHAR_FOUR
    of '5': CHAR_FIVE
    of '6': CHAR_SIX
    of '7': CHAR_SEVEN
    of '8': CHAR_EIGHT
    of '9': CHAR_NINE
    of ':': CHAR_COLON
    of ';': CHAR_SEMICOLON
    of '<': CHAR_LEFTBRACKET
    of '=': CHAR_EQUALS
    of '>': CHAR_RIGHTBRACKET
    of '?': CHAR_QUSTMARK
    of '@': CHAR_ATSYMBOL
    of 'A': CHAR_CAPITAL_A
    of 'B': CHAR_CAPITAL_B
    of 'C': CHAR_CAPITAL_C
    of 'D': CHAR_CAPITAL_D
    of 'E': CHAR_CAPITAL_E
    of 'F': CHAR_CAPITAL_F
    of 'G': CHAR_CAPITAL_G
    of 'H': CHAR_CAPITAL_H
    of 'I': CHAR_CAPITAL_I
    of 'J': CHAR_CAPITAL_J
    of 'K': CHAR_CAPITAL_K
    of 'L': CHAR_CAPITAL_L
    of 'M': CHAR_CAPITAL_M
    of 'N': CHAR_CAPITAL_N
    of 'O': CHAR_CAPITAL_O
    of 'P': CHAR_CAPITAL_P
    of 'Q': CHAR_CAPITAL_Q
    of 'R': CHAR_CAPITAL_R
    of 'S': CHAR_CAPITAL_S
    of 'T': CHAR_CAPITAL_T
    of 'U': CHAR_CAPITAL_U
    of 'V': CHAR_CAPITAL_V
    of 'W': CHAR_CAPITAL_W
    of 'X': CHAR_CAPITAL_X
    of 'Y': CHAR_CAPITAL_Y
    of 'Z': CHAR_CAPITAL_Z
    of '[': CHAR_LEFTSQBRACKET
    of '\\': CHAR_BACKSLASH
    of ']': CHAR_RIGHTSQBRACKET
    of '^': CHAR_CARET
    of '_': CHAR_UNDERSCORE
    of '`': CHAR_GRAVE
    of 'a': CHAR_SMALL_A
    of 'b': CHAR_SMALL_B
    of 'c': CHAR_SMALL_C
    of 'd': CHAR_SMALL_D
    of 'e': CHAR_SMALL_E
    of 'f': CHAR_SMALL_F
    of 'g': CHAR_SMALL_G
    of 'h': CHAR_SMALL_H
    of 'i': CHAR_SMALL_I
    of 'j': CHAR_SMALL_J
    of 'k': CHAR_SMALL_K
    of 'l': CHAR_SMALL_L
    of 'm': CHAR_SMALL_M
    of 'n': CHAR_SMALL_N
    of 'o': CHAR_SMALL_O
    of 'p': CHAR_SMALL_P
    of 'q': CHAR_SMALL_Q
    of 'r': CHAR_SMALL_R
    of 's': CHAR_SMALL_S
    of 't': CHAR_SMALL_T
    of 'u': CHAR_SMALL_U
    of 'v': CHAR_SMALL_V
    of 'w': CHAR_SMALL_W
    of 'x': CHAR_SMALL_X
    of 'y': CHAR_SMALL_Y
    of 'z': CHAR_SMALL_Z
    of '{': CHAR_LEFTCURLYBRACKET
    of '|': CHAR_PIPE
    of '}': CHAR_RIGHTCURLYBRACKET
    of '~': CHAR_TILDE
    else: CHAR_INVALID