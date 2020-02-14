#this script will generate a complete set of narrow survey results
#it takes 3*(15 + 15 + 2 + 2) = 102 hours = 4.25 days to run

#julia isn't actually in my path
#alias julia="/home/anthony/software/julia-1.3.0/bin/julia --color=yes"

# how long does one algorithm with a 10s time limit take to run?
# 90 problems * 9 datasets * 10 seconds / 60sec/min / 60min/hr = 2.25 hours
# LBO and GANM have two algs to test, so 4.5 hours
# everything else has 6 algs to test, so 13.5 hours

# the main.jl program takes the following arguments:
#	algorithms experiment_name pop_size time_limit start_ds end_ds

#we need to test:
# jaya rao1 rao2  CAC TLBO TBO | LBO GANM

#let's start with the 10 second results
#we only take up three processors, so if the quad core system needs
#to do something it won't affect the results
julia main.jl jaya jaya_narrow_survey_p30 30 10 1 9 &
julia main.jl rao1 rao1_narrow_survey_p30 30 10 1 9 &
julia main.jl rao2 rao2_narrow_survey_p30 30 10 1 9 &
sleep 15h

julia main.jl CAC   CAC_narrow_survey_p30 30 10 1 9 &
julia main.jl TBO   TBO_narrow_survey_p30 30 10 1 9 &
julia main.jl TLBO TLBO_narrow_survey_p30 30 10 1 9 &
sleep 15h

#now we need to test GANM and LBO
#we'll split up the datasets, so I can keep all three cores
#busy all the time
julia main.jl LBO LBO_narrow_survey_p30 30 10 1 3 &
julia main.jl LBO LBO_narrow_survey_p30 30 10 4 6 &
julia main.jl LBO LBO_narrow_survey_p30 30 10 7 9 &
sleep 2h #each process should take 1.5 hours to finish

julia main.jl GANM GANM_narrow_survey_p30 30 10 1 3 &
julia main.jl GANM GANM_narrow_survey_p30 30 10 4 6 &
julia main.jl GANM GANM_narrow_survey_p30 30 10 7 9 &
sleep 2h

#now we do the exact same thing, just with every time
#limit doubled

julia main.jl jaya jaya_narrow_survey_p30 30 20 1 9 &
julia main.jl rao1 rao1_narrow_survey_p30 30 20 1 9 &
julia main.jl rao2 rao2_narrow_survey_p30 30 20 1 9 &
sleep 30h

julia main.jl CAC   CAC_narrow_survey_p30 30 20 1 9 &
julia main.jl TBO   TBO_narrow_survey_p30 30 20 1 9 &
julia main.jl TLBO TLBO_narrow_survey_p30 30 20 1 9 &
sleep 30h

julia main.jl LBO LBO_narrow_survey_p30 30 20 1 3 &
julia main.jl LBO LBO_narrow_survey_p30 30 20 4 6 &
julia main.jl LBO LBO_narrow_survey_p30 30 20 7 9 &
sleep 4h

julia main.jl GANM GANM_narrow_survey_p30 30 20 1 3 &
julia main.jl GANM GANM_narrow_survey_p30 30 20 4 6 &
julia main.jl GANM GANM_narrow_survey_p30 30 20 7 9 &
sleep 4h
