function test()
    for dataset in 1:9
        problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")
        @assert length(problems) == 90
    end
end
test()
println("dataset tests passed")
