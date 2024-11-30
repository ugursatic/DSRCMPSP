########ADP CODE############3


function ADP_Training(PreTaskState,DueDateState,FreeResource,predecessor,taskDuration,AMPTD,ARU,
    maxarrivals,arrivalprobs,reward,DueDates,Tardiness,StocTask,DiscountFactor,
    Simulation,PERIODS,Iterations,randTaskComp,randPrArv,Features_no,Mdl)

    ###test variables
    #DS =copy(DueDateState)
    #PTs =copy(PreTaskState)
    #FRR =copy(FreeResource
    ########################333
    #Features_no = 3 #WARNING this is the number of feature I used
    #act = [] #action ? I forgot
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    q0 = 0.0 #NOTE I DONT HAVE THIS VALUE
    Coef_no = TypeNo*Features_no #How many coefficient I have
    q = zeros(Float64,Coef_no)
    Q = zeros(Float64,Iterations,Coef_no)
    Q0_all = zeros(Float64,Iterations) #Q_0 value, currently not used
    TestProfit = zeros(Float64,Iterations,Simulation)
    #Meanprofit = zeros(Float64,Iterations) #I forgot the purpose
    #MX = zeros(Float64,Iterations,4) #I forgot the purpose
    ##KESTEN's Stepsize Rule
    Kesten_cond = 0
    Kesten = 0

    for Step = 1:Iterations
        println("Step = ",Step)
        Sum_profit = zeros(Float64,Simulation) #discounted profit
        #UP = zeros(Float64,Simulation) # Un discounted profit
        ##### Iterations
        X=zeros(Simulation,Coef_no)
        #Testing=zeros(Simulation,Coef_no)
        TPRU = zeros(Int64,TypeNo) #Total project resource usage it
        PDSA = zeros(Int64,TypeNo) #number of idle days since arrival.
        ######NOTE TEST PURPOSE
        #taskstate_holder = zeros(Int8,PERIODS,TypeNo*MaxProjectNO*maxtask)
        #DueDateState_holder = zeros(Int16,PERIODS,TypeNo*MaxProjectNO) #No profit test purpose
        #action_holder =zeros(Int8,PERIODS,TypeNo*MaxProjectNO*maxtask) #No profit test purpose
        #FreeResource_holder = zeros(Int8,PERIODS,size(FreeResource,1)) #No profit test purpose
        #Profit_holder = zeros(Float64,PERIODS)
        #################

        for Sim = 1:Simulation
            ###### PRE-Simulation variables ###############################################################################################
            ### Feature 2 ### Current resource usage of a project type ### SUM #####
            Pre_CPRU = zeros(Int64,TypeNo)
            if Mdl == 1 || Mdl == 5 || Mdl == 6 || Mdl == 9
                PositiveTaskCode = postive_task_summary(taskDuration,PreTaskState) # Generates a matrix that processing tasks are 1 and idle and completed tasks are 0
                ResourceUsage = zeros(Int64,size(ARU,1),TypeNo,MaxProjectNO,maxtask) #a array to store resource usage of pre-decision state.
                for n = 1 : size(ARU,1)
                    ResourceUsage[n,:,:,:] = PositiveTaskCode.*ARU[n,:,:,:]
                end
                Pre_CPRU = sum(sum(sum(ResourceUsage,dims=1),dims=4),dims=3)[1,:,1,1] #pre-decision state resorge usage
            end
            ############################################################################

            ### Feature 2 ### Sum of prosessed times of a project ######
            Pre_PT = zeros(Int64,TypeNo) #processed time in the pre-decision state
            Pre_FERPT = zeros(Int64,TypeNo) #Sum of remaining processing time of a project in the pre-decision state
            #Pre_TERRN = zeros(Int64,TypeNo) #Total expected future required resource number in the pre-decision state
            for j = 1:TypeNo, k = 1:MaxProjectNO,i = 1:maxtask
                taskcode = Task_Summary(taskDuration,PreTaskState)  #Generates a matrix that processing tasks are 1,  idle tasks are -1,  and completed tasks are 0
                if taskcode[j,k,i] == 0 #task completed
                    if Mdl == 1 || Mdl == 2 || Mdl == 3 || Mdl == 6 || Mdl == 7 || Mdl == 8
                        Pre_PT[j] += AMPTD[j,k,i] #!NOTE max processed time assined.
                    end
                elseif taskcode[j,k,i] >0 #task on going or newly begun
                    if Mdl == 1 || Mdl == 2 || Mdl == 3 || Mdl == 6 || Mdl == 7 || Mdl == 8
                        Pre_PT[j] += AMPTD[j,k,i] + 1 - PreTaskState[j,k,i]
                    end
                    if Mdl == 2 || Mdl == 4 || Mdl == 5 || Mdl == 6 || Mdl == 7 || Mdl == 11
                        Pre_FERPT[j] +=  PreTaskState[j,k,i] -1 #remaining time
                    end
                    #for n = 1 : size(ARU,1) #expected future resource requirment
                    #    Pre_TERRN[j] += (Pre_FERPT.*ARU[n,j,k,i])[1]
                    #end
                else
                    if Mdl == 2 || Mdl == 4 || Mdl == 5 || Mdl == 6 || Mdl == 7 || Mdl == 11
                        Pre_FERPT[j] += AMPTD[j,k,i] #max processed time assined.
                    end
                    #for n = 1 : size(ARU,1) #expected future resource requirment
                    #    Pre_TERRN[j] += (AMPTD[j,k,i].*ARU[n,j,k,i])[1]
                    #end
                end
            end

            ############################################################################

            ### Feature 3 ### Total resource used for a project type ######
            #INSTEAD USE TPRU
            #Pre_TPRU = TPRU #zeros(Int64,TypeNo) #Total resource used for a project type in the pre-decision state
            #for n = 1 : size(ARU,1)
            #    Pre_TPRU += sum(sum(Pre_PT.*ARU[n,:,:,:],dims=3),dims=1)[:,1,1] #!NOTE max processed time is used.
            #end !NOTE we do not need to calculate this we can use TRPU
            ############################################################################

            ### Feature 4 ### Free resources ######
            #Pre_FreeRes = sum(FreeResource)[1] #NOTE sum of all resource types
            ############################################################################

            ### Feature 5 ### Sum of remaining processing time of a project  ######
            #Pre_FERPT # Degined and calculated in feature 2.
            ############################################################################

            ### Feature 6 ### Total expected future required resource number ######
            #Pre_TERRN # Degined and calculated in feature 2.
            ############################################################################

            ### Feature 7 ### Number of passive days since project arrival ######
            #INSTEAD USE PDSA
            #Pre_PDSA = PDSA
            ############################################################################

            ### Feature 8 ### Potantial/Expected Future reward ######
            Pre_PEFR = zeros(Float64,TypeNo) #Potantial/Expected Future reward in the pre-decision state
            if Mdl == 2 || Mdl == 4 || Mdl == 5 || Mdl == 6 || Mdl == 7 || Mdl == 11
                for j = 1:TypeNo
                    if Pre_FERPT[j] > 0
                        if Pre_FERPT[j] > DueDateState[j,1]
                            Pre_PEFR[j] = (reward[j]-Tardiness[j])/Pre_FERPT[j]
                        else
                            Pre_PEFR[j] = reward[j]/Pre_FERPT[j]
                        end
                    end
                end
            end

            ##################################################################################################################
            if Mdl == 1
                X[Sim,1:Coef_no]=[Pre_PT;Pre_CPRU] #For Mdl 1. Tested working #old 7
            elseif Mdl == 2
                X[Sim,1:Coef_no]=[Pre_PT;Pre_PEFR] #For Mdl 2. Tested working bad results
            elseif Mdl == 3
                X[Sim,1:Coef_no]=[Pre_PT;TPRU] #For Mdl 3. Tested working
            elseif Mdl == 4
                X[Sim,1:Coef_no]=[TPRU;Pre_PEFR] #For Mdl 4.
            elseif Mdl == 5
                X[Sim,1:Coef_no]=[Pre_CPRU;Pre_PEFR] #For Mdl 5.
            elseif Mdl == 6
                X[Sim,1:Coef_no]=[Pre_PT;Pre_CPRU;Pre_PEFR] #For Mdl 6.
            elseif Mdl == 7
                X[Sim,1:Coef_no]=[Pre_PT;TPRU;Pre_PEFR] #For Mdl 7.
            elseif Mdl == 8
                X[Sim,1:Coef_no]=Pre_PT #For Mdl 8
            elseif Mdl == 9
                X[Sim,1:Coef_no]=Pre_CPRU #For Mdl 9.
            elseif Mdl == 10
                X[Sim,1:Coef_no]=TPRU #For Mdl 10.
            elseif Mdl == 11
                X[Sim,1:Coef_no]=Pre_PEFR #For Mdl 11.
            end
            #########################

            for t=1:PERIODS
                #taskstate_holder[t,:] = reshape(PreTaskState[:,1,:]',TypeNo*MaxProjectNO*maxtask) #  TEST PURPOSE
                #DueDateState_holder[t,:] = reshape(DueDateState[:,1],TypeNo*MaxProjectNO)   #  TEST PURPOSE
                #FreeResource_holder[t,:] = FreeResource  #  TEST PURPOSE
                DueDateState, PreTaskState, best_action, FreeResource, Profit, TPRU, PDSA =
                ADP_Periods(q, q0, PreTaskState, DueDateState, FreeResource, taskDuration, predecessor, ARU, reward,
                Tardiness, DueDates, arrivalprobs, StocTask, AMPTD, TPRU, PDSA,randTaskComp,randPrArv,Mdl)
                #action_holder[t,:] = reshape(best_action[:,1,:]',TypeNo*MaxProjectNO*maxtask)  #  TEST PURPOSE
                #Profit_holder[t] = Profit  #  TEST PURPOSE
                if t==1 #DISCOUNTED profit
                    #UP[Sim]+=Profit
                    Sum_profit[Sim]+=Profit
                else
                    #UP[Sim]+=Profit
                    Sum_profit[Sim]+=DiscountFactor^(t-1)*Profit
                end
            end
        end
        TestProfit[Step,:] = Sum_profit

        if sum(TestProfit[Step,:]) == 0
            println("NO Profit after all simulations in iteration ",Step)
            #Q_excel = zeros(Float64,PERIODS,Coef_no)
            #Q_excel[1,:] = reshape(q',Coef_no)
            #Excelscreen = hcat(taskstate_holder,DueDateState_holder,action_holder,FreeResource_holder,Profit_holder,Q_excel)
            #SimulationFlame = DataFrame(Excelscreen)
            #CSV.write("C:\\JuliaOutput\\NoProfitSim.csv", SimulationFlame)
        end
        ##############################################
        xdata = copy(X) # independent variables
        ydata = copy(Sum_profit) #dependent variable
        p0 = zeros(Float64,Coef_no) #Zeros is better than ones
        lb = fill(0.0,Coef_no)#[0.0,0.0,0.0,0.0]#zeros(Float64,2*TypeNo+1)
        #ub = [Inf,Inf, Inf, Inf, Inf]
                fit = []
                if Coef_no == 2
                    fit = curve_fit(Coef_no_2_multiModel, xdata, ydata, p0)
                elseif Coef_no == 3
                    fit = curve_fit(Coef_no_3_multiModel, xdata, ydata, p0)
                elseif Coef_no == 4
                    fit = curve_fit(Coef_no_4_multiModel, xdata, ydata, p0)
                elseif Coef_no == 5
                    fit = curve_fit(Coef_no_5_multiModel, xdata, ydata, p0)
                elseif Coef_no == 6
                    fit = curve_fit(Coef_no_6_multiModel, xdata, ydata, p0)
                elseif Coef_no == 8
                    fit = curve_fit(Coef_no_8_multiModel, xdata, ydata, p0)
                elseif Coef_no == 9
                    fit = curve_fit(Coef_no_9_multiModel, xdata, ydata, p0)
                elseif Coef_no == 10
                    fit = curve_fit(Coef_no_10_multiModel, xdata, ydata, p0)
                elseif Coef_no == 12
                    fit = curve_fit(Coef_no_12_multiModel, xdata, ydata, p0)
                elseif Coef_no == 15
                    fit = curve_fit(Coef_no_15_multiModel, xdata, ydata, p0)
                elseif Coef_no == 18
                    fit = curve_fit(Coef_no_18_multiModel, xdata, ydata, p0)
                elseif Coef_no == 20
                    fit = curve_fit(Coef_no_20_multiModel, xdata, ydata, p0)
                elseif Coef_no == 30
                    fit = curve_fit(Coef_no_30_multiModel, xdata, ydata, p0)
                end
        q_new = round.(copy(fit.param),digits=6) #Rounding as Peter requested.
        #println(X)
        #println(Sum_profit)
        #println(q_new)

        #Other solver
        #inner_optimizer = NewtonTrustRegion()
        #initials = zeros(Float64,Coef_no)
        #initials = [0.1 -0.1;-0.1 0.1;0.0 -0.1;-0.1 0.0;0.1 0.0;0.1  0.0]
        #lower = [0.0 -1000;-1000 0.0;-0.1 -1000;-1000 -0.1;0.0 -0.1;0.0 -0.1]
        #upper = [1000 0.0 ;0.0  1000;0.1  0.0 ;0.0   0.1;1000  0.1;1000  0.1]
        #regOpt = optimize(objective,lower,upper ,initials)
        #regOpt = optimize(objective, initials)
        #println("Optim =",Optim.minimizer(regOpt))
        #q_new = Optim.minimizer(regOpt) #WARNING BE CARAFUL WITH OTHER MdlS
        #q_new[2:Coef_no,:] = Optim.minimizer(regOpt)[2:Coef_no] #WARNING BE CARAFUL WITH OTHER MdlS
        #coefficients = lm(X,Sum_profit)
        #q_new = coefficients.pp.beta0 # base coefficient vector of length p
        HStepsize = Iterations/100
        #HStepsize = 50# Harmonic Stepsize a in powell's book section 11.7
        #NOTE #Powell suggest use ~~ iteration/10 for stepsize

        ##KESTEN's Stepsize Rule
        #=
        if sum(sum(X'.*q_new,dims=2),dims=2)[1,1]-Kesten_cond<0
            Kesten +=1
        end
        Kesten_cond = sum(sum(X'.*q_new,dims=2),dims=2)[1,1]
        if Step <= 2
            Kesten = Step
        end
        stepsize=HStepsize/(HStepsize+Kesten^Step-1) #Kesten Rule
        #################################
        =#
        #=
        #UGUR's Stepsize rule
        stepsize=1
        if sum(sum(X'.*q_new,dims=2),dims=2)[1,1]-Kesten_cond>0
            stepsize=1 #Ugur's rule
        else
            stepsize=HStepsize/(HStepsize+Step-1) #Kesten Rule
        end
        Kesten_cond = sum(sum(X'.*q_new,dims=2),dims=2)[1,1]
        =#
        ########

        #### HARMONIC STEPSIZE ################
        stepsize=HStepsize/(HStepsize+Step-1) ### Harmonic stepsize is from warren powell's book.
        ######## update the value of parameters
        #r0=(1-stepsize)*r0+stepsize*newr0
        #r=(1-stepsize1)*r+stepsize1*newr[2:2+3*numjobs]' ##other regressing method
        q=(1-stepsize).*q.+stepsize.*q_new
        q= round.(q,digits=6) #Rounding as Peter requested.
        #NOTE Updating r0
            #q0=stepsize*q0+(1-stepsize)*q_new[1,1]
            q0 = 0 #NOTE NO R0 in this Mdl
        #####
        Q[Step,:] = q
        Q0_all[Step] = q0
        #Meanprofit[Step] = mean(Sum_profit) #I forgot the purpose
        #MX[Step,1] = mean(X[:,1]) #I forgot the purpose
        #MX[Step,2] = mean(X[:,2]) #I forgot the purpose
        #MX[Step,3] = mean(X[:,3]) #I forgot the purpose
        #MX[Step,4] = mean(X[:,4]) #I forgot the purpose
        #sigma[Step] = stderror(fit)
        #Excelscreen1 = hcat(Sum_profit,X,Testing)
        #df3 = DataFrame(Excelscreen1)
        #CSV.write("C:\\JuliaOutput\\New_ADP_TESTT_iteration.csv", df3)
    end

    #println("q_0 = ",q0,"Q values = ",q)
    #######################
    ### Printing the policy and reward to EXCELL
    #Q_excel = Q#reshape(Q,Iterations,Coef_no*TypeNo) #NOTE this reshape only for excel.
    #Excelscreen = hcat(Meanprofit,MX,Q)
    #df1 = DataFrame(TestProfit,string.(1:Iterations))
    #df1 = DataFrame(hcat(TestProfit,Q),string.(1:Simulation+4))
    #CSV.write("C:\\JuliaOutput\\New_ADP_TEST.csv", df1)
    #println(Q0_all[100])
    return Q0_all, Q
end
function ADP_Periods(q,q0,PreTaskState, DueDateState, FreeResource, taskDuration, predecessor, ARU,
    reward, Tardiness, DueDates, arrivalprobs, StocTask, AMPTD,TPRU,PDSA,randTaskComp,randPrArv,Mdl)
    #AMPTD is a error control purpose array, Not important
    TypeNo,MaxProjectNO,maxtask = size(PreTaskState,1),size(PreTaskState,2),size(PreTaskState,3)
    actions = falses(TypeNo,MaxProjectNO,maxtask)
    best_action =  zeros(Int8,TypeNo,MaxProjectNO,maxtask) # local best action
    #### task condisition summary 0 is completed, 1 is ongoing, -1 is waiting
    TaskCode = Task_Summary(taskDuration,PreTaskState)
    ##### Finding Ready to process tasks => actions = true
    actions = ReadyToProcessTasks(predecessor,ARU,TaskCode,FreeResource,actions)
    ###### Feasible actions based on resource availability, network control is done at ReadyToProcessTasks
    all_RPT =findall(a->a==true, actions) #this found all readyto process tasks
    Feasible_actions= [] #Feasible actions #CartesianIndex

    push!(Feasible_actions,[]) #do nothing action #CartesianIndex


    ##### Total resource used for a project type ### Definition #####
    Resource_usage_of_action=[]#resouce usage collector.
    push!(Resource_usage_of_action,zeros(Int16,size(ARU,1))) #Do nothing action

    ##################################################

    for N in combinations(all_RPT)# These are CartesianIndex
        RTest=zeros(Int16,size(ARU,1))  #resource requirments of all task will be active again
        MNew = zeros(Int8,TypeNo,MaxProjectNO,maxtask)
        for n in N #resource usage of the actions.
            RTest=RTest+ARU[:,n] #find resource usage of action N
        end
        #if the total active project required less resource then available
        if  sum(RTest .<= FreeResource) == size(FreeResource,1)
            push!(Feasible_actions,N)
            push!(Resource_usage_of_action,RTest)
        end
    end
    #######################
    ##### For each feasible action, found the post decision state and due date. use this is Mdl.
    # We calculate post decision states, due date for each action
    Action_States = zeros(Int8,size(Feasible_actions,1),TypeNo,MaxProjectNO,maxtask) ##Feasible actions
    Approximate = zeros(Float64,size(Feasible_actions,1))#approximate profit with r values from due date and task processing times
    Temp_PDSA =zeros(Int64, size(Feasible_actions,1), TypeNo) #Number of passive days since project arrival
    Temp_TPRU= zeros(Int64, size(Feasible_actions,1), TypeNo) #Total resource usage of a project type.
    x = 0
    MaxProfit = 0
    #println("state = ",PreTaskState[:,1,:])
    for N in Feasible_actions #for all feasible actions #These are action states.
        x +=1 #action number
        ####### Generate a feasible action (Test action) from action particles
        PostTaskCode = Task_Summary(taskDuration,PreTaskState)
        PositiveTaskCode = postive_task_summary(taskDuration,PreTaskState)
        for n in N #generates the action from action particles.
            Action_States[x,n] = 1
            PostTaskCode[n] = 1 #this activates the task with action.
            PositiveTaskCode[n] = 1 #this activates the task with action.
        end
        test_action = Action_States[x,:,:,:]
        #################################

        ###### Sum of processed times of a project ######
        PT = zeros(Int64, TypeNo) #Sum of processed time of a project
        FERPT = zeros(Int64, TypeNo)#Sum of remaining processing time of a project
        #TERRN = zeros(Int64, TypeNo) #Total expected future required resource number
        #Temp_PDSA[x,:] = copy(PDSA) #Number of passive days since project arrival
        #For_PDSA = trues(TypeNo) #check if all task are vaiting

        for j = 1:TypeNo, k = 1:MaxProjectNO, i = 1:maxtask
            if PostTaskCode[j,k,i] == 0 #task completed
                if Mdl == 1 || Mdl == 2 || Mdl == 3 || Mdl == 6 || Mdl == 7 || Mdl == 8
                    PT[j] += AMPTD[j,k,i] #max processed time assined.
                end
            elseif PostTaskCode[j,k,i] > 0 #task on going or newly begun
                if Mdl == 1 || Mdl == 2 || Mdl == 3 || Mdl == 6 || Mdl == 7 || Mdl == 8
                    PT[j] += AMPTD[j,k,i] + 1 - PreTaskState[j,k,i] #processed time
                end
                if Mdl == 2 || Mdl == 4 || Mdl == 5 || Mdl == 6 || Mdl == 7 || Mdl == 11
                    FERPT[j] +=  PreTaskState[j,k,i] -1 #remaining time
                end
                #for n = 1 : size(ARU,1) #expected future resource requirment
                #    TERRN[j] += (FERPT.*ARU[n,j,k,i])[1]
                #end
                #For_PDSA[j] = 0 #at least one task is ongoing.
            else
                if Mdl == 2 || Mdl == 4 || Mdl == 5 || Mdl == 6 || Mdl == 7 || Mdl == 11
                    FERPT[j] += AMPTD[j,k,i] #max processed time assined.
                end
                #for n = 1 : size(ARU,1) #expected future resource requirment
                #    TERRN[j] += (AMPTD[j,k,i].*ARU[n,j,k,i])[1]
                #end
            end
        end

        ############################################################

        ##### Current resource usage of a project #####
        ResourceUsage = zeros(Int64,size(ARU,1),TypeNo,MaxProjectNO,maxtask)

        ##### Current resource usage of an action #####
        Action_ResourceUsage = zeros(Int64,size(ARU,1),TypeNo,MaxProjectNO,maxtask)

        for n = 1 : size(ARU,1)
            ResourceUsage[n,:,:,:] = PositiveTaskCode.*ARU[n,:,:,:]
            Action_ResourceUsage[n,:,:,:] = Action_States[x,:,:,:].*ARU[n,:,:,:]
        end
        ########################################################
        if Mdl == 3 || Mdl == 4 || Mdl == 7 || Mdl == 10
            Temp_TPRU[x,:] = copy(TPRU) #Total resource usage of a project type.
        end
        PEFR = zeros(Float64,TypeNo)
        CPRU = zeros(Int64,TypeNo)
        ############### Generate Post Decision state with a action #################################
        for j = 1:TypeNo
            ##### Current resource usage of a project type ### SUM #####
            if Mdl == 1 || Mdl == 5 || Mdl == 6 || Mdl == 9
                CPRU[j] = sum(sum(sum(ResourceUsage,dims=4),dims=3),dims=1)[1,j,1,1]
            end
            ##### Sum of prosessed times of a project ######
            #PT[j]
            #println("PT[",j,"] = ",PT[j])

            ##### Total resource used for a project type ### SUM #####
            if Mdl == 3 || Mdl == 4 || Mdl == 7 || Mdl == 10
                Temp_TPRU[x,j] += sum(sum(sum(Action_ResourceUsage,dims=4),dims=3),dims=1)[1,j,1,1]
            end

            ##### Action resource used for a project type ### SUM #####
            #APRU[x,j] += sum(sum(sum(Action_ResourceUsage,dims=4),dims=3),dims=1)[1,j,1,1]

            ##### Free resources ### SUM #####
            #FreeRes = sum(FreeResource)[1] - sum(Resource_usage_of_action[x,:])[1]
            #println("FreeRes = ",FreeRes)

            #####Sum of remaining processing time of a project ######
            #FERPT[j]
            #println("FERPT[",j,"] = ",FERPT[j])

            #####Total expected future required resource number  ######
            #TERRN[j]
            #println("TERRN[",j,"] = ",TERRN[j])

            ##### Number of passive days since project arrival ######
            #if For_PDSA == 1 #if there is no ongoing task. Its value 0 if a task is ongoing
            #    Temp_PDSA[x,j] += 1 #Number of passive days since project arrival
            #end
            #Temp_PDSA[x,j]
            #println("Temp_PDSA[",x,",",j,"]",j,"] = ",Temp_PDSA[x,j])

            ##### Potantial/Expected Future reward #######
            if Mdl == 2 || Mdl == 4 || Mdl == 5 || Mdl == 6 || Mdl == 7 || Mdl == 11
                if FERPT[j] > 0
                    if FERPT[j] > DueDateState[j,1]
                        PEFR[j] = (reward[j]-Tardiness[j])/FERPT[j]
                    else
                        PEFR[j] = reward[j]/FERPT[j]
                    end
                end
            end
            ################################################

            if Mdl == 1
                #Mdl 1 Sum of prosessed times of a project and Current resource usage of a project type
                Approximate[x] += PT[j]*q[j] + CPRU[j]*q[j+TypeNo]
            elseif Mdl == 2
                #Mdl 2 Sum of prosessed times of a project and Potantial/Expected Future reward
                Approximate[x] += PT[j]*q[j] + PEFR[j]*q[j+TypeNo]
            elseif Mdl == 3
                #Mdl 3
                Approximate[x] += PT[j]*q[j] + Temp_TPRU[x,j]*q[j+TypeNo]
            elseif Mdl == 4
                #Mdl 4
                Approximate[x] += Temp_TPRU[x,j]*q[j] + PEFR[j]*q[j+TypeNo]
            elseif Mdl == 5
                #Mdl 5
                Approximate[x] += CPRU[j]*q[j] + PEFR[j]*q[j+TypeNo]
            elseif Mdl == 6
                #Mdl 6
                Approximate[x] += PT[j]*q[j] + CPRU[j]*q[j+TypeNo] + PEFR[j]*q[j+2*TypeNo]
            elseif Mdl == 7
                #Mdl 7
                Approximate[x] += PT[j]*q[j] + Temp_TPRU[x,j]*q[j+TypeNo] + PEFR[j]*q[j+2*TypeNo]
            elseif Mdl == 8
                #Mdl 8
                Approximate[x] += PT[j]*q[j]
            elseif Mdl == 9
                #Mdl 9
                Approximate[x] += CPRU[j]*q[j]
            elseif Mdl == 10
                #Mdl 10
                Approximate[x] += Temp_TPRU[x,j]*q[j]
            elseif Mdl == 11
                #Mdl 11
                Approximate[x] += PEFR[j]*q[j]
            end
        end
        #Imme_reward = Immediate_Expected_Reward(taskDuration,reward,Tardiness,DueDateState,PreTaskState,StocTask,PostTaskCode)
        #Approximate[x] += q0 + Imme_reward
    end
    #Best action selection by profit, if more action has same max profit, one selected by random.
    Max_profits = findall(a->a==findmax(Approximate)[1], Approximate) #finds location of maximum profits
    RA = Max_profits[size(Max_profits,1)] #rand(Max_profits) #Random selection of best action
    best_action = Action_States[RA,:,:,:] #selected best action
    MaxProfit = Approximate[RA] #profit of selected action
    if Mdl == 3 || Mdl == 4 || Mdl == 7 || Mdl == 10
        TPRU = Temp_TPRU[RA,:] # Total oroject resource usage since arrival.
    end
    PDSA = Temp_PDSA[RA,:] # return value for number of passive days since arrival
    ###################################

    if q0 != true #if q0=ture its simulation, otherwise its training
        #println("action = ",best_action[:,1,:])
        #println(Approximate)#println(Action_States[:,:,1,:])#println(best_action)
        #NOTE ERROR CONTROL for an action, if it is for ongoing or completed task
        actionparticles =Feasible_actions[RA]#findall(a->a==1, best_action) #this found all readyto process tasks
        for actionparticle in actionparticles
            FreeResource = FreeResource .- ARU[:,actionparticle] #reduce used resources !NOTE MULTI RESOURCE support
            if PreTaskState[actionparticle] !=  AMPTD[actionparticle]
                println("ERROR WRONG ACTION AND TASK COMBINATION")
                println("given state =",PreTaskState)
                println("selected best action =",best_action)
            end
        end
        #                     STATE ITERATION
        old = copy(DueDateState) #ERROR CONTROL PURPOSE, NOT IMPORTANT
        oldpre = copy(PreTaskState) #ERROR CONTROL PURPOSE, NOT IMPORTANT
        DueDateState,PreTaskState,FreeResource,Profit,NewArrivals,GB,GB = state_iteration(taskDuration,
        ARU,reward,Tardiness,DueDates,DueDateState,PreTaskState,FreeResource,
        best_action,arrivalprobs,StocTask,predecessor,randTaskComp,randPrArv)


        ##### reseting some value holders for NEW project arrival ####
        if Mdl == 3 || Mdl == 4 || Mdl == 7 || Mdl == 10
        for j=1:TypeNo
            if NewArrivals[j] > 0 #New project arrival
                TPRU[j] = 0 # Total used resources since new project arrival.
                #PDSA[j] = 0 # passive days since new project arrival
            end
        end
        end
        #################################################################


        #NOTE ERROR CONTROL
        for a = 1:size(DueDateState,1)
            #NOTE completed project has due date
            if Profit == DueDateState[a] !=0 && all(PreTaskState[a,1,:].==0)
                #println("Step",Step," = ","Sim",Sim)
                println("completed project has due date")
                #println("old projects =",oldp)
                println("completion reward =",Profit)
                #println("old projects =",oldp)
                #println("new projects =",PreState)
                println("old due date =",old)
                println("new due date =",DueDateState)
                println("old state = ",oldpre)
                println("new state = ",PreTaskState)
                println("FreeResource = ",FreeResource)
                println("best action = ",best_action)
            end
            #NOTE due date is more then is suppose to be
            if DueDateState[a] > DueDates[a]
                    println("due date is more then is suppose to be")
                    println("old due date =",old)
                    println("new due date =",DueDateState)
                    println("old state = ",oldpre)
                    println("new state = ",PreTaskState)
            end
        end
    else
        Profit = 0    #For test simulation only
    end
    ##############################
    #println("reward = ",Profit)
    return DueDateState,PreTaskState,best_action,FreeResource,Profit, TPRU, PDSA
end #Thested working fine, Need test with multiple resource.
####### ADP TRAINING ###############

#### shared functions #############
function Immediate_Expected_Reward(taskDuration,reward,Tardiness,DueDateState,PreTaskState,StocTask,PostTaskCode)
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
                    Prob = Prob*disp(PreTaskState[n],taskDuration[n[1],n[3]])
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
function Coef_no_2_multiModel(x, p)
    x_1, x_2 = x[:,1], x[:,2]
    a_1, a_2= p[1], p[2]
    @. a_1*x_1+a_2*x_2
end
function Coef_no_3_multiModel(x, p)
    x_1, x_2, x_3 = x[:,1], x[:,2],x[:,3]
    a_1, a_2, a_3 = p[1], p[2],p[3]
    @. a_1*x_1+a_2*x_2+a_3*x_3
end
function Coef_no_4_multiModel(x, p)
    x_1, x_2, x_3, x_4 = x[:,1], x[:,2],x[:,3],x[:,4]
    a_1, a_2, a_3, a_4= p[1], p[2],p[3],p[4]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4
end
function Coef_no_5_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5
end
function Coef_no_6_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6 =  x[:,6]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6 =  p[6]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6
end
function Coef_no_8_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8=  x[:,6], x[:,7],x[:,8]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8=  p[6], p[7],p[8]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8
end
function Coef_no_9_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9 =  x[:,6], x[:,7],x[:,8],x[:,9]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9 =  p[6], p[7],p[8],p[9]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9
end
function Coef_no_10_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9, x_10 =  x[:,6], x[:,7],x[:,8],x[:,9],x[:,10]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9, a_10 =  p[6], p[7],p[8],p[9],p[10]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9+a_10*x_10
end
function Coef_no_12_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9, x_10 =  x[:,6], x[:,7],x[:,8],x[:,9],x[:,10]
    x_11, x_12 = x[:,11], x[:,12]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9, a_10 =  p[6], p[7],p[8],p[9],p[10]
    a_11, a_12= p[11], p[12]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9+a_10*x_10+
    a_11*x_11+a_12*x_12
end
function Coef_no_15_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9, x_10 =  x[:,6], x[:,7],x[:,8],x[:,9],x[:,10]
    x_11, x_12, x_13, x_14, x_15 = x[:,11], x[:,12],x[:,13],x[:,14],x[:,15]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9, a_10 =  p[6], p[7],p[8],p[9],p[10]
    a_11, a_12, a_13, a_14, a_15 = p[11], p[12],p[13],p[14],p[15]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9+a_10*x_10+
    a_11*x_11+a_12*x_12+a_13*x_13+a_14*x_14+a_15*x_15
end
function Coef_no_18_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9, x_10 =  x[:,6], x[:,7],x[:,8],x[:,9],x[:,10]
    x_11, x_12, x_13, x_14, x_15 = x[:,11], x[:,12],x[:,13],x[:,14],x[:,15]
    x_16, x_17, x_18 =  x[:,16], x[:,17],x[:,18]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9, a_10 =  p[6], p[7],p[8],p[9],p[10]
    a_11, a_12, a_13, a_14, a_15 = p[11], p[12],p[13],p[14],p[15]
    a_16, a_17, a_18=  p[16], p[17],p[18]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9+a_10*x_10+
    a_11*x_11+a_12*x_12+a_13*x_13+a_14*x_14+a_15*x_15+a_16*x_16+a_17*x_17+a_18*x_18
end
function Coef_no_20_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9, x_10 =  x[:,6], x[:,7],x[:,8],x[:,9],x[:,10]
    x_11, x_12, x_13, x_14, x_15 = x[:,11], x[:,12],x[:,13],x[:,14],x[:,15]
    x_16, x_17, x_18, x_19, x_20 =  x[:,16], x[:,17],x[:,18],x[:,19],x[:,20]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9, a_10 =  p[6], p[7],p[8],p[9],p[10]
    a_11, a_12, a_13, a_14, a_15 = p[11], p[12],p[13],p[14],p[15]
    a_16, a_17, a_18, a_19, a_20 =  p[16], p[17],p[18],p[19],p[20]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9+a_10*x_10+
    a_11*x_11+a_12*x_12+a_13*x_13+a_14*x_14+a_15*x_15+a_16*x_16+a_17*x_17+a_18*x_18+a_19*x_19+a_20*x_20
end
function Coef_no_30_multiModel(x, p)
    x_1, x_2, x_3, x_4, x_5 = x[:,1], x[:,2],x[:,3],x[:,4],x[:,5]
    x_6, x_7, x_8, x_9, x_10 =  x[:,6], x[:,7],x[:,8],x[:,9],x[:,10]
    x_11, x_12, x_13, x_14, x_15 = x[:,11], x[:,12],x[:,13],x[:,14],x[:,15]
    x_16, x_17, x_18, x_19, x_20 =  x[:,16], x[:,17],x[:,18],x[:,19],x[:,20]
    x_21, x_22, x_23, x_24, x_25 = x[:,21], x[:,22],x[:,23],x[:,24],x[:,25]
    x_26, x_27, x_28, x_29, x_30 =  x[:,26], x[:,27],x[:,28],x[:,29],x[:,30]
    a_1, a_2, a_3, a_4, a_5 = p[1], p[2],p[3],p[4],p[5]
    a_6, a_7, a_8, a_9, a_10 =  p[6], p[7],p[8],p[9],p[10]
    a_11, a_12, a_13, a_14, a_15 = p[11], p[12],p[13],p[14],p[15]
    a_16, a_17, a_18, a_19, a_20 =  p[16], p[17],p[18],p[19],p[20]
    a_21, a_22, a_23, a_24, a_25 = p[21], p[22],p[23],p[24],p[25]
    a_26, a_27, a_28, a_29, a_30 =  p[26], p[27],p[28],p[29],p[30]
    @. a_1*x_1+a_2*x_2+a_3*x_3+a_4*x_4+a_5*x_5+a_6*x_6+a_7*x_7+a_8*x_8+a_9*x_9+a_10*x_10+
    a_11*x_11+a_12*x_12+a_13*x_13+a_14*x_14+a_15*x_15+a_16*x_16+a_17*x_17+a_18*x_18+a_19*x_19+a_20*x_20+
    a_21*x_21+a_22*x_22+a_23*x_23+a_24*x_24+a_25*x_25+a_26*x_26+a_27*x_27+a_28*x_28+a_29*x_29+a_30*x_30
end
