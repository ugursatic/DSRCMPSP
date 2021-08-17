

#RBA CODES
function RBA(STDur,ARU,PreTaskState,FreeResource,PredecessorTasks,AMPTD)
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
    RPT = count(actions)#this returns how many ready to process tasks are available
    #2 generate an action with priority rule.
    for num = 1:RPT
        #PRULE
        rhold=findall(a->a==maximum(AMPTD[actions.==true]), AMPTD) #find longest durations
        reference = []
        for ref in rhold
            if actions[ref] == true #this fixes the wrong references of findall (like un active reference)
                push!(reference,ref)
            end
        end
        Random_longest = rand(reference) # Randon Longest action selection if more than one same size action.
        if sum(ARU[:,Random_longest] .<= FreeResource) == size(FreeResource,1)
            #enough resource available
            best_action[Random_longest] = 1 #selects the actions for random longest task
            FreeResource = FreeResource .- ARU[:,Random_longest] #reduce used resources
        end
            actions[Random_longest] = false # assures that task con not be selected again.
    end
    return best_action
end #
#####
