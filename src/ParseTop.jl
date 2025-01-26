module ParseTop

using Dates, DataFrames

export parsetop

function parsetop(fname::AbstractString)
    #this regex will match the beginning of a new block
    top = r"^\s*top - (\d\d:\d\d:\d\d).*"
    #this regex will match the start of a new table
    table = r"^\s*PID.*"
    blocks = DataFrame[]
    open(fname) do io
        line = readline(io)
        while true
            m = match(top,line)
            if !isnothing(m)
                @assert length(m.captures) == 1
                thistime = m.captures[1] |> Time
                line = readline(io)
                while isnothing(match(table,line))
                    line = readline(io)
                end
                header = split(line)
                rows = []
                while true
                    line = readline(io)
                    #want this to be a row vector
                    if eof(io) || (!isnothing(match(top,line)))
                        #end of this block, build a baby dataframe
                        #looks like there is often an empty line at the end
                        #of a block
                        filter!(rows) do r
                            !isempty(r)
                        end
                        rowmat = vcat(rows...)
                        df = Dict("timestamp" => thistime,
                                  (header[i] => rowmat[:,i] for i in 1:length(header))...) |> DataFrame
                        push!(blocks,df)
                        break
                    end
                    push!(rows,split(line) |> permutedims)
                end
                if eof(io)
                    break
                end
            end
        end
        vcat(blocks...)
    end
end

end # module ParseTop
