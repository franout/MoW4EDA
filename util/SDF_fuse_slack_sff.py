import re 
import os 
import sys
import argparse


TOP_NAME=os.environ['MoW4EDA_SYNTH_TOP_LEVEL_NAME']

SLACK_STANDARD_VALUE=os.environ['MoW4EDA_SYNTH_CLOCK_VALUE_NS']

def net_name_fix_zoix(string):
	tmp = string.replace("\\","")
	tmp = tmp.replace("/",".")
	return tmp.replace(" ","")


def read_slack_info(input_file):
    nets={}
    pattern = r'^\s*([-+]?\d*\.?\d+|\*)\s+([-+]?\d*\.?\d+|\*)\s+(.*)$'
    with open(input_file,"r") as fin:
        line=fin.readline()
        while line:
            line=line.strip()
            match =  re.match(pattern,line)
            if match :
                max_rise, max_fall, point = match.groups()
                # Convert max_rise and max_fall to float if they are not '*'
                max_rise_value = abs(float(max_rise)) if max_rise != '*' else float(SLACK_STANDARD_VALUE)
                max_fall_value = abs(float(max_fall)) if max_fall != '*' else float(SLACK_STANDARD_VALUE)
                nets[TOP_NAME+"."+point.replace("/",".")] = {"R" : max_rise_value, "F" :max_fall_value}
            line=fin.readline()   
    return nets


def fuse_slack_with_sff(slack_file,fault_list,output_file):
    nets={}
    nets=read_slack_info(slack_file)
    pattern = r'\s*<\s*([\d\s]+)\s*>\s*(\w+)\s*(\w)\s*\{PORT\s+"([^"]+)"\}'

    with open(fault_list,"r") as fault_list_fin, open(output_file,"w") as fault_list_out:
        line=fault_list_fin.readline()
        while line:
            processed_line = line
            match = re.match(pattern,line.rstrip())
            if match :
                faultInfo,status, value, port = match.groups()
                port = net_name_fix_zoix(port)
                if port in nets:
                    timing = "("+str(nets[port][value])+"ns)"
                    processed_line =" ".join(["\t <"+faultInfo+"> ",status, value, timing ,"{ PORT \"" + port+ "\"}\n" ])
                else : 
                    print("ERROR! missing fault placement " + str(port) + " in slack file")
                    sys.exit(1)
            fault_list_out.write(processed_line)
            line=fault_list_fin.readline()



if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--slack-file", type=str,
                        help="slack file to parse")
    parser.add_argument("--input-fault-list-file", type=str,
        help="input fault list file (Z01X format)")
    parser.add_argument("--output-fault-list-file", type=str,
                        help="output fault list file")
    parser.add_argument("-h|--help", action="store_true",
                        help="show usage")
    args = parser.parse_args()

    fuse_slack_with_sff(slack_file=args.slack_file,fault_list=args.input_fault_list_file,output_file=args.output_fault_list_file)
    exit()
 
    