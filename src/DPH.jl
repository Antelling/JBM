"""Dominance Principle Heuristic for the MDMKP
Dominance Principle was originally proposed for Multi Demand Knapsack in
    "A new polynomial time algorithm for 0–1 multiple knapsack problem based
        on dominant principles" by Balachandar and Kannan
        Referred to as paper 1
Dominance Principle was adapted to MDMKP in
    "A new heuristic approach for Knapsack/Covering Problem", also by
        Balachandar and Kannan
        Referred to as paper 2
"""

function DPH(problem::Problem)
    #steps taken from fig 1 in paper 1

    n = length(problem.objective) #number of dimensions, width of coeff matrix, length of bitlist
    m = length(problem.upper_bounds) #number of dimension constraints
    M = 2^62 #"M (a large value)"


    #step 1
    solution::BitList = falses(n)

    while(true)
        #step 2
        #in paper 1, form matrix A of the coefficient matrix of the dimension constraints
        #in paper 2, form matrix a of the coefficient matrix of the demand constraints
        #paper 1 is easier to read so let's do that first
        A = [coeffs for (coeffs, bound) in problem.upper_bounds]
        A = permutedims(reshape(hcat(A...), (length(A[1]), length(A))))
        B = [bound for (coeffs, bound) in problem.upper_bounds]

        #construct intercept matrix
        #next we "Form the matrix D[i,j] for i=1,2,3...m and j =1,2,3,...n",
        #where m is the amount of constraints and n is number of dimensions
        D = Array{Float64,2}(undef,m,n) #d is an m by n matrix
        for i in 1:m
            for j in 1:n
                D[i,j] = A[i,j] > 0 ?
                    B[i]/A[i,j] :
                    M
            end
        end



        for column in 1:n
            if min(D[:,column]...) < 1
                #step 3: I am supposed to set all values of the matrix to a large value,
                #to prevent solution[i] from coming on
                #I'm just going to skip over it though
            else
                row_index_of_max = argmin(D[:, column]) #step 4: encircle the smallest intercept in each column
                #step 5: record which rows contain more than one min
                #we never do anything with that record, so I'm not going to

                #step 6: multiply min with corresponding objective function value
                result = D[row_index_of_max, column] * problem.objective[column]
                # Step – 7: If the product is maximum in k th column, then set x k = 1 .
                if result > max(D[:,column]) #should this be > or >=? Who knows???
                    solution[column] = 1

                    #step 8: Update the constraint matrix as follows
                    # b[i] = b[i] - a[i,k], i = 1 to m
                    # a[i,k] = 0 for i = 1 to m
                    #I don't know if this is supposed to be included in the above if
                    #statement ¯\_(ツ)_/¯
                    #also those variables don't make sense how they were used???????
                    #I think I'm meant to do this:
                    for row in 1:m
                        B[row] -= A[row, column]
                        A[row, column] = 0
                    end
                end

            end
        end
        
        if(sum(A) == 0)
            break
        end
    end
end
