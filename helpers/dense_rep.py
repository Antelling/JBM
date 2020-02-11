import xlsxwriter
import json, os
import numpy as np

"""Define results dir"""
RESULTS_DIR = "../results/rao1_narrow_survey"

"""convert from index major order to case first order"""
def switch_order(results):
	new_list = []
	for offset in range(6):
		for index in range(offset, 90, 6):
			new_list.append(results[index])
	return new_list


"""create workbook"""
workbook = xlsxwriter.Workbook('rao1_fast_dense.xlsx', {'nan_inf_to_errors': True})

"""define xlsxwrite formats"""
percentage_format = workbook.add_format({'num_format': '0.00%'})
title_format = workbook.add_format({'bold': True, 'align': 'center'})
default_format = workbook.add_format({})

"""load optimals"""
OPTIMALS = json.loads(open("../benchmark_problems/new_opts.json").read())

"""takes a list of observed scores and the cplex reported optimals, and then
returns a list of percentages and the amount of observed values that were
skipped over. A value is skipped if it failed to reach feasibility, or if cplex
failed to find a feasible solution.

returns the calculated (percentages, failures) tuples, where percentages and
tuples are arrays segmented by case. observed and optimal must both be in case
first order. """
def calc_percentages(observed, optimals):
	observed = [o[0] for o in observed]
	percentages = []
	failures = []
	for case_start_index in range(0, 90, 15):
		case_observed = observed[case_start_index:(case_start_index+15)]
		case_optimals = optimals[case_start_index:(case_start_index+15)]
		print(len(case_observed))
		case_percentages = []
		case_failures = 0
		for i in range(len(case_observed)):
			if case_observed[i] > 0 and case_optimals[i] > 0:
				case_percentages.append((case_optimals[i] - case_observed[i])/case_optimals[i])
			else:
				case_failures += 1
		percentages.append(case_percentages)
		failures.append(case_failures)

	return (percentages, failures)


"""convert data of the form {"alg1": [x, y, z]} to ["alg1", x, y, z]"""
def dictdata_to_listdata(data, dup_title=True):
	new_data = []
	for key in data:
		subarray = [key]
		subarray += data[key]
		if dup_title:
			subarray.append(subarray[0])
		new_data.append(subarray)
	return new_data


"""loop over every file in the passed directory. Determine the stopping criteria
of the file by splitting on underscores and taking the second item. Determine
the dataset by looking at the third character. Segment the results by stopping
criteria, and then create a subdict of the algorithm results. Each algorithm
has a list of percentages and a number describing how many results were excluded
from the list of percentages"""
def get_data(results_dir, combine_cases=True):
	algorithms_percentages = {}
	algorithms_failures = {}
	for file in os.listdir(results_dir):
		dataset = file[2]

		#determine the stopping criteria and make sure we have a place to
		#store the results:
		stopping_criteria = file.replace(".json", "").split("_")[1]
		if not stopping_criteria in algorithms_percentages:
			algorithms_percentages[stopping_criteria] = {}
			algorithms_failures[stopping_criteria] = {}

		#load the data from the passed file
		file = open(os.path.join(results_dir, file))
		results = json.loads(file.read())
		file.close()

		for alg in results:
			if not alg in algorithms_percentages[stopping_criteria]:
				algorithms_percentages[stopping_criteria][alg] = []
				algorithms_failures[stopping_criteria][alg] = []

			results[alg] = switch_order(results[alg])
			case_percentages, case_failures = calc_percentages(results[alg], OPTIMALS[dataset])

			#we now have two arrays of six items each, each representing a case
			#if we want to combine the cases, we will reformat the data into arrays
			#of one item each, like so:
			if combine_cases:
				smushed_percentages = [[]]
				totaled_failure = [0]
				for i in range(len(case_percentages)):
					smushed_percentages[0] += case_percentages[i]
					totaled_failure[0] += case_failures[i]
				case_percentages = smushed_percentages
				case_failures = totaled_failure

			#now, we loop over every item in the case_percentages and case_failures,
			#ad append the results to the algorithms total for each stopping criteria
			for i in range(len(case_percentages)):
				algorithms_percentages[stopping_criteria][alg].append(np.mean(case_percentages[i]))
				algorithms_failures[stopping_criteria][alg].append(case_failures[i])

	#algorithms_percentages and algorithms_failures are both currently dicts
	#but for our easy table generation we want a list of lists
	return (algorithms_percentages, algorithms_failures)


"""create a table on the passed sheet starting at the passed location with the
passed data. return the width and height occupied by the new table. """
def create_table(sheet, table_title, column_headers, data, row_start, column_start):
	#first we need to determine the table dimensions
	data = dictdata_to_listdata(data)
	width = len(data[0])
	height = len(data)

	width -= 1 #I don't know why I have to do this ???

	#create the table title
	sheet.merge_range(row_start, column_start, row_start, column_start + width, table_title, title_format)
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
	column_headers = [{'header': 'Algorithm'}] + column_headers
	return column_headers

def generate_separate_case_headers(format):
	column_headers = []
	for ds in range(1, 10):
		column_headers += [{'header': f'ds{ds}_cs{cs}', 'format': format} for cs in range(1, 7)]
	column_headers = [{'header': 'Algorithm'}] + column_headers
	return column_headers

def add_totals(array, dup_label=True):
	return array + [sum(array)]

def add_means(array, dup_label=True):
	return array + [np.mean(array)]


all_combined_percentages, all_combined_failures = get_data("../results/rao1_narrow_survey", combine_cases=True)
all_separate_percentages, all_separate_failures = get_data("../results/rao1_narrow_survey", combine_cases=False)
for stopping_criteria in all_combined_percentages:
	combined_percentages = all_combined_percentages[stopping_criteria]
	combined_failures = all_combined_failures[stopping_criteria]
	separate_percentages = all_separate_percentages[stopping_criteria]
	separate_failures = all_separate_failures[stopping_criteria]

	for alg in combined_percentages:
		combined_percentages[alg] = add_means(combined_percentages[alg])
		separate_percentages[alg] = add_means(separate_percentages[alg])
	for alg in combined_failures:
		combined_failures[alg] = add_totals(combined_failures[alg])
		separate_failures[alg] = add_totals(separate_failures[alg])

	sheet = workbook.add_worksheet(stopping_criteria)

	start_row = 0
	percentage_headers = generate_combined_case_headers(percentage_format) + [{'header': 'Mean', 'format': percentage_format}, {'header': 'Algorithm '}]
	filled_width, filled_height = create_table(sheet, "Combined Cases Percentage Averages", percentage_headers, combined_percentages, start_row, 0)
	start_row += filled_height + 3

	failure_headers = generate_combined_case_headers(default_format) + [{'header': 'Total'}, {'header': 'Algorithm '}]
	filled_width, filled_height = create_table(sheet, "Combined Cases Skipped Percentage Totals", failure_headers, combined_failures, start_row, 0)
	start_row += filled_height + 3

	percentage_headers = generate_separate_case_headers(percentage_format) + [{'header': 'Mean', 'format': percentage_format}, {'header': 'Algorithm '}]
	filled_width, filled_height = create_table(sheet, "Separate Cases Percentage Averages", percentage_headers, separate_percentages, start_row, 0)
	start_row += filled_height + 3

	failure_headers = generate_separate_case_headers(default_format) + [{'header': 'Total'}, {'header': 'Algorithm '}]
	filled_width, filled_height = create_table(sheet, "Separate Cases Skipped Percentage Totals", failure_headers, separate_failures, start_row, 0)

	sheet.set_column(1, 6*9, 10) #widen every column

workbook.close()
