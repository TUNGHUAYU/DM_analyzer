#!/bin/bash


# <<< function definition >>>

# $1: path_CA_DM_Component_csv
# $2: path_CA_DM_Component_csv
#
# CA:= ConditionA
# CB:= ConditionB
# DM:= Data Model

function compare(){

    local path_CA_DM_component_csv=$1
    local path_CB_DM_component_csv=$2

    
    awk \
    --assign OUT_DIR=${path_OUT_folder} \
    '
    function get_file_name(file_path){
        
        n = split(file_path, file_path_array, "/")
        
        return file_path_array[n]
    }

    function get_file_condition(file_path){
        
        n = split(file_path, file_path_array, "/")

        return file_path_array[n-2]
    }

    ## 
    # array "info" structure shows below
    # "info"
    #   argument
    #       type
    #       file1_value
    #       file2_value
    
    BEGIN{
        # setup devider as ','
        FS=","

        # check input file is the same component
        fileA_info["filename"] = get_file_name(ARGV[1])
        fileB_info["filename"] = get_file_name(ARGV[2])
        fileA_info["condition"] = get_file_condition(ARGV[1])
        fileB_info["condition"] = get_file_condition(ARGV[2])
        
        if ( fileA_info["filename"] != fileB_info["filename"] ){
            exit 1
        }

        # 
        max_nbr_field = 0
    }
    
    # parse first file and ignore first row
    ARGIND == 1 && FNR != 1 { 
    
        # get argument, type, and value from first file
        argument = $2
        type     = $3
        value    = $4
        
        # assign type and value to info array
        info[argument]["type"] = type
        info[argument]["file1_value"] = value
    
        # find max number of field of argument
        split(argument, a, ".")
        len = length(a)
        if ( len > max_nbr_field ){
            max_nbr_field = len
        }
    
        next 
    }
    
    # parse first file and ignore first row
    ARGIND == 2 && FNR != 1 { 
        
        # get argument, type, and value from second file
        argument = $2
        type     = $3
        value    = $4
    
        # assign type and value to info array
        info[argument]["type"] = type
        info[argument]["file2_value"] = value
    
        # find max number of field of argument
        split(argument, a, ".")
        len = length(a)
        if ( len > max_nbr_field ){
            max_nbr_field = len
        }
    
        next 
    }
    
    # output format content
    END{
        
        out_csv_path = sprintf("%s/%s", OUT_DIR, fileA_info["filename"])
    
        # header
        for ( i=1; i<=max_nbr_field; i++ ){
            printf("%s%d,", "arg_field", i)                             > out_csv_path 
        } 
        printf("%s,%s,%s\n", "type", fileA_info["condition"], fileB_info["condition"])      >> out_csv_path 
       
        # content
        for ( argument in info ){
            split(argument, argument_array, ".")
            for( i=1; i<=max_nbr_field; i++ ){
                printf("%s,", argument_array[i])                        >> out_csv_path
            }
            printf("%s,%s,%s\n", info[argument]["type"], info[argument]["file1_value"], info[argument]["file2_value"]) >> out_csv_path
        }
    
    }
    ' ${path_CA_DM_component_csv} ${path_CB_DM_component_csv}

}



# <<< main >>>
# usage message
function HELP(){
    echo "usage: $(basename $0) <PATH CA DM folder> <PATH CB DM folder>"
    echo "DM:= Data Model"
    echo "CA:= Condition A"
    echo "CB:= Condition B"
}

# confirm number of argument is right
if [[ $# != 2 ]];then
    HELP
    exit 1
fi

# assign variable value
path_CA_DM_DIR=$1
path_CB_DM_DIR=$2
path_OUT_folder="$(pwd)/DM_comparison"

# display variable value
echo "path_DM_csv1 = ${path_CA_DM_DIR}"
echo "path_DM_csv2 = ${path_CB_DM_DIR}"

# create output folder 
if [[ -d ${path_OUT_folder} ]];then
    read -p "Overwrite ${path_OUT_folder}? (y/n) "
    if [[ ${REPLY} == "y" ]]; then
        rm ${path_OUT_folder} -rf
    fi
fi

mkdir ${path_OUT_folder}

# check two DM folder have the same number of components
num_CA_component=$(ls -l ${path_CA_DM_DIR} | wc -l)
num_CB_component=$(ls -l ${path_CB_DM_DIR} | wc -l)

if [[ ${num_CA_component} != ${num_CB_component} ]]; then
    echo "number of Condition A component: ${num_CA_component}"
    echo "number of Condition B component: ${num_CB_component}"
    echo "Error: DMs do NOT have the same number of component"
    exit 2
fi


for file_path in ${path_CA_DM_DIR}/*.csv
do
    filename=$(basename ${file_path})
    path_CA_DM_csv="${path_CA_DM_DIR}/${filename}"
    path_CB_DM_csv="${path_CB_DM_DIR}/${filename}"
    echo "compare ${path_CA_DM_csv} ${path_CB_DM_csv}"
    compare ${path_CA_DM_csv} ${path_CB_DM_csv}
done
