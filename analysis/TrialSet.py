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