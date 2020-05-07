import xlsxwriter
import json, os
import numpy as np
from collections import OrderedDict
from matplotlib import pyplot as plt
from datetime import datetime

results_dirs = ["../results/Rao2", "../results/Rao1", "../results/CAC"]
results_dirs = ["../results/rao1_p30_tl120", "../results/rao1_p60_tl120", "../rao2_p60_tl120", "../rao2_p30_tl120"]


def add_formats(workbook):
	percentage_format = workbook.add_format({'num_format': '0.00%'})
	title_format = workbook.add_format({'bold': True, 'align': 'center'})
	default_format = workbook.add_format({})
	return {
		"percent": percentage_format,
		"title": title_format,
		"default": default_format}

"""load optimals"""
OPTIMALS = json.loads(open("../benchmark_problems/new_opts.json").read())
def get_optimal(problem_id):
	return OPTIMALS[str(problem_id["dataset"])][(problem_id["case"]-1)*15 + ((problem_id["instance"]-1))]


"""convert data of the form {"alg1": [x, y, z]} to [["alg1", x, y, z]]"""
def dictdata_to_listdata(data, dup_title=True):
	new_data = []
	for key in data:
		subarray = [key]
		subarray += data[key]
		if dup_title:
			subarray.append(subarray[0])
		new_data.append(subarray)
	return new_data


"""create a table on the passed sheet starting at the passed location with the
passed data. return the width and height occupied by the new table. """
def create_table(sheet, table_title, column_headers, data, row_start, column_start, formats):
	#first we need to determine the table dimensions
	print("making table ", table_title)
	data = dictdata_to_listdata(data)
	width = 11
	height = len(data)
	width -= 1 #I don't know why I have to do this ???

	#create the table title
	sheet.merge_range(row_start, column_start, row_start, column_start + width, table_title, formats["title"])
	row_start += 1 #move cell pointer to below the title
	sheet.set_column(column_start, column_start, 35) #widen the first column
	sheet.set_column(column_start + width, column_start + width, 35) #widen the last column

	#create the table
	sheet.add_table(
		row_start, column_start,
		row_start + height, column_start + width,
		{'data': data, 'columns': column_headers})

	return width, height + 1 #plus one because we added the title

def generate_combined_case_headers(format):
	column_headers = [{'header': f'ds{ds}', 'format': format} for ds in range(1, 10)]
	column_headers = [{'header': 'Algorithm'}] + column_headers + [{'header': 'Algorithm '}]
	return column_headers

def parse_time(timestamp):
	try:
		return datetime.strptime(timestamp, "%X.%f")
	except ValueError: #no fractional seconds
		return datetime.strptime(timestamp, "%X")


#first we load the result dir tree into a dictionary format
def make_root_excel_summary(res_dir, make_xlsx=True, make_graphs=False):
	print("making root results for " + res_dir)
	results = OrderedDict()

	#get list of results files
	files = [f for f in os.listdir(res_dir) if f[7] == "_"]

	#==========================#load the folder structure into a memory structure
	for popsize_name in sorted(files, key=lambda x: int(x[8:])):
		print("    current popsize is: " + popsize_name)
		subresults = OrderedDict()

		for dataset_name in sorted(os.listdir(os.path.join(res_dir, popsize_name))):
			print("        current dataset is: " + dataset_name)
			subsubresults = OrderedDict()

			for algorithm_name in sorted(os.listdir(os.path.join(res_dir, popsize_name, dataset_name))):
				print("            current algorithm is: " + algorithm_name)
				if os.path.getsize(os.path.join(res_dir, popsize_name, dataset_name, algorithm_name)) > 3000000:
					print("				file too large, skipping")
					continue

				try:
					string_val = open(os.path.join(res_dir, popsize_name,
									  dataset_name, algorithm_name), "r").read()
				except UnicodeDecodeError:
					continue

				if not string_val:
					continue
				val = json.loads(string_val)
				print("					results loaded. ")
				subsubresults[algorithm_name] = val
				print("					done")

			subresults[dataset_name] = subsubresults
		results[popsize_name] = subresults

	#===========================================fill the excel file in with data
	if make_xlsx:
		workbook = xlsxwriter.Workbook(os.path.join(res_dir, 'summary.xlsx'), {'nan_inf_to_errors': True})
		formats = add_formats(workbook)

		print("workbook created")

		for popsize in results:
			print("  populating worksheet for popsize ", popsize)
			#results for each popsize are on unique sheets
			worksheet = workbook.add_worksheet(popsize)

			#now get a list of all metaheuristics that ran for this popsize
			dataset_metaheuristic_percentages = OrderedDict()
			dataset_metaheuristic_exclusions = OrderedDict()
			for dataset in results[popsize]:
				for meta_name in results[popsize][dataset]:
					dataset_metaheuristic_percentages[meta_name] = [[]] * 9
					dataset_metaheuristic_exclusions[meta_name] = [[]] * 9

			#fill in the list of metas that ran with summary stats
			#for all the results we have
			for meta_name in dataset_metaheuristic_percentages:
				for dataset in results[popsize]:
					try:
						dataset_i = int(dataset[8:]) # strip "dataset_"
					except ValueError:
						continue #its not a result folder
					try:
						data = results[popsize][dataset][meta_name]
						percents = [(get_optimal(s["problem"])-s["best_ten"][0]["score"])/s["best_ten"][0]["score"]
							if (get_optimal(s["problem"]) > 0 and s["best_ten"][0]["score"] > 0) else -1
							for s in data]
					except KeyError:
						percents = [np.NaN]


					mean_value = np.mean([p for p in percents if p >= 0])
					exclusions = sum([1 for p in percents if p < 0])
					dataset_metaheuristic_percentages[meta_name][dataset_i-1] = mean_value
					dataset_metaheuristic_exclusions[meta_name][dataset_i-1] = exclusions

			#we need to replace [] with "" in the empty case
			for key in dataset_metaheuristic_percentages:
				for i, result in enumerate(dataset_metaheuristic_percentages[key]):
					if result == []:
						dataset_metaheuristic_percentages[key][i] = ""

			percentage_headers = generate_combined_case_headers(formats["percent"])
			default_headers = generate_combined_case_headers(formats["default"])
			row, column = create_table(worksheet, "Combined Cases Percentage Averages", percentage_headers, dataset_metaheuristic_percentages, 0, 0, formats)
			row, column = create_table(worksheet, "Amount of Problems Excluded From Means", default_headers, dataset_metaheuristic_exclusions, row+1, 0, formats)

		print("closing workbook...")
		workbook.close()
		print("workbook closed. ")

	#====================================================make the summary graphs
	if make_graphs:
		for ps in results:
			for ds in results[ps]:
				for meta in results[ps][ds]:
					lines = []
					for problem in results[ps][ds][meta][1:6]:
						optimal = get_optimal(problem["problem"])
						times, scores, best_encountered = [], [], []
						start_time = parse_time(problem["timeframe_results"][0][0])
						for (time, score) in problem["timeframe_results"]:
							elapsed_time = parse_time(time) - start_time
							if score < 0 or optimal < 0:
								percent = None
							else:
								percent = (optimal - score)/optimal

							raw_percent = (optimal - score)/optimal

							if len(best_encountered) == 0 or raw_percent < best_encountered[-1]:
								best_encountered.append(raw_percent)
							else:
								best_encountered.append(best_encountered[-1])
							times.append(elapsed_time.microseconds)
							scores.append(percent)
						times = list(range(len(scores)))
						plt.plot(times, scores)

					plt.title(meta + " scores over time")
					plt.rcParams["figure.figsize"] = (7,7)
					plt.savefig(os.path.join(res_dir, ps, ds, f"graph_score_{meta}.png"),
							dpi=300)
					plt.clf()

def make_root_excel_summaries(res_dir):
	results = {}
	for folder in reversed(list(os.listdir(res_dir))):
		make_root_excel_summary(os.path.join(res_dir, folder))


for results_dir in results_dirs:
	make_root_excel_summaries(results_dir)
