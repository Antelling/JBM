import xlsxwriter
import json, os
import numpy as np

workbook = xlsxwriter.Workbook('s_meta_compare_bench_raw.xlsx')

optimals_path = "../benchmark_problems/benchmark_cplex_optimals.json"
optimals = json.loads(open(optimals_path).read())

negative_format = workbook.add_format({'bg_color': 'green'})
normal_format = workbook.add_format({})
bitstring_format = workbook.add_format({'shrink': True, 'font_color': 'gray'})
title_format = workbook.add_format({'bold': True})
deemph_format = workbook.add_format({'font_color': 'gray'})

def write_alg_results(row, column, ws, start_name, start_results, dataset):
    ws.write(row, column, start_name, title_format)
    row += 1
    ws.write(row, column, "s-meta", title_format)
    ws.write(row, column+1, "mean score", title_format)
    ws.write(row, column+2, "mean time", title_format)
    ws.write(row, column+3, "stdev score", title_format)
    ws.write(row, column+4, "stdev time", title_format)
    row += 1
    for s_meta in start_results:
        ws.write(row, 0, s_meta, title_format)
        column = 1
        scores = []
        times = []
        for sample in start_results[s_meta]:
            # ws.write(row, column, sample[0])
            scores.append(sample[0])
            # ws.write(row+1, column, sample[1])
            times.append(sample[1])
            # column += 1

        print(dataset, " ", start_name, " ", s_meta, " ", len(scores))
        percentages = [(optimals[dataset][int(np.floor(i/(len(scores)/90)))] - scores[i])/optimals[dataset][int(np.floor(i/(len(scores)/90)))] for i in range(len(scores))]
        ws.write(row, column, np.mean(percentages))
        ws.write(row, column+1, np.mean(times))
        ws.write(row, column+2, np.std(percentages))
        ws.write(row, column+3, np.std(times))
        row += 1

    row += 1
    return row, 0

for ds in range(1,10):
    file = open("../results/s_meta_bench/full_test_suite_ds" + str(ds) + ".json", "r").read()
    file = file.replace("🦔🦔🦔🦔", "exh_flip_or_swap")
    results = json.loads(file)[0]
    ws = workbook.add_worksheet(str(ds))
    row = 0
    column = 0
    for start_population in results:
        row, column = write_alg_results(row, column, ws, start_population, results[start_population], str(ds))


workbook.close()
