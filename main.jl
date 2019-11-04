include("compose.jl")

for dataset in [1]
    print("dataset: $dataset")
    problems = parse_file("benchmark_problems/mdmkp_ct$(dataset).txt")
    println(problems[2])
    println(length(problems))
end
