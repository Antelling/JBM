import json, os
import numpy as np

results_dir = "../results/junk-test"
optimals_path = "../benchmark_problems/new_opts.json"

def switch_order(results):
    new_list = []
    for offset in range(6):
        for index in range(offset, 90, 6):
            new_list.append(results[index])
    return new_list

optimals = json.loads(open(optimals_path).read())

for file in os.listdir(results_dir):
	if not "genimps" in file:
		continue

    dataset = file[2]
    print(dataset)

    file = open(os.path.join(results_dir, file))
    results = json.loads(file.read())
    file.close()

    for alg in results:
        results[alg] = switch_order(results[alg])
