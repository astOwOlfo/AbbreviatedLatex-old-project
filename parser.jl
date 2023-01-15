include("tokenizer.jl")
include("document.jl")
include("indentation-parser.jl")
include("macro-parser.jl")

function atxparse(
        code::AbstractString,
        indentors::Vector{Indentor},
        macros::Vector{Macro}
    )::IndentorBlock

    tokens = tokenize(code)
    indented = indentation_parse(tokens, indentors)
    return macro_parse(indented, macros)
end
