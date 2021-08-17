using Gtk #to open pick a file dialog.
using ZipFile

function MPSPLIB(STC)
    MPTD,MPRU,PredecessorTasks,Resource,reward, PDD, Tardiness, arrival = MPSPLIB_READER()
    TypeNo = size(MPTD,1)
    #STC = 0 #How many early or late completion we have.
    EC = STC#Maximum Late completion period than expected
    LC = STC#Maximum Late completion period than expected
    PinType = ones(Int8,TypeNo) #Project no in a type
    #reward = zeros(Int8,TypeNo)  #Project reward of a type
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
        ARU = zeros(Int16,NoResource,TypeNo,MaxProjectNO,maxtask) # All resource usages for all projects
        for i = 1: MaxProjectNO
            ARU[:,:,i,:] = MPRU[:,:,:]
        end
    ######

    return PredecessorTasks, STDur, AMPTD, MPRU, ARU, Resource, reward, PDD, Tardiness, arrival
end
function MPSPLIB_READER()
    ################################## MPSPLIB READER ####################################
    ZIPfile =open_dialog("Pick a file", GtkNullContainer(), ("*.zip",))
    Files = ZipFile.Reader(ZIPfile)
    lines = readlines(Files.files[2]) #reads as line
    ReadProject = [] #project information files
    arrival = [] #arrival dates of projects

    Resources=zeros(Int16,4) #resource amount in problem
    for i = 5:size(lines,1)-3
        if lines[i] == "\t\t\t<project>"
            push!(ReadProject,findfile(Files, split(split(lines[i+1], "\t\t\t\t<filename>")[2],"</filename>")[1])) #info file of project
            push!(arrival,parse(Int64,split(split(lines[i+2], "\t\t\t\t<start>")[2],"</start>")[1])) #arrival date of project
        elseif lines[i] == "<project>"
            push!(ReadProject,findfile(Files, split(split(lines[i+1], "<filename>")[2],"</filename>")[1])) #info file of project
            push!(arrival,parse(Int64,split(split(lines[i+2], "<start>")[2],"</start>")[1])) #arrival date of project
        elseif lines[i] == "\t\t<resources>"
            Resources[1] = parse(Int64,split(split(lines[i+1], "\t\t\t<resource>")[2],"</resource>")[1]) #Resource 1 number
            Resources[2] = parse(Int64,split(split(lines[i+2], "\t\t\t<resource>")[2],"</resource>")[1]) #Resource 2 number
            Resources[3] = parse(Int64,split(split(lines[i+3], "\t\t\t<resource>")[2],"</resource>")[1]) #Resource 3 number
            Resources[4] = parse(Int64,split(split(lines[i+4], "\t\t\t<resource>")[2],"</resource>")[1]) #Resource 4 number
        elseif lines[i] == "<resources>"
            Resources[1] = parse(Int64,split(split(lines[i+1], "<resource>")[2],"</resource>")[1]) #Resource 1 number
            Resources[2] = parse(Int64,split(split(lines[i+2], "<resource>")[2],"</resource>")[1]) #Resource 2 number
            Resources[3] = parse(Int64,split(split(lines[i+3], "<resource>")[2],"</resource>")[1]) #Resource 3 number
            Resources[4] = parse(Int64,split(split(lines[i+4], "<resource>")[2],"</resource>")[1]) #Resource 4 number
        end
    end
    NoResource = 4
    GlobalResource = size(Resources[Resources.!=0],1) #active resources
    #Resources = Resources[Resources.!=0]
    ##### \/ Project details \/ ####
    TypeNo=size(ReadProject,1)
    Ptype_successors = Array{Any}(undef,TypeNo)#[j][i][m]
    Ptype_P_times = Array{Any}(undef,TypeNo)#[j][i]
    Ptype_Rusage = Array{Any}(undef,TypeNo)# [j][i,r]
    reward =zeros(Int64,TypeNo)
    PDD =zeros(Int64,TypeNo)
    Tardiness =zeros(Int64,TypeNo)
    n=1
    maxtask = 0
    p = ReadProject[1]
    for p in ReadProject #this reads project files
        #println("project ",n)
        lines = readlines(p) #reads as line
        Horizon=split(lines[7], "  ")
        #PDD[n]=parse(Int64,last(Horizon))#horizon to due date
        line=split(lines[15], " ")
        P_info = line[line.!=""]
        Tasks = parse(Int64,P_info[2])#number of tasks
        PDD[n] = parse(Int64,P_info[4])
        #due date #dont use this due date is best completion time.
        Tardiness[n] = parse(Int64,P_info[5])#Tardiness cost
        reward[n] = Tardiness[n]*2
        if maxtask < Tasks
            maxtask = Tasks #max task update
        end
        Project_successors = Array{Any}(undef,Tasks) #hold successor of a project
        #for i=19 :19+Tasks+1 #19 and +1 for dummy tasks.
        for i=20 :19+Tasks #No dummy
            line =split(lines[i], " ")
            T_info = line[line.!=""]
            T_info[1] #task no
            T_info[2] #modes
            ns = parse(Int64,T_info[3])  #number of successors
            successors = zeros(Int8,ns) #hols successor of a task
            for sc = 1 : ns #for each successors
                if parse(Int64,T_info[3+sc]) != Tasks+2
                    successors[sc] = parse(Int64,T_info[3+sc])-1 #successors
                end
                #NOTE -1 since I deleted the start dummy
            end
            Project_successors[i-19] = successors #[][] variable
            #println("task ",i-19,"successors = ",successors)
        end
        Ptype_successors[n] = Project_successors # [][][] array, 3 dimension. typeno, maxtask, predeccsor
        Rusage = zeros(Int64,Tasks+2,4) #R usages of a project
        P_times = zeros(Int64,Tasks+2) #processing times of a project
        #for i=25+Tasks :25+Tasks*2+1 #25 and +1 for dummy tasks.
        for i=26+Tasks :25+Tasks*2 #No dummy
            line =split(lines[i], " ")
            T_info = line[line.!=""]
            T_info[1] ##task no
            T_info[2] #modes
            P_times[i-(25+Tasks)] = parse(Int64,T_info[3]) #duration
            Rusage[i-(25+Tasks),:] = [parse(Int64,T_info[4]),parse(Int64,T_info[5]),parse(Int64,T_info[6]),parse(Int64,T_info[7])]
            #T_info[5] #R1 usage
            #T_info[6] #R2 usage
            #T_info[7] #R3 usage
            #T_info[8] #R4 usage
            #println("task ",i-(25+Tasks),"resorce usages = ",T_info)
        end
        Ptype_Rusage[n] =Rusage
        Ptype_P_times[n] =P_times
        n+=1
        R_info = split(lines[30+Tasks*2], "   ")
        #RESOURCEAVAILABILITIES #will not used
        for r = (GlobalResource+1):4
            #Resources[r] +=  round.( trunc.(Int16, parse(Float64,R_info[r+1]) ) )# 5P30T problem
            #Resources[r] +=  round.( trunc.(Int16, parse(Float64,R_info[r+1]) ) *( (100-(10*TypeNo) )/100) )#quation 30
            Resources[r] +=  trunc.(Int16, round.(parse(Float64,R_info[r+1])*((50-(4*TypeNo))/100)))# equation 27
            #parse(Int64,R_info[r+1]) #resource amount
        end
        #parse(Int64,R_info[3]) #resource 2 amount
        #parse(Int64,R_info[4]) #resource 3 amount
        #parse(Int64,R_info[5]) #resource 5 amount
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
        #NOTE DUE DATE ATTEMPT
        #PDD[j]= trunc(Int16, round( horizon * 1 *( OS[j]+TypeNo* mean(RR[:,j]./(Resources* horizon) ) ) ) )
        PDD[j] = trunc(Int16, round(PDD[j] + ( TypeNo* mean(RR[:,j]./(Resources) ) ) ) ) # equation 28
        #OS*horizon * (1+mean resource usage ratio)
    end
    return MPTD,MPRU,PredecessorTasks,Resources,reward, PDD, Tardiness, arrival
    ################################## MPSPLIB READER ####################################
end
function findfile(dir, name)
    for f in dir.files
        if f.name == name
            return f
        end
    end
    nothing
end
function successor_to_prodecessors(Ptype_successors,TypeNo,maxtask)
    #Ptype_successors[j][i][m]
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
