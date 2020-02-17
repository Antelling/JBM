#this script will generate a complete set of narrow survey results
#it takes 3*(15 + 15 + 2 + 2) = 102 hours = 4.25 days to run

#julia isn't actually in my path
#alias julia="/home/anthony/software/julia-1.3.0/bin/julia --color=yes"

# how long does one algorithm with a 10s time limit take to run?
# 90 problems * 9 datasets * 10 seconds / 60sec/min / 60min/hr = 2.25 hours
# LBO and GANM have two algs to test, so 4.5 hours
# Rao1, Rao2, jaya, TBO, and TLBO each have 10 algs, so 22.5 hours
# CAC has 6 algs, so 13.5 hours

# the main.jl program takes the following arguments:
#	algorithms experiment_name pop_size time_limit start_ds end_ds

#we need to test:
# rao1 rao2

#we are supposed to test for 60 seconds, so 10 alg results will take 135 hours
#thats more than five and a half days
#but we have three cores

julia main.jl rao1 rao1_results 30 60 1 3 &
julia main.jl rao1 rao1_results 30 60 4 6 &
julia main.jl rao1 rao1_results 30 60 7 9 &
