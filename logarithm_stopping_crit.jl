using LsqFit

@. model(x, parameters) = log(x*parameters[1] + parameters[2])*parameters[3] + parameters[4]


xdata = [1, 2, 3, 4, 5, 6, 7, 8, 9]
ydata = [1, 20, 30, 35, 37, 40, 42, 43, 43]
