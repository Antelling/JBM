using JSON
include("compose.jl")
include("src/narrow_surveys.jl")

#TODO: cache initial pops
#TODO: change from top 5 to top 1/6

function load_initial_pop(filename)
	file = open(filename)
	data = JSON.parse(file)
	close(file)
	populations = []
	for pop in data
		p_id = Problem_ID(pop[1]["dataset"], pop[1]["instance"], pop[1]["case"])
		solutions = Population()
		for sol in pop[2]
			push!(solutions, Solution(sol[2], sol[1]))
		end
		push!(populations, tuple(p_id, solutions))
	end
	populations
end

function main(; time_limit::Number=10, popsize::Int=30, generator::Function, experiment_name::String, datasets=1:9)
    run(`mkdir -p results/$(experiment_name)`)
    metaheuristics = generator(popsize=popsize, time_limit=time_limit)

    for dataset in datasets
        problems = parse_file("./benchmark_problems/mdmkp_ct$(dataset).txt", dataset)
		initial_pops = load_initial_pop("initial_pops/ds$(dataset)_ps$popsize.json")

        results = Dict{String,Vector}()
		improved_gen_results = Vector{Tuple{Problem_ID, Vector{Tuple{Int,Int}}, String, Float64}}()
        for (name, alg) in metaheuristics
            results[name] = Vector()
        end

        for (i, problem) in enumerate(problems)
            println("")
            println("")
            println("Testing $(problem.id)")

            # generate an initial population using the greedy construct strategy
            # do not force feasibility
            ds_i, pop = initial_pops[i]
			@assert JSON.json(ds_i) == JSON.json(problem.id)

            for (name, meta) in metaheuristics
                curr_pop = deepcopy(pop)
                start_time = time()
                improvement_gens = meta(curr_pop, problem)
                end_time = time()
				elapsed_time = end_time - start_time
				push!(improved_gen_results, tuple(problem.id, improvement_gens, name, elapsed_time))
                highest = get_population_scores(curr_pop)[end]
                println("$name found highest score of $highest")
                push!(results[name], (highest, elapsed_time))
            end
        end

        file = open("results/$(experiment_name)/ds$(dataset)_tl$(time_limit).json", "w")
        write(file, JSON.json(results))
		close(file)
        file = open("results/$(experiment_name)/ds$(dataset)_tl$(time_limit)_genimps.json", "w")
		write(file, JSON.json(improved_gen_results))
        close(file)
    end
end

name_to_func = Dict(
	"jaya"=>generate_jaya_narrow_survey,
	"rao1"=>generate_rao1_narrow_survey,
	"CAC"=>generate_CAC_narrow_survey,
	"rao2"=>generate_rao2_narrow_survey,
	"TLBO"=>generate_TLBO_narrow_survey,
	"TBO"=>generate_TBO_narrow_survey,
	"LBO"=>generate_LBO_narrow_survey,
	"GANM"=>generate_GANM_narrow_survey)


#timelimit is in seconds, but I treat the command line arg as milliseconds
main(
	generator=name_to_func[ARGS[1]],
	experiment_name=ARGS[2],
	popsize=parse(Int, ARGS[3]),
	time_limit=parse(Float64, ARGS[4]),
	datasets=parse(Int, ARGS[5]):parse(Int, ARGS[6]),
	)
