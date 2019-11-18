function test_DPH()
    for dataset in [1]
	    problems = parse_file("../benchmark_problems/mdmkp_ct$(dataset).txt")

	    for problem in problems[1:1]
	        DPH(problem)
		end
	end
end

D = test_DPH()
