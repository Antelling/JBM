import ExcelWriter, ResultSet, result_formatter

#make workbook 
book = ExcelWriter.Book("rao_report")

#experiment result locations 
experiment_names = ["rao2_p30_t120", "rao2_p60_t120", "rao1_p30_tl120", "rao1_p60_t120"]
prefix = "results/"
trialset = TrialSet()
for name in experiment_names:
    ResultSet.load_genimps(prefix + name, trialset)

#------------------------------------------------------------summary section 
for meta_family in ["Rao1", "Rao2"]:
    
    summary_sheet = book.add_sheet(meta_family + " Summary Tables")
    summary_sheet.add_big_title(meta_family + " Summary Tables", 36)
    summary_sheet.new_section("Rao1")
    table = result_formatter.extract_table(trialset, {"metaheuristic": "Rao1"}, ["popsize", "n_params", "local_search"], ["dataset"])
    summary_sheet.add_table(table)

    #fill in information
    for experiment in experiments:
        summary_sheet.new_section(experiment.experiment_name)
        experiment.excel_summary(summary_sheet)


#cleanup
summary_sheet.new_section()
book.save()