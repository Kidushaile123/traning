#!/bin/bash

# The code segment below creates variables that point to file paths used in the analysis process 
project_folder=/home/garrydj/data_delivery/umgc/2022-q2/220420_A00223_0818_AHJVVJDSX3/Garry_Project_106
index_folder=/home/garrydj/haile023/mm10_index_files/mm10
destination_folder=/scratch.global/haile023
temp_file_storage=/scratch.global/haile023/temp_files


# changing the working directory to where atac-seq files are located 
cd ${project_folder}


# This for loop creates the corresponding bash file that will be queued in slurm for each pair end read alignment 
for i in *R1*
do
echo "#!/bin/bash

# Setting up the resources needed for the each job  
#SBATCH -N 1
#SBATCH --ntasks=16
#SBATCH --time=24:00:00
#SBATCH --mem=55gb
#SBATCH -p msismall
#SBATCH -o /home/garrydj/haile023/repro_out/${i/_R1_001.fastq.gz/.out}

# Activating the conda environment
source /home/garrydj/haile023/.bashrc
conda activate base

# Initializing the necessary alignment and sorting tools (bowtie2, samtools and picard)
module load bowtie2/2.2.4
module load samtools
module load picard-tools





# Creating sam file form each pair-end read alignment  
bowtie2 -p 16 -q -X 2000 -x ${index_folder} -1 $project_folder/$i -2 $project_folder/${i/R1_001.fastq.gz/R2_001.fastq.gz} -S $destination_folder/${i/_R1_001.fastq.gz/.sam}

# Using samtool to create bam file from the sam file
samtools view -bS $destination_folder/${i/_R1_001.fastq.gz/.sam} > $destination_folder/${i/_R1_001.fastq.gz/.bam}

# Removes the sam file 
rm $destination_folder/${i/_R1_001.fastq.gz/.sam}

# Sort the bam file
java -jar /panfs/roc/msisoft/picard/2.25.6/picard.jar SortSam I=$destination_folder/${i/_R1_001.fastq.gz/.bam} O=$destination_folder/${i/_R1_001.fastq.gz/.sorted.bam} SORT_ORDER=coordinate TMP_DIR=$temp_file_storage CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT CREATE_MD5_FILE=true


# Checks if every read is matched with its mate pair and correct it if needed 
java -jar /panfs/roc/msisoft/picard/2.25.6/picard.jar FixMateInformation I=$destination_folder/${i/_R1_001.fastq.gz/.sorted.bam} O=$destination_folder/${i/_R1_001.fastq.gz/.sorted.fixed_mate.bam} TMP_DIR=$temp_file_storage CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT CREATE_MD5_FILE=true

# Removes the sorted am file
rm $destination_folder/${i/_R1_001.fastq.gz/.sorted.bam}


# Identifies and marks duplicate reads
java -jar /panfs/roc/msisoft/picard/2.25.6/picard.jar MarkDuplicates I=$destination_folder/${i/_R1_001.fastq.gz/.sorted.fixed_mate.bam} O=$destination_folder/${i/_R1_001.fastq.gz/.dedup.bam} M=$destination_folder/${i/_R1_001.fastq.gz/.metrics.txt} REMOVE_DUPLICATES=true TMP_DIR=$temp_file_storage CREATE_INDEX=true VALIDATION_STRINGENCY=SILENT CREATE_MD5_FILE=true

# Creates a symbolic link from the final index file 
ln -s $destination_folder/${i/_R1_001.fastq.gz/.dedup.bai} $destination_folder/${i/_R1_001.fastq.gz/.dedup.bam.bai}



# Removes the fixed_mate.bam files
rm $destination_folder/${i/_R1_001.fastq.gz/.sorted.fixed_mate.bam}

# Writes the above code segemnt in to a separte bash file for each pair-end alignment  
" >> /home/garrydj/haile023/parallel_computing_scripts/${i/_R1_001.fastq.gz/.sh}
done


