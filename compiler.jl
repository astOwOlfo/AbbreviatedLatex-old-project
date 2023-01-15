compile(c::UnicodeChar) = c.t

compile(s::Space) = s.nnewlines == 0 ? " " : '\n'^s.nnewlines

function compile(c::Command)
    compileerror(c, "unknown command $command_begin$(c.t)")

    ""
end

compile(v::Verbatim) = v.t

compile(::InternalMarkerEndOfFile)   = ""
compile(::InternalMarkerBeginOfFile) = ""

compile(i::IndentorBlock) =
    i.indentor.open_replacement *
    join(compile.(i.contents)) *
    i.indentor.close_replacement

compile(m::MacroBlock) = join(
    map(m._macro.replacement) do s
        if s isa String
            s
        elseif s isa Int
            join(compile.(m.arguments[s]))
        else
            error(MethodError())
        end
    end
)
