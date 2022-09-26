#!/bin/bash


# <<< functions >>>

# display usage messsage 
function HELP(){
    echo "usage $(basename $0) <target folder>"
}


# <<< main  >>>

# check argumenet 
if [[ $# != 1 ]];then
    HELP
    exit 1
fi

# assign value
search_workdir=$1
pattern="*DM.txt"

# search "*DM.txt" in workdir ( including child folder )
for path in $(find ${search_workdir} -name ${pattern} -type f)
do

    echo "bash convert_DM_txt2csv.sh ${path}"
    bash convert_DM_txt2csv.sh ${path} 

done

