This workflow is currently under development use it with caution

# Group A Streptococcus (GAS) Identification and Typing   

# Introduction  


This workflow will identify Streptococcus pyogenes (Group A Streptococcus) and its emm typing.  
This is a bioinformatic pipeline developed using WDL to perform serotyping group A Streptococcus (GAS) speices. This pipeline uses docker containers which will simplyfy and reduce the installation and compatibility issues arrise duing installation of softwares. The workflow can be deployed in a standalone computer as well as using Terra platform. To run as a standalone simply clone the repository to your working environment and to run the pipeline you need a cromwell to be installed as a prerequisite. To run in Terra platform, you can use the [Dockstore](https://dockstore.org/workflows/github.com/neranjan007/GAS_identification/gas_identification_wf2:main?tab=info) to search and launch to Terra.   

CT-GASIDnType workflow takes paired end reads as input, and will perform:  
*  Quality control
*  Contamination check
*  Assemble reads to scaffolds
*  Confirm taxa
*  Perform emm typing (GAS)  
*  Check for antibiotic resistance genes  

# Quick Run Guide  
Pipeline can be run on command line or using Terra interface.  
Pre-requisite for command line: Cromwell need to be installed in the local computer

## Installation  
```bash
git clone https://github.com/neranjan007/GAS_identification.git  
```

### Database:   
Will need the Kraken2/Bracken database present as a tar.gz file.   
Standard-8  :  [https://benlangmead.github.io/aws-indexes/k2](https://benlangmead.github.io/aws-indexes/k2)   :  [download link](https://genome-idx.s3.amazonaws.com/kraken/k2_standard_08gb_20230605.tar.gz)    



**inputs**   

*  Illumina paired end reads in gz format.
*  Kraken bracken database in tar.gz format.  

Input JSON file should have the following required input variables:  
```json
{
  "GAS_identification_workflow.samplename": "String",
  "GAS_identification_workflow.R1": "File",
  "GAS_identification_workflow.R2": "File",
  "GAS_identification_workflow.kraken2_database": "File"
}
```

Workflow is written in WDL and can be implemented in Terra or can be run in a local computer with Cromwell.    

### Command line  

```
java -jar cromwell run workflows/wf_gas_identification.wdl -i input.json 
```  


## Reference  
*  https://www.cdc.gov/streplab/index.html  


