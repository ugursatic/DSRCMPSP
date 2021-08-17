####



#LOCAL OPTIMUM CODE
function LocalOptimum(STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks,STC)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #Feasible task processing orders based on project networks, resource usage will be considered later
    TaskCode = Task_Summary(STDur,PreTaskState) # task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    all_RPT =findall(a->a==-1, TaskCode) #returns CartesianIndex
    FeasibleOrders= [] #Feasible task processing orders

    for N in permutations(all_RPT) #task permutations #WARNING might fail in big problems.
        Eleminate = 0 #eleminate task processing order N
        for n in N #for each action
            if PredecessorTasks[n[1],n[3]] != 0 #if a PredecessorTasks exist n[3] != 1 #if not the fist task
                for parent in PredecessorTasks[n[1],n[3]] #for each predecissor
                    if TaskCode[n[1],n[2],parent] == -1 #if PredecessorTasks not completed
                        if findall(x->x==CartesianIndex(n[1],n[2],parent) , N) > findall(x->x==n , N)
                            #if PredecessorTasks comes after our task in the generated task processing order
                             Eleminate = 1 #eleminate task processing order N
                        end
                    end
                end
            end
        end
        if Eleminate != 1 # task processing order is not faulty
            push!(FeasibleOrders,N) #save feasible order.
        end
    end

    ###Found reward and completion time of schedules
    Schedile_scores = zeros(Float64,size(FeasibleOrders,1))
    Schedile_rewards = zeros(Float64,size(FeasibleOrders,1))
    for counter = 1:size(FeasibleOrders,1)
         Schedile_scores[counter],Schedile_rewards[counter] = task_processing_order_score(FeasibleOrders[counter],STC,
            STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks)
    end
    ###Found reward and completion time of schedules
    #####Find the best schedule, if has same reward check completion time, if have same competion time randomly select one

    MaxRewards = findall(a->a==maximum(Schedile_rewards),Schedile_rewards) #gives the order of best profit
    Best_action_no = 0
    #N=3
    Shortest_completion = Inf
    for N in MaxRewards #for more than one best scheduling order
        if Schedile_scores[N] < Shortest_completion
            Shortest_completion =  Schedile_scores[N]
            Best_action_no = N
        elseif Schedile_scores[N] == Shortest_completion
            Best_action_no =   N
        end
    end
    return FeasibleOrders[Best_action_no] #this is a task processing order. Best_action_no #
end #NOTE RETURN is not a action it is task order,
#####
#GA CODES
function GA(STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks,STC)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    Population = 100 #NOTE TEST VALUES
    Generationsize = 100  #NOTE TEST VALUES
    Elitsize = Int(Population * (1/10)) #NOTE TEST VALUES
    Mutation_rate = Int(Population * (1/10)) #NOTE TEST VALUES
    TaskCode = Task_Summary(STDur,PreTaskState) # task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    all_NPT =findall(a->a==-1, TaskCode) #All need processing tasks, returns CartesianIndex

    #Population
    POP = Array{Any}(undef,Population)
    Schedile_scores = zeros(Float64,Population)
    Schedile_rewards = zeros(Float64,Population)
    for ind = 1:Population
        TPO = [] #Task processing order
        NPT = copy(all_NPT)#I copied that so I dont need to generate NPT for each population.
        #NOTE This is serial processing scheme !SGS!!
        while NPT != [] #till all task are ordered
            #1 generated ready to process tasks
            RPT = [] #Ready to process tasks
            for n in NPT #For all remaining tasks (CartesianIndex)
                j,k,i=n[1],n[2],n[3]
                if PredecessorTasks[j,i] != 0 #if a PredecessorTasks exist
                    NetworkControl = true # all PredecessorTasks are complete or scheduled
                    for parent in PredecessorTasks[j,i] #for each predecissor (n1 projet type, n3 task no)
                        if TaskCode[j,k,parent] == -1 && findfirst(a->a==CartesianIndex(j,k,parent), TPO) == nothing#if PredecessorTasks is active or completed, or scheduled before
                            NetworkControl=false
                        end
                    end
                    if NetworkControl == true
                        push!(RPT,n)
                    end
                else
                    #first task
                    push!(RPT,n)
                end
            end
            #2 assing one of the ready to process task randomly.
            AT = rand(RPT) #Assinged Task
            push!(TPO,AT)#Assing one task randomly to task processing order
            #3 update ready to process task with assining ones
            splice!(NPT,findfirst(a->a==AT, NPT))#Task is removed from NPT
            #4 repeat 2 and 3 till no ready to process task is remain.
        end
        POP[ind] = TPO
        #Scores of each TSP
        Schedile_scores[ind],Schedile_rewards[ind] = task_processing_order_score(POP[ind],STC,
        STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks)
    end
    NewGeneration = Array{Any}(undef,Population)
    NewGeneration_scores = zeros(Float64,Population)
    NewGeneration_rewards = zeros(Float64,Population)
    for gen = 1 : Generationsize
        POP, Schedile_scores, Schedile_rewards = Shorting(POP, Schedile_scores, Schedile_rewards) # ranking the schedules
        for ind = 1:Elitsize
            NewGeneration[ind] =  copy(POP[ind])
            NewGeneration_scores[ind] = copy(Schedile_scores[ind])
            NewGeneration_rewards[ind] = copy(Schedile_rewards[ind])
        end #Elitist selection
        for ind = Elitsize+1:Population
            NewGeneration[ind] =  Crosover(POP,Mutation_rate,PredecessorTasks)
            NewGeneration_scores[ind],NewGeneration_rewards[ind] = task_processing_order_score(POP[ind],STC,
            STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks)
            #mutation is included inside of the crosover code
        end #rest of the population is created by crosover
    end
    POP, Schedile_scores, Schedile_rewards = Shorting(POP, Schedile_scores, Schedile_rewards) # ranking the schedules
    return POP[1] #this is a task processing order.
end #WARNING RETURN is not a action it is task order,
function Shorting(Priorty_space, Schedile_scores, Schedile_rewards)
    incr = div(length(Schedile_scores), 2)
    while incr > 0
        for i in incr+1:length(Schedile_scores)
            j = i
            tmp = Schedile_scores[i]
            tmp2 = Priorty_space[i]
            tmp3 = Schedile_rewards[i]
            while j > incr && Schedile_scores[j - incr] > tmp
                Schedile_scores[j] = Schedile_scores[j-incr]
                Schedile_rewards[j] = Schedile_rewards[j-incr]
                Priorty_space[j] = Priorty_space[j-incr]
                j -= incr
            end
            Schedile_scores[j] = tmp
            Schedile_rewards[j] = tmp3
            Priorty_space[j] = tmp2
        end
        if incr == 2
            incr = 1
        else
            incr = floor(Int, incr * 5.0 / 11)
        end
    end
    #maximize reward
    incr = div(length(Schedile_rewards), 2)
    while incr > 0
        for i in incr+1:length(Schedile_rewards)
            #i=4
            j = i
            tmp = Schedile_rewards[i]
            tmp2 = Priorty_space[i]
            tmp3 = Schedile_scores[i]
            while j > incr && Schedile_rewards[j - incr] < tmp
                Schedile_scores[j] = Schedile_scores[j-incr]
                Schedile_rewards[j] = Schedile_rewards[j-incr]
                Priorty_space[j] = Priorty_space[j-incr]
                j -= incr
            end
            Schedile_scores[j] = tmp3
            Schedile_rewards[j] = tmp
            Priorty_space[j] = tmp2
        end
        if incr == 2
            incr = 1
        else
            incr = floor(Int, incr * 5.0 / 11)
        end
    end
    return Priorty_space, Schedile_scores,Schedile_rewards
end#shorting the schedules using shellsort #working
function Crosover(Priorty_space,Mutation_rate,PredecessorTasks)
    Fno = rand(1:size(Priorty_space,1)) # number of father task # maybe size(,1) is better try tomorrow
    Mno = rand(1:size(Priorty_space,1)) # number of mother task
    Father = Priorty_space[Fno] #selecting candidates for Crosover
    Mother = Priorty_space[Mno]
    Crossoverpoint = rand(1:size(Mother,1))
    Kid = copy(Mother)
    TP = zeros(Int16,size(Mother,1))
    #find order of the remaining mother task in father
    for b = Crossoverpoint : size(Mother,1)
        TP[b] = findfirst(a->a==Mother[b], Father)
    end
    #Assing remaining mother task according to fathers priorty
    for b = Crossoverpoint : size(Mother,1)
        minimum(TP[TP.!=0])
        c = findfirst(a->a==minimum(TP[TP.!=0]),TP)#find father task with higest pri.
        Kid[b] = Mother[c] # assing remaining mother task according to fathers priorty
        TP[c] = 0 #remove assined task
    end
    #Kid task is ready.

    #MUTATION of Kid
    prob=rand(1:100)
    if prob <= Mutation_rate
        Kid = mutation(Kid,PredecessorTasks)
    end
    return Kid
end
function mutation(Kid,PredecessorTasks)
    #1)select a task for MUTATION
    Random = rand(1:size(Kid,1))
    #2)Move the task randomly between its bredecessor and itself
    #2.1) find tasks PredecessorTaskss
    b=1
    TP = zeros(Int16,size(Kid,1)) #order of PredecessorTasks tasks
    if PredecessorTasks[Kid[Random][1],Kid[Random][3]] != 0
        for parent in PredecessorTasks[Kid[Random][1],Kid[Random][3]] #for each predecissor]
            #global b #need in testing
            if findfirst(x->x==CartesianIndex(Kid[Random][1],Kid[Random][2],parent) , Kid) != nothing
                TP[b] = findfirst(x->x==CartesianIndex(Kid[Random][1],Kid[Random][2],parent) , Kid)
            end #if PredecessorTasks task is not on processing or processed.
            b=+1
        end
    end
    #2.1.1) find the PredecessorTasks who is comes last compare to other PredecessorTaskss.
    x = maximum(TP)#this is the location of predeccsor
    #2.1.2) select the position of this PredecessorTaskss
    #2.1.3)check if the PredecessorTasks is not allocated at Random-1
    HolderKid = copy(Kid)
    if x != Random-1
        #2.2)assing task randomly (lets say position = x+1).
        nl=rand(x+1:Random-1) #new location
        HolderKid[nl] = Kid[Random]
        #2.3)move the task between (x => x+1, x+1=>x+2,...x+n+>random)
        for n = nl:Random-1
            HolderKid[n+1] = Kid[n]
        end
    end
    return HolderKid
end #
#####

#####SHARED FUNCTION######
function task_processing_order_score(TaskOrder,STC,STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)

    #########This is added since GA and ORBA ignores the stochastic task durations.
    meandurations = zeros(Int8,TypeNo,maxtask)
    for P = 1:TypeNo #this adds the late completiosn
        for T =1:maxtask
            meandurations[P,T] = STDur[P,T] - STC #STC is late finish periods
        end
    end
    ################
    #Serial schedule-generation scheme
    t = 0 #this is iteration number to calculate who much iteration required to complete the schedule.
    n = 1 #a task in task order
    taskorder_profit = 0 # profit of task order
    while n <= size(TaskOrder,1) #for each task in task order
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #Predicessor and resource availabity check.
        j,k,i = TaskOrder[n][1],TaskOrder[n][2],TaskOrder[n][3]
        if PredecessorTasks[j,i] == 0 || sum(PreTaskState[j,k,PredecessorTasks[j,i]].== 0) == size(PredecessorTasks[j,i],1)
            if sum(ARU[:,TaskOrder[n]] .<= FreeResource) == size(FreeResource,1) #If there are enough resource
                FreeResource = FreeResource .- ARU[:,TaskOrder[n]] #reduce used resources
                Action[TaskOrder[n]] = 1 #make it an action
                control, e = true, 1 #first process as much as task if we have resources, second keeps the number.
                while control == true && n+e <= size(TaskOrder,1) #second condition helps the array size boundry
                    if sum(ARU[:,TaskOrder[n+e]] .<= FreeResource) == size(FreeResource,1)  #If there are enough resource
                        je,ke,ie = TaskOrder[n+e][1],TaskOrder[n+e][2],TaskOrder[n+e][3]
                        if PredecessorTasks[je,ie] == 0 || sum(PreTaskState[je,ke,PredecessorTasks[je,ie]].== 0) == size(PredecessorTasks[je,ie],1)
                            FreeResource = FreeResource .- ARU[:,TaskOrder[n+e]] #reduce used resources
                            Action[TaskOrder[n+e]] = 1 #make it an action
                            e +=1 #try next unscheduled task
                        else
                            control = false #predicessors are not completed
                        end
                    else
                        control = false #not enough resources.
                    end
                end
                n += e #next un scheduled tasks
            end
        end
        #State iteration,
        DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,GB,GB =
        state_iteration(STDur,ARU,reward,Tardiness,DueDates,DueDateState,
        PreTaskState,FreeResource,Action,0.0,0,PredecessorTasks)
        t+=1 #next iteration
        taskorder_profit += Profit #Do I need to use discounting ??
    end
    #######
    #Continue till projects are COMPLETED
    while sum(PreTaskState) != 0
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #State iteration,
        DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,GB,GB =
        state_iteration(STDur,ARU,reward,Tardiness,DueDates,DueDateState,
        PreTaskState,FreeResource,Action,0.0,0,PredecessorTasks)
        t+=1 #next iteration
        taskorder_profit += Profit #Do I need to use discounting ??
    end
    return t,taskorder_profit
end
function TPO_to_action(TaskOrder,ARU,PreTaskState,FreeResource,PredecessorTasks)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #Serial schedule-generation scheme
    n = 1 #a task in task order
    taskorder_profit = 0 # profit of task order
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #Predicessor and resource availabity check.
        if PredecessorTasks[TaskOrder[n][1],TaskOrder[n][3]] == 0 || sum(PreTaskState[TaskOrder[n][1],TaskOrder[n][2],PredecessorTasks[TaskOrder[n][1],TaskOrder[n][3]]]) == 0
            #no predicessor exist or all predecissors are completed
            if sum(ARU[:,TaskOrder[n]] .<= FreeResource) == size(FreeResource,1) #If there are enough resource
                FreeResource = FreeResource .- ARU[:,TaskOrder[n]] #reduce used resources
                Action[TaskOrder[n]] = 1 #make it an action
                control, e = true, 1 #first process as much as task if we have resources, second keeps the number.
                while control == true && n+e <= size(TaskOrder,1) #second condition helps the array size boundry
                    #println("task order size = ",size(TaskOrder,1))
                    if sum(ARU[:,TaskOrder[n+e]] .<= FreeResource) == size(FreeResource,1)  #If there are enough resource
                        if PredecessorTasks[TaskOrder[n+e][1],TaskOrder[n+e][3]] == 0 || sum(PreTaskState[TaskOrder[n+e][1],TaskOrder[n+e][2],PredecessorTasks[TaskOrder[n+e][1],TaskOrder[n+e][3]]]) == 0
                            #no predicessor exist or all predecissors are completed
                            FreeResource = FreeResource .- ARU[:,TaskOrder[n+e]] #reduce used resources
                            Action[TaskOrder[n+e]] = 1 #make it an action
                            e +=1 #try next unscheduled task
                        else
                            control = false #predicessors are not completed
                        end
                    else
                        control = false #not enough resources.
                    end
                end
                n += e #next un scheduled tasks
            end
        end
        ###########
        #I used n-1 TaskOrder
        #Generate remaining task order.
        tasks = size(TaskOrder,1)
        RemainingTaskOrder = []
        for x = n:tasks # for remaining tasks
            push!(RemainingTaskOrder,TaskOrder[x]) #save remaining tasks
        end
        ###############
    return Action, RemainingTaskOrder
    #######
end#it returns an action and remaining processing plan.
function TPO_to_action2(TaskOrder,ARU,PreTaskState,FreeResource,PredecessorTasks)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #Serial schedule-generation scheme
    taskorder_profit = 0 # profit of task order
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        RemainingTaskOrder = []
        #Predicessor and resource availabity check.
        for n =1 : size(TaskOrder,1)
            if PredecessorTasks[TaskOrder[n][1],TaskOrder[n][3]] == 0 || sum(PreTaskState[TaskOrder[n][1],TaskOrder[n][2],PredecessorTasks[TaskOrder[n][1],TaskOrder[n][3]]]) == 0
                #no predicessor exist or all predecissors are completed
                if sum(ARU[:,TaskOrder[n]] .<= FreeResource) == size(FreeResource,1) #If there are enough resource
                    FreeResource = FreeResource .- ARU[:,TaskOrder[n]] #reduce used resources
                    Action[TaskOrder[n]] = 1 #make it an action
                else
                    push!(RemainingTaskOrder,TaskOrder[n]) #save remaining tasks
                end
            else
                push!(RemainingTaskOrder,TaskOrder[n]) #save remaining tasks
            end
        end
        ###########
    return Action, RemainingTaskOrder
    #######
end#it returns an non-idle action and remaining processing plan.
##########################
