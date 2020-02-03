import xlsxwriter
import json, os
import numpy as np

results_dir = "../results/rao1_fast"
optimals_path = "../benchmark_problems/new_opts.json"

def switch_order(results):
    new_list = []
    for offset in range(6):
        for index in range(offset, 90, 6):
            new_list.append(results[index])
    return new_list


workbook = xlsxwriter.Workbook('rao1_fast.xlsx')

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
    
    for alg in results:
        results[alg] = switch_order(results[alg])

    row = 0
    column = 0

    sheet.write(row, column, "alg name", title_format)
    sheet.write(row, column+1, "mean % error", title_format)
    sheet.write(row, column+2, "standard deviation % error", title_format)
    sheet.write(row, column+3, "mean times", title_format)
    sheet.write(row, column+4, "standard deviation times", title_format)
    row += 1

    percentage_dict = {}
    for alg in results:
        percentages = [(optimals[dataset][i] - results[alg][i][0])/optimals[dataset][i] for i in range(len(results[alg])) if optimals[dataset][i] > -1]
        percentage_dict[alg] = percentages
        times = [res[1] for res in results[alg]]
        sheet.write(row, column, alg)
        sheet.write(row, column+1, np.mean(percentages))
        sheet.write(row, column+2, np.std(percentages))
        sheet.write(row, column+3, np.mean(times))
        sheet.write(row, column+4, np.std(times))
        row += 1

    row += 2

    for alg in results:
        sheet.write(row, column, alg)
        for percent in percentage_dict[alg]:
            column += 1
            sheet.write(row, column, percent)
        row += 1

        column = 0


workbook.close()
