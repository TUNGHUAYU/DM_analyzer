#!/bin/bash

# <<< function definition >>>

##
# path: A/B/C/experiment_20220906/fw_MKT_0906/.../connecting/DM_component_CSVs
#
# output: "<exp_date> <fw_version> <condition>"
#
function get_info(){

    local file_path=$1
   
    echo "${file_path}" | \
    awk \
    '
    BEGIN{
        FS="/"
    }
    {
        N = split($0, file_path_array, "/")

        # condition
        condition = file_path_array[N-1]

        # search fw_version and exp_date
        for ( i=1; i<=N; i++ ){
            
            # fw version
            if ( match(file_path_array[i], /fw_*/) ){
                fw_version = file_path_array[i]
            }

            # exp_date
            if ( match(file_path_array[i], /experiment_*/) ){
                exp_date = file_path_array[i]
            }
        }

        # display
        printf("%s %s %s", exp_date, fw_version, condition)
    }
    '
}

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
        N = split(file_path, file_path_array, "/")
        return file_path_array[N]
    }

    function get_file_condition(file_path){
        N = split(file_path, file_path_array, "/")
        return file_path_array[N-2]
    }

    function get_file_fw_version(file_path){
        N = split(file_path, file_path_array, "/")
        for ( i=1; i<=N; i++ ){
            if ( match(file_path_array[i], /fw_*/) ){
                n = i
                break
            }
        }
        return file_path_array[n]
    }

    function get_file_exp_date(file_path){
        N = split(file_path, file_path_array, "/")
        for ( i=1; i<=N; i++ ){
            if ( match(file_path_array[i], /experiment_.*/) ){
                n = i
                break
            }
        }
        return file_path_array[n]
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
        fileA_info["fw_version"] = get_file_fw_version(ARGV[1])
        fileB_info["fw_version"] = get_file_fw_version(ARGV[2])
        fileA_info["exp_date"] = get_file_exp_date(ARGV[1])
        fileB_info["exp_date"] = get_file_exp_date(ARGV[2])
        
        if ( fileA_info["filename"] != fileB_info["filename"] ){
            exit 1
        }

        # 
        max_nbr_field = 0
		max_nbr_field_file1 = 0
		max_nbr_field_file2 = 0
    }
	
	# get the maximun number of field in first file
	# example ( wifi.csv header )
	# No.,arg_field1,arg_field2,arg_field3,arg_field4,arg_field5,arg_field6,arg_field7,arg_field8,arg_field9,arg_field10,type,value
	
	ARGIND == 1 && FNR == 1 { 
		max_nbr_field_file1 = NF
		next
	}
	
    # parse first file and ignore first row
	# example ( wifi.csv content )
	# 48,Device,WiFi,Radio,1,OperatingStandards,,,,,,string,"a,n,ac,ax",
	
    ARGIND == 1 && FNR != 1 { 
    
		# get "argument" from first file
		# compose argument with string format
		for( i=2; i<=max_nbr_field_file1 - 2; i++ ){
			if ( i == 2 ){
				argument=$2
			} else {
				if ( $i ){
					argument = sprintf("%s.%s", argument, $i)
				}
			}
		}

		# get "type" from first file
		type     = $(max_nbr_field_file1 - 1)
		
		# get "value" from first file
		split($0, a, "\"")
		value    = a[2]
		

		# assign type and value to info array
		info[argument]["type"] = type
		info[argument]["file1_value"] = value
		info[argument]["file2_value"] = "<none>"

		next 
    }
	
	# get the maximun number of field in second file
	# example ( wifi.csv header )
	# No.,arg_field1,arg_field2,arg_field3,arg_field4,arg_field5,arg_field6,arg_field7,arg_field8,arg_field9,arg_field10,type,value
	
	ARGIND == 2 && FNR == 1 { 
	
		max_nbr_field_file2 = NF
		
		if (max_nbr_field_file1 >= max_nbr_field_file2){
			max_nbr_field = max_nbr_field_file1
		} else {
			max_nbr_field = max_nbr_field_file2
		}
		
		next
	}
    
	# parse second file and ignore first row
	# example ( wifi.csv content )
	# 48,Device,WiFi,Radio,1,OperatingStandards,,,,,,string,"a,n,ac,ax",
	
	ARGIND == 2 && FNR != 1 { 
	   
		# get "argument" from second file
		# compose argument with string format
		for( i=2; i<=max_nbr_field_file1 - 2; i++ ){
			if ( i == 2 ){
				argument=$2
			} else {
				if ( $i ){
					argument = sprintf("%s.%s", argument, $i)
				}
			}
		}

		# get "type" from second file
		type     = $(max_nbr_field_file1 - 1)
		
		# get "value" from second file
		split($0, a, "\"")
		value    = a[2]

		# assign type and value to info array
		info[argument]["type"] = type
		if ( "file1_value" in info[argument] ){
		   info[argument]["file2_value"] = value
		} else {
		   info[argument]["file1_value"] = "<none>"
		   info[argument]["file2_value"] = value
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
	   fileA_header = sprintf("%s-%s-%s", fileA_info["exp_date"], fileA_info["fw_version"], fileA_info["condition"])
	   fileB_header = sprintf("%s-%s-%s", fileB_info["exp_date"], fileB_info["fw_version"], fileB_info["condition"])
	   printf("%s,%s,%s\n", "type", fileA_header, fileB_header)      >> out_csv_path 
	  
	   # content
	   for ( argument in info ){
		   split(argument, argument_array, ".")
		   for( i=1; i<=max_nbr_field; i++ ){
			   printf("%s,", argument_array[i])                        >> out_csv_path
		   }
		   printf("%s,\"%s\",\"%s\"\n", info[argument]["type"], info[argument]["file1_value"], info[argument]["file2_value"]) >> out_csv_path
	   }

	}
' ${path_CA_DM_component_csv} ${path_CB_DM_component_csv}

}

#
# brief: list component difference between two DMs

function list_component(){

    # header
    printf "%s,%s,%s\n" "name" ${A_condition} ${B_condition}

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


# get the exp_date, fw_version, and condition 
fileA_info=($( get_info ${path_CA_DM_DIR} ))
A_exp_date=${fileA_info[0]}
A_fw_version=${fileA_info[1]}
A_condition=${fileA_info[2]}

fileB_info=($( get_info ${path_CB_DM_DIR} ))
B_exp_date=${fileB_info[0]}
B_fw_version=${fileB_info[1]}
B_condition=${fileB_info[2]}


# create output folder 
path_OUT_folder="$(pwd)/DM_comparison/${A_fw_version}-${A_condition}_vs_${B_fw_version}-${B_condition}"
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

# create commom folder
path_OUT_folder="${path_OUT_folder}/commom"
if [[ -d ${path_OUT_folder} ]];then
    read -p "Overwrite ${path_OUT_folder}? (y/n) "
    if [[ ${REPLY} == "y" ]]; then
        rm ${path_OUT_folder} -rf
    fi
fi

mkdir -p ${path_OUT_folder}


# compare process
for file_name in ${comm_DM_component_arr[@]}
do

    path_CA_DM_csv="${path_CA_DM_DIR}/${file_name}"
    path_CB_DM_csv="${path_CB_DM_DIR}/${file_name}"

    echo "compare ${path_CA_DM_csv} ${path_CB_DM_csv}"
    compare ${path_CA_DM_csv} ${path_CB_DM_csv} ${path_OUT_folder}
done
