########ADP CODE############

####### ADP TRAINING ###############
function ADP_Training(PreTaskState,DueDateState,FreeResource,PredecessorTasks,STDur,AMPTD,ARU,
    lambda,reward,DueDates,Tardiness,StocTask,DiscountFactor,Simulation,SimDura,Iterations)

    #Initials##############
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    Coef_no = TypeNo*2 #Number of coefficient in linear model
    coef = zeros(Float64,Coef_no) #coffecients in linear model
    Coefficients = zeros(Float64,Iterations,Coef_no) #all coefficients during training
    ########################

    for Step = 1:Iterations
        #iteration initials#########################
        Sum_profit = zeros(Float64,Simulation) #dependent variable #discounted profit
        X=zeros(Simulation,Coef_no) #independent variables
        ##############################################

        for Sim = 1:Simulation
            PositiveTaskCode = postive_task_summary(STDur,PreTaskState) #Ongoing Tasks
            ResourceUsage = zeros(Int64,size(ARU,1),TypeNo,MaxProjectNO,maxtask)
            for n = 1 : size(ARU,1)
                ResourceUsage[n,:,:,:] = PositiveTaskCode.*ARU[n,:,:,:]
            end #Resource usage of ongoing tasks
            PRU = sum(sum(sum(ResourceUsage,dims=1),dims=4),dims=3)[1,:,1,1] #state resource usage
            PT = zeros(Int64,TypeNo) #processed time of project types
            taskcode = Task_Summary(STDur,PreTaskState)

            #processed time of project types calculation#########
            for j = 1:TypeNo, k = 1:MaxProjectNO,i = 1:maxtask
                if taskcode[j,k,i] == 0 #task completed
                    PT[j] += AMPTD[j,k,i] #max processed time assined.
                elseif taskcode[j,k,i] >0 #task on going or newly begun
                    PT[j] += AMPTD[j,k,i] + 1 - PreTaskState[j,k,i]
                end
            end
            ########################################
            X[Sim,1:Coef_no]=[PT;PRU] #independent variables
            #########################

            #Running simulations for an iteration :
            for t=1:SimDura
                DueDateState,PreTaskState,best_action,FreeResource,Profit= ADP_Simulation(coef,
                PreTaskState, DueDateState, FreeResource, STDur, PredecessorTasks, ARU, reward,
                Tardiness, DueDates, lambda, StocTask, AMPTD)
                if t==1 #DISCOUNTED profit
                    Sum_profit[Sim]+=Profit
                else
                    Sum_profit[Sim]+=DiscountFactor^(t-1)*Profit
                end
            end
            #########################################
        end

        #Q squares method using curve_fit #NOTE Manually select the number of p according to Coef_no.
        @. multimodel(x, p) = p[1]*x[:, 1]+p[2]*x[:, 2]+p[3]*x[:, 3]+p[4]*x[:, 4]+
        p[5]*x[:, 5]+p[6]*x[:, 6]+p[7]*x[:, 7]+p[8]*x[:, 8]+p[9]*x[:, 9]+p[10]*x[:, 10]#+
        #p[11]*x[:, 11]+p[12]*x[:, 12]+p[13]*x[:, 13]+p[14]*x[:, 14]+p[15]*x[:, 15]+
        #p[16]*x[:, 16]+p[17]*x[:, 17]+p[18]*x[:, 18]+p[19]*x[:, 19]+p[20]*x[:, 20]
        xdata = copy(X) # independent variables
        ydata = copy(Sum_profit) #dependent variable
        p0 = zeros(Float64,Coef_no) #Zeros is better than ones
        lb = fill(0.0,Coef_no)#[0.0,0.0,0.0,0.0]#zeros(Float64,2*TypeNo+1)
        #ub = [Inf,Inf, Inf, Inf, Inf]
        fit = curve_fit(multimodel, xdata, ydata, p0)#,lower=lb)
        coef_new = round.(copy(fit.param),digits=6) #Rounding
        #######################################################

        #Stepsize method##################################
        #NOTE #Powell suggest use ~~ iteration/10 for stepsize
        HStepsize = Iterations/10
        #HStepsize = 50# Harmonic Stepsize a in powell's book section 11.7
        stepsize=HStepsize/(HStepsize+Step-1) ### Harmonic stepsize is from warren powell's book.
        #########################################################

        ######## update the value of parameters
        coef=(1-stepsize).*coef.+stepsize.*coef_new
        coef= round.(coef,digits=6) #Rounding.
        Coefficients[Step,:] = coef
        ##############################
    end
    return Coefficients
end
function ADP_Simulation(coef,PreTaskState, DueDateState, FreeResource, STDur, PredecessorTasks, ARU,
    reward, Tardiness, DueDates, lambda, StocTask, AMPTD)
    #AMPTD is a error control purpose array, Not important
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    actions = falses(TypeNo,MaxProjectNO,maxtask)
    best_action =  zeros(Int8,TypeNo,MaxProjectNO,maxtask) # local best action

    #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    TaskCode = Task_Summary(STDur,PreTaskState)

    ##### Finding Ready to process tasks => actions = true
    actions = ReadyToProcessTasks(PredecessorTasks,ARU,TaskCode,FreeResource,actions)

    ###### Feasible actions based on resource availability, network control is done at ReadyToProcessTasks
    all_RPT =findall(a->a==true, actions) #this found all readyto process tasks
    Feasible_actions= [] #Feasible actions #CartesianIndex
    Resource_usage_of_action=[]#resouce usage collector.
    push!(Feasible_actions,[]) #do nothing action #CartesianIndex
    for N in combinations(all_RPT)# These are CartesianIndex
        RTest=zeros(Int16,size(ARU,1))  #resource requirments of all task will be active again
        MNew = zeros(Int8,TypeNo,MaxProjectNO,maxtask)
        for n in N #resource usage of the actions.
            RTest=RTest+ARU[:,n] #find resource usage of action N
        end
        #if the total active project required less resource then available
        if  sum(RTest .<= FreeResource) == size(FreeResource,1)
            push!(Feasible_actions,N)
        end
    end
    ######################################################################

    #Test each feasible action with a brute force algorithm!!!
    Action_States = zeros(Int8,size(Feasible_actions,1),TypeNo,MaxProjectNO,maxtask) ##Feasible actions
    Approximate = zeros(Float64,size(Feasible_actions,1))#approximate profit with r values from due date and task processing times
    x = 0
    MaxProfit = 0
    for N in Feasible_actions #for all feasible actions #These are action states.
        x +=1 #action number
        ####### Generate a feasible action (Test action) from action particles
        PostTaskCode = Task_Summary(STDur,PreTaskState)
        PositiveTaskCode = postive_task_summary(STDur,PreTaskState)
        for n in N #generates the action from action particles.
            Action_States[x,n] = 1
            PostTaskCode[n] = 1 #this activates the task with action.
            PositiveTaskCode[n] = 1 #this activates the task with action.
        end
        #################################
        PT = zeros(Int64, TypeNo)
        for j = 1:TypeNo, k = 1:MaxProjectNO, i = 1:maxtask
            if PostTaskCode[j,k,i] == 0 #task completed
                PT[j] += AMPTD[j,k,i] #max processed time assined.
            elseif PostTaskCode[j,k,i] > 0 #task on going or newly begun
                PT[j] += AMPTD[j,k,i] + 1 - PreTaskState[j,k,i]
            end
        end
        ResourceUsage = zeros(Int64,size(ARU,1),TypeNo,MaxProjectNO,maxtask)
        for n = 1 : size(ARU,1)
            ResourceUsage[n,:,:,:] = PositiveTaskCode.*ARU[n,:,:,:]
        end
        ############### Generate Post Decision state with a action
        for j = 1:TypeNo
            Approximate[x] += PT[j]*coef[j] + sum(sum(sum(ResourceUsage,dims=4),dims=3),dims=1)[1,j,1,1]*coef[j+TypeNo]
        end
    end
    #Best action selection by profit, if more action has same max profit, one selected by random.
    Max_profits = findall(a->a==findmax(Approximate)[1], Approximate) #finds location of maximum profits
    RA = rand(Max_profits) #Random selection of best action
    best_action = Action_States[RA,:,:,:] #selected best action
    MaxProfit = Approximate[RA] #profit of selected action
    ###################################

    #reduce used resources of the new action
    actionparticles =Feasible_actions[RA]#findall(a->a==1, best_action) #this found all readyto process tasks
    for actionparticle in actionparticles
        FreeResource = FreeResource .- ARU[:,actionparticle] #reduce used resources.
    end
    ##############################

    #STATE ITERATION
    old = copy(DueDateState) #ERROR CONTROL PURPOSE, NOT IMPORTANT
    oldpre = copy(PreTaskState) #ERROR CONTROL PURPOSE, NOT IMPORTANT
    DueDateState,PreTaskState,FreeResource,Profit,GB,GB,GB = state_iteration(STDur,
    ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
    best_action,lambda,StocTask,PredecessorTasks)
    #NOTE ERROR CONTROL
        for a = 1:size(DueDateState,1)
            #NOTE if completed project has due date
            if Profit == DueDateState[a] !=0 && all(PreTaskState[a,1,:].==0)
                println("completed project has due date")
                println("completion reward =",Profit)
                println("old due date =",old)
                println("new due date =",DueDateState)
                println("old state = ",oldpre)
                println("new state = ",PreTaskState)
                println("FreeResource = ",FreeResource)
                println("best action = ",best_action)
            end
            #NOTE if due date is more then is suppose to be
            if DueDateState[a] > DueDates[a]
                    println("due date is more then is suppose to be")
                    println("old due date =",old)
                    println("new due date =",DueDateState)
                    println("old state = ",oldpre)
                    println("new state = ",PreTaskState)
            end
        end
    ##############################
    return DueDateState,PreTaskState,best_action,FreeResource,Profit
end
####### End of ADP TRAINING ###############

#### shared functions #############
function Immediate_Expected_Reward(STDur,reward,Tardiness,DueDateState,PreTaskState,StocTask,PostTaskCode)
    TypeNo = size(PreTaskState,1)
    MaxProjectNO = size(PreTaskState,2)
    maxtask = size(PreTaskState,3)
    Profit = 0
    ExpectedFutureTaskState = copy(PreTaskState)
    for n in findall(a->a==1, PostTaskCode)#Active tasks
        if PreTaskState[n] <= 1+StocTask*2 #if task processed more or equal to min completion time
            ExpectedFutureTaskState[n] = -1 #task may completed
        end
    end

    for j = 1:TypeNo
        for i = 1:MaxProjectNO
            if (all(ExpectedFutureTaskState[j,i,:].<=0) && any(PreTaskState[j,i,:].!=0)) #project my competed.
                Prob = 1.0
                for n in findall(a->a==-1, ExpectedFutureTaskState)#expected completions
                    Prob = Prob*disp(PreTaskState[n],STDur[n[1],n[3]])
                end
                if DueDateState[j,i] != 0 #NO LATE PROJECT
                    Profit += (reward[j])*Prob  #Earning full reward
                else # LATE PROJECT
                    Profit += (reward[j]-Tardiness[j])*Prob #Earning punished reward
                end
            end
        end
    end
    return Profit
end
############

##############ADP Online decision Codess#########
function ADP(STDur,ARU,PreTaskState,DueDateState,FreeResource,PredecessorTasks,AMPTD,StocTask,coef,reward,Tardiness,lambda)
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    actions = falses(TypeNo,MaxProjectNO,maxtask)
    best_action =  zeros(Int8,TypeNo,MaxProjectNO,maxtask) # local best action
    #1 generate ready to process tasks
    #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    TaskCode = Task_Summary(STDur,PreTaskState)
    #######################
    ##### Finding Ready to process tasks => actions = true
    actions = ReadyToProcessTasks(PredecessorTasks,ARU,TaskCode,FreeResource,actions)
    #######################
    all_AP =findall(a->a==true, actions) #feasible action particles returns CartesianIndex
    FeasibleOrders= [] #Feasible task processing orders

    #Generating all feasible actions
    PSS = [] #for saving all possible action state spaces for Vt-1
    RT = [] #for saving all possible action state spaces for Vt-1 resource usages for testNOTE test puropose
    push!(PSS,best_action)#Adding do nothing to availble actions.
    for N in combinations(all_AP)
        #collect(combinations(all_AP))
        RTest=zeros(Int64,size(ARU,1))  #resource requirments of all task will be active again
        MNew = zeros(Int8,TypeNo,MaxProjectNO,maxtask)
        for n in N #resource usage of the actions.
            RTest=RTest.+ARU[:,n]
        end
        #if the total active project required less resource then available
        if  sum(RTest .<= FreeResource) == size(FreeResource,1)
            for n in N
                MNew[n]=1
            end
            push!(PSS,MNew)
        end
    end
    #####

    #ADP model to action generation #########
    Approximate = zeros(Float64,size(PSS,1))#approximate profit with q values from due date and task processing tim
    x = 0
    for test_action in PSS
        x +=1 #action number
        PT = zeros(Int64, TypeNo)
        #Generate post decision state
        PostTaskCode = copy(TaskCode)
        for n in findall(a->a==1, test_action)
            PostTaskCode[n] = 1
        end
        #####
        ### aproximate reward generation for all feasible actions.
        for j = 1:TypeNo
            for k = 1:MaxProjectNO
                #processed time of tasks
                for i = 1:maxtask
                    if PostTaskCode[j,k,i] == 0 #task completed
                        PT[j] += AMPTD[j,k,i] #max processed time assined.
                    elseif PostTaskCode[j,k,i] >0 #task on going or newly begun
                        PT[j] += AMPTD[j,k,i] + 1 - PreTaskState[j,k,i]
                    end
                end
            end
            ##########
            #Version 2
            ResourceUsage = zeros(Int64,size(ARU,1),TypeNo,MaxProjectNO,maxtask)
            for n = 1 : size(ARU,1)
                ResourceUsage[n,:,:,:] = PostTaskCode.*ARU[n,:,:,:]
            end
            Approximate[x] += PT[j]*coef[j]+ sum(sum(sum(ResourceUsage,dims=4),dims=3),dims=1)[1,j,1,1]*coef[j+TypeNo]
        end
    end
    ####################################
    #Best action selection by profit, if more action has same max profit, one selected by random.
    Max_profits = findall(a->a==findmax(Approximate)[1], Approximate) #finds location of maximum profits
    RA = rand(Max_profits) #Random selection of best action
    best_action = PSS[RA]#selected best action

    return best_action
end 
#####
