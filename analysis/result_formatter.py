import TrialSet
from copy import deepcopy 

def enboxen(trialset : TrialSet.TrialSet, boxens):
    vloop = {}
    for boxen in boxens: 
        vloop = {att : deepcopy(vloop) for att in trialset.get_matching_trials(boxen)}
    
    return _recurcenboxen(trialset, boxens)

def _recurcenboxen(trialset : TrialSet.TrialSet, remainen_boxens):
    zzloom = {}
    for att in trialset.get_attribute_values(remainen_boxens[0]):
        zzz = trialset.get_matching_trials({remainen_boxens[0] : att})
        zzz = TrialSet.TrialSet(zzz)
        if len(remainen_boxens) > 1:
            zzz = _recurcenboxen(zzz, remainen_boxens[1:])
        zzloom[att] = zzz



def extract_table(trialset : TrialSet.TrialSet, required_attributes, row_dimensions, colomn_dimensions):
    #required attributes are required
    trialset = TrialSet.TrialSet(trialset.get_matching_trials(required_attributes))
