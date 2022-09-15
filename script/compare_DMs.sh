#!/bin/bash

# <<< function definition >>>

# $1: path_CA_DM_Component_csv
# $2: path_CA_DM_Component_csv
# $3: path_OUT_DIR
#
# CA:= ConditionA
# CB:= ConditionB
# DM:= Data Model

function compare(){

    local path_CA_DM_component_csv=$1
    local path_CB_DM_component_csv=$2
    local path_OUT_DIR=$3

    # awk process for comparison
    awk \
    --assign OUT_DIR=${path_OUT_DIR} \
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

#
# brief: list component difference between two DMs

function list_component(){

    # header
    printf "%s,%s,%s\n" "name" ${CA} ${CB}

    #
    for component in ${union_DM_component_arr[@]}
    do

        printf "%s," ${component}

        if [[ "${CA_DM_component_list[*]}" =~ "${component}" ]]; then
            printf "%s," "V"
        fi

        if [[ "${CB_DM_component_list[*]}" =~ "${component}" ]]; then
            printf "%s," "V"
        fi

        printf "\n"

    done

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

# get the condition of two DMs
CA=$( echo ${path_CA_DM_DIR} | awk -F"/" '{print $(NF-1)}' )
CB=$( echo ${path_CB_DM_DIR} | awk -F"/" '{print $(NF-1)}' )

# create output folder 
path_OUT_folder="$(pwd)/DM_comparison/${CA}_${CB}"
if [[ -d ${path_OUT_folder} ]];then
    read -p "Overwrite ${path_OUT_folder}? (y/n) "
    if [[ ${REPLY} == "y" ]]; then
        rm ${path_OUT_folder} -rf
    fi
fi

mkdir -p ${path_OUT_folder}


# get csv file and assign in array
CA_DM_component_list=($(find ${path_CA_DM_DIR} -name "*.csv" -type f))
CB_DM_component_list=($(find ${path_CB_DM_DIR} -name "*.csv" -type f))

# comm
comm_DM_component_arr=\
($(
    comm -12 \
    <(printf '%s\n' "${CA_DM_component_list[@]##*/}" | sort) \
    <(printf '%s\n' "${CB_DM_component_list[@]##*/}" | sort)
))

# A-B
comp_A_DM_component_arr=\
($(
    comm -13 \
    <(printf '%s\n' "${CA_DM_component_list[@]##*/}" | sort) \
    <(printf '%s\n' "${CB_DM_component_list[@]##*/}" | sort)
))

# B-A
comp_B_DM_component_arr=\
($(
    comm -23 \
    <(printf '%s\n' "${CA_DM_component_list[@]##*/}" | sort) \
    <(printf '%s\n' "${CB_DM_component_list[@]##*/}" | sort)
))

# A and B union
union_DM_component_arr+=(${comm_DM_component_arr[@]})
union_DM_component_arr+=(${comp_A_DM_component_arr[@]})
union_DM_component_arr+=(${comp_B_DM_component_arr[@]})

# produce the component list of two DMs
path_list_file="${path_OUT_folder}/component_list.csv"
{
list_component 
} > ${path_list_file}

#
path_OUT_folder="${path_OUT_folder}/commom"
if [[ -d ${path_OUT_folder} ]];then
    read -p "Overwrite ${path_OUT_folder}? (y/n) "
    if [[ ${REPLY} == "y" ]]; then
        rm ${path_OUT_folder} -rf
    fi
fi

mkdir -p ${path_OUT_folder}


for file_name in ${comm_DM_component_arr[@]}
do

    path_CA_DM_csv="${path_CA_DM_DIR}/${file_name}"
    path_CB_DM_csv="${path_CB_DM_DIR}/${file_name}"

    echo "compare ${path_CA_DM_csv} ${path_CB_DM_csv}"
    compare ${path_CA_DM_csv} ${path_CB_DM_csv} ${path_OUT_folder}
done
