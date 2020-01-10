import xlsxwriter
import json, os
import numpy as np

results_dir = "../results/wide_survey"
optimals_path = "../benchmark_problems/benchmark_cplex_optimals.json"

def geo_mean_overflow(iterable):
    iterable = [x if x > 0 else 1 for x in iterable]
    a = np.log(iterable)
    return np.exp(a.sum()/len(a))


workbook = xlsxwriter.Workbook('normal_results.xlsx')

negative_format = workbook.add_format({'bg_color': 'green'})
normal_format = workbook.add_format({})
bitstring_format = workbook.add_format({'shrink': True, 'font_color': 'gray'})
title_format = workbook.add_format({'bold': True})
deemph_format = workbook.add_format({'font_color': 'gray'})

optimals = json.loads(open(optimals_path).read())

for file in os.listdir(results_dir):
    short_file = file.replace(".json", "")
    sheet = workbook.add_worksheet(short_file)
    dataset = file[2]
    print(dataset)

    file = open(os.path.join(results_dir, file))
    results = json.loads(file.read())
    file.close()

    row = 0
    column = 0

    sheet.write(row, column, "alg name", title_format)
    sheet.write(row, column+1, "arithmetic mean % error", title_format)
    sheet.write(row, column+2, "standard deviation % error", title_format)
    sheet.write(row, column+3, "arithmetic mean times", title_format)
    sheet.write(row, column+4, "standard deviation times", title_format)
    row += 1

    for alg in results:
        percentages = [(optimals[dataset][i] - results[alg][i][0])/optimals[dataset][i] for i in range(len(results[alg]))]
        times = [res[1] for res in results[alg]]
        sheet.write(row, column, alg)
        sheet.write(row, column+1, np.mean(percentages))
        sheet.write(row, column+2, np.std(percentages))
        sheet.write(row, column+3, np.mean(times))
        sheet.write(row, column+4, np.std(times))
        row += 1

workbook.close()
