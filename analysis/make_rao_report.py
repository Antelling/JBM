import ExcelWriter, TrialSet, result_formatter

#make workbook 
book = ExcelWriter.Book("rao_report")

#load data
experiment_names = ["rao2_p30_t120", "rao2_p60_t120", "rao1_p30_tl120", "rao1_p60_t120"]
prefix = "results/"
trialset = TrialSet.TrialSet()
for name in experiment_names:
    trialset.load_genimps(prefix + name)


#headers for tables
def ds_headers(format):
        column_headers = [{'header': f'ds{ds}', 'format': format} for ds in range(1, 10)]
        column_headers = [{'header': 'Algorithm'}] + column_headers
        return column_headers
def case_headers(format):
        column_headers = [{'header': f'case{cs}', 'format': format} for cs in range(1, 7)]
        column_headers = [{'header': 'Algorithm'}] + column_headers
        return column_headers
def all_headers(format):
        column_headers = [{'header': 'Algorithm'}, {'header': 'summary', 'format': format}]
        return column_headers

#------------------------------------------------------------summary section 
for meta_family in ["Rao1", "Rao2"]:
    summary_sheet = book.add_sheet(meta_family + " Summary Tables")
    summary_sheet.add_big_title(meta_family + " Summary Tables", 36)
    summary_sheet.new_section("All Results")
    
    all_results = result_formatter.extract_table(
        trialset, 
        {"metaheuristic": "Rao1"}, 
        ["popsize", "n_param", "local_search"], 
        ["metaheuristic"])
    mean_table = result_formatter.summarize(all_results, result_formatter.ts_mean)
    summary_sheet.add_table(mean_table, title="Averages", headers=all_headers(book.percentage_format))
    std_table = result_formatter.summarize(all_results, result_formatter.ts_std)
    summary_sheet.add_table(std_table, title="Standard Deviations", headers=all_headers(book.percentage_format))
    invalid_table = result_formatter.summarize(all_results, result_formatter.ts_invalid)
    summary_sheet.add_table(invalid_table, title="Total Invalid", headers=all_headers(book.default_format))

    summary_sheet.new_section("Per Dataset")
    ds_results = result_formatter.extract_table(
        trialset, 
        {"metaheuristic": "Rao1"}, 
        ["popsize", "n_param", "local_search"], 
        ["dataset"])
    mean_table = result_formatter.summarize(ds_results, result_formatter.ts_mean)
    summary_sheet.add_table(mean_table, title="Dataset Means", headers=ds_headers(book.percentage_format))
    std_table = result_formatter.summarize(ds_results, result_formatter.ts_std)
    summary_sheet.add_table(std_table, title="Dataset Standard Deviations", headers=ds_headers(book.percentage_format))
    invalid_table = result_formatter.summarize(ds_results, result_formatter.ts_invalid)
    summary_sheet.add_table(invalid_table, title="Dataset Averages", headers=ds_headers(book.default_format))


    summary_sheet.new_section("Per Case")
    case_results = result_formatter.extract_table(
        trialset, 
        {"metaheuristic": "Rao1"}, 
        ["popsize", "n_param", "local_search"], 
        ["case"])
    mean_table = result_formatter.summarize(case_results, result_formatter.ts_mean)
    summary_sheet.add_table(mean_table, title="Case Means", headers=case_headers(book.percentage_format))
    std_table = result_formatter.summarize(case_results, result_formatter.ts_std)
    summary_sheet.add_table(std_table, title="Case Standard Deviations", headers=case_headers(book.percentage_format))
    invalid_table = result_formatter.summarize(case_results, result_formatter.ts_invalid)
    summary_sheet.add_table(invalid_table, title="Case Averages", headers=case_headers(book.default_format))

    summary_sheet.new_section()

#cleanup
book.save()