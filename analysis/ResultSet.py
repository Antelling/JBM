import os, json, re
import numpy as np
import ExcelWriter, Graphs

"""load a set of CPLEX-determined optimals and look them up by problem id"""
class OptimalSet(object):
    def __init__(self):
        try:
            self.optimals = json.loads(open("../benchmark_problems/new_opts.json").read())
        except FileNotFoundError:
            self.optimals = json.loads(open("./benchmark_problems/new_opts.json").read())

    def get_optimal(self, problem_id):
        ds_opts = self.optimals[str(problem_id["dataset"])]
        return ds_opts[(problem_id["case"]-1)*15 + ((problem_id["instance"]-1))]

"""collection of all nine datasets and associated expirement metadata"""
class ExperimentResult(object):
    def __init__(self, filepath, opts):
        self.opts = opts 
        self.experiment_name = os.path.basename(filepath)

        for infostr in os.path.basename(filepath).split(".")[0].split("_"):
            if not infostr:
                continue
            elif infostr[0] == "p":
                self.popsize = int(infostr[1:])
            elif infostr[0:1] == "ps":
                self.popsize = int(infostr[2:])
            elif infostr[0:1] == "tl":
                self.timelimit = int(infostr[2:])

        self.datasets = []

    def add_dataset(self, dataset_result):
        self.datasets.append(dataset_result)
        self.datasets.sort(key=lambda x: x.dataset_id)

    def excel_summary(self, sheet: ExcelWriter.Sheet):
        dataset_summaries = []
        included_metaheuristics = set()
        for dataset in self.datasets:
            included_metaheuristics = included_metaheuristics.union(dataset.included_metaheuristics())
            dataset_summaries.append((dataset.dataset_id, dataset.get_summary_stats()))

        #change from using datasets as the datastructure root to metaheuristics
        table = {meta : [] for meta in included_metaheuristics}
        for (dataset_id, dataset) in dataset_summaries:
            for meta, summary in dataset.items(): 
                table[meta].append(summary)

        for (statname, stattype, tabletitle) in [
                ("mean", False, "Average Percentage Error"), 
                ("std", False, "Standard Deviation of Percentage Errors"), 
                ("invalid", True, "Total Invalid/Failed Problems Excluded From Other Tables")]:
            sheet.add_summary_table(table, statname, table_title=tabletitle, last_col_total=stattype)

    """insert whisker plots of all metaheuristic results for each dataset to the current sheet section"""
    def whisker_plots(self, sheet: ExcelWriter.Sheet):
        metas = {meta : [] for meta in self.included_metaheuristics()}
        for meta in metas:
            metas[meta] = [ds._results_for_meta(meta) for ds in self.datasets]
        sheet.add_image(Graphs.whisker_plot(metas))

    def included_metaheuristics(self):
        included_metaheuristics = set()
        for dataset in self.datasets:
            included_metaheuristics = included_metaheuristics.union(dataset.included_metaheuristics())
        return included_metaheuristics



"""Results for several algorithms on the 90 problems of a dataset. """
class DatasetResult(object):
    def __init__(self, dataset_id):
        self.results = []
        self.dataset_id = dataset_id
    
    def add_result(self, result):
        self.results.append(result)

    def get_summary_stats(self):
        valid_dict = self._split_validity()
        sum_stats = {}
        for meta in valid_dict:
            sum_stats[meta] = {
                "mean": np.mean(valid_dict[meta]["valid"]),
                "std": np.std(valid_dict[meta]["valid"]),
                "invalid": len(valid_dict[meta]["invalid"])
            }
            
                
        return sum_stats

    def _results_for_meta(self, meta_name):
        results = []
        for result in self.results:
            if result.meta_name == meta_name:
                results.append(result)
        return results

    def _split_validity(self):
        validity_dict = {}
        for meta in self.included_metaheuristics():
            try:
                self._results_for_meta(meta)[0].is_valid() #trigger a potential error before updating the validity_dict
                validity_dict[meta] = {"valid": [], "invalid": []}
                for result in self._results_for_meta(meta):
                    key = "valid" if result.is_valid() else "invalid"
                    validity_dict[meta][key].append(result.best_percent())
            except IndexError:
                pass
        return validity_dict

    """
    We want to be able to ask questions like, "how does this metaheuristic 
    family perform on mixed cost cases?"
    """
    def segment_results(self):
        validity_dict = {}
        for meta in self.included_metaheuristics():
            try:
                self._results_for_meta(meta)[0].is_valid() #trigger a potential error before updating the validity_dict
                validity_dict[meta] = {"valid": [], "invalid": []}
                for result in self._results_for_meta(meta):
                    key = "valid" if result.is_valid() else "invalid"
                    validity_dict[meta][key].append(result.best_percent())
            except IndexError:
                pass
        return validity_dict

    def included_metaheuristics(self):
        return set([result.meta_name for result in self.results])

"""A trial holds the result for one metaheuristic instance applied to one problem. """
class Trial(object):
    def __init__(self, problem_id, genimps, meta_name, elapsed_time, folder_name, opts):
        self.problem_id = problem_id
        self.genimps = genimps 
        self.meta_name = meta_name 

        self.attributes = {}

        #problem derived attributes
        self.attributes["case"] = problem_id["case"]
        self.attributes["dataset"] = problem_id["dataset"]
        self.attributes["instance"] = problem_id["instance"]
        self.attributes["mixed_cost"] = problem_id["case"] > 3

        #result derived attributes
        self.attributes["found_score"] = best = self.genimps[-1][1]
        self.attributes["optimal_score"] = opts.get_optimal(self.problem_id)
        self.attributes["percentage"] = (self.attributes["optimal_score"] - self.attributes["found_score"]) / self.attributes["optimal_score"]
        self.attributes["feasible"] = self.attributes["optimal_score"] > 0 and self.attributes["found_score"] > 0
        self.attributes["elapsed_time"] = elapsed_time

        #algorithm configuration attributes 
        self.attributes["metaheuristic"] = re.match(r"^(\S+) ", meta_name).group(1)
        self.attributes["n_param"] = re.match(r".*top(\d+)", meta_name).group(1)
        self.attributes["local_search"] = re.match(r"^\S+ \S+ \S+ (.+)", meta_name).group(1)
        
        self.attributes["popsize"] = re.match(r".*p(\d+)", folder_name).group(1)
        self.attributes["time_limit"] = re.match(r".*tl?(\d+)", folder_name).group(1)

"""A TrialSet is a collection of trials and an API for querying them."""
class TrialSet(object):
    def __init__(self, trials=None):
        self.trials = trials if not (trials is None) else []

    def add_trial(self, trial : Trial): 
        self.trials.append(trial)

    """accepts a dictionary of attribute name-value pairs. Returns all 
    trials with attributes that superset the passed dictionary. """
    def get_matching_trials(self, attributes):
        attributes = attributes.items()
        return [t for t in self.trials if attributes <= t.attributes.items()]

    """accepts an attribute key, returns the set of all values for the key possessed 
    by trials in this trialset."""
    def get_attribute_values(self, attribute):
        return set([t.attributes[attribute] for t in self.trials])


"""load an experiment saved in the genimp format"""
def load_genimps(filepath, trialset):
    opts = OptimalSet()

    for file in os.listdir(filepath):
        if "genimps" in file: 
            data = json.loads(open(os.path.join(filepath, file), "r").read())
            for result in data: 
                result = Trial(*result, filepath, opts)
                trialset.add_result(result)

            experiment.add_dataset(dataset_result)