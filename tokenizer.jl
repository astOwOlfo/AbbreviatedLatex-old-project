const command_begin             = ";"
const endoflinecomment_begin    = "~~"
const multilinecomment_begin    = "~~--"
const multilinecomment_end      = "--~~"
const verbatim_begin            = "`"


abstract type Token end

struct UnicodeChar <: Token
    t::Char
    ind_in_code::Int
end

struct Space <: Token
    nnewlines::Int
    ind_in_code::Int
end

struct Command <: Token
    t::String
    ind_in_code::Int
end

struct Verbatim <: Token
    t::String
    ind_in_code::Int
end

Base.:(==)(c::UnicodeChar,  d::UnicodeChar) = c.t == d.t
Base.:(==)(s::Space,        t::Space)       =
    min(2, s.nnewlines) == min(2, t.nnewlines)
Base.:(==)(c::Command,      d::Command)     = c.t == d.t
Base.:(==)(v::Verbatim,     w::Verbatim)    = v.t == w.t

struct InternalMarkerBeginOfFile <: Token end
struct InternalMarkerEndOfFile   <: Token end



function tokenize(code::AbstractString)::Vector{Token}
    tokens = Token[]

    i::Int = firstindex(code)
    while i ≤ lastindex(code)
        next_i, token = next_token(code, i)
        push!(tokens, token)
        i = next_i
    end

    tokens
end

function next_token(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Token}, Nothing}

    i > lastindex(code) && return nothing

    s = next_token_space(code, i)
    s !== nothing && return s

    c = next_token_command(code, i)
    c !== nothing && return c

    v = next_token_verbatim(code, i)
    v !== nothing && return v

    return (nextind(code, i), UnicodeChar(code[i], i))
end

function next_token_verbatim(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Verbatim}, Nothing}

    i_begin = i

    b = next_verbatim_begin(code, i)
    b === nothing && return nothing
    i, beginend_length = b

    end_pattern = verbatim_begin^beginend_length

    contents = ""
    while !hassubstringat(code, i, end_pattern)
        contents *= code[i]
        i = nextind(code, i)
        if i > lastindex(code)
            compileerror(i,
                "expected $end_pattern before end of file"
            )
            return (i, Verbatim(contents, i_begin))
        end
    end
    i = nextind(code, i, length(end_pattern))

    (i, Verbatim(contents, i_begin))
end

function next_verbatim_begin(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Int}, Nothing}

    begin_length = 0
    while hassubstringat(code, i, verbatim_begin)
        i = nextind(code, i, length(verbatim_begin))
        begin_length += 1
    end
    begin_length > 0 ? (i, begin_length) : nothing
end

function next_token_command(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Command}, Nothing}

    hassubstringat(code, i, command_begin) ||
        return nothing

    i = nextind(code, i, length(command_begin))

    if i > lastindex(code)
        compileerror(i,
            "expected command after $command_begin, found end of file"
        )
        return (i, Command("", i))
    end

    if code[i] ∈ 'a':'z' || code[i] ∈ 'A':'Z'
        t = ""
        while i ≤ lastindex(code) && (code[i] ∈ 'a':'z' || code[i] ∈ 'A':'Z')
            t *= code[i]
            i = nextind(code, i)
        end
        return (i, Command(t, i))
    elseif next_newline(code, i) !== nothing
        return (next_newline(code, i), Command("\n", i))
    else
        return (nextind(code, i), Command(string(code[i]), i))
    end
end

function next_token_space(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Space}, Nothing}

    nnewlines = 0
    something_done = false
    while i ≤ lastindex(code)
        if isspace(code[i]) && code[i] ∉ ('\n', '\r')
            i = nextind(code, i)
            something_done = true
            continue
        end

        n = next_newline(code, i)
        if n !== nothing
            i = n
            nnewlines += 1
            something_done = true
            continue
        end

        c = next_comment(code, i)
        if c !== nothing
            i, comment = c
            nnewlines += comment.nnewlines
            something_done = true
            continue
        end

        break
    end

    something_done ?
        (i, Space(nnewlines, i)) :
        nothing
end

function next_comment(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Space}, Nothing}

    multiline = next_multilinecomment(code, i)
    multiline !== nothing && return multiline

    endofline = next_endoflinecomment(code, i)
    endofline !== nothing && return endofline

    nothing
end

function next_endoflinecomment(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Space}, Nothing}

    hassubstringat(code, i, endoflinecomment_begin) ||
        return nothing

    i = nextind(code, i, length(endoflinecomment_begin))
    nnewlines = 0
    while true
        i > lastindex(code) && return (i, Space(nnewlines+1, i))

        n = next_newline(code, i)
        if n !== nothing
            return (n, Space(nnewlines+1, i))
        end

        c = next_multilinecomment(code, i)
        if c !== nothing
            i, comment = c
            nnewlines += comment.nnewlines
            continue
        end

        i = nextind(code, i)
    end
end

function next_multilinecomment(
        code::AbstractString,
        i::Int
    )::Union{Tuple{Int, Space}, Nothing}

    hassubstringat(code, i, multilinecomment_begin) ||
        return nothing

    nnewlines = 0
    i = nextind(code, i, length(multilinecomment_begin))
    while !hassubstringat(code, i, multilinecomment_end)
        if i > lastindex(code)
            compileerror(i, "multiline comment not closed before end of file")
            return (i, Space(nnewlines, i))
        end

        c = next_comment(code, i)
        if c !== nothing
            i, comment = c
            nnewlines += comment.nnewlines
            continue
        end

        n = next_newline(code, i)
        if n !== nothing
            i = n
            nnewlines += 1
            continue
        end

        i = nextind(code, i)
    end
    i = nextind(code, i, length(multilinecomment_end))

    return (i, Space(nnewlines, i))
end

function next_newline(code::AbstractString, i::Int)::Union{Int, Nothing}
    if code[i] == '\n'
        next_i = nextind(code, i)
        if next_i ≤ lastindex(code) && code[i] == '\r'
            return nextind(code, next_i)
        else
            return next_i
        end
    end
    if code[i] == '\r'
        next_i = nextind(code, i)
        if next_i ≤ lastindex(code) && code[i] == '\n'
            return nextind(code, next_i)
        else
            return next_i
        end
    end

    nothing
end


untokenize(c::UnicodeChar) = string(c.t)
untokenize(s::Space)       = s.nnewlines == 0 ?
                                " " :
                                "<NEWLINE>"^s.nnewlines
untokenize(c::Command)     = command_begin * c.t
untokenize(v::Verbatim)    = "`" * v.t * "`"
untokenize(::InternalMarkerBeginOfFile) = "<BEGIN OF FILE>"
untokenize(::InternalMarkerEndOfFile)   = "<END OF FILE>"
untokenize(tokens)         = join(untokenize.(tokens))


function hassubstringat(
        s::AbstractString,
        substring_begin_in_s::Int,
        substring::AbstractString
    )::Bool

    i_substring = firstindex(substring)
    i_s = substring_begin_in_s
    while i_substring ≤ lastindex(substring)
        i_s > lastindex(s) && return false
        s[i_s] == substring[i_substring] || return false
        i_s         = nextind(s,         i_s)
        i_substring = nextind(substring, i_substring)
    end
    true
end
