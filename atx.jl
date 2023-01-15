include("parser.jl")
include("compiler.jl")
include("indentors.jl")
include("macros.jl")



dynamic = "-d" ∈ ARGS || "--dynamic" ∈ ARGS || "-dp" ∈ ARGS
compile_to_pdf = "-p" ∈ ARGS || "--pdf" ∈ ARGS || "-dp" ∈ ARGS
args_no_flags = filter(x->x∉("-d","--dynamic","-p","--pdf","-dp"), ARGS)

if length(args_no_flags) != 2
    println("USAGE : julia atx.jl <input.atx> <output.tex>")
    println("Use the '-d' or '--dynamic' flag to update output.tex "*
            "each time input.tex is changed.")
    println("Use the '-p' or '--pdf' flag to execute 'pdflatex <output.tex>' "*
            "after updating output.tex.")
    exit(1)
end

input_filename, output_filename = args_no_flags

if !isfile(input_filename)
    printstyled("ERROR : "; bold=true, color=:red)
    println("input file $input_filename doesn't exist")
    exit(1)
end



function main()
    global dynamic, input_filename

    if dynamic
        firsttime = true
        while true
            println(firsttime ? "COMPILING " : "RECOMPILING")
            firsttime = false

            compile_inputfile()

            watch_file(input_filename)
            sleep(0.05)
        end
    else
        compile_inputfile()
    end
end


function compile_inputfile()
    global input_filename, output_filename, compile_to_pdf

    global code = read(input_filename, String)
    println("COMPILING THE FOLLOWING SOURCE : ")
    println(code)
    parsed = atxparse(code, standard_indentors, standard_macros)
    compiled = compile(parsed)
    println("COMPILED :")
    println(compiled)
    open(output_filename, "w") do f
        print(f, compiled)
    end

    if compile_to_pdf
        try
            run(pipeline(`yes x`, `pdflatex $output_filename`))
        catch
            printstyled("ERROR : PDFLATEX FAILED\n"; bold=true, color=:red)
        end
    end
end



function compileerror(msg::String)
    printstyled("ERROR : "; bold=true, color=:red)
    println(msg)
end

function compileerror(i::Int, msg::String)
    printstyled("ERROR AT ", position_in_code(i), " : "; bold=true, color=:red)
    println(msg)
end

function compileerror(t::Token, msg::String)
    compileerror(t.ind_in_code, msg)
end

function compileerror(t::InternalMarkerBeginOfFile, msg::String)
    printstyled("ERROR NEAR BEGINNING OF FILE : "; bold=true, color=:red)
    println(msg)
end

function compileerror(t::InternalMarkerEndOfFile, msg::String)
    printstyled("ERROR NEAR END OF FILE : "; bold=true, color=:red)
    println(msg)
end

struct PositionInCode
    line::Int
    column::Int
end

function position_in_code(i::Int)
    global code

    try
        line = max(
            count(c->c=='\n', code[1:i-1]),
            count(c->c=='\r', code[1:i-1])
        ) + 1

        column = line == 1 ? i :
            count(j for j in 1:i-1 if '\n' ∉ code[j:i] && '\r' ∉ code[j:i])

        return PositionInCode(line, column)
    catch
        return PositionInCode(-1, -1)
    end
end

function Base.show(io::IO, p::PositionInCode)
    print(io, p.line, ":", p.column)
end



using FileWatching

main()
