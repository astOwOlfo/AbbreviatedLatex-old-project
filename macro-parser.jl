abstract type MacroArgument end
struct ShortMacroArgument <: MacroArgument end
struct LongMacroArgument  <: MacroArgument end

struct Macro
    syntax::Vector{Union{Vector{Token}, MacroArgument}}
    replacement::Vector{Union{String, Int}}

    function Macro(
            syntax::Vector{Union{Vector{Token}, MacroArgument}},
            replacement::Vector{Union{String, Int}}
        )

        @assert !any(
            syntax[i] isa Vector{Token} && syntax[i+1] isa Vector{Token}
            for i in 1:lastindex(syntax)-1
        )

        new(syntax, replacement)
    end
end

Base.:(==)(m::Macro, n::Macro) =
    m.syntax      == n.syntax &&
    m.replacement == n.replacement

struct MacroBlock
    _macro::Macro
    arguments::Vector{Vector{Any}}
end



function macro_parse(blocks::Vector{Any}, macros::Vector{Macro})
    parsed = replace_macros(blocks, macros)
    deepparsed = Any[macro_parse(b, macros) for b in parsed]
    deepparsed
end

macro_parse(token::Token, macros::Vector{Macro}) =
    token

macro_parse(b::IndentorBlock, macros::Vector{Macro}) =
    IndentorBlock(
        b.indentor,
        macro_parse(b.contents, macros)
    )

macro_parse(b::MacroBlock, macros::Vector{Macro}) =
    MacroBlock(
        b._macro,
        [macro_parse(argument, macros) for argument in b.arguments]
    )


function replace_macros(
        blocks::Vector{Any},
        macros::Vector{Macro}
    )::Vector{Any}

    while true
        r = replace_macros_run(blocks, macros)
        r === nothing && return blocks
        blocks = r
    end
end

function replace_macros_run(
        blocks::Vector{Any},
        macros::Vector{Macro}
    )::Union{Vector{Any}, Nothing}

    something_done = false
    for _macro in macros
        r = replace_macro_all(blocks, _macro)
        r === nothing && continue
        blocks = r
        something_done = true
    end

    something_done ? blocks : nothing
end

function replace_macro_all(
        blocks::Vector{Any},
        _macro::Macro
    )::Union{Vector{Any}, Nothing}

    something_done = false
    while true
        r = replace_macro_once(blocks, _macro)
        r === nothing && return something_done ? blocks : nothing
        blocks = r
        something_done = true
    end
end

function replace_macro_once(
        blocks::Vector{Any},
        _macro::Macro
    )::Union{Vector{Any}, Nothing}

    for macro_begin in eachindex(blocks)
        blocks[macro_begin] isa Space && continue

        m = read_macro(blocks, macro_begin, _macro.syntax)
        if m !== nothing
            macro_end_plus1, arguments = m
            return [
                blocks[1:macro_begin-1]
                MacroBlock(_macro, arguments)
                blocks[macro_end_plus1:end]
            ]
        end
    end

    nothing
end


function read_macro(
        blocks::Vector{Any},
        i::Int,
        syntax::Vector{Union{Vector{Token}, MacroArgument}}
    )::Union{Tuple{Int, Vector{Vector{Any}}} , Nothing}

    if isempty(syntax)
        return (i, Vector{Any}[])
    else
        i > lastindex(blocks) && return nothing
        while blocks[i] isa Space
            i += 1
            i > lastindex(blocks) && return nothing
        end

        read_macro(blocks, i, syntax[1], syntax[2:end])
    end
end

function read_macro(
        blocks::Vector{Any},
        i::Int,
        syntaxatom::Vector{Token},
        nextsyntaxatoms::Vector{Union{Vector{Token}, MacroArgument}}
    )::Union{Tuple{Int, Vector{Vector{Any}}}, Nothing}

     hassubvectorat(blocks, i, syntaxatom) ||
        return nothing

    t = read_macro(blocks, i + length(syntaxatom), nextsyntaxatoms)
    t === nothing && return nothing
    return t
end

function read_macro(
        blocks::Vector{Any},
        i::Int,
        syntaxatom::ShortMacroArgument,
        nextsyntaxatoms::Vector{Union{Vector{Token}, MacroArgument}}
    )::Union{Tuple{Int, Vector{Vector{Any}}}, Nothing}

    if i == firstindex(blocks) || blocks[i-1] isa Space
        next_space_i = any(isa.(blocks[i:end], Space)) ?
            first(j for j in i:lastindex(blocks) if blocks[j] isa Space) :
            lastindex(blocks) + 1

        t = read_macro(blocks, next_space_i, nextsyntaxatoms)
        if t !== nothing
            end_i, t_arguments = t
            argument = blocks[i:next_space_i-1]
            return (end_i, [[argument]; t_arguments])
        end
    end

    t = read_macro(blocks, i+1, nextsyntaxatoms)
    if t !== nothing
        end_i, t_arguments = t
        argument = blocks[i]
        return (end_i, [[[argument]]; t_arguments])
    end

    nothing
end

function read_macro(
        blocks::Vector{Any},
        i::Int,
        syntaxatom::LongMacroArgument,
        nextsyntaxatoms::Vector{Union{Vector{Token}, MacroArgument}}
    )::Union{Tuple{Int, Vector{Vector{Any}}}, Nothing}

    next_space_i = any(isa.(blocks[i:end], Space)) ?
        first(j for j in i:lastindex(blocks) if blocks[j] isa Space) :
        lastindex(blocks) + 1

    for argument_end in next_space_i-1:-1:i
        t = read_macro(blocks, argument_end+1, nextsyntaxatoms)
        if t !== nothing
            end_i, t_arguments = t
            argument = blocks[i:argument_end]
            return (end_i, [[argument,]; t_arguments])
        end
    end

    nothing
end
