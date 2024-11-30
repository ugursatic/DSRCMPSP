    #Pkg. add(["Combinatorics","Statistics","LsqFit","DataFrames","CSV","LinearAlgebra","Random","ZipFile"])
    #Pkg.add("Gtk")
    using Combinatorics #for conbinations chosing alternative actions.
    using Statistics #For mean function
    using LsqFit # For curve fit
    using DataFrames, CSV #required for printing to excel
    using LinearAlgebra
    using Random #For using seeds

    #include("FILE LOCATION\\ADP_models_automated.jl")
    #include("FILE LOCATION\\RBA.jl") 
    #include("FILE LOCATION\\ORBAandGA.jl")
    #include("FILE LOCATION\\Problem_Reader.jl") 
    #include("FILE LOCATION\\MPSPLIB_2P.jl") 
    #include("FILE LOCATION\\MPSPLIB_Reader_5P.jl")

#Initial Values ###################################################################################################################
MaxProjectNO = 1 #NOTE this is an initial, it might be used in future.
DiscountFactor = 0.999# use 0.999
Simulation,PERIODS = 100, 1000
Iterations = 100
STC,maxarrivals = 1,1

repeater(MaxProjectNO,DiscountFactor,Simulation,PERIODS,Iterations,STC,maxarrivals)

#######################################################################################
    function repeater(MaxProjectNO,DiscountFactor,Simulation,PERIODS,Iterations,STC,maxarrivals)
        A=  [0.01,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9]  
        RValues = []

        predecessor, taskDuration, AMPTD, RU, ARU, FreeResource, maxarrivals, reward, DueDates, Tardiness, arrival = GenerateInitials(STC,maxarrivals,MaxProjectNO)
        #predecessor, taskDuration, AMPTD, RU, ARU, FreeResource, maxarrivals, reward, DueDates, Tardiness, arrival = PROGEN_MAX(STC,maxarrivals)
        #predecessor, taskDuration, AMPTD, RU, ARU, FreeResource, maxarrivals, reward, DueDates, Tardiness, arrival = MPSPLIB(STC,maxarrivals)
        
        TypeNo = size(taskDuration,1)
        maxtask = size(taskDuration,2)

        for Mdl = 4:4
            Finish = zeros(Float64,5,size(A,1))
            MeanValues = zeros(Float64,4,size(A,1))
            deviationValues = zeros(Float64,4,size(A,1))

            Features_no = 2
            if Mdl == 8 || Mdl == 9 || Mdl == 10 || Mdl == 11
                Features_no = 1
            elseif Mdl == 6 || Mdl == 7
                Features_no = 3
            else
                Features_no = 2
            end
            RValues = zeros(Float64,size(A,1),TypeNo*Features_no)
            Arrivals = fill(" ",size(A,1),4)
            Completion = fill(" ",size(A,1),4)
            Due = fill(" ",size(A,1),4)
            GA_count = zeros(Int64,size(A,1))
            GA_Train = zeros(Float64,size(A,1))
            holdArrival = zeros(Int16,TypeNo)
            holdCompletion  = zeros(Int16,TypeNo)
            holdDue  = zeros(Int16,TypeNo)
            holdGA_Trn = 0.0
            Full_Profit= zeros(Float64,size(A,1),4)

            CANPP = zeros(Float64,size(A,1))
            CR = zeros(Float64,size(A,1),size(FreeResource,1))
            CMOP = zeros(Float64,size(A,1))
            Q = zeros(Float64,Iterations,Features_no*TypeNo)

            for x = 1:size(A,1)

                #Simulation seeds#######
                randPrArv  = MersenneTwister(1905) # project arrival seed
                randTaskComp = Array{Any}(undef,TypeNo,maxtask)
                for j = 1:TypeNo
                    for i = 1:maxtask
                        randTaskComp[j,i]   =  MersenneTwister(100*j+i)
                    end
                end
                ###########################################################

                Control = 1 #ADP
                    start = time()
                    #Iterations = 100
                    TPERIODS = copy(PERIODS)
                    TSimulation = copy(Simulation)
                    #if A[x] <= 0.4#0.01
                    #    TPERIODS = 1000 #multiply with 10
                    #end
                    ### Training ###############################################################
                    garbage, PreTaskState, DueDateState = TESTState(MaxProjectNO,taskDuration,A[x],DueDates)
                    Q0_all, Q = ADP_Training(PreTaskState,DueDateState,FreeResource,predecessor,taskDuration,AMPTD,
                    ARU,maxarrivals,A[x],reward,DueDates,Tardiness,STC,DiscountFactor,TSimulation,TPERIODS,Iterations,
                    randTaskComp,randPrArv,Features_no,Mdl)
                    RValues[x,:] = Q[Iterations,:] #This is only used to generate a coefficient values table.
                    Finish[5,x] = time() - start #Training time.
                    start = time()
                    ###############################################################################################

                    ### Simulation ################################################################################
                    #Simulation seeds####### This is reseted here so all simulations will start from the same point.
                    randPrArv  = MersenneTwister(1905) # project arrival seed
                    randTaskComp = Array{Any}(undef,TypeNo,maxtask)
                    for j = 1:TypeNo
                        for i = 1:maxtask
                            randTaskComp[j,i]   =  MersenneTwister(100*j+i)
                        end
                    end
                    garbage, PreTaskState, DueDateState = TESTState(MaxProjectNO,taskDuration,A,DueDates)
                    Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],Garbage,Garbage, fullprofit, CANPP[x],CR[x,:],CMOP[x] = Repeatersimulation(
                    taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor,Simulation,
                    PERIODS,A[x],STC,DiscountFactor,AMPTD,Q[Iterations,:],Control,randTaskComp,randPrArv,Mdl)#
                    for j  = 1:TypeNo
                        Arrivals[x,Control] *= string(holdArrival[j]) * " "
                        Completion[x,Control] *= string(holdCompletion[j]) * " "
                        Due[x,Control] *= string(holdDue[j]) * " "
                    end
                    #co[x,:] = copy(Q[Iterations,:])
                    MeanValues[Control,x] = mean(Sum_profit)
                    deviationValues[Control,x]= std(Sum_profit)
                    Full_Profit[x,Control]= mean(fullprofit)
                    Finish[Control,x] = time() - start
                    #COPYPROFIT[x,:] = copy(Sum_profit)
                    println("ADP with ",x," arrival rate finished in",Finish[5,x]," + ",Finish[Control,x],"  ", MeanValues[Control,x])
                    ################################################################################################

                    #=
                Control = 2 # priorty rule
                    start = time()
                    garbage, PreTaskState, DueDateState = TESTState(MaxProjectNO,taskDuration,A[x],DueDates)
                    Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],Garbage,Garbage, fullprofit, CANPP[x],CR[x,:],CMOP[x] = Repeatersimulation(
                    taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                    predecessor,Simulation,PERIODS,A[x],STC,DiscountFactor,AMPTD,0,Control,randTaskComp,randPrArv,[])
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
                    #=
                Control = 3 #GA
                    start = time()
                    garbage, PreTaskState, DueDateState = TESTState(MaxProjectNO,taskDuration,A[x],DueDates)
                    Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],Garbage,Garbage, fullprofit, CANPP[x],CR[x,:],CMOP[x]= Repeatersimulation(
                    taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                    predecessor,Simulation,PERIODS,A[x],STC,DiscountFactor,AMPTD,0,Control,randTaskComp,randPrArv,[])

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
                    println("GA with ",x," arrival rate finished in",Finish[Control,x],"  ", MeanValues[Control,x])
                    =#
                    #=
                Control = 4 #Static Best
                    start = time()
                    garbage, PreTaskState, DueDateState = TESTState(MaxProjectNO,taskDuration,A[x],DueDates)
                    Sum_profit,holdArrival[:],holdCompletion[:],holdDue[:],Garbage,Garbage, fullprofit, CANPP[x],CR[x,:],CMOP[x] = Repeatersimulation(
                    taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
                    predecessor,Simulation,PERIODS,A[x],STC,DiscountFactor,AMPTD,0,Control,randTaskComp,randPrArv,[])
                    for j  = 1:TypeNo
                        Arrivals[x,Control] *= string(holdArrival[j]) * " "
                        Completion[x,Control] *= string(holdCompletion[j]) * " "
                        Due[x,Control] *= string(holdDue[j]) * " "
                    end
                    MeanValues[Control,x] = mean(Sum_profit)
                    deviationValues[Control,x]= std(Sum_profit)
                    Full_Profit[x,Control]= mean(fullprofit)
                    Finish[Control,x] = time() - start
                    println("ORBA with ",x," arrival rate finished in",Finish[Control,x],"  ", MeanValues[Control,x])
                    =#
            end
                #dfTEST = DataFrame(COPYPROFIT',["0.5","0.6"])
                #CSV.write("C:\\JuliaOutput\\UgurProfitsfiveandsix.csv", dfTEST )

            CANPP = CANPP./(Simulation*PERIODS)
            CMOP = CMOP./(Simulation*PERIODS)
            CR = CR./(Simulation*PERIODS)
            PCR =  zeros(Float64,size(A,1),4) #Print Free resource amount per unit
            for i = 1:size(CR,2)
                PCR[:,i] = CR[:,i]
            end

            ArP = zeros(Float64,size(A,1))
            ArP[1:size(A,1)] = A
            df2 = DataFrame(hcat(ArP,MeanValues',deviationValues',Finish',Arrivals,Completion,Due,GA_count,GA_Train,Full_Profit,CANPP,CMOP,PCR[:,1],PCR[:,2],PCR[:,3],PCR[:,4]
            ),
            ["Arrival prob.","ADP","RBA","GA","ORBA","ADP_dev","RBA_dev","GA_dev","ORBA_dev","ADP_run","RBA_run","GA_run","ORBA_run",
            "ADP_training","ADP_Arrival","RBA_Arrivals","GA_Arrivals","ORBA_Arrivals",
            "ADP_Completion","RBA_Completion","GA_Completion","ORBA_Completion",
            "ADP_Due","RBA_Due","GA_Due","ORBA_Due","GA_Call","GA_av_training","ADP_F","RBA_F","GA_F","ORBA_F","CANPP","CMOP","FreeR1","FreeR2","FreeR3","FreeR4",])

            CSV.write(string("C:\\JuliaOutput\\Test Model ",Mdl," ",TypeNo,"p",maxtask,"t",size(FreeResource,1),"r Results.csv"), df2)

            #prepare R values excel
            #WARNING this vector should change when tested model is changed.
            q1vector =string.("j",Vector{Int32}(1:size(RValues,2)/Features_no)," q1")
            q2vector = []
            q3vector = []
            R_titles = vcat(q1vector)
            if Mdl == 6 || Mdl == 7
                q2vector =string.("j",Vector{Int32}(1:size(RValues,2)/Features_no)," q2")
                q3vector =string.("j",Vector{Int32}(1:size(RValues,2)/Features_no)," q3")
                R_titles = vcat(q1vector, q2vector, q3vector)
            elseif Mdl == 1 || Mdl == 2 || Mdl == 3 || Mdl == 4 || Mdl == 5
                q2vector =string.("j",Vector{Int32}(1:size(RValues,2)/Features_no)," q2")
                R_titles = vcat(q1vector, q2vector)
            end
            println(R_titles)
            df3 = DataFrame(RValues, R_titles)

            CSV.write(string("C:\\JuliaOutput\\Test Model ",Mdl," ",TypeNo,"p",maxtask,"t",size(FreeResource,1),"r Rvalues.csv"), df3)

        end
    end
    function Repeatersimulation(taskDuration,ARU,reward,Tardiness,DueDates,DS,PT,FRR,
        predecessor,Simulation,PERIODS,arrivalprobs,STC,DiscountFactor,AMPTD,Q,Control,randTaskComp,randPrArv,Mdl)

        TypeNo,MaxProjectNO,maxtask = size(PT,1),size(PT,2),size(PT,3)
        #policy = load("policy.jld2")["policy"]
        ####### Initial State generating with empty state and arrivals
        #Simulation = 1#One long simulation
        #PERIODS = 100
        UP = zeros(Float64,Simulation)
        Sum_profit = zeros(Float64,Simulation)
        #DS =copy(DueDateState)
        #PT =copy(PreTaskState)
        #FRR =copy(FreeResource)
        StoreArrivals = zeros(Int16,TypeNo) #stores number of arrivals.
        StoreCompletion= zeros(Int16,TypeNo) #stores number of completion.
        StoreDue= zeros(Int16,TypeNo) #stores number of late completion.
        StoreGA = 0# Int GA counter.
        StoreGA_Training = 0.0#Float time variable
        TPRU = zeros(Int64,TypeNo) #Total project resource usage it
        PDSA = zeros(Int64,TypeNo) #number of idle days since arrival.

        ##### Statitstic definitions for Chris's suggested statistics for second review.
        Chris_FreeResource_holder = zeros(Int64,size(FRR,1))
        Chris_more_than_one_project_processed = 0
        Chris_average_number_of_processed_projects = 0
        ###########

        for Sim = 1:Simulation
            start = time()
            DueDateState=copy(DS)
            PreTaskState=copy(PT)
            FreeResource=copy(FRR)
            ######NOTE TEST PURPOSE
            #=taskstate_holder = zeros(Int8,PERIODS,TypeNo,MaxProjectNO,maxtask)
            DueDateState_holder = zeros(Int8,PERIODS,TypeNo,MaxProjectNO)
            action_holder =zeros(Int8,PERIODS,TypeNo,MaxProjectNO,maxtask)
            FreeResource_holder = zeros(Int8,PERIODS)
            Profit_holder = zeros(Float64,PERIODS) =#


            ##### Statitstic definitions for Chris's suggested statistics for second review.
            Chris_number_of_processed_projects = zeros(Int8,PERIODS)
            ###########
            TaskOrder = [] #first task order of simulation.
            for t=1:PERIODS
                #Generate a action for a state
                #println("pre = ",reshape(PreTaskState[:,1,:]',length(PreTaskState)))
                #println("Free resource ",FreeResource)

                if Control >= 3 && sum(negative_task_summary(taskDuration,PreTaskState)) < 0 #if any decision is necesarry.
                    if TaskOrder == [] #if no task order remained from previos iteration
                        if Control == 3
                            GA_start = time()
                            TaskOrder =GA(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor,STC)
                            StoreGA_Training += (time() - GA_start)
                            StoreGA += 1
                        elseif  Control == 4
                            TaskOrder = LocalOptimum(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,predecessor,STC)
                        end
                        #println("Task Order generated")
                    end
                    #println("begin to convert")
                    #convert task order to an action. and got remaining task order.
                    best_action, TaskOrder = TPO_to_action2(TaskOrder,ARU,PreTaskState,FreeResource,predecessor)
                    #println("An Action from Task Order generated")
                elseif Control >= 3
                    best_action = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #nothing to do action.
                end
                if Control == 1
                    q0 = true #I dont have Q0 with my current models
                    garbage1,garbage2,best_action,garbage3,garbage4, TPRU, PDSA = ADP_Periods(Q , q0, PreTaskState,
                    DueDateState, FreeResource, taskDuration, predecessor, ARU, reward, Tardiness, DueDates,
                    arrivalprobs, STC, AMPTD,TPRU,PDSA,[],[],Mdl)
                elseif Control == 2
                    best_action = RBA(taskDuration,ARU,PreTaskState,FreeResource,predecessor,AMPTD)
                end

                #best_action = policy_to_action(policy,PreTaskState,DueDateState,taskDuration)

                #Reduce resources before ITERATION
                actionparticles =findall(a->a==1, best_action) #this found all readyto process tasks
                #RTU = zeros(Int64,size(ARU,1))
                    for actionparticle in actionparticles
                        FreeResource = FreeResource .- ARU[:,actionparticle] #reduce used resources
                        #RTU = RTU .+ ARU[:,actionparticle]
                        if PreTaskState[actionparticle] !=  AMPTD[actionparticle]
                            println("ERROR WRONG ACTION AND TASK COMBINATION")
                            println("given state =",PreTaskState)
                            println("selected best action =",best_action)
                        end
                        j,k,i = actionparticle[1],actionparticle[2],actionparticle[3]
                        if predecessor[j,i] != 0 && sum(PreTaskState[j,k,predecessor[j,i]].== 0) != size(predecessor[j,i],1)
                            println("NETWORK ERROR",actionparticle[1],actionparticle[2],actionparticle[3])
                        end
                    end
                    #if RUSA != RTU
                    #    println("Action resource usage calculation has an error here")
                    #    println("RUSA = ",RUSA)
                    #    println("RTU = ",RTU)
                    #end
                ############################

                ##### Recording new statistics as Chris suggestes ######
                #### The average number of project types processed in one unit of time. ####
                for j = 1:TypeNo
                    for i = 1:maxtask
                        if PreTaskState[j,1,i] != AMPTD[j,1,i] && PreTaskState[j,1,i] != 0 || best_action[j,1,i] == 1
                            Chris_number_of_processed_projects[t] += 1
                            if j !=TypeNo
                                j+=1
                                i=1
                            else
                                i = maxtask
                            end
                        end
                    end
                end
                #### What proportion of the period where more than one type of project is processed?  ####
                if Chris_number_of_processed_projects[t] > 1
                    Chris_more_than_one_project_processed += 1
                end
                ### The proportion of available free resources. ###
                Chris_FreeResource_holder = Chris_FreeResource_holder .+ FreeResource # add remaining free sources
                ##############################################################################

                #RESURCE Control
                for k = 1:size(FreeResource,1)
                    if FreeResource[k] < 0
                        #println("Quefficient = ",Q)
                        println("negative resource usage WARNING")
                        #println("Algorithm = ",Control)
                        println("state = ",PreTaskState[:,1,:])
                        println("action = ",best_action[:,1,:])
                        println("resource ",k," is =",FreeResource[k] )
                    end
                end
                #Iterate the state with the action.
                #println("before state iteration")
                DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,Comp,Due =
                state_iteration(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,
                PreTaskState,FreeResource,best_action,arrivalprobs,STC,predecessor,randTaskComp,randPrArv)

                #to use the remaining taskOrder if no arrival occors
                if sum(NewArrivals) != 0 #if a new project arriva you can not use remained task order.
                    TaskOrder = [] #previous task order become useless.
                end

                ##### reseting some value holders for NEW project arrival ####
                for j=1:TypeNo
                    if NewArrivals[j] > 0 #New project arrival
                        TPRU[j] = 0 # Total used resources since new project arrival.
                        PDSA[j] = 0 # passive days since new project arrival
                    end
                end
                #################################################################

                #Store Arrivals,
                for j = 1:TypeNo
                    StoreArrivals[j] += NewArrivals[j]
                    StoreCompletion[j] +=Comp[j]
                    StoreDue[j] += Due[j]

                end
                #######
                #println("iteration",Sim,"-",t,"done")
                    ######NOTE TEST PURPOSE
                    #SAVING iteration values of simulation.
                    #=taskstate_holder[t,:,:,:] = PreTaskState
                    DueDateState_holder[t,:,:] = DueDateState
                    FreeResource_holder[t] = FreeResource[1]
                    action_holder[t,:,:,:] = best_action
                    Profit_holder[t] = Profit =#
                    ###########

                #DISCOUNTED profit
                if t==1
                    UP[Sim]+=Profit
                    Sum_profit[Sim]+=Profit
                    #println("iteration profit =",Profit)
                else
                    UP[Sim]+=Profit
                    Sum_profit[Sim]+=DiscountFactor^(t-1)*Profit
                    #println("iteration profit =",DiscountFactor^(t-1)*Profit)
                end
                #########
                #println(FreeResource)
                #println(Chris_number_of_processed_projects[t])
                #println(Chris_more_than_one_project_processed)
                #println(Chris_FreeResource_holder[1])
            end

            ##### Statitstic definitions for Chris's suggested statistics for second review.
            Chris_average_number_of_processed_projects += sum(Chris_number_of_processed_projects,dims=1)[1]
            ###########
            #println("simulation ",Sim," is end")
            #println("simulation profit = ",Sum_profit[Sim])
            #println("simulation time = ",time() - start)
        end
        return Sum_profit,StoreArrivals,StoreCompletion,StoreDue,StoreGA,StoreGA_Training, UP,
        Chris_average_number_of_processed_projects, Chris_FreeResource_holder, Chris_more_than_one_project_processed
    end
    ### Initial State functions ###
    function InitialState(MaxProjectNO,taskDuration,arrivalprobs,DueDates)
        initialstateArrivals = MersenneTwister(19052022)
        TypeNo, maxtask = size(taskDuration,1),size(taskDuration,2)
        ##### Random Project Arrivals for first state
            NewArrivals = zeros(Int8,TypeNo) #WARNING this is for old code.
            for j = 1:TypeNo
                if rand(initialstateArrivals) <= arrivalprobs
                #if rand() <= arrivalprobs
                    NewArrivals[j] = 1
                end
            end
        ######
            #NewArrivals = [1,1]
        ##### first pre-decision state
            PreState = zeros(Int8,TypeNo)
            PreTaskState = zeros(Int8,TypeNo,MaxProjectNO,maxtask)

            DueDateState = zeros(Int8,TypeNo,MaxProjectNO)
            for j=1:TypeNo
                PreState[j] += NewArrivals[j]
                if NewArrivals[j] > 0
                    for i = 1:NewArrivals[j]
                        PreTaskState[j,i,:] += taskDuration[j,:]
                        DueDateState[j,i] += DueDates[j]
                    end
                end
            end
        #######
        return PreState, PreTaskState, DueDateState
    end #emty state + random arrivals
    function TESTState(MaxProjectNO,taskDuration,arrivalprobs,DueDates)
        TypeNo,maxtask = size(taskDuration,1),size(taskDuration,2)
        ##### first pre-decision state
            PreState = zeros(Int8,TypeNo)
            PreTaskState = zeros(Int8,TypeNo,MaxProjectNO,maxtask)
            DueDateState = zeros(Int16,TypeNo,MaxProjectNO)
            for j=1:TypeNo
                #if arrival[j] == 0
                    for i = 1:MaxProjectNO
                        PreTaskState[j,i,:] += taskDuration[j,:]
                        DueDateState[j,i] += DueDates[j]
                    end
                #end
            end
        #######
        return PreState, PreTaskState, DueDateState
    end #an initial state where all projects exist but no processing
    function GenerateInitials(STC,maxarrivals,MaxProjectNO)
        ###########My old problem rewards#####################

        #### 4 project sample 2 tasks
        #=
        MPTD =Int8[5 1;4 2;3 3;2 4]#;1 5] # project task durations
        MPRU =Int8[2 1;2 1;2 1;2 1] #project resource usage
        PDD= Int8[4,5,6,7] # project due dates
        Tardiness=Int8[3,4,5,6]
        reward=Int8[18,27,18,18]
        =#

        ### 2 project 3 tasks sample
        #=
        MPTD =Int8[1 2 5;4 3 4]#;7 8 9] # project task durations
        MPRU =Int8[1 2 1;1 2 1]#;1 2 1] #project resource usage
        PDD= Int8[10,15]#,25] # project due dates
        Tardiness=Int8[8,5]#,25]
        reward=Int8[12,6]
        =#
        ############Common values

        #### 3 project sample 2 tasks
        #=
        MPTD =Int8[5 2;1 3;2 7] # project task durations
        MPRU =Int8[1 1;2 1;3 2] #project resource usage
        PDD= Int8[10,8,10] # project due dates
        Tardiness=Int8[5,3,19]
        reward=Int8[8,5,20]
        =#

        #### 2 project sample 2 tasks
        
        MPTD =Int8[2 2;3 1] # project task durations
        MPRU =Int8[2 2;1 3] #project resource usage
        PDD= Int8[8,5] # project due dates
        Tardiness=Int8[1,9]
        reward=Int8[3,10]
        
        #########################################
        TypeNo = size(MPTD,1)
        EC = STC#Maximum Late completion period than expected
        LC = STC#Maximum Late completion period than expected
        #arrivalprob = copy(ArrivalProbabilty)
        PinType = ones(Int8,TypeNo) #Project no in a type
        #reward = zeros(Int8,TypeNo)  #Project reward of a type
        maxtask=size(MPTD,2) #maximum number of task in each type. WARNING I fixed this to my old problems
        #MaxProjectNO = maximum(PinType)
        NoResource = 1 # WARNING this need to be change for more resource option
        RU=zeros(Int8,NoResource,TypeNo,maxtask) #Resource usage
        RU[1,:,:] = MPRU

        ###### Project reward
            #I already have this for old problems
            #WARNING I REMOVED THE reward again
            #reward2 = sum(reward,dims=2)
            #reward = copy(reward2) #zeros(Int8,TypeNo) #
        ######

        ###### Project due date
            #I already have this for old problems
        ######

        ###### Project tardiness cost
            #I already have this for old problems
        ######

        ###### Project matrix
            predecessor = zeros(Int8,TypeNo,maxtask)
            for i=1:TypeNo
                predecessor[i,2:maxtask] = 1:maxtask-1 #WARNING only for old problems makes a sequential project network.
            end
        ######

        ###### Stochastic Task Duration
        #taskDuration=zeros(Int8,TypeNo,maxtask)
            taskDuration = MPTD .+ LC #For adaptation of old code
        ######

        AMPTD = zeros(Int8,TypeNo, MaxProjectNO,maxtask) # All durations for all projects
        for i = 1: MaxProjectNO
            AMPTD[:,i,:] = taskDuration[:,:] #for all project task durations
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

        ###### Project Arrivals
            #maxarrivals = 1
            #arrivalprobs = arrivalprob
        ######
        garbage = 1
        return predecessor, taskDuration, AMPTD, RU, ARU, Resource, maxarrivals, reward, PDD, Tardiness, garbage
    end #which generates problems, old problem informations are inside
    ######

    #### Shared functions ####
        function state_iteration(taskDuration,ARU,reward,Tardiness,DueDates,DueDateState,
            PreTaskState,FreeResource,best_action,arrivalprobs,STC,predecessor,randTaskComp,randPrArv)
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
                                Random_prob = rand(randTaskComp[j,x]) #for task completion #Here it generate the same completion probs for all actions.
                                if Random_prob <= disp(PreTaskState[j,i,x],taskDuration[j,x]) #completion Probabiltyblity
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
                for j = 1:TypeNo
                    #if rand() <= arrivalprobs && PostState[j] < MaxProjectNO #for project arrivals
                    if rand(randPrArv) <= arrivalprobs && PostState[j] < MaxProjectNO #for project arrivals
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
                            PS[j,i,:] += taskDuration[j,:] #pretaskstate
                            DS[j,i] += DueDates[j]
                        end
                    end
                end
            ######
            PreS = copy(PostState) #PreState
            return DS,PS,FR,Profit,NewArrivals,Completion,Late_comp
        end#adabted for MPSPLIB end task dummy
        function ReadyToProcessTasks(predecessor,ARU,TaskCode,FreeResource,actions)
            ##### Finding Ready to process tasks => actions = true
            #NOTE multiple resources and unsequential projects networks are supported!
            #WARNING CHECK HERE
            TypeNo,MaxProjectNO,maxtask = size(TaskCode,1),size(TaskCode,2),size(TaskCode,3)
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        #If task is not processed and there are enough unallocated resources from all types are exist and all predicessor tasks are completed
                        if  TaskCode[j,i,x] == -1 &&
                            sum(ARU[:,j,i,x] .<= FreeResource) == size(FreeResource,1) &&
                            (predecessor[j,x] == 0 ||
                            sum(TaskCode[j,i,predecessor[j,x]].== 0) == size(predecessor[j,x],1) )
                            actions[j,i,x] = true ##Ready to process task
                        end
                    end
                end
            end
            ##### Finding Ready to process tasks => actions = true
            return actions
        end#
        function negative_task_summary(taskDuration,PreTaskState)
            #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
            TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
            TaskCode = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #for summary
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        if PreTaskState[j,i,x] == taskDuration[j,x]
                            TaskCode[j,i,x] = -1
                        end
                    end
                end
            end
            #######################
            return TaskCode
        end
        function postive_task_summary(taskDuration,PreTaskState)
            #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
            TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
            TaskCode = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #for summary
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        if PreTaskState[j,i,x] >0 && PreTaskState[j,i,x] < taskDuration[j,x]
                            TaskCode[j,i,x] = 1
                        end
                    end
                end
            end
            #println(TaskCode," task codes")
            #######################
            return TaskCode
        end
        function Task_Summary(taskDuration,PreTaskState)
            #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
            TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
            TaskCode = zeros(Int8,TypeNo,MaxProjectNO,maxtask) #for summary
            for j = 1:TypeNo
                for i = 1:MaxProjectNO
                    for x = 1:maxtask
                        if PreTaskState[j,i,x] >0 && PreTaskState[j,i,x] < taskDuration[j,x]
                            TaskCode[j,i,x] = 1
                        elseif PreTaskState[j,i,x] == taskDuration[j,x]
                            TaskCode[j,i,x] = -1
                        end
                    end
                end
            end
            #println(TaskCode," task codes")
            #######################
            return TaskCode
        end#working
        function disp(state,FulltaskDuration)
            #here we have uniform distribution
            EFprob = 0.000
            if FulltaskDuration!=2 || state != 2#if state late finish is not 2, #normal finish is 1, early finish is 0
                EFprob = 1/state
            else
                EFprob = 1/3 #1/2#
            end
            return EFprob
        end # creates uniform distribution of early completion (1/3,1/2,1)
    ##########################
