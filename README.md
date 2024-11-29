# ADPforDSRCMPSP
# EJOR-DSRCMPSP User Guides (Version 1.0)
## Citing This Repository
If you use any materials, data, or software from this repository in your research or project, please cite the relevant publications. Citing this work properly helps to acknowledge the authors' contributions. You can find the recommended citations below:

* Satic, U., Jacko, P. and Kirkbride, C. (2024) ‘A simulation-based approximate dynamic programming approach to dynamic and stochastic resource-constrained multi-project scheduling problem’, _European Journal of Operational Research_, 315(2), pp.  454-469. doi: 10.1016/j.ejor.2023.10.046.

## Introduction
EJOR-DSRCMPSP is a solver for dynamic and stochastic resource-constrained multi-project scheduling problems where projects generate rewards at their completion, completions later than a due date cause tardiness costs, task duration is uncertain, and new projects arrive randomly during the ongoing project execution both of which disturb the existing project scheduling plan. EJOR-DSRCMPSP contains the solution algorithms and benchmark problem information used in Satic (2024). These solution algorithms are: 

  * an approximate dynamic programming (ADP),
  * a dynamic programming algorithm (DP), Both ADP and DP algorithms aim to maximise the time-average profit,
  * a genetic algorithm (GA),
  * an optimal reactive baseline algorithm (ORBA), both GA and ORBA generate a schedule to maximise the total profit of ongoing projects,
  * a rule-based algorithm which prioritises the processing of tasks with the highest processing durations.

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
1. [Prerequisites](#prerequisites)
2. [Steps](#steps)
3. [Usage](#usage)
4. [Support](#support)
5. [License](#license)

## Installation

The source codes of EJOR-DSRCMPSP are in the src folder.  Download the source code and open it with 1.60 version of Julia.  
"EJOR paper Main code" is the main file. 
 
## Prerequisites
 - In line 9, remove "#". Then select line 9 and run it to install Combinatorics and StatsBase packages. After package installation is completed type a "#" to start of line 9.
  - In line 15, remove "#". Then select line 15 and run it to install JLD2 and FileIO packages. After package installation is completed type a "#" to start of line 15.
  - In line 19, remove "#". Then select line 19 and run it to install those packages. After package installation is completed type a "#" to start of line 10.
These steps will not be required in future usage.

## Steps
1) Select and run the lines from 1-23 to include dependencies. 
2) Select and run the lines from 108 to 2134 to register the required functions.
   
## Usage

### 1) Running the Code :
  The algorithm can be run by selecting and running the lines from 24 to 104 in the default settings. How to change the default is explained in the following subsections. 


### 2) Obtaining Results : 
The code writes differences between maximum and minimum value increases of each iteration till the difference is smaller than the stopping criteria to the REPL console. The code also writes the running time to the REPL console when it completes. 
 
[Diffirences between maximum and minimum value increases] = [Maximum value increase]-[Minimum value increase]. 

In our paper, we used the average of final [Maximum value increase] and [Minimum value increase] as the long-term average profit per unit time.   

### 3) Problem Selection :
**Default problem:** The two projects with two tasks each problem is assigned as the default problem.

**Other pre-defined problems:**  To be able to run a test with other pre-defined problems, first, put one "#" sign to each line from 51 to 55. 

Then remove one "#" sign from the start of lines :
* from 44 to 48 for The three projects with two tasks each problem,
* from 37 to 41 for The two projects with three tasks each problem, 
* from 31 to 35 for The four projects with two tasks for each problem.

Note: only one problem can be used at once.  

 **Creating custom problems:** Due to the computational limits of dynamic programming, most problems might not work. Thus we do not suggest changing the test problem. The setting of the default problem can be changed for customisation. 
 
MPTD =Int8[X Y;Z T], is used for (expected) task durations.

MPRU =Int8[X Y;Z T], is used for resource usage, 

PDD= Int8[A,B], is used for project's due dates,

Tardiness=Int8[A,B], is used for project's tardiness cost

reward=Int8[X Y;Z T],is used for task's completion reward

A is the first project type, B is the second project type.

X is the first project type's first task. Y is the first project type's second task. 

Z is the second project type's first task. T is the second project type's second task.

### 4) Deterministic or Stochastic Task Duration Option Selection :

Line 78 (EFoptions = 1 #Early Finish Options. early finish, normal finish, late finish) represents the task duration type selection.

**Default setting:**  The default value is 1, which represents deterministic task duration.

 **Stochastic task duration:** For stochastic tasks durations, change line 78 (EFoptions) from 1 to 3. Also remove the "#" sign from line 98 "#Controlrule()", which removes unrealistic stochastic task duration options to prevent errors. 

In line 78, 1 represents tasks are deterministic. 3 represents that there are 3 tasks completion options which are late, normal and early completions. 5, 7, 9, etc. could be used for this setting. For example, 5 will represent a task that may complete a maximum of 2 periods early or 2 periods late. However, due to small task durations, using other than 3 for stochastic tasks durations may cause an error. Unfortunately, it is not tested. 

### 5) Project Arrival Probability Selection : 

Line 86 (ArrivalProbabilty=) represents the project arrival probability of each project type. 

**Default setting:** the default setting of this variable is 0.01 which means a 1% arrival rate per transition time. 

**How to change:** change the value in line 86 from 0.01 to the desired amount. 

**WARNING:** the algorithm does not work with value 0, and the algorithm newer stops with value 1. Thus please avoid these numbers.

### 6) Solution Method Selection : 

Lines 1383 to 1387 are related to solution method selection. 

#### 6.1) Dynamic programming : 

This code uses dynamic programming as the default solution approach. Line 1381 calls the Dynamic programming solving function. 

To use Dynamic programming remove the "#" sign in front of line 1383 (if there are any), and put "#" signs to each line from 1384 to 1387 (if there is not).

It should look like this :

Line 1383 Best_action= greed_policy(timee,RA,State_space)

Line 1384 #Best_action= Notgreed_policy(timee,RA,State_space)

Line 1385 #Best_action= GeneticAlgorihm(timee,RA,State_space)

Line 1386 #Best_action= PriortyRule(timee,RA,State_space)

Line 1387 #Best_action= Static_Best_Action_Founder(timee,RA,State_space)

#### 6.2) Worst decision algorithm : 
To use the Worst decision algorithm remove the "#" sign in front of line 1384 (if there are any), and put "#" signs to each line from 1385 to 1387 and 1383 (if there is not). 

It should look like this :

Line 1383 #Best_action= greed_policy(timee,RA,State_space)

Line 1384 Best_action= Notgreed_policy(timee,RA,State_space)

Line 1385 #Best_action= GeneticAlgorihm(timee,RA,State_space)

Line 1386 #Best_action= PriortyRule(timee,RA,State_space)

Line 1387 #Best_action= Static_Best_Action_Founder(timee,RA,State_space)

#### 6.3) Genetic algorithm : 

Running a Genetic algorithm requires more changes. 

We used the value iteration method for algorithms 6.1 and 6.2 to calculate the long-term average profit per unit time of the methods.

We can use the value iteration method only for dynamic programming. But we can use the policy evaluation method for other algorithms. To be able to use the policy evaluation method our policy should fix (note: if the policy is getting better in some iterations, it will also work e.i. dynamic programming). However, we can not use the policy evaluation method if our policy is getting worse (like random) in some iterations.  

Since the genetic algorithm is a heuristic approach, it will create different (random) policies in each iteration. Since these policies are random, sometimes they will be worse than the previous iteration. Thus we can not use the policy evaluation method with random GA policies. 

As a solution, we run GA for the whole state space once and store it. Then we use that fixed policy and calculate its long-term average profit per unit time using the policy evaluation method. 
Thus we need more change to Run GA.

to use a Genetic algorithm :

1) remove the "#" sign in front of line 1385 (if there are any), and put "#" signs to other lines (if there is not). 

It should look like this :

Line 1383 #Best_action= greed_policy(timee,RA,State_space)

Line 1384 #Best_action= Notgreed_policy(timee,RA,State_space)

Line 1385 Best_action= GeneticAlgorihm(timee,RA,State_space)

Line 1386 #Best_action= PriortyRule(timee,RA,State_space)

Line 1387 #Best_action= Static_Best_Action_Founder(timee,RA,State_space)

2) remove the "#" sign in front of the lines 101,102 and 103(if there are any), and put "#" signs to 104 (if there is not). Then run the code as defined in section 1 Running the Code. This will run the GA once and store its policy. 

3) remove the "#" sign in front of the lines 89, 104,  (if there are any), and put "#" signs to 88,101,102 and 103 (if there is not). Also, change each DeltaFounder to DeltaFounder2 in the cases() function that starts at line 1324. Then run the code as defined in section 1 Running the Code. This will calculate the long-term average profit of the stored policy. 

#### 6.4) Longest task first priority rule algorithm : 

Although the priority rule algorithm should work only doing step one, I called it with three steps like GA. The reason might be saving computation time or some coding issue. Unfortunately, I don't remember.  

To use the Longest task first priority rule algorithm 

1) remove the "#" sign in front of line 1386 (if there are any), and put "#" signs to other lines (if there is not). 

It should look like this :

Line 1383 #Best_action= greed_policy(timee,RA,State_space)

Line 1384 #Best_action= Notgreed_policy(timee,RA,State_space)

Line 1385 #Best_action= GeneticAlgorihm(timee,RA,State_space)

Line 1386 Best_action= PriortyRule(timee,RA,State_space)

Line 1387 #Best_action= Static_Best_Action_Founder(timee,RA,State_space)

2) remove the "#" sign in front of the lines 101,102 and 103(if there are any), and put "#" signs to 104 (if there is not). Then run the code as defined in section 1 Running the Code. This will run the rule-based algorithm once and store its policy. 

3) remove the "#" sign in front of the lines 89, 104,  (if there are any), and put "#" signs to 88,101,102 and 103 (if there is not). Also, change each DeltaFounder to DeltaFounder2 in the cases() function that starts at line 1324. Then run the code as defined in section 1 Running the Code. This will calculate the long-term average profit of the stored policy. 

Note : the stored GA policies which used in our paper are available in Genetic algorithm policies folder. 

#### 6.5) Optimal reactive baseline algorithm (ORBA) : 
Although ORBA may work only doing step one, it is not time efficient. ORBA takes much time to generate the (static) optimal policy of a state. Since this policy will not change with iterations, we could run ORBA once then store its policy. Then we could use this stored policy for evaluation.

To use LOptimal reactive baseline algorihm (ORBA) : 

1) remove the "#" sign in front of line 1386 (if there are any), and put "#" signs to other lines (if there is not). 

It should look like this :

Line 1383 #Best_action= greed_policy(timee,RA,State_space)

Line 1384 #Best_action= Notgreed_policy(timee,RA,State_space)

Line 1385 #Best_action= GeneticAlgorihm(timee,RA,State_space)

Line 1386 #Best_action= PriortyRule(timee,RA,State_space)

Line 1387 Best_action= Static_Best_Action_Founder(timee,RA,State_space)

2) remove the "#" sign in front of the lines 101,102 and 103(if there are any), and put "#" signs to 104 (if there is not). Then run the code as defined in section 1 Running the Code. This will run the rule-based algorithm once and store its policy. 

3) remove the "#" sign in front of the lines 89, 104,  (if there are any), and put "#" signs to 88,101,102 and 103 (if there is not). Also, change each DeltaFounder to DeltaFounder2 in the cases() function that starts at line 1324. Then run the code as defined in section 1 Running the Code. This will calculate the long-term average profit of the stored policy. 

#### 7) Resouce availability setting :
The default resource availability is given as 3 in line 74 (Res1 = 3). To change resource availability just change this value. 

## Support
This code is my first Julia code. Thus the code might be written poorly and might be hard to work with. 

Please contact ugur.satic@agu.edu.tr for your questions and help requests. 

## License
This project is licensed under the terms of the [MIT License](LICENSE).

For more information, please see the [LICENSE folder](LICENSE) for detailed licensing documentation.

