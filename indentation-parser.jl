struct Indentor
    precedence::Int

    open::Vector{Token}
    close::Vector{Token}

    open_replacement::String
    close_replacement::String
end

Base.:(==)(i::Indentor, j::Indentor) =
    i.precedence        == j.precedence &&
    i.open              == j.open &&
    i.close             == j.close &&
    i.open_replacement  == j.open_replacement &&
    i.close_replacement == j.close_replacement

struct IndentorBlock
    indentor::Indentor
    contents::Vector{Any}
end

function indentation_parse(
        tokens::Vector{Token},
        indentors::Vector{Indentor}
    )::IndentorBlock

    indented_tokens = [
        InternalMarkerBeginOfFile()
        tokens
        InternalMarkerEndOfFile()
    ]
    indentors_and_marker = [
        indentors
        Indentor(
            typemax(Int)÷10,
            [InternalMarkerBeginOfFile()], [InternalMarkerEndOfFile()],
            document_begin, document_end
        )
    ]
    end_i, block =
        read_indentorortoken(indented_tokens, 1, indentors_and_marker, Indentor[])
    block
end

function read_indentorortoken(
        tokens::Vector{Token},
        i::Int,
        indentors::Vector{Indentor},
        indentor_stack::Vector{Indentor}
    )::Tuple{Int, Union{Token, IndentorBlock}}

    open_indentor_i = findfirst(indentors) do indentor
        hassubvectorat(tokens, i, indentor.open)
    end

    if open_indentor_i === nothing
        return (i+1, tokens[i])
    else
        open = indentors[open_indentor_i].open
        open_indentors = filter(indentors) do indentor
            indentor.open == open
        end
        return read_indentor(tokens, i+length(open), indentors, open_indentors, [indentor_stack; open_indentors])
    end
end

function read_indentor(
        tokens::Vector{Token},
        i::Int,
        indentors::Vector{Indentor},
        indentors_canclose::Vector{Indentor},
        indentor_stack::Vector{Indentor}
    )::Tuple{Int, IndentorBlock}

    contents = Any[]
    while true
        if i > lastindex(tokens)
            compileerror(tokens[end],
                "expected " *
                join((untokenize(i.close) for i in indentors_canclose), ", ", " or ") *
                " before end of file"
            )
            return (i, IndentorBlock(indentors_canclose[1], contents))
        end

        close_indentor_i = findfirst(indentors_canclose) do indentor
            hassubvectorat(tokens, i, indentor.close)
        end
        if close_indentor_i !== nothing
            indentor = indentors_canclose[close_indentor_i]
            return (
                i + length(indentor.close),
                IndentorBlock(indentor, contents)
            )
        end

        closed_higher = filter(indentor_stack) do indentor
            indentor.precedence ≥
                maximum(ind.precedence for ind in indentors_canclose) &&
                hassubvectorat(tokens, i, indentor.close)
        end
        if !isempty(closed_higher)
            compileerror(tokens[i],
                "expected " *
                join((untokenize(i.close) for i in indentors_canclose), ", ", " or ") *
                " before " *
                untokenize(closed_higher[1].close)
            )
            return (
                i,
                IndentorBlock(indentors_canclose[1], contents)
            )
        end

        i, indentorortoken = read_indentorortoken(tokens, i, indentors, indentor_stack)
        push!(contents, indentorortoken)
    end
end



function hassubvectorat(
        xs::Vector,
        subvector_begin::Int,
        subvector::Vector
    )::Bool

    i_xs = subvector_begin
    i_subvector = 1
    while i_subvector ≤ length(subvector)
        i_xs > lastindex(xs)                && return false
        xs[i_xs] != subvector[i_subvector]  && return false
        i_xs        += 1
        i_subvector += 1
    end
    true
end
