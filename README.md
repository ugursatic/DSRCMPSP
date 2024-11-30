# EJOR-DSRCMPSP User Guides (Version 1.0)
## Citing This Repository
If you use any materials, data, or software from this repository in your research or project, please cite the relevant publications. Citing this work properly helps to acknowledge the authors' contributions. You can find the recommended citations below:

* Satic, U., Jacko, P. and Kirkbride, C. (2024) ‘A simulation-based approximate dynamic programming approach to dynamic and stochastic resource-constrained multi-project scheduling problem’, _European Journal of Operational Research_, 315(2), pp.  454-469. doi: 10.1016/j.ejor.2023.10.046.

## Introduction
EJOR-DSRCMPSP is a solver for dynamic and stochastic resource-constrained multi-project scheduling problems where projects generate rewards at their completion, completions later than a due date cause tardiness costs, task duration is uncertain, and new projects arrive randomly during the ongoing project execution both of which disturb the existing project scheduling plan. EJOR-DSRCMPSP contains the solution algorithms and benchmark problem information used in Satic (2024). 

These solution algorithms are: 

  * an approximate dynamic programming (ADP),
  * a dynamic programming algorithm (DP), Both ADP and DP algorithms aim to maximise the time-average profit,
  * a genetic algorithm (GA),
  * an optimal reactive baseline algorithm (ORBA), both GA and ORBA generate a schedule to maximise the total profit of ongoing projects,
  * a rule-based algorithm which prioritises the processing of tasks with the highest processing durations.

Problem Limitations:
 * All projects in one problem should have the same task number. If different task-numbered projects are considered in one problem, dummy tasks must be added to lower-numbered projects. A dummy task is a task that does not have any duration and resource consumption. 

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
1. [Prerequisites](#prerequisites)
2. [Steps](#steps)
3. [Usage](#usage)
4. [Support](#support)
5. [License](#license)

## Installation

The source codes of EJOR-DSRCMPSP are in the "Algorithm Codes" folder.  Download the source codes and open the main file with 1.60 version of Julia.  
"EJOR paper Main code" is the main file. 
 
## Prerequisites
 - In line 1, remove "#". Then select line 1 and run it to install some packages. After package installation is completed type a "#" to start of line 1.
 - In line 2, remove "#". Then select line 2 and run it to install Gtk package. After package installation is completed type a "#" to start of line 2.
These steps will not be required in future usage.

## Steps
1) Select and run the lines from 3-8 to include dependencies. 
2) Select and run the lines from 27 to 765 to register the required functions.
3) Type the file location of the Julia file of the required solvers. Then remove "#" from the start of their line.
4) Type the file location of the Julia file of the required problem readers. Then remove "#" from the start of their line.
5) Select and run the lines from 10 to 15 to register the required solvers and problem readers.
6) Create a folder in C named JuliaOutput
   
## Usage

### 1) Running the Code :
  The algorithm can be run by selecting and running the lines from 18 to 24 in the default settings. How to change the default is explained in the following subsections. 
  
### 2) Obtaining Results : 
After completion, the algorithm generates two result files in C:\\JuliaOutput named Test model ___ Results.csv and Test model ___ Rvalues.csv
The results file shows the following outputs:
 * Column A: tested project arrival rates
 * Columns B to E: Mean profit of tested algorithms.
 * Columns F to I: Standard deviation of the profit of tested algorithms.
 * Columns J to N: Run time of simulations for each algorithm.
 * Column A: Training time of ADP method.
 * Columns O to R: Number of arrival of projects in that test.
 * Columns S to V: Number of project completions (including late completions)
 * Columns W to Z: Number of late project completions
 * Column AA: Number of Genetic algorithms is called during simulation.
 * Column AB: Number of Genetic algorithms required retraining 
 * Columns AC to AF: Undiscounted Mean profit of tested algorithms.
 * Columns AG and AH: Some test statistics
 * Columns AI to AL: average free resource availability.
 * Column AA: Number of Genetic algorithms is called during simulation.

### 3) Problem Selection :
**Default problem:** The two projects with two tasks each problem is assigned as the default problem.

**Other pre-defined problems:**  To be able to run a test with other pre-defined problems are available in GenerateInitials function.  

Add  "#=" to current problem lines 507 and 513

Then remove one "#=" sign from the start of lines :
* from 498 and 504 for The three projects with two tasks each problem,
* from 488 to 494 for The two projects with three tasks each problem, 
* from 479 to 485 for The four projects with two tasks for each problem.

Note: only one problem can be used at once.  

 **Problems created with PROGEN:** 

- In line 13, remove "#"
- Type a "#" at to start of line 31
- In line 32, remove "#"

 **Problems from MPSPLIB:** 

- In lines 14 and 15, remove "#"
- Type a "#" at to start of line 31
- In line 33, remove "#"

### 4) Deterministic or Stochastic Task Duration Option Selection :

Line 22 (STC = 1 #Early Finish Options. early finish, normal finish, late finish) represents the task duration type selection.

**Default setting:**  The default value is 1, which represents 1 early finish and 1 late finish task duration.

 **Deterministic task duration:** For stochastic task durations, change STC to 0. 

### 5) Project Arrival Probability Selection : 

Line 28 A represents the project arrival probability of each project type. 

**How to change:** change this array with different arrival probabilities.  

**WARNING:** the algorithm does not work with value 0, and the algorithm newer stops with value 1. Thus please avoid these numbers.

### 6) Solution Method Selection : 

Lines 80 to 180 are related to solution method selection. 

EJOR-DSRCMPSP is able to run multiple algorithms together except for Dynamic programming and the Longest task first priority rule algorithm. Dynamic programming overrides the results of the Longest task first priority rule algorithm. Thus only one of them should be selected. 

#### 6.1) Approximate Dynamic programming : 

ADP is active as default. If you do not want to use it put "#=" at line 97 and "=#" at 124.

#### 6.2) Dynamic programming : 

EJOR-DSRCMPSP does not include a DP training module. It only has a DP policy reader. It reads the policies generated by [IJPR-DSRCMPSP]([http://url.com](https://github.com/ugursatic/IJPR-DSRCMPSP)).
To able to run DP policies remove "#=" from line 125,"=#" from line 142, "#" from line 230 and "#" from line 303.

#### 6.3) Genetic algorithm : 

to use a Genetic algorithm :

remove the "#" from line 12,"#=" from line 143 and "=#" from line 163 (if there are any) 

#### 6.4) Longest task first priority rule algorithm : 

Although the priority rule algorithm should work only doing step one, I called it with three steps like GA. The reason might be saving computation time or some coding issue. Unfortunately, I don't remember.  

To use the Longest task first priority rule algorithm 

remove the "#" from line 11,"#=" from line 125 and "=#" from line 142 (if there are any) 

#### 6.5) Optimal reactive baseline algorithm (ORBA) : 

To use LOptimal reactive baseline algorihm (ORBA) : 

remove the "#" from line 12,"#=" from line 164 and "=#" from line 181 (if there are any) 

## Support
This code is my second Julia code. Thus the code might be written poorly and might be hard to work with. 

Please contact ugur.satic@agu.edu.tr for your questions and help requests. 

## License
This project is licensed under the terms of the [MIT License](LICENSE).

For more information, please see the [LICENSE folder](LICENSE) for detailed licensing documentation.

