#!/bin/bash

# display usage
function HELP(){
    echo "usage: $(basename $0) <PATH DM txt>"
    echo "DM: Data Model"
}

# confirm number of argument is right
if [[ $# != 1 ]];then
    HELP
    exit 1
fi

# assign variable value
path_DM_dump_file=$1
path_OUT_folder="$(dirname $1)/DM_component_CSVs"

# display variable value
echo "path_DM_dump_file = ${path_DM_dump_file}"

# create output folder 
if [[ -d ${path_OUT_folder} ]];then
    read -p "Overwrite ${path_DM_dump_file}? (y/n) "
    if [[ ${REPLY} == "y" ]]; then
        rm ${path_OUT_folder} -rf
    fi
fi

mkdir ${path_OUT_folder}



# cut ANSI header and parsing
cat ${path_DM_dump_file} | \
sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g" | \
awk --assign OUT_DIR=${path_OUT_folder} \
'
# create a dictionary structure "info"
# the layout of "info" shown below
# "info"
#   component
#       nbr_of_var
#           name
#           type
#           value

# find the starter of each component
# example:
# getv from/to component(eRT.com.cisco.spvtg.ccsp.led): Device.
# $3    : getv from/to component(eRT.com.cisco.spvtg.ccsp.led): Device.
# arr[2]: eRT.com.cisco.spvtg.ccsp.led

$0 ~ "getv from/to component"{

    split($3, arr, "[()]")
    component = arr[2]

    #print "component: " component
}

# parse first line of variable ( including nbr_of_var and var_name )
# example:
# Parameter    1 name: Device.ArcLED.Brightness.Diming
# $2    : 1
# $4    : Device.ArcLED.Brightness.Diming
$0 ~ "Parameter"{

    gsub("\r", "", $0)

    nbr_of_var  = $2
    var_name    = $4

    # print "nbr_of_var: " nbr_of_var
    # print "var_name: " var_name

    info[component][nbr_of_var]["name"] = var_name
	
	# calculate the maximum number of field in all "var_name"
	len = split( var_name, a, "." )
	if ( len > max_nbr_field ){
		max_nbr_field = len
	}
}

# parse second line of variable ( including type and value )
# example 
#                type:     string,    value: 100% 
# $2    : string,
# $4    : 100%
$0 ~ "type:"{

    gsub("\r", "", $0)

    var_type    = $2
    var_value   = $4
    
    # remove , from var_type
    gsub(/,/,"",var_type)

    # print "var_type: " var_type
    # print "var_value: " var_value

    info[component][nbr_of_var]["type"] = var_type
    info[component][nbr_of_var]["value"] = var_value
}


# input
# component = eRT.com.cisco.spvtg.ccsp.lmlite
# output
# return => lmlite
function extract_component_last_field(component){
    num = split(component, component_arr, ".")
    return component_arr[num]
}

# the layout of "info" shown below
# "info"
#   component
#       nbr_of_var
#           name
#           type
#           value


END{

	# output
	# example ( wifi.csv content )
	# No.,arg_field1,arg_field2,arg_field3,arg_field4,arg_field5,arg_field6,arg_field7,arg_field8,arg_field9,arg_field10,type,value
	# 1,Device,WiFi,RadioNumberOfEntries,,,,,,,,uint,"2",
	# 2,Device,WiFi,SSIDNumberOfEntries,,,,,,,,uint,"16",
	# ... and so on ...
	# 48,Device,WiFi,Radio,1,OperatingStandards,,,,,,string,"a,n,ac,ax",
	
    for( component in info ){

        # extract component
        comp = extract_component_last_field(component)
        
        # assign value to variable "csv_path"
        csv_path = OUT_DIR "/" comp ".csv"    
        
        # display header
        # printf("%s,%s,%s,%s\n", "No.", "name", "type", "value")		> csv_path 
		printf("%s,", "No.")     										> csv_path 
		for ( i=1; i<=max_nbr_field; i++ ){
            printf("%s%d,", "arg_field", i)								> csv_path
        }
		printf("%s,%s\n", "type", "value")     							> csv_path 
		
		     
        for( nbr_of_var in info[component] ){
            
            # display component and nbr_of_var value
            printf("%s,", nbr_of_var)                               	>> csv_path

            # display name
			split( info[component][nbr_of_var]["name"], name_array, "." );
			for ( i=1; i<=max_nbr_field; i++ ){
				printf("%s,", name_array[i])      						>> csv_path
			}
			
			# display type and value
			# value need be quoted by "%s" format
            printf("%s,", info[component][nbr_of_var]["type"])      	>> csv_path
            printf("\"%s\",", info[component][nbr_of_var]["value"])     >> csv_path

            # newline
            printf("\n")                                            	>> csv_path
        }
    }

}
' 
