abstract type MarcoArgument end
struct ShortMarcoArgument <: MarcoArgument end
struct LongMarcoArgument  <: MarcoArgument end

struct Marco
    syntax::Vector{Union{Vector{Token}, MarcoArgument}}
end

struct MarcoBlock
    marco::Marco
    arguments::Vector{Any}
end

function read_toplevelmarco(
        indentorblock::IndentorBlock,
        i::Int,
        marco::Marco
    )::Union{Tuple{Int, MarcoBlock}, Nothing}

    argumenst = []
    for syntaxelement in marco.syntax
        r = read_marcosyntaxelement(indentorblock, i, syntaxelement)
        r == nothing && return nothing
        i, argument = r
        argument !== nothing && push!(arguments, argument)
    end
    (i, arguments)
end

function read_marcosyntaxelement(
        indentorblock::IndentorBlock,
        i::Int,
        syntaxelement::Vector{Token}
    )::Union{Tuple{Int, Any}, Nothing}

    i > lastindex(indentorblock.contents) && return nothing

    if indentorblock.contents[i] isa Vector
        return indentorblock.contents[i] == syntaxelement ?
                (i+1, nothing) :
                nothing
    else
        return hassubvectorat(indentorblock.contents, i, syntaxelement) ?
                (i+length(syntaxelement), nothing) :
                nothing
    end
end

function read_marcosyntaxelement(
        indentorblock::IndentorBlock,
        i::Int,
        syntaxelement::ShortMarcoArgument
    )::Union{Tuple{Int, Any}, Nothing}

    i > lastindex(indentorblock.contents) && return nothing
    indentorblock.contents[i] isa Space   && (i += 1)
    i > lastindex(indentorblock.contents) && return nothing
    (i+1, indentorblock.contents[i])
end

function read_marcosyntaxelement(
        indentorblock::IndentorBlock,
        i::Int,
        syntaxelement::LongMarcoArgument
    )
    body
end
