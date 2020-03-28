include("compose.jl")
using JSON, Random, Dates

println("Running on $(Threads.nthreads()) threads")

"""
In this file, we attempt to cram as many applications of the metaheuristic as
we can into a timelimit. This ensures we are always quickly coming up with
improved solutions.


Stopping Criteria
================================================================================
the stopping criteria can be:
a time time limit:
	This does not work well, because the graph of applications to best
	discovered score is logarithmic - eventually, we will be "trapped" in the
	flat part of the graph, and no new improvements will be found. Additionally,
	different metaheuristics or even different problems may need different time
	limits - the time limit then becomes a parameter that needs to be tuned for
	every problem.
a maximum amount of failed metaheuristic application attempts:
	This stopping criteria attempts to determine when a metaheuristic has
	entered the flat part of the logarithm graph, but does so in an indirect,
	hard to control manner. Some metaheuristics are faster or slower than
	others, so using a flat "n failed attempts" stopping criteria will not be a
	fair comparison.

So, we need a stopping criteria that is understandable, easy to control, and
automatically efficient. I proposed: Minimum improvement over timeframe.

The user/business will specify:
A timeframe
A minimum score improvement

The metaheuristic will then be applied to the problem for the timeframe amount
of time. The improvement is then defined as the new best result's score minus
the previous best result's score. If this score is greater or equal to the
minimum score improvement, repeat the process.

A longer timeframe will lead to a more accurate measure of the improvement rate,
but may waste time spinning on an already-leveled-out problem/solution-set
scenario.

All businesses, when applying metaheuristics, are limited by server costs.
Otherwise, they would rent a whole datacenter and simply try every possible
solution. By allowing the stopping criteria to be expressed as a ratio between
time and improvement rate, a business can exactly determine the optimal time to
stop - as long as there is a function to convert the score of a solution to an
exact, constant monetary cost.
"""
const timeframe = 1.5
const minimum_improvement = 5

"""
There is one more thing we need to consider. Say we have all night to determine
the best way to cut tomorrow's steel stock to fulfill tomorrow's steel orders.
We have 6 hours to find the best solution. Is it better to run a metaheuristic
with a smaller population size numerous times, or a metaheuristic with a much
larger population only once?

Let's specify a large timelimit, and after each timeframe, we will record the
current elapsed time and the best found score of the current solution.
"""
const time_limit = 120
const pop_sizes = [6, 12, 18, 24, 30, 60, 90]

"""Get a formatted datetime stamp"""
function date_time_stamp()
	df = Dates.@dateformat_str("Y-mm-dTHHMM");
	return Dates.format(now(), df)
end


"""Specify some common metaheuristic families"""
const name_to_func = Dict(
	"jaya"=>generate_jaya_narrow_survey,
	"rao1"=>generate_rao1_narrow_survey,
	"CAC"=>generate_CAC_narrow_survey,
	"rao2"=>generate_rao2_narrow_survey,
	"TLBO"=>generate_TLBO_narrow_survey,
	"TBO"=>generate_TBO_narrow_survey,
	"LBO"=>generate_LBO_narrow_survey,
	"GANM"=>generate_GANM_narrow_survey)

"""Create a structure to hold experimental results for one problem"""
struct ProblemResults
	timeframe_results::Vector{Tuple{Dates.Time,Int}}
	best_ten::Vector{Solution}
	problem::Problem_ID
end

"""Combine each population size with each metaheuristic in the
metaheuristic family specified by the "meta_family::String" parameter. Run the
pairing, cramming as many repetitions into the timelimit constant as possible,
using the minimum improvement ratio stopping criteria constants specified
earlier. While the experiment runs, store the score of the best scoring solution
of the current population after each timeframe constant, as well as the top ten
best solutions ever encountered, sorted best to worst. """
function run_experiment(meta_family::String)
	start_date = date_time_stamp()

	Threads.@threads for popsize in pop_sizes
		println("popsize: $popsize")
		metaheuristics = name_to_func[meta_family](popsize=popsize,
				time_limit=timeframe) #each metaheuristic will run for the
				#small timestep specified in timeframe

		Threads.@threads for dataset in 1:9
			println("	dataset: $dataset")
			Threads.@threads for (name, alg) in metaheuristics
				println("		alg: $(name)")
				#make sure the folders needed to store this experiments info exists
				folder_path =
					"results/$(meta_family)/$(start_date)" *
					"/popsize_$(popsize)/dataset_$(dataset)/"
				run(`mkdir -p $folder_path`)
				#make the file as well
				filename = replace(name, " "=>"_")
				run(`touch $(folder_path)/$(filename).json`)

				#load the problems and a place to store problem results
				problems = parse_file(
					"./benchmark_problems/mdmkp_ct$(dataset).txt",
					dataset)
				dataset_results = Vector{ProblemResults}()

				#loop over every problem
				for problem in problems
					println("			problem: $(problem.id)")
					push!(dataset_results, cram_metaheuristic_apps(
							alg, problem, time_limit, popsize))
				end
				file = open("$(folder_path)/$(filename).json", "w")
				write(file, JSON.json(dataset_results))
				close(file)
			end
		end
	end
end

"""cram as many applications of the metaheuristic as possible into the
timelimit"""
function cram_metaheuristic_apps(alg, problem, time_limit, popsize)
	#initialize result storage
	problem_bests_over_time = Vector{Tuple{Dates.Time,Int}}()
	problem_top_ten_solutions = Vector{Solution}()

	#how should we generate an initial population?
	#we want the same initial population for each problem id AND
	#popsize AND metaheuristic trial number, REGARDLESS of
	#the current metaheuristic or current runtime.
	metaheuristic_trial = 1
	start_time = now()
	while metaheuristic_trial < 10000
		random_seed  =  problem.id.dataset * 1e10 +
						problem.id.instance * 1e9 + #2 digits
						problem.id.case * 1e7 + #1 digits
						popsize * 1e4 + #3 digits
						metaheuristic_trial #4 digits
		Random.seed!(Int(random_seed))
		pop = greedy_construct(problem, popsize,
			ls=NLS, force_valid=false)

		termination_reason = run_metaheuristic(alg, pop, problem,
				problem_bests_over_time, start_time, time_limit)
		#if this is a 1, the metaheuristic is exhausted, but
		#not the timlimit. We should continue the loop.
		#if this is a 2, the time limit is exhausted, so we
		#should terminate the loop. However, before we do
		#anything, we must include this run's top ten solutions
		#in our problem-wide top ten.
		problem_top_ten_solutions = sort(vcat(
				problem_top_ten_solutions,
				pop), by=x->-x.score)[1:minimum([end,10])]

		if termination_reason == 2
			break
		else
			metaheuristic_trial += 1
		end
	end

	return ProblemResults(problem_bests_over_time, problem_top_ten_solutions,
		problem.id)
end

"""Run the metaheuristic until one of two stopping criteria occurs:
1) minimum improvement rate is violated
2) time limit is violated.
If 1) occurs, return 1. If 2), return 2.

the parameters populatin and improvement_gens are updated in place. """
function run_metaheuristic(alg, pop::Population, problem::Problem,
		improvement_gens, start_time, time_limit::Number)
	time_limit = Dates.Second(time_limit)
	prev_best = get_best_solution(pop)
	push!(improvement_gens, tuple(now(), prev_best.score))
	while true
		a = now()
		alg(pop, problem)
		#the application of the algorithm occurs in place,
		#and returns fine grained improvement generation
		#detail. However, we that much fidelity takes a lot
		#of space to store and sync with version control,
		#and we don't really need it.

		new_best = get_best_solution(pop)
		push!(improvement_gens, tuple(now(), new_best.score))

		#check stopping criteria
		if (now() - start_time) > time_limit
			return 2
		elseif new_best.score - prev_best.score < minimum_improvement
			return 1
		end

		#if no stopping criteria was met, update prev_best and continue the
		#loop
		prev_best = new_best
	end
end

run_experiment("rao2")
