import json, os
results_dirs = ["../results/Rao2", "../results/Rao1"]

for results_dir in results_dirs:
	for date in os.listdir(results_dir):
		try:
			for popsize in os.listdir(os.path.join(results_dir, date)):
				for dataset in os.listdir(os.path.join(results_dir, date, popsize)):
					try:
						data = json.loads(open(os.path.join(results_dir, date, popsize, dataset, "control.json"), "r").read())
						new_data = []
						for entry in data:
							entry["timeframe_results"] = []
							new_data.append(entry)
						with open(os.path.join(results_dir, date, popsize, dataset, "control2.json"), "w") as file:
							file.write(json.dumps(new_data))
							print("writing to file ", os.path.join(results_dir, date, popsize, dataset, "control2.json"))
					except (FileNotFoundError, json.decoder.JSONDecodeError):
						pass
		except NotADirectoryError:
			pass
