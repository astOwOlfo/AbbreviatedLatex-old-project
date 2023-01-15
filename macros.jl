function splitkeeping(r::Regex, s::String)::Vector{String}
    matches = collect(eachmatch(r, s))

    isempty(matches) ? [s] : filter(!isempty, [
        s[1 : _begin(matches[1])-1]
        matches[1].match
        collect(Iterators.flatten(
            (
                s[_end(matches[i-1])+1 : _begin(matches[i])-1],
                matches[i].match
            )
            for i in 2:lastindex(matches)
        ))
        s[_end(matches[end])+1 : end]
    ])
end

function parse_macro_syntax(
        s::String
    )::Vector{Union{Vector{Token}, MacroArgument}}

    map(splitkeeping(r"(SHORT)|(LONG)", s)) do a
        if a == "SHORT"
            ShortMacroArgument()
        elseif a == "LONG"
            LongMacroArgument()
        else
            tokenize(a)
        end
    end
end

function parse_macro_replacement(
        s::String
    )::Vector{Union{String, Int}}

    map(splitkeeping(r"#[0-9]+#", s)) do a
        m = match(r"^#[0-9]+#$", a)
        if m !== nothing
            parse(Int, m.match[2:end-1])
        else
            a
        end
    end
end

_begin(m::RegexMatch) = m.offset
_end(m::RegexMatch) = m.offset + length(m.match) - 1

const unparsed_standard_macros = [

    # === GREEK AND HEBREW LETTERS ===

    (";a",              "\\alpha ")
    (";b",              "\\beta ")
    (";c",              "\\chi ")
    (";d",              "\\delta ")
    (";e",              "\\epsilon ")
    (";et",             "\\eta ")
    (";g",              "\\gamma ")
    (";io",             "\\iota ")
    (";k",              "\\kappa ")
    (";l",              "\\lambda ")
    (";m",              "\\mu ")
    (";nu",             "\\nu ")
    (";w",              "\\omega ")
    (";f",              "\\phi ")
    (";p",              "\\pi ")
    (";ps",             "\\psi ")
    (";r",              "\\rho ")
    (";s",              "\\sigma ")
    (";t",              "\\tau ")
    (";q",              "\\theta ")
    (";up",             "\\upsilon ")
    (";xi",             "\\xi ")
    (";z",              "\\zeta ")
    (";dg",             "\\digamma ")
    (";ve",             "\\varepsilon ")
    (";vk",             "\\varkappa ")
    (";vf",             "\\varphi ")
    (";vp",             "\\varpi ")
    (";vs",             "\\varsigma ")
    (";vq",             "\\vartheta ")
    (";D",              "\\Delta ")
    (";G",              "\\Gamma ")
    (";L",              "\\Lambda ")
    (";W",              "\\Omega ")
    (";F",              "\\Phi ")
    (";Pi",             "\\Pi ")
    (";PI",             "\\Pi ")
    (";Ps",             "\\Psi ")
    (";PS",             "\\Psi ")
    (";Si",             "\\Sigma ")
    (";SI",             "\\Sigma ")
    (";Q",              "\\Theta ")
    (";Up",             "\\Upsilon ")
    (";UP",             "\\Upsilon ")
    (";X",              "\\Xi ")
    (";al",             "\\aleph ")
    (";be",             "\\beth ")
    (";da",             "\\daleth ")
    (";gi",             "\\gimel ")


    # === LETEX MATH CONSTRUCTS ===

    ("LONG/LONG",       "\\frac{#1#}{#2#}")
    (";VLONG",          "\\sqrt{#1#}")
    (";V^LONGLONG",     "\\sqrt[#1#]{#2#}")
    ("^_LONG",          "\\overline{#1#}")
    ("__LONG",          "\\underline{#1#}")
    ("^^^LONG",          "\\widehat{#1#}")
    ("^~LONG",          "\\widetilde{#1#}")
    ("^->LONG",         "\\overrightarrow{#1#}")
    ("^}LONG",          "\\overbrace{#1#}")
    ("_}LONG",          "\\underbrace{#1#}")


    # === DELIMITERS ===

    (";|",              "\\mid ")
    ("||",              "\\Vert ")
    ("\\\\",            "\\backslash ")
    (";\\",             "\\setminus ")
    # ("\\(",             "(")
    # ("\\)",             ")")
    # ("\\[",             "[")
    # ("\\]",             "]")
    # ("\\{",             "\\{")
    # ("\\}",             "\\}")
    # ("\\;<",            "\\langle ")
    # ("\\;>",            "\\rangle ")
    # (";|_",             "\\lfloor ")
    # (";_|",             "\\rfloor ")
    # (";|^",             "\\lceil ")
    # (";^|",             "\\rceil ")


    # === VARIABLE-SIZED SYMBOLS ===

    (";S",              "\\sum ")
    (";P",              "\\prod ")
    (";Cp",             "\\coprod ")
    (";CP",             "\\coprod ")
    (";I",              "\\int ")
    (";OI",             "\\oint ")
    (";II",             "\\iint ")
    (";N",              "\\bigcap ")
    (";U",              "\\bigcup ")
    ("\\\\//",          "\\bigvee ")
    ("//\\\\",          "\\bigwedge ")
    ("; ",              "\\ ")


    # STANDARD FUNCTION NAMES

    ("\\LONG",          "\\operatorname{#1#}")
    (";-",              "^{-1}")


    # === BINARY OPERATION/RELATION SYMBOLS ===

    (".,",              ";")
    ("*",               "\\cdot ")
    (";x",              "\\times ")
    (";/",              "/")
    (";%",              "\\div ")
    ("%",               "\\%")
    ("%%LONG",          "\\pmod{#1#}")
    (";mod",            "\\bmod ")
    ("!",               "\\not")
    ("===",             "\\equiv ")
    ("~",               "\\sim ")
    ("~=",              "\\approx ")
    ("+-",              "\\pm ")
    ("-+",              "\\mp ")
    ("=<",              "\\leqslant ")
    (">=",              "\\geqslant ")
    ("<<",              "\\ll ")
    (">>",              "\\gg ")
    ("<<<",             "\\lll ")
    (">>>",             "\\ggg ")
    ("-<",              "\\prec ")
    (">-",              "\\succ ")
    ("-<=",             "\\preceq ")
    (">-=",             "\\succeq ")
    (";C",              "\\subset ")
    (";B",              "\\supset ")
    (";C=",             "\\subseteq ")
    (";D=",             "\\supseteq ")
    (";i",              "\\in ")
    (";ni",             "\\ni ")
    ("/\\",             "\\wedge ")
    ("\\/",             "\\vee ")
    ("^LONG",           "^{#1#} ")
    ("_LONG",           "_{#1#} ")
    ("_LONG^LONG",      "_{#1#}^{#2#} ")
    ("\\!",             "!")
    ("\\*",              "*")


    # === ARROW SYMBOLS ===

    ("<-",              "\\leftarrow ")
    ("->",              "\\rightarrow ")
    ("<->",             "\\leftrightarrow ")
    ("<--",             "\\longleftarrow ")
    ("-->",             "\\longrightarrow ")
    ("<-->",            "\\longleftrightarrow ")
    ("<=",              "\\Leftarrow ")
    ("=>",              "\\Rightarrow ")
    ("<=>",             "\\Leftrightarrow ")
    ("<==",             "\\Longleftarrow ")
    ("==>",             "\\Longrightarrow ")
    ("<==>",            "\\Longleftrightarrow ")


    # === MISCELANEOUS SYMBOLS ===

    (";oo",             "\\infty ")
    (";DD",             "\\nabla ")
    (";de",             "\\partial ")
    (";eh",             "\\eth ")
    ("...",             "\\ldots ")
    ("***",             "\\cdots ")
    ("\\...",           "\\ddots ")
    ("|...",            "\\vdots ")
    (";im",             "\\Im ")
    (";Im",             "\\Im ")
    (";IM",             "\\Im ")
    (";re",             "\\Re ")
    (";Re",             "\\Re ")
    (";RE",             "\\Re ")
    (";A",              "\\forall ")
    (";E",              "\\exists ")
    (";0",              "\\emptyset ")
    (";ii",             "\\imath ")
    (";jj",             "\\jmath ")
    (";wp",             "\\wp ")


    # === MATH MODE ACCENTS

    ("^^SHORT",         "\\bar{#1#}")
    ("^>SHORT",         "\\vec{#1#}")


    # === OTHER STYLES ===

    ("@SHORT",          "\\mathcal{#1#}")
    ("#SHORT",          "\\mathbb{#1#}")
    ("&SHORT",          "\\mathfrac{#1#}")
    ("?SHORT",          "\\mathbf")


    # === BINOMIAL AND MULTINOMIAL COEFFICIENTS ===

    (";(LONGLONG;)",    "\\binom{#1#}{#2#}")


    # === DOCUMENT STUFF ===

    (
        ";quick",

        """

        \\begin{document}

        """
    )

    (
        ";doc",

        """

        \\begin{document}

        \\maketitle

        """
    )
]

const standard_macros_unsorted = [
    Macro(
        parse_macro_syntax(syntax),
        parse_macro_replacement(replacement)
    )

    for (syntax, replacement) in unparsed_standard_macros
]

const standard_macros = sort(standard_macros_unsorted;
    by = _macro -> (
        maximum(
            length(atom)
            for atom in _macro.syntax
            if atom isa Vector{Token}
        ),
        length(_macro.syntax)
    ),
    rev=true
)

using StatsBase
function warn_conflicting_macros(unparsed_macros)
    syntaxes = [
        replace(replace(syntax, "SHORT"=>"ARG"), "LONG"=>"ARG")
        for (syntax, replacement) in unparsed_macros
    ]
    repeated_syntaxes = (s for (s, n) in countmap(syntaxes) if n > 1)
    for syntax in repeated_syntaxes
        println("SYNTAX ", syntax, " IS USED FOR MORE THAN ONE MACRO")
        conflicting_macros = filter(unparsed_standard_macros) do syntax_def
            syntax_def[1] == syntax
        end
        println(join(conflicting_macros, "\n"))
        println()
    end
end

warn_conflicting_macros(unparsed_standard_macros)
