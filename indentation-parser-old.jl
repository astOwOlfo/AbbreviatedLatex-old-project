struct Indentor
    open::Vector{Token}
    close::Vector{Token}
end

Base.:(==)(i::Indentor, j::Indentor) =
    i.open == j.open && i.close == j.close

struct IndentorBlock
    indentor::Indentor
    contents
end

function indentor_parse(tokens::Vector{Token}, indentors::Vector{Indentor})
    tokens_inside_indentor = [
        InternalMarkerBeginOfFile()
        tokens
        InternalMarkerEndOfFile()
    ]
    indentors_and_marker = [
        indentors
        Indentor([InternalMarkerBeginOfFile()], [InternalMarkerBeginOfFile()])
    ]
    _, indentor = read_indentorortoken(
        tokens_inside_indentor,
        1,
        indentors_and_marker
    ]
    indentor
end

function read_indentorortoken(
        tokens::Vector{Token},
        i::Int,
        indentors::Vector{Indentor}
    )::Tuple{Int, Union{IndentorBlock, Token}}

    pointed_indentors = filter(indentors) do indentor
        hassubvectorat(tokens, i, indentor.open)
    end

    return isempty(pointed_indentors) ?
        (i+1, tokens[i]) :
        read_indentor(tokens, i, indentors, pointed_indentors)
end

function read_indentor(
        tokens::Vector{Token},
        i::Int,
        indentors::Vector{Indentor},
        indentors_canclose::Vector{Indentor}
    )::Tuple{Int, IndentorBlock}

    space_blocks = []

    while true
        close_i = findfirst(indentors_canclose) do indentor
            hassubvectorat(tokens, i, indentor.close)
        end
        if close_i !== nothing
            indentor = indentors_canclose[close_i]
            return (
                i + length(indentor.close),
                IndentorBlock(indentor, space_blocks)
            )
        end

        if i > lastindex(tokens)
            compileerror(tokens, i,
                "expected" *
                join((i.close for i in indentors_canclose), ", ", ", or ") *
                "before end of file"
            )
            return (i, IndentorBlock(space_blocks))
        end

        if tokens[i] isa Space
            push!(space_blocks, tokens[i])
            i += 1
            continue
        end

        i, block = read_spaceblock(tokens, i, indentors, indentors_canclose)
        push!(space_blocks, block)
    end
end

function read_spaceblock(
        tokens::Vector{Token},
        i::Int,
        indentors::Vector{Indentor},
        indentors_canclose::Vector{Indentor}
    )::Tuple{Int, Vector{Any}}

    block_contents = []

    while !(
            tokens[i] isa Space ||
            any(
                hassubvectorat(tokens, i, ind.close)
                for ind in indentors_canclose
            )
        )

        i, indtok = read_indentorortoken(tokens, i, indentors)
        push!(block_contents, indtok)
    end

    (i, block_contents)
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
        xs[i_xs] !== subvector[i_subvector] && return false
        i_xs        += 1
        i_subvector += 1
    end
    true
end
