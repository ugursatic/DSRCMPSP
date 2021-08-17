    using Combinatorics #for conbinations chosing alternative actions.
    using Statistics #For mean function
    using LsqFit # For curve fit
    using DataFrames, CSV #required for printing to excel
    using LinearAlgebra
    using Random #For using seeds

    include("MPSPLIB_Reader.jl") #MPSPLIB problem reader.
    #include("Problem_Reader.jl") #Other Problem reader
    include("ADP.jl") #Approximate dynamic program codes
    #include("RBA.jl") #Rule based algorithm codes
    #include("ORBAandGA.jl") #Optimal reactive baseline algorithm and Genetic algorithm codes
    ##################################################################################

    #FUNCTIONS ############################################################
    function repeater(MaxProjectNO,DiscountFactor,Simulation,SimDura)
        A = [0.01,0.1,0.2,0.3,0.4,0.5,0.7,0.8,0.9] #Arrival rates
        STC = 1 #Stochastic task completion options. 1=one early and one late completion, 2=two early and two late completion options. ETC.

        #WARNING USE ONLY ONE FROM BELOW #################################################
        ###USE Below for MPSPLIB problems :
        PredecessorTasks, STDur, AMPTD, RU, ARU, FreeResource, reward, DueDates, Tardiness, arrival = MPSPLIB(STC)

        ###USE Below for Other big problems :
        #PredecessorTasks, STDur, AMPTD, RU, ARU, FreeResource, reward, DueDates, Tardiness, arrival = PROGEN_MAX(STC)

        ###USE Below for small problems : NOTE also edit GenerateInitials()
        #PredecessorTasks, STDur, AMPTD, RU, ARU, FreeResource, reward, DueDates, Tardiness, arrival= GenerateInitials()
        #################################################################################

        #Variables ##########################
        TypeNo = size(STDur,1) #Number of project types in the problem
        Finish = zeros(Float64,5,size(A,1)) #Variable to hold running time of algorithms.
        MeanValues = zeros(Float64,4,size(A,1))#Mean smulation profits of algorithms.
        deviationValues = zeros(Float64,4,size(A,1))#deviations of simulation profits.
        RValues = zeros(Float64,size(A,1),TypeNo*2)#Quefficient for ADP
        Arrivals = fill(" ",size(A,1),4)#number of project arrivals occurs during simulations
        Completion = fill(" ",size(A,1),4)#number of project completion occurs during simulations
        Due = fill(" ",size(A,1),4)#number of late project completion occurs during simulations
        GA_count = zeros(Int64,size(A,1))#Counter for how many time GA is called.
        GA_Train = zeros(Float64,size(A,1))#average training time of GA
        holdArrival = zeros(Int16,TypeNo) #counter of arrivals
        holdCompletion  = zeros(Int16,TypeNo)#counter of project completion
        holdDue  = zeros(Int16,TypeNo) #counter of late project completion
        holdGA_Trn = 0.0#Counter for total training times of GA
        Full_Profit= zeros(Float64,size(A,1),4)#simulation profit without discounting #NOTE not used in this work
        #########################################

        for x = 1:size(A,1)
            #####ADP code################################################
                #Please select number of iteration in ADP
                Iterations = 100 #Number of iteration in ADP
                ###########
                Control = 1 #ADP, do not change this.
                start = time() #Time keeping
                PreTaskState, DueDateState = InitialState(MaxProjectNO,STDur,A[x],DueDates)
                Q = ADP_Training(PreTaskState,DueDateState,FreeResource,PredecessorTasks,STDur,AMPTD,
                ARU,A[x],reward,DueDates,Tardiness,STC,DiscountFactor,Simulation,SimDura,Iterations)
                RValues[x,:] =  Q[Iterations,:]
                Finish[5,x] = time() - start #Training time.
                start = time()
                PreTaskState, DueDateState = InitialState(MaxProjectNO,STDur,A,DueDates)
                Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],Garbage,Garbage, fullprofit = Repeatersimulation(
                STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                PredecessorTasks,Simulation,SimDura,A[x],STC,DiscountFactor,AMPTD,Q[Iterations,:],Control)#
                for j  = 1:TypeNo
                    Arrivals[x,Control] *= string(holdArrival[j]) * " "
                    Completion[x,Control] *= string(holdCompletion[j]) * " "
                    Due[x,Control] *= string(holdDue[j]) * " "
                end
                MeanValues[Control,x] = mean(Sum_profit)
                deviationValues[Control,x]= std(Sum_profit)
                Full_Profit[x,Control]= mean(fullprofit)
                Finish[Control,x] = time() - start
                println("ADP with ",x," arrival rate finished in",Finish[5,x]," + ",Finish[Control,x])
            #######################################################################

            #####RBA code################################################
            #=
                Control = 2 # RBA
                start = time()
                PreTaskState, DueDateState = InitialState(MaxProjectNO,STDur,A[x],DueDates)
                Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],Garbage,Garbage, fullprofit = Repeatersimulation(
                STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                PredecessorTasks,Simulation,SimDura,A[x],STC,DiscountFactor,AMPTD,0,Control)
                for j  = 1:TypeNo
                    Arrivals[x,Control] *= string(holdArrival[j]) * " "
                    Completion[x,Control] *= string(holdCompletion[j]) * " "
                    Due[x,Control] *= string(holdDue[j]) * " "
                end
                MeanValues[Control,x] = mean(Sum_profit)
                deviationValues[Control,x]= std(Sum_profit)
                Full_Profit[x,Control]= mean(fullprofit)
                Finish[Control,x] = time() - start
                println("RBA with ",x," arrival rate finished in",Finish[Control,x])
                =#
            #######################################################################

            #####GA code################################################
            #=
                Control = 3 #GA
                start = time()
                PreTaskState, DueDateState = InitialState(MaxProjectNO,STDur,A[x],DueDates)
                Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],GA_count[x],holdGA_Trn, fullprofit= Repeatersimulation(
                STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                PredecessorTasks,16,SimDura,A[x],STC,DiscountFactor,AMPTD,0,Control)
                for j  = 1:TypeNo
                    Arrivals[x,Control] *= string(holdArrival[j]) * " "
                    Completion[x,Control] *= string(holdCompletion[j]) * " "
                    Due[x,Control] *= string(holdDue[j]) * " "
                end
                GA_Train[x] =holdGA_Trn/GA_count[x]
                MeanValues[Control,x] = mean(Sum_profit)
                deviationValues[Control,x]= std(Sum_profit)
                Full_Profit[x,Control]= mean(fullprofit)
                Finish[Control,x] = time() - start
                println("GA with ",x," arrival rate finished in",Finish[Control,x])
                =#
            #######################################################################

            #####ORBA code################################################
            #=
            Control = 4 #Static Best
                start = time()
                PreTaskState, DueDateState = InitialState(MaxProjectNO,STDur,A[x],DueDates)
                Sum_profit, holdArrival[:], holdCompletion[:], holdDue[:], Garbage, Garbage, fullprofit = Repeatersimulation(
                STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                PredecessorTasks,100,SimDura,A[x],STC,DiscountFactor,AMPTD,0,Control)
                for j  = 1:TypeNo
                    Arrivals[x,Control] *= string(holdArrival[j]) * " "
                    Completion[x,Control] *= string(holdCompletion[j]) * " "
                    Due[x,Control] *= string(holdDue[j]) * " "
                end
                MeanValues[Control,x] = mean(Sum_profit)
                deviationValues[Control,x]= std(Sum_profit)
                Full_Profit[x,Control]= mean(fullprofit)
                Finish[Control,x] = time() - start
                println("ORBA with ",x," arrival rate finished in",Finish[Control,x])
                =#
            #######################################################################
        end

        #Print results to EXCELL
        ArP = zeros(Float64,size(A,1))
        ArP[1:size(A,1)] = A
        df2 = DataFrame(hcat(ArP,MeanValues',deviationValues',Finish',Arrivals,Completion,Due,GA_count,GA_Train,Full_Profit))
        rename!(df2,["Arrival prob.","ADP","RBA","GA","ORBA","ADP_dev","RBA_dev","GA_dev","ORBA_dev","ADP_run","RBA_run","GA_run","ORBA_run",
        "ADP_training","ADP_Arrival","RBA_Arrivals","GA_Arrivals","ORBA_Arrivals",
        "ADP_Completion","RBA_Completion","GA_Completion","ORBA_Completion",
        "ADP_Due","RBA_Due","GA_Due","ORBA_Due","GA_Call","GA_av_training","ADP_F","RBA_F","GA_F","ORBA_F"])
        CSV.write("C:\\JuliaOutput\\UgurResults.csv", df2)

        #Quefficients values to excel
        df3 = DataFrame(RValues)
        CSV.write("C:\\JuliaOutput\\UgurRvalues.csv", df3)
    end #Compares the algorithms for multiple arrival rate

    function Repeatersimulation(STDur,ARU,reward,Tardiness,DueDates,DS,PT,FRR,
        PredecessorTasks,Simulation,SimDura,lambda,STC,DiscountFactor,AMPTD,Q,Control)

        TypeNo,MaxProjectNO,maxtask = size(PT,1),size(PT,2),size(PT,3)

        ####### Initial State generating with empty state and arrivals
        UP = zeros(Float64,Simulation)
        Sum_profit = zeros(Float64,Simulation)

        StoreArrivals = zeros(Int16,TypeNo) #stores number of arrivals.
        StoreCompletion= zeros(Int16,TypeNo) #stores number of completion.
        StoreDue= zeros(Int16,TypeNo) #stores number of late completion.
        StoreGA = 0# Int GA counter.
        StoreGA_Training = 0.0#Float time variable.
        for Sim = 1:Simulation
            start = time()
            DueDateState=copy(DS) #Assures all simulations starts from same state
            PreTaskState=copy(PT) #Assures all simulations starts from same state
            FreeResource=copy(FRR) #Assures all simulations starts from same state
            TaskOrder = [] #first task order of simulation.
            for t=1:SimDura
                #Generate a action for a state
                if Control >= 3 && sum(negative_task_summary(STDur,PreTaskState)) < 0 #if any decision is necesarry.
                    if TaskOrder == [] #if no task order remained from previos iteration
                        if Control == 3
                            GA_start = time()
                            TaskOrder =GA(STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks,STC)
                            StoreGA_Training += (time() - GA_start)
                            StoreGA += 1
                        elseif  Control == 4
                            TaskOrder =LocalOptimum(STDur,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,PredecessorTasks,STC)
                        end
                    end
                    #convert task order to an action. and got remaining task order.
                    best_action, TaskOrder = TPO_to_action2(TaskOrder,ARU,PreTaskState,FreeResource,PredecessorTasks)
                elseif Control >= 3
                    best_action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #nothing to do action.
                end
                if Control == 1
                    best_action = ADP(STDur,ARU,PreTaskState,DueDateState,FreeResource,PredecessorTasks,AMPTD,STC,Q,reward,Tardiness,lambda)
                elseif Control == 2
                    best_action = RBA(STDur,ARU,PreTaskState,FreeResource,PredecessorTasks,AMPTD)
                end

                #Reduce resources before ITERATION
                actionparticles =findall(a->a==1, best_action) #this found all readyto process tasks
                    for actionparticle in actionparticles
                        FreeResource = FreeResource .- ARU[:,actionparticle] #reduce used resources
                        if PreTaskState[actionparticle] !=  AMPTD[actionparticle]
                            println("ERROR WRONG ACTION AND TASK COMBINATION")
                            println("given state =",PreTaskState)
                            println("selected best action =",best_action)
                        end
                        j,k,i = actionparticle[1],actionparticle[2],actionparticle[3]
                        if PredecessorTasks[j,i] != 0 && sum(PreTaskState[j,k,PredecessorTasks[j,i]].== 0) != size(PredecessorTasks[j,i],1)
                            println("NETWORK ERROR",actionparticle[1],actionparticle[2],actionparticle[3])
                        end
                    end
                ############################

                #RESURCE Control
                for k = 1:size(FreeResource,1)
                    if FreeResource[k] < 0
                        println("negative resource usage WARNING")
                        println("state = ",PreTaskState[:,1,:])
                        println("action = ",best_action[:,1,:])
                        println("resource ",k," is =",FreeResource[k] )
                    end
                end
                #Iterate the state with the action.
                DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,Comp,Due =
                state_iteration(STDur,ARU,reward,Tardiness,DueDates,DueDateState,
                PreTaskState,FreeResource,best_action,lambda,STC,PredecessorTasks)

                #to use the remaining taskOrder if no arrival occors
                if sum(NewArrivals) != 0 #if a new project arriva you can not use remained task order.
                    TaskOrder = [] #previous task order become useless.
                end

                #Store Arrivals,
                for j = 1:TypeNo
                    StoreArrivals[j] += NewArrivals[j]
                    StoreCompletion[j] +=Comp[j]
                    StoreDue[j] += Due[j]

                end

                #DISCOUNTED profit
                if t==1
                    UP[Sim]+=Profit
                    Sum_profit[Sim]+=Profit
                else
                    UP[Sim]+=Profit
                    Sum_profit[Sim]+=DiscountFactor^(t-1)*Profit
                end
                #########
            end
        end
        return Sum_profit,StoreArrivals,StoreCompletion,StoreDue,StoreGA,StoreGA_Training, UP
    end #Runs a simulation with given stata and solution method.

    ### Initial State functions ###
    function InitialState(MaxProjectNO,STDur,lambda,DueDates)
        TypeNo, maxtask = size(STDur,1),size(STDur,2)
        ##### first pre-decision state
            PreTaskState = zeros(Int8,TypeNo,MaxProjectNO,maxtask)
            DueDateState = zeros(Int8,TypeNo,MaxProjectNO)
        #######
        return PreTaskState, DueDateState
    end #emty state
    function TESTState(MaxProjectNO,STDur,lambda,DueDates)
        TypeNo,maxtask = size(STDur,1),size(STDur,2)
        ##### first pre-decision state
            PreTaskState = zeros(Int8,TypeNo,MaxProjectNO,maxtask)
            DueDateState = zeros(Int16,TypeNo,MaxProjectNO)
            for j=1:TypeNo
                #if arrival[j] == 0
                    for i = 1:MaxProjectNO
                        PreTaskState[j,i,:] += STDur[j,:]
                        DueDateState[j,i] += DueDates[j]
                    end
                #end
            end
        #######
        return PreTaskState, DueDateState
    end #an initial state where all projects exist but no processing
    function GenerateInitials()
        ###########My old problem data#####################
        #WARNING just use one problem

        #### 4 project sample 2 tasks
        #MPTD =Int8[5 1;4 2;3 3;2 4]#;1 5] # project task durations
        #MPRU =Int8[2 1;2 1;2 1;2 1] #project resource usage
        #PDD= Int8[4,5,6,7] # project due dates
        #Tardiness=Int8[3,4,5,6]
        #reward=Int8[18,27,18,18]

        ### 2 project 3 tasks sample
        MPTD =Int8[1 2 5;4 3 4]#;7 8 9] # project task durations
        MPRU =Int8[1 2 1;1 2 1]#;1 2 1] #project resource usage
        PDD= Int8[10,15]#,25] # project due dates
        Tardiness=Int8[8,5]#,25]
        reward=Int8[12,6]

        #### 3 project sample 2 tasks
        #MPTD =Int8[5 2;1 3;2 7] # project task durations
        #MPRU =Int8[1 1;2 1;3 2] #project resource usage
        #PDD= Int8[10,8,10] # project due dates
        #Tardiness=Int8[5,3,19]
        #reward=Int8[8,5,20]

        #### 2 project sample 2 tasks
        #MPTD =Int8[2 2;3 1] # project task durations
        #MPRU =Int8[2 2;1 3] #project resource usage
        #PDD= Int8[8,5] # project due dates
        #Tardiness=Int8[1,9]
        #reward=Int8[3,10]
        #########################################

        TypeNo = size(MPTD,1)
        STC = 1 #How many early or late completion we have.
        EC = STC#Maximum Late completion period than expected
        LC = STC#Maximum Late completion period than expected
        PinType = ones(Int8,TypeNo) #Project no in a type
        maxtask=size(MPTD,2) #maximum number of task in each type. WARNING I fixed this to my old problems
        MaxProjectNO = maximum(PinType)
        NoResource = 1 # WARNING this need to be change for more resource option
        RU=zeros(Int8,NoResource,TypeNo,maxtask) #Resource usage
        RU[1,:,:] = MPRU

        ###### Project matrix
            PredecessorTasks = zeros(Int8,TypeNo,maxtask)
            for i=1:TypeNo
                PredecessorTasks[i,2:maxtask] = 1:maxtask-1 #WARNING only for old problems makes a sequential project network.
            end
        ######

        ###### STDur = Stochastic Task Duration
            STDur = MPTD .+ LC #For adaptation of old code
        ######

        AMPTD = zeros(Int8,TypeNo, MaxProjectNO,maxtask) # All durations for all projects
        for i = 1: MaxProjectNO
            AMPTD[:,i,:] = STDur[:,:] #for all project task durations
        end

        ###### Task Resource consumption
            RU=zeros(Int8,NoResource,TypeNo,maxtask) #Resource usage
            RU[1,:,:] = MPRU
            ARU = zeros(Int8,NoResource,TypeNo,MaxProjectNO,maxtask) # All resource usages for all projects
            for i = 1: MaxProjectNO
                ARU[:,:,i,:] = RU[:,:,:]
            end
        ######

        ###### Resource availabity
        Resource=zeros(Int8,NoResource)
        Resource[1] = 3 #every resource has 3 capasity we have 1 resource :D
        ######

        garbage = 1
        return PredecessorTasks, STDur, AMPTD, RU, ARU, Resource, reward, PDD, Tardiness, garbage
    end #which generates problems, old problem informations are inside
    ######

    #### Shared functions ####
        function state_iteration(STDur,ARU,reward,Tardiness,DueDates,DueDateState,
            PreTaskState,FreeResource,best_action,lambda,STC,PredecessorTasks)
            ###############Post Decision state #With stochactic task duration
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
                        if (PreTaskState[j,i,x] >0 && PreTaskState[j,i,x] < STDur[j,x]) ||  (PreTaskState[j,i,x] == STDur[j,x] && best_action[j,i,x] == 1) # On going or new task processing
                            if PreTaskState[j,i,x] <= 1+STC*2 #task is ready to be completed and its ongoing
                                Random_prob = rand()
                                if Random_prob <= disp(PreTaskState[j,i,x],STDur[j,x]) #completion Probabiltyblity
                                    FR = FR  .+ ARU[:,j,i,x] #relise the used resources #NOTE suitable for multi resources
                                    PostTaskState[j,i,x] = 0 #Early normal or late completion with probablity
                                else #No early completion option
                                    if PostTaskState[j,i,x] == 1
                                        println("WARNING Task completion probability error 1")
                                        println("Pre = ",PreTaskState[j,i,x])
                                        println("J and i = ",j,"-",x)
                                        println("task duration = ",STDur[j,x] )
                                        println("Required = ",disp(PreTaskState[j,i,x],STDur[j,x]))
                                        println("random = ",Random_prob )
                                    end
                                    PostTaskState[j,i,x] -= 1 #reduce remaining duration
                                end
                            else #No early completion option
                                if PostTaskState[j,i,x] == 1
                                    println("WARNING Task completion probability error 2")
                                    println("Pre = ",PreTaskState[j,i,x])
                                    println("J and i = ",j,"-",x)
                                    println("task duration = ",STDur[j,x] )
                                end
                                PostTaskState[j,i,x] -= 1 #reduce remaining duration
                            end
                        end #task completion
                    end
                    #################################
                    if sum(PostTaskState[j,i,:]) != 0 #if project not completed
                        PostState[j] +=1 #number of project after iteration, before new arrival
                    end

                    if (all(PostTaskState[j,i,:].==0) && any(PreTaskState[j,i,:].!=0)) #NEWLY COMPLETED PROJECTS
                        # REWARD calculation
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
                for j = 1:TypeNo
                    if rand() <= lambda && PostState[j] < MaxProjectNO
                        #means system is emty and arrival happens we see it otherwise we dont care.
                        NewArrivals[j] = 1
                        #global arricalcount[j] +=1 #NOTE this is for counting new arrivals
                    end
                end
            ######

            ##### new pre-decision state after arrivals
                PS = copy(PostTaskState) #pretaskstate
                for j=1:TypeNo
                    PostState[j] += NewArrivals[j]
                    if NewArrivals[j] > 0
                        for i = 1:NewArrivals[j]
                            PS[j,i,:] += STDur[j,:] #pretaskstate
                            DS[j,i] += DueDates[j]
                        end
                    end
                end
            ######
            PreS = copy(PostState) #PreState
            return DS,PS,FR,Profit,NewArrivals,Completion,Late_comp
        end#adabted for MPSPLIB end task dummy
        function ReadyToProcessTasks(PredecessorTasks,ARU,TaskCode,FreeResource,actions)
            ##### Finding Ready to process tasks => actions = true
            #NOTE multiple resources and unsequential projects networks are supported!
            TypeNo,MaxProjectNO,maxtask = size(TaskCode,1),size(TaskCode,2),size(TaskCode,3)
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        #If task is not processed and there are enough unallocated resources from all types are exist and all predicessor tasks are completed
                        if  TaskCode[j,i,x] == -1 &&
                            sum(ARU[:,j,i,x] .<= FreeResource) == size(FreeResource,1) &&
                            (PredecessorTasks[j,x] == 0 ||
                            sum(TaskCode[j,i,PredecessorTasks[j,x]].== 0) == size(PredecessorTasks[j,x],1) )
                            actions[j,i,x] = true ##Ready to process task
                        end
                    end
                end
            end
            ##### Finding Ready to process tasks => actions = true
            return actions
        end#
        function negative_task_summary(STDur,PreTaskState)
            #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
            TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
            TaskCode = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #for summary
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        if PreTaskState[j,i,x] == STDur[j,x]
                            TaskCode[j,i,x] = -1
                        end
                    end
                end
            end
            #######################
            return TaskCode
        end
        function postive_task_summary(STDur,PreTaskState)
            #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
            TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
            TaskCode = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #for summary
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        if PreTaskState[j,i,x] >0 && PreTaskState[j,i,x] < STDur[j,x]
                            TaskCode[j,i,x] = 1
                        end
                    end
                end
            end
            #println(TaskCode," task codes")
            #######################
            return TaskCode
        end
        function Task_Summary(STDur,PreTaskState)
            #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
            TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
            TaskCode = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #for summary
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        if PreTaskState[j,i,x] >0 && PreTaskState[j,i,x] < STDur[j,x]
                            TaskCode[j,i,x] = 1
                        elseif PreTaskState[j,i,x] == STDur[j,x]
                            TaskCode[j,i,x] = -1
                        end
                    end
                end
            end
            #######################
            return TaskCode
        end#working
        function disp(state,FullSTDur)
            #here we have uniform distribution
            EFprob = 0.000
            if FullSTDur!=2 || state != 2#if state late finish is not 2, #normal finish is 1, early finish is 0
                EFprob = 1/state
            else
                EFprob = 1/3 #1/2#
            end
            return EFprob
        end # creates uniform distribution of early completion (1/3,1/2,1)
    #END OF FUNCTIONS##############################################################


    #WARNING First run above then below ###############################################

    ##################################################################################
    #Initials
    Simulation,SimDura = 100, 1000 #Number of Simulation, Duration of Simulation
    DiscountFactor = 0.999# use 0.999
    ##################################################################################
    #NOTE Do not change this number.
    MaxProjectNO = 1 #Maximum number of projects from same type can available at a time in the system
    #NOTE Multiple project from same type do not supported by some functions thus do not change this number.
    repeater(MaxProjectNO,DiscountFactor,Simulation,SimDura)
