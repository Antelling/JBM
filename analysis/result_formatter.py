import TrialSet
from copy import deepcopy 
import collections
import numpy as np

def flattend(d, parent_key='', sep='_'):
    items = []
    for k, v in d.items():
        new_key = parent_key + sep + k if parent_key else k
        if isinstance(v, collections.MutableMapping):
            items.extend(flattend(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

"""accepts a trialset and list of attribute names, returns a recursive
dict keyed with the values of the attribute at each level. """
def enboxen(trialset : TrialSet.TrialSet, boxens):
    vloop = {}
    for boxen in boxens: 
        vloop = {att : deepcopy(vloop) for att in trialset.get_attribute_values(boxen)}
    
    return _recurcenboxen(trialset, boxens)

"""recursively segment a trialset according to the passed list of 
attribute names"""
def _recurcenboxen(trialset : TrialSet.TrialSet, remainen_boxens):
    zzloom = {}
    for att in trialset.get_attribute_values(remainen_boxens[0]):
        zzz = trialset.get_matching_trials({remainen_boxens[0] : att})
        zzz = TrialSet.TrialSet(zzz)
        if len(remainen_boxens) > 1:
            zzz = _recurcenboxen(zzz, remainen_boxens[1:])
        zzloom[att] = zzz

    return zzloom


"""The flattend function I took from stackoverflow concats 
each dimension value with an underscore. So if the dimensions 
are [popsize, n_params] the labels would look like 
["30_1", "30_5", ..., "60_30"]. This function splits up the key 
and labels each dimension, returning a new key."""
def label_key(key, dimensions) -> str:
    key = key.split("_")
    newkey = []
    for i in range(len(key)):
        newkey.append(dimensions[i] + "::" + key[i])
    return " ".join(newkey)


def extract_table(trialset : TrialSet.TrialSet, required_attributes, row_dimensions, column_dimensions):
    #required attributes are required
    trialset = TrialSet.TrialSet(trialset.get_matching_trials(required_attributes))
    
    first_level = flattend(enboxen(trialset, row_dimensions))
    for key, trialset in first_level.items():
        first_level[key] = flattend(enboxen(trialset, column_dimensions))

    table = {}
    for key, val in first_level.items():
       table[label_key(key, row_dimensions)] = val 

    return table


def summarize(table, sum_func):
    table = deepcopy(table)
    for row in table:
        for col in table[row]:
            table[row][col] = sum_func(table[row][col])
    return table


def ts_mean(trialset : TrialSet):
    percents = [t.attributes["percentage"] for t in trialset.trials if t.attributes["feasible"]]
    return np.mean(percents)

def ts_std(trialset : TrialSet):
    percents = [t.attributes["percentage"] for t in trialset.trials if t.attributes["feasible"]]
    return np.std(percents)

def ts_invalid(trialset : TrialSet):
    invalids = [1 for t in trialset.trials if not t.attributes["feasible"]]
    return len(invalids)