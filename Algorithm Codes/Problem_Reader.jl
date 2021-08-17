using Gtk #to open pick a file dialog.
using ZipFile

function PROGEN_MAX(STC)
    MPTD,MPRU,PredecessorTasks,Resource,reward, PDD, Tardiness, arrival = PROGEN_MAX_READER()
    TypeNo = size(MPTD,1)
    EC = STC#Maximum Late completion period than expected
    LC = STC#Maximum Late completion period than expected
    PinType = ones(Int8,TypeNo) #Project no in a type
    maxtask=size(MPTD,2) #maximum number of task in each type. WARNING I fixed this to my old problems
    MaxProjectNO = maximum(PinType)
    NoResource = size(Resource,1)

    ###### Project reward
        reward2 = sum(reward,dims=2)
        reward = copy(reward2) #zeros(Int8,TypeNo) #
    ######

    ###### Stochastic Task Duration
        STDur = MPTD .+ LC #For adaptation of old code
        AMPTD = zeros(Int16,TypeNo, MaxProjectNO,maxtask) # All durations for all projects
        for i = 1: MaxProjectNO
            AMPTD[:,i,:] = STDur[:,:] #for all project task durations
        end
    ######

    ###### Task Resource consumption
        ARU = zeros(Int8,NoResource,TypeNo,MaxProjectNO,maxtask) # All resource usages for all projects
        for i = 1: MaxProjectNO
            ARU[:,:,i,:] = MPRU[:,:,:]
        end
    ######
    return PredecessorTasks, STDur, AMPTD, MPRU, ARU, Resource, reward, PDD, Tardiness, arrival
end

function findfile(dir, name)
    for f in dir.files
        if f.name == name
            return f
        end
    end
    nothing
end #open a file
function successor_to_prodecessors(Ptype_successors,TypeNo,maxtask)
    PredecessorTasks = Array{Any}(undef,TypeNo,maxtask)
    for j=1:TypeNo
        aTasks = Array{Any}(undef,maxtask)
        for i=1:maxtask
            PredecessorTasks[j,i] = 0
        end
        for i=1:maxtask
            for m in Ptype_successors[j][i]
                if m != 0
                    if PredecessorTasks[j,m] == 0
                        PredecessorTasks[j,m] = i
                    else
                        hold = copy(PredecessorTasks[j,m])
                        PredecessorTasks[j,m] = vcat(hold,i)
                    end
                end
            end
        end
    end
    return PredecessorTasks
end #convert successor ;ost to predecessor list
function PROGEN_MAX_READER()
    ################################## MPSPLIB READER ####################################
    ZIPfile =open_dialog("Pick a file", GtkNullContainer(), ("*.zip",))
    Files = ZipFile.Reader(ZIPfile)
    mainfile = findfile(Files,"my_file.txt")
    lines = readlines(mainfile) #reads as line #Files.files[4]
    ##############Multi Project problem informations. ###############
    TypeNo =    parse(Int64,split(lines[1], "\t")[2])
    reward =    parse.(Int, split(lines[2], "\t")[2:TypeNo+1])
    PDD =       zeros(Int64,TypeNo)
    OS = parse.(Float64, split(lines[3], "\t")[2:TypeNo+1])
    Tardiness = parse.(Int, split(lines[4], "\t")[2:TypeNo+1])
    NoResource = parse(Int64,split(lines[5], "\t")[2])
    Resources = zeros(Int64,NoResource)#parse.(Int, split(lines[6], "\t")[2:NoResource+1])
    ReadProject = Array{Any}(undef,TypeNo)
    arrival = zeros(Int8,TypeNo) #We dont have this in this problem
    for j = 1 : TypeNo
        ReadProject[j] = findfile(Files, lines[j+7])
    end
    ###############

    ##### \/ Project details \/ ####
    Ptype_successors = Array{Any}(undef,TypeNo)#[j][i][m]
    Ptype_P_times = Array{Any}(undef,TypeNo)#[j][i]
    Ptype_Rusage = Array{Any}(undef,TypeNo)# [j][i,r]
    n=1
    maxtask = 0
    lines = 0
    for p in ReadProject #this reads project files
        Hold_p = readlines(p) #reads as line
        if String[]!= Hold_p
            lines = Hold_p
        else
        #lines = readlines(p) #reads as line
        end
        InfoHold = split(lines[1], "\t")
        Tasks = parse(Int64,InfoHold[1])#number of tasks
        Project_successors = Array{Any}(undef,Tasks) #hold successor of a project
        if maxtask < Tasks
            maxtask = Tasks #max task update
        end

        for i=1 : Tasks #No start dummy
            T_info =split(lines[i+2], "\t")
            #T_info[1] #task no
            #T_info[2] #modes
            ns = parse(Int64,T_info[3])  #number of successors
            successors = zeros(Int8,ns) #hols successor of a task
            for sc = 1 : ns #for each successors
                if parse(Int64,T_info[3+sc]) != Tasks+1
                    successors[sc] = parse(Int64,T_info[3+sc]) #successors
                end
            end
            Project_successors[i] = successors #[][] variable
        end
        Ptype_successors[n] = Project_successors # [][][] array, 3 dimension. typeno, maxtask, predeccsor
        Rusage = zeros(Int64,Tasks,NoResource) #R usages of a project
        P_times = zeros(Int64,Tasks) #processing times of a project
        for i=5+Tasks :4+Tasks*2 #No start dummy
            T_info =split(lines[i], "\t")
            #T_info[1] ##task no
            #T_info[2] #modes
            P_times[i-(4+Tasks)] = parse(Int64,T_info[3]) #duration
            for r = 1:NoResource
                Rusage[i-(4+Tasks),r] = parse(Int64,T_info[3+r])
            end
        end
        #R_info =parse.(Int, split(lines[6+Tasks*2], "\t")) #resource amounts for single p problem
        Ptype_Rusage[n] =Rusage
        Ptype_P_times[n] =P_times
        n+=1
        Resources +=  trunc.(Int16, round.(parse.(Int, split(lines[6+Tasks*2], "\t")).*((50-(4*TypeNo))/100)))#avaiable resources.
    end

    PredecessorTasks = successor_to_prodecessors(Ptype_successors,TypeNo,maxtask)
    MPRU=zeros(Int16,NoResource,TypeNo,maxtask) #Resource usage
    MPTD = zeros(Int16,TypeNo,maxtask) # All durations for all projects
    for j = 1:TypeNo
        RR = zeros(Float16,NoResource,TypeNo)
        for i = 1:maxtask
            MPTD[j,i] = Ptype_P_times[j][i]
            for r = 1:NoResource
                MPRU[r,j,i] = Ptype_Rusage[j][i,r]
                RR[r,j] += MPRU[r,j,i]*MPTD[j,i]
            end
        end

        horizon=sum(MPTD[j,:])
        arbitrary_factor = 1.5
        PDD[j]= trunc(Int16, round(((1-OS[j]) * max( mean(RR[:,j]./Resources)*TypeNo, maximum(MPTD[j,:]) ) +
        OS[j] * max( horizon , mean(RR[:,j]./Resources)*TypeNo) )*arbitrary_factor) )
    end
    #### Resource amount is alwasy higher than max required.
    for r = 1:NoResource
        Resources[r] = max(Resources[r],maximum(MPRU[r,:,:]))
    end
    ####
    return MPTD,MPRU,PredecessorTasks,Resources,reward, PDD, Tardiness, arrival
    ################################## MPSPLIB READER ####################################
end
function writefile()
    open("my_file.txt", "w") do io
           write(io,
           "TypeNo\t2\r\n"*
           "reward\t3\t10\r\n"*
           "PDD\t8\t5\r\n"*
           "Tardiness\t1\t9\r\n"*
           "NoResource\t4\r\n"*
           "Resources\t30\t35\t40\t45\r\n"*
           "files\r\n"*
           "projects/PSP5t2P4R1.sch\r\n"*
           "projects/PSP5t2P4R2.sch\r\n");
       end
       lines = readlines("my_file.txt")
end
