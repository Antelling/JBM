import json, os
import numpy as np
from copy import deepcopy
from matplotlib.lines import Line2D

from matplotlib import pyplot as plt

results_dir = "../results/rao2_p60"
OPTS_PATH = "../benchmark_problems/new_opts.json"

def make_opt_dict_cfo():
	optimals = json.loads(open(OPTS_PATH).read())
	instance = 1
	case = 1
	ref_dict = {}
	for ds in range(1, 10):
		index = 0
		for case in range(1, 7):
			for instance in range(1, 16):
				opt = optimals[str(ds)][index]
				key = f"{ds} {instance} {case}"
				optimals[key] = opt
				index += 1
	return optimals

def apply_stopping_critera(applications, percentages, n_fails):
	prev_percentage = percentages[0]
	prev_applications = applications[0]
	cutoff = False
	for i in range(1, len(applications)):
		current_percentage = percentages[i]
		current_applications = applications[i]
		if current_applications - prev_applications <= n_fails:
			prev_percentage = current_percentage
			prev_applications = current_applications
		else:
			cutoff = True
			break
	return (prev_percentage, cutoff)

def apply_maxapps_cutoff(applications, percentages, maxapps):
	prev_percentage = percentages[0]
	cutoff = False
	for i in range(1, len(applications)):
		if applications[i] > maxapps:
			cutoff = True
			break
		prev_percentage = percentages[i]
	return (prev_percentage, cutoff)


opt_dict = make_opt_dict_cfo()

color_list = ["red", "gold", "green", "cyan", "blue", "purple", "black", "brown", "tab:blue", "tab:orange", "tab:green"]
next_color_to_use = 0
color_map = {}

for file in os.listdir(results_dir):
	if not "genimps" in file:
		continue

	dataset = file[2]
	print(dataset)

	file = open(os.path.join(results_dir, file))
	results = json.loads(file.read())
	file.close()

	labeled_app_percent_pairs = {}

	for test in results:
		key = test[0]
		impgens = test[1]
		label = test[2]
		if len(impgens) == 0: #skip over control
			continue
		if impgens[0][1] < 1: #do we have to start feasible?
			continue

		#now we need to figure out what color to use for this label
		if label in color_map:
			color_to_use = color_map[label]
		else:
			color_to_use = color_list[next_color_to_use]
			color_map[label] = color_to_use
			next_color_to_use += 1

		key = f"{key['dataset']} {key['instance']} {key['case']}"
		opt = opt_dict[key]
		if opt == -1: #CPLEX failed to find an optimal
			continue
		x = []
		y = []
		for i in range(len(impgens)):
			val = impgens[i][1]
			percent = 100 - ((opt-val)/opt) * 100
			x.append(impgens[i][0])
			y.append(percent)
		if max(y) > 100:
			print(key)
		plt.plot(x, y, linewidth=.4, color=color_to_use, label=label)

		#we need to save the calculated percentage applications pairs according to the algorithm label
		if not label in labeled_app_percent_pairs:
			labeled_app_percent_pairs[label] = []
		labeled_app_percent_pairs[label].append((x, y))
	plt.ylabel("percent of CPLEX reported optimal")
	plt.xlabel("number of metaheuristic applications")
	plt.title(f"Rao1 1 minute dataset{dataset} performance over applications")

	#pyplot does not combine duplicate labels
	#I found this code on stack overflow to suck out the labels and combine duplicates
	handles, labels = plt.gca().get_legend_handles_labels()
	newLabels, newHandles = [], []
	for handle, label in zip(handles, labels):
		if label not in newLabels:
			#I want to increase the line width of the handle
			#but this handle is actually the last line graphed for this element
			#we can't make a deepcopy
			#so let's just make a whole new line
			handle = Line2D([0], [0], color=handle.get_color(), lw=4)
			handle.set_linewidth(2.0)
			newLabels.append(label)
			newHandles.append(handle)
	plt.legend(newHandles, newLabels)
	plt.savefig(f"impgen_graphs/ds{dataset}_app_over_per.png", bbox_inches='tight', dpi=700)
	plt.clf() #clear figure

	print("starting next graph type")
	#now we want to make a graph of how the average percentage changes as the
	#stopping criteria changes
	for label in labeled_app_percent_pairs:
		averages = []
		for stopping_criteria in range(2, 700):
			percentages = []
			cutoff_applied = False
			for i in range(len(labeled_app_percent_pairs[label])):
				_, __ = apply_maxapps_cutoff(
					labeled_app_percent_pairs[label][i][0],
					labeled_app_percent_pairs[label][i][1],
					stopping_criteria)
				percentage, cutoff = apply_stopping_critera(
					labeled_app_percent_pairs[label][i][0],
					labeled_app_percent_pairs[label][i][1],
					stopping_criteria)
				cutoff_applied = cutoff_applied or cutoff
				percentages.append(percentage)
			averages.append(np.mean(percentages))
			if not cutoff_applied:
				#we have increased the stopping criteria to above a value that
				#it makes any difference to our data
				break
		plt.plot(averages, color=color_map[label], label=label)
	plt.title(f"max failed attempts affect on dataset {dataset} average scores")
	plt.xlabel("amount of failed applications used as stopping criteria")
	plt.ylabel("average percentage of optimals acheived")
	plt.legend()
	plt.savefig(f"impgen_graphs/ds{dataset}_stopping_criteria_effects.png", bbox_inches='tight', dpi=700)
	plt.clf()

	print("starting final graph")
	#now we graph of how changing the maximum applications changes the score
	#now we want to make a graph of how the average percentage changes as the
	#stopping criteria changes
	for label in labeled_app_percent_pairs:
		averages = []
		for maxapps in range(2, 15000):
			percentages = []
			cutoff_applied = False
			for i in range(len(labeled_app_percent_pairs[label])):
				percentage, cutoff = apply_maxapps_cutoff(
					labeled_app_percent_pairs[label][i][0],
					labeled_app_percent_pairs[label][i][1],
					maxapps)
				cutoff_applied = cutoff_applied or cutoff
				percentages.append(percentage)
			averages.append(np.mean(percentages))
			if not cutoff_applied:
				#we have increased the stopping criteria to above a value that
				#it makes any difference to our data
				break
		plt.plot(averages, color=color_map[label], label=label)
	plt.title(f"max apps affect on dataset {dataset} average scores")
	plt.xlabel("amount of applications")
	plt.ylabel("average percentage of optimals acheived")
	plt.legend()
	plt.savefig(f"impgen_graphs/ds{dataset}_max_apps.png", bbox_inches='tight', dpi=700)
	plt.clf()
