####



#LOCAL OPTIMUM CODE
function LocalOptimum(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor,STC)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #println("begin")
    #Feasible task processing orders based on project networks, resource usage will be considered later
    TaskCode = Task_Summary(taskDuration,PreTaskState) # task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    #println("then")
    all_RPT =findall(a->a==-1, TaskCode) #returns CartesianIndex
    FeasibleOrders= [] #Feasible task processing orders
    #println("before permutation")
    #println(size(all_RPT,1))
    say = 0
    for N in permutations(all_RPT) #task permutations #WARNING might fail in big problems.
        #say+=1
        #println(say)
        Eleminate = 0 #eleminate task processing order N
        for n in N #for each action
            if predecessor[n[1],n[3]] != 0 #if a predecessor exist n[3] != 1 #if not the fist task
                for parent in predecessor[n[1],n[3]] #for each predecissor
                    if TaskCode[n[1],n[2],parent] == -1 #if predecessor not completed
                        if findall(x->x==CartesianIndex(n[1],n[2],parent) , N) > findall(x->x==n , N)
                            #if predecessor comes after our task in the generated task processing order
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
    ###I found all feasible schedules.
    #println("after permutation")
    ###Found reward and completion time of schedules
    Schedile_scores = zeros(Float64,size(FeasibleOrders,1))
    Schedile_rewards = zeros(Float64,size(FeasibleOrders,1))
    for counter = 1:size(FeasibleOrders,1)
         Schedile_scores[counter],Schedile_rewards[counter] = task_processing_order_score(FeasibleOrders[counter],STC,
            taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor)
    end
    ###Found reward and completion time of schedules
    #println("after score")
    #####Find the best schedule, if has same reward check completion time, if have same competion time randomly select one

    #Same as GA###########
    #=FeasibleOrders, Schedile_scores, Schedile_rewards = Shorting(FeasibleOrders, Schedile_scores, Schedile_rewards)
    Best_action_no = FeasibleOrders[1]=#
    #############
    #ORBA SPECIAL~~~~~~~~~~~~~~~

    MaxRewards = findall(a->a==maximum(Schedile_rewards),Schedile_rewards) #gives the order of best profit
    Best_action_no = 0
    #N=3
    Shortest_completion = Inf
    for N in MaxRewards #for more than one best scheduling order
        if Schedile_scores[N] < Shortest_completion
            Shortest_completion =  Schedile_scores[N]
            Best_action_no = N
        elseif Schedile_scores[N] == Shortest_completion
            #if rand(1:2) == 2 #WARNING SHALL I USE RANDOM ??
                Best_action_no =   N
                #println(Best_action_no)
            #end
        end
    end

    #println("best action")
    return FeasibleOrders[Best_action_no] #this is a task processing order. Best_action_no #
    #NOTE
end #WARNING RETURN is not a action it is task order, convert properly.
#####
#GA CODES
function GA(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor,STC)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #println("inside the GA")
    Population = 100 #NOTE TEST VALUES
    Generationsize = 100  #NOTE TEST VALUES
    Elitsize = Int(Population * (1/10)) #NOTE TEST VALUES
    Mutation_rate = Int(Population * (1/10)) #NOTE TEST VALUES
    #Feasible task processing orders based on project networks, resource usage will be considered later
    TaskCode = Task_Summary(taskDuration,PreTaskState) # task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    all_NPT =findall(a->a==-1, TaskCode) #All need processing tasks, returns CartesianIndex
    ####NEED GA CODE HERE @~~~

    #!NOTE CONTROL
    #    println(TaskCode)
    #    println(PreTaskState)
    #Population
    POP = Array{Any}(undef,Population)
    Schedile_scores = zeros(Float64,Population)
    Schedile_rewards = zeros(Float64,Population)
    #println("generate population !!!!")
    for ind = 1:Population
        #println("population =",ind)
        TPO = [] #Task processing order
        NPT = copy(all_NPT)#I copied that so I dont need to generate NPT for each population.
        #NOTE This is serial processing scheme !SGS!!
        while NPT != [] #till all task are ordered
            #println(size(NPT,1))
            #1 generated ready to process tasks
            RPT = [] #Ready to process tasks
            for n in NPT #For all remaining tasks (CartesianIndex)
                j,k,i=n[1],n[2],n[3]
                if predecessor[j,i] != 0 #if a predecessor exist
                    NetworkControl = true # all predecessor are complete or scheduled
                    for parent in predecessor[j,i] #for each predecissor (n1 projet type, n3 task no)
                        if TaskCode[j,k,parent] == -1 && findfirst(a->a==CartesianIndex(j,k,parent), TPO) == nothing#if predecessor is active or completed, or scheduled before
                            NetworkControl=false
                        end
                    end
                    if NetworkControl == true
                        push!(RPT,n)
                    end
                else
                    #first task
                    #Save to ready to process tasks
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
        #println("processing order", size(TPO,1))
        POP[ind] = TPO
        #println(POP[ind])
        #I have a random Task processing order.
        #Scores of each TSP
        #task order is faulty
        Schedile_scores[ind],Schedile_rewards[ind] = task_processing_order_score(POP[ind],STC,
        taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor)
        #Now I need population amount TPS with scores.
        #println("task score founded")
    end
    #println("First population generated !!!!")
    NewGeneration = Array{Any}(undef,Population)
    NewGeneration_scores = zeros(Float64,Population)
    NewGeneration_rewards = zeros(Float64,Population)
    for gen = 1 : Generationsize
        #println("first generation")
        POP, Schedile_scores, Schedile_rewards = Shorting(POP, Schedile_scores, Schedile_rewards) # ranking the schedules
        #println("after shorting")
        for ind = 1:Elitsize
            NewGeneration[ind] =  copy(POP[ind])
            NewGeneration_scores[ind] = copy(Schedile_scores[ind])
            NewGeneration_rewards[ind] = copy(Schedile_rewards[ind])
        end #Elitist selection
        for ind = Elitsize+1:Population
            NewGeneration[ind] =  Crosover(POP,Mutation_rate,predecessor)
            NewGeneration_scores[ind],NewGeneration_rewards[ind] = task_processing_order_score(POP[ind],STC,
            taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor)
            #mutation is included inside of the crosover code
        end #rest of the population is created by crosover
        #println("mutation and cross over ended")
    end
    #println("End of generation")
    POP, Schedile_scores, Schedile_rewards = Shorting(POP, Schedile_scores, Schedile_rewards) # ranking the schedules
    #println("End of shorting")
    return POP[1] #this is a task processing order.
end #WARNING RETURN is not a action it is task order, convert properly.
function Shorting(Priorty_space, Schedile_scores, Schedile_rewards)
    #shellsort shorting from rosettacode.org
    #Schedile_scores = [17 , 15 , 10 ,15 , 12 , 12] #test values
    #Priorty_space = ["ali", "veli", 49, 50,[1,2,3],[]] #test values
    #Schedile_rewards = [17 , 15 , 18 ,21 , 21 , 20] #test values
    #minimize time
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
function Crosover(Priorty_space,Mutation_rate,predecessor)
    #println(size(Priorty_space,1))
    Fno = rand(1:size(Priorty_space,1)) # number of father task # maybe size(,1) is better try tomorrow
    Mno = rand(1:size(Priorty_space,1)) # number of mother task
    Father = Priorty_space[Fno] #selecting candidates for Crosover
    Mother = Priorty_space[Mno]
    #println(Mother)
    #println(Father)

    #veli > ali 49 > 50  atti > batti and kac  #Test purpose
    #Father = ["ali","veli",49,50,"atti","batti","kac"] #Test purpose
    #Mother = [49,"ali",50,"atti","kac","veli","batti"] #Test purpose
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
        Kid = mutation(Kid,predecessor)
    end
    #println(Kid)
    return Kid
end
function mutation(Kid,predecessor)
    #= !NOTE REMOVE THESE TEST WARIABLES LATER
    Kid =findall(a->a!=-1, ss)
    Kid = ["ali","veli",49,50] #Test purpose
    ss = ["ali" "veli";49 50]
    predecessor = zeros(Int8,2,2)
    for i=1:2
        predecessor[i,2:2] = 1:2-1 #WARNING only for old problems makes a sequential project network.
    end
    Kid[Random][2] need to be Kid[Random][3]
    Kid[Random][1] project no
    predecessor[Kid[Random][1],Kid[Random][2]] #predecessor tasks #WARNING 2 will be 3 in real code
    CartesianIndex(Kid[Random][1],1)
    =#
    #1)select a task for MUTATION
    Random = rand(1:size(Kid,1))
    #2)Move the task randomly between its bredecessor and itself
    #2.1) find tasks predecessors
    b=1
    TP = zeros(Int16,size(Kid,1)) #order of predecessor tasks
    if predecessor[Kid[Random][1],Kid[Random][3]] != 0
        for parent in predecessor[Kid[Random][1],Kid[Random][3]] #for each predecissor]
            #global b #need in testing
            if findfirst(x->x==CartesianIndex(Kid[Random][1],Kid[Random][2],parent) , Kid) != nothing
                TP[b] = findfirst(x->x==CartesianIndex(Kid[Random][1],Kid[Random][2],parent) , Kid)
            end #if predecessor task is not on processing or processed.
            b=+1
        end
    end
    #2.1.1) find the predecessor who is comes last compare to other predecessors.
    x = maximum(TP)#this is the location of predeccsor
    #2.1.2) select the position of this predecessors
    #2.1.3)check if the predecessor is not allocated at Random-1
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
function task_processing_order_score(TaskOrder,STC,taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    ###IDLE MODE #####
    #########This is added since GA and LO ignores the stochastic task durations.
    meandurations = zeros(Int8,TypeNo,maxtask)
    for P = 1:TypeNo #this adds the late completiosn
        for T =1:maxtask
            meandurations[P,T] = taskDuration[P,T] - STC #STC is late finish periods
        end
    end
    ################
    #Serial schedule-generation scheme
    t = 0 #this is iteration number to calculate who much iteration required to complete the schedule.
    n = 1 #a task in task order
    taskorder_profit = 0 # profit of task order
        #println(size(TaskOrder,1))
        testi = []
    while n <= size(TaskOrder,1) #for each task in task order
        #if testi == PreTaskState
        #    println("task order size = ",size(TaskOrder,1)," n = ",n)
        #    println(PreTaskState[:,1,:])
        #    println("FreeResource = ", FreeResource)
        #end
        testi = copy(PreTaskState)
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #Predicessor and resource availabity check.
        j,k,i = TaskOrder[n][1],TaskOrder[n][2],TaskOrder[n][3]
        if predecessor[j,i] == 0 || sum(PreTaskState[j,k,predecessor[j,i]].== 0) == size(predecessor[j,i],1)
            #println("no predicessor exist or all predecissors are completed")
            if sum(ARU[:,TaskOrder[n]] .<= FreeResource) == size(FreeResource,1) #If there are enough resource
                #println("Resources are available")
                FreeResource = FreeResource .- ARU[:,TaskOrder[n]] #reduce used resources
                Action[TaskOrder[n]] = 1 #make it an action
                control, e = true, 1 #first process as much as task if we have resources, second keeps the number.
                #println("first task is assined")
                while control == true && n+e <= size(TaskOrder,1) #second condition helps the array size boundry
                    if sum(ARU[:,TaskOrder[n+e]] .<= FreeResource) == size(FreeResource,1)  #If there are enough resource
                        je,ke,ie = TaskOrder[n+e][1],TaskOrder[n+e][2],TaskOrder[n+e][3]
                        if predecessor[je,ie] == 0 || sum(PreTaskState[je,ke,predecessor[je,ie]].== 0) == size(predecessor[je,ie],1)
                            #println("no predicessor exist or all predecissors are completed for next task")
                            FreeResource = FreeResource .- ARU[:,TaskOrder[n+e]] #reduce used resources
                            Action[TaskOrder[n+e]] = 1 #make it an action
                            e +=1 #try next unscheduled task
                            #println("next task is assined")
                        else
                            control = false #predicessors are not completed
                        end
                    else
                        control = false #not enough resources.
                    end
                end
                #println("inside while is completed")
                n += e #next un scheduled tasks
            end
        end
        #State iteration,
        #println(PreTaskState[:,1,:])
        #println(FreeResource)
        DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,GB,GB =
        state_iteration2(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,
        PreTaskState,FreeResource,Action,0.0,0,predecessor)
        t+=1 #next iteration
        taskorder_profit += Profit #Do I need to use discounting ??
    end
    #######
    #println("first while completed")
    #Continue till projects are COMPLETED
    while sum(PreTaskState) != 0
        #println("remaining tasks = ",size(PreTaskState[PreTaskState.!=0],1))
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #State iteration,
        DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,GB,GB =
        state_iteration2(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,
        PreTaskState,FreeResource,Action,0.0,0,predecessor)
        t+=1 #next iteration
        taskorder_profit += Profit #Do I need to use discounting ??
    end
    #println("second while completed")
    #I can combine two while but I dont see any advantage or disadvantage.
    return t,taskorder_profit
end #controlled working,
function task_processing_order_score2(TaskOrder,STC,taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    ###NON IDLE MODE #####

    ################
    #Serial schedule-generation scheme
    t = 0 #this is iteration number to calculate who much iteration required to complete the schedule.
    taskorder_profit = 0 # profit of task order
    RemainingTaskOrder = []
    while sum(PreTaskState) != 0
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #Predicessor and resource availabity check.
        for n =1 : size(TaskOrder,1)
            j,k,i = TaskOrder[n][1],TaskOrder[n][2],TaskOrder[n][3]
            if predecessor[j,i] == 0 || sum(PreTaskState[j,k,predecessor[j,i]].== 0) == size(predecessor[j,i],1)
                #println("no predicessor exist or all predecissors are completed")
                if sum(ARU[:,TaskOrder[n]] .<= FreeResource) == size(FreeResource,1) #If there are enough resource
                    #println("Resources are available")
                    FreeResource = FreeResource .- ARU[:,TaskOrder[n]] #reduce used resources
                    Action[TaskOrder[n]] = 1 #make it an action
                else
                    push!(RemainingTaskOrder,TaskOrder[n]) #save remaining tasks
                end
            else
                push!(RemainingTaskOrder,TaskOrder[n]) #save remaining tasks
            end
        end
        TaskOrder=copy(RemainingTaskOrder)
        #State iteration,
        #println(PreTaskState[:,1,:])
        #println(FreeResource)
        DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,GB,GB =
        state_iteration2(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,
        PreTaskState,FreeResource,Action,0.0,0,predecessor)
        t+=1 #next iteration
        taskorder_profit += Profit #Do I need to use discounting ??
    end
    return t,taskorder_profit
end #controlled working,
function TPO_to_action(TaskOrder,ARU,PreTaskState,FreeResource,predecessor)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #Serial schedule-generation scheme
    n = 1 #a task in task order
    taskorder_profit = 0 # profit of task order
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        #Predicessor and resource availabity check.
        if predecessor[TaskOrder[n][1],TaskOrder[n][3]] == 0 || sum(PreTaskState[TaskOrder[n][1],TaskOrder[n][2],predecessor[TaskOrder[n][1],TaskOrder[n][3]]]) == 0
            #no predicessor exist or all predecissors are completed
            if sum(ARU[:,TaskOrder[n]] .<= FreeResource) == size(FreeResource,1) #If there are enough resource
                FreeResource = FreeResource .- ARU[:,TaskOrder[n]] #reduce used resources
                Action[TaskOrder[n]] = 1 #make it an action
                control, e = true, 1 #first process as much as task if we have resources, second keeps the number.
                while control == true && n+e <= size(TaskOrder,1) #second condition helps the array size boundry
                    #println("task order size = ",size(TaskOrder,1))
                    if sum(ARU[:,TaskOrder[n+e]] .<= FreeResource) == size(FreeResource,1)  #If there are enough resource
                        if predecessor[TaskOrder[n+e][1],TaskOrder[n+e][3]] == 0 || sum(PreTaskState[TaskOrder[n+e][1],TaskOrder[n+e][2],predecessor[TaskOrder[n+e][1],TaskOrder[n+e][3]]]) == 0
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
function TPO_to_action2(TaskOrder,ARU,PreTaskState,FreeResource,predecessor)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    #Parallel schedule-generation scheme
    taskorder_profit = 0 # profit of task order
        Action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) ##Feasible actions
        RemainingTaskOrder = []
        #Predicessor and resource availabity check.
        for n =1 : size(TaskOrder,1)
            if predecessor[TaskOrder[n][1],TaskOrder[n][3]] == 0 || sum(PreTaskState[TaskOrder[n][1],TaskOrder[n][2],predecessor[TaskOrder[n][1],TaskOrder[n][3]]]) == 0
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
end#it returns an action and remaining processing plan.
##########################

#No random completion or early completion is accepted here
#also no new arrival
function state_iteration2(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,
    PreTaskState,FreeResource,best_action,arrivalprobs,STC,predecessor)
    ###############Post Decision state #With stochactic task duration
    # PostState, PostTaskState = Pre_to_Post_state(PreState,PreTaskState,best_action)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    DS = copy(DueDateState)
    PostTaskState = copy(PreTaskState)
    PostState = zeros(Int8,TypeNo)
    FR = copy(FreeResource)
    Completion= zeros(Int16,TypeNo)
    Late_comp= zeros(Int16,TypeNo)
    Profit = 0
    for j = 1:TypeNo
        for i = 1:MaxProjectNO
            for x = 1:maxtask
                if (PreTaskState[j,i,x] >0 && PreTaskState[j,i,x] < taskDuration[j,x]) ||  (PreTaskState[j,i,x] == taskDuration[j,x] && best_action[j,i,x] == 1) # On going or new task processing
                    if PreTaskState[j,i,x] <= 1+STC*2 #task is ready to be completed and its ongoing
                        #Random_prob = rand() #for task completion #Here it generate the same completion probs for all actions.
                        #Random_prob = rand(randTaskComp[j,x]) #for task completion #Here it generate the same completion probs for all actions.
                        #No random completion or early completion is accepted here
                        if 1 <= disp(PreTaskState[j,i,x],taskDuration[j,x]) #completion Probabiltyblity
                            FR = FR  .+ ARU[:,j,i,x] #relise the used resources #NOTE suitable for multi resources
                            PostTaskState[j,i,x] = 0 #Early normal or late completion with probablity
                        else #No early completion option
                            if PostTaskState[j,i,x] == 1
                                println("WARNING Task completion probability error 1")
                                println("Pre = ",PreTaskState[j,i,x])
                                println("J and i = ",j,"-",x)
                                println("task duration = ",taskDuration[j,x] )
                                println("Required = ",disp(PreTaskState[j,i,x],taskDuration[j,x]))
                                println("random = ",Random_prob )
                            end
                            PostTaskState[j,i,x] -= 1 #reduce remaining duration
                        end
                    else #No early completion option
                        if PostTaskState[j,i,x] == 1
                            println("WARNING Task completion probability error 2")
                            println("Pre = ",PreTaskState[j,i,x])
                            println("J and i = ",j,"-",x)
                            println("task duration = ",taskDuration[j,x] )
                        end
                        PostTaskState[j,i,x] -= 1 #reduce remaining duration
                    end
                end #task completion
            end
            #################################
            if sum(PostTaskState[j,i,:]) != 0 #if project not completed
                PostState[j] +=1 #number of project after iteration, before new arrival
            end

            if (all(PostTaskState[j,i,:].==0) && any(PreTaskState[j,i,:].!=0)) #||
                #(taskDuration[j,maxtask] ==0 &&  all(PostTaskState[j,i,predecessor[j,maxtask]].==0&&
                #any(PreTaskState[j,i,predecessor[j,maxtask]].!=0)) )
                #NEWLY COMPLETED PROJECTS
                #println("A PROJECT COMPLETION")
                #PostState[j] -= 1 # reduce the completed project#not needed added above
                ####### REWARD calculation
                if DS[j,i] != 0 #NO LATE PROJECT
                    DS[j,i] = 0 # make the due date 0
                    Profit += reward[j] #Earning full reward
                    Completion[j] += 1
                else # LATE PROJECT
                    Profit += reward[j]-Tardiness[j] #Earning punished reward
                    Late_comp[j] += 1
                    Completion[j] += 1
                end
                #######################################
            else #ON GOING or WAITING PROJECTS
                if DS[j,i] != 0 #Project is not late already,
                    DS[j,i] -=1
                end
            end
            ######################
        end
    end

        NewArrivals = zeros(Int8,TypeNo) #WARNING this is for old code.
        #no new arrival
    ######

    ##### new pre-decision state after arrivals
        PS = copy(PostTaskState) #pretaskstate
        for j=1:TypeNo
            PostState[j] += NewArrivals[j]
            if NewArrivals[j] > 0
                for i = 1:NewArrivals[j]
                    PS[j,i,:] += taskDuration[j,:] #pretaskstate
                    DS[j,i] += DueDates[j]
                end
            end
        end
    ######
    PreS = copy(PostState) #PreState
    return DS,PS,FR,Profit,NewArrivals,Completion,Late_comp
end#adabted for MPSPLIB end task dummy
