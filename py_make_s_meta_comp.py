import xlsxwriter
import json, os
import numpy as np

def geo_mean_overflow(iterable):
    iterable = [x if x > 0 else 1 for x in iterable]
    a = np.log(iterable)
    return np.exp(a.sum()/len(a))

workbook = xlsxwriter.Workbook('s_meta_compare_bench_raw.xlsx')

negative_format = workbook.add_format({'bg_color': 'green'})
normal_format = workbook.add_format({})
bitstring_format = workbook.add_format({'shrink': True, 'font_color': 'gray'})
title_format = workbook.add_format({'bold': True})
deemph_format = workbook.add_format({'font_color': 'gray'})

benched_times = json.loads(open("results/s_meta_bench/full_test_suite_ds3.json", "r").read())

def write_alg_results(row, column, ws, start_name, start_results):
    ws.write(row, column, start_name, title_format)
    row += 1
    ws.write(row, column, "s-meta", title_format)
    ws.write(row, column+1, "mean score", title_format)
    ws.write(row, column+2, "mean time", title_format)
    ws.write(row, column+3, "geo mean score", title_format)
    ws.write(row, column+4, "geo mean time", title_format)
    ws.write(row, column+5, "stdev score", title_format)
    ws.write(row, column+6, "stdev time", title_format)
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
        ws.write(row, column, np.mean(scores))
        ws.write(row, column+1, np.mean(times))
        ws.write(row, column+2, geo_mean_overflow(scores))
        ws.write(row, column+3, geo_mean_overflow(times))
        ws.write(row, column+4, np.std(scores))
        ws.write(row, column+5, np.std(times))
        row += 1

    row += 1
    return row, 0

for i, ds in enumerate(benched_times):
    print(i)
    ws = workbook.add_worksheet(str(i+1))

    row = 0
    column = 0

    for start in ds:
        row, column = write_alg_results(row, column, ws, start, ds[start])




workbook.close()
