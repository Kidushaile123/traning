#!/bin/bash

# Gets all the bash job scripts corresponding to each pair-end alignment analysis 
all_files=/home/garrydj/haile023/parallel_computing_scripts/*

# Use a for a loop to sumbit those scripts to slurm and have them run concurrent·ly
for j in $all_files
do

sbatch $j

done

