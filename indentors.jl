const standard_indentors = [
    Indentor(
        precedence,
        tokenize(open), tokenize(close),
        open_replacement, close_replacement
    )

    for (precedence, open, close, open_replacement, close_replacement) in [
        (3, ";;",  ";;",           "\\(",              "\\)")
        (3, "\$",  "\$",           "\\[",              "\\]")
        (2, "{",   "}",            "{",                "}")
        (2, "(",   ")",            "\\left(",          "\\right)")
        (2, "[",   "]",            "\\left[",          "\\right]")
        (2, "(",   "]",            "\\left(",          "\\right]")
        (2, "[",   ")",            "\\left[",          "\\right)")
        (2, ";{",  ";}",           "\\left\\{",        "\\right\\}")
        # ("\\(", "\\)",          "(",                ")")
        # ("\\[", "\\]",          "[",                "]")
        # ("\\{", "\\}",          "{",                "}")
        (2, ";<",  ";>",           "\\left\\langle ",  "\\right\\rangle ")
        (2, "|_",  "_|",           "\\left\\lfloor ",  "\\right\\rfloor ")
        (2, "|^",  "^|",           "\\left\\lceil ",   "\\right\\rceil ")

        (2, "{",   ")",             "\\left ",        "")
        (2, "(",   "}",             "\\right ",       "")

        # === ESCAPED INDENTORS ===

        (0, "\\(", "",             "(",                "")
        (0, "\\)", "",             ")",                "")
        (0, "\\[", "",             "[",                "")
        (0, "\\]", "",             "]",                "")
        (0, "\\{", "",             "\\{",              "")
        (0, "\\}", "}",            "\\}",              "")
        (0, "\\;<","",             "\\langle ",        "")
        (0, "\\;>","",             "\\rangle ",        "")
        (0, "\\|_","",             "\\lfloor ",        "")
        (0, "\\_|","",             "\\rfloor ",        "")
        (0, "\\|^","",             "\\lceil ",         "")
        (0, "\\^|","",             "\\rceil ",         "")



        # === DOCUMENT STUFF ===

        (4, ";title",  "\n",       "\\title{",     "}\n")
        (4, ";title",  "\n\n",     "\\title{",     "}\n\n")
        (4, ";author", "\n",       "\\author{",    "}\n")
        (4, ";author", "\n\n",     "\\author{",    "}\n\n")
        (4, ";date",   "\n",       "\\date{",      "}\n")
        (4, ";date",   "\n\n",     "\\date{",      "}\n\n")
        (4, "####",    "\n\n",     "\\subsubsection{", "}\n")
        (4, "####",    "\n\n",     "\\subsubsection{", "}\n\n")
        (4, "###",     "\n",       "\\subsection{", "}\n")
        (4, "###",     "\n\n",     "\\subsection{", "}\n\n")
        (4, "##",      "\n",       "\\section{",   "}\n")
        (4, "##",      "\n\n",     "\\section{",   "}\n\n")
        (1, ";***",    ";***",     "\\textit{\\textbf{", "}}")
        (1, ";**",     ";**",      "\\textbf{",    "}")
        (1, ";*",      ";*",       "\\textit{",    "}")
    ]
]
