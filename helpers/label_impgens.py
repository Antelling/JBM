import os, json

labels = """control
Rao1 top1 bottom1 fast local search
Rao1 top5 bottom5 fast local search
Rao1 top15 bottom15 fast local search
Rao1 top1 bottom1 no local search
Rao1 top5 bottom5 no local search
Rao1 top15 bottom15 no local search""".split("\n")

def label(results_dir, labels, output_dir):
	for filename in os.listdir(results_dir):
		if not "genimps" in filename:
			continue

		file = open(os.path.join(results_dir, filename))
		results = json.loads(file.read())
		file.close()

		i = 0
		while True:
			try:
				for label in labels:
					results[i].append(label)
					i += 1
			except IndexError:
				break

		file = open(os.path.join(output_dir, filename), "w")
		file.write(json.dumps(results))
		file.close()


# label("../results/junk-test", labels, "../results/labeled_junk_test")