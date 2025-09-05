import argparse
import os

PATH_TO_APPEND= os.environ['MoW4EDA_FSIM_ELABORATION_TOP_LEVEL_NAME']


def generate_full_strobe(input_file,output_file, is_sff):
    signals = {}
    with open(input_file,"r") as input_fl:
        line= input_fl.readline()
        while line:
            net_name = line.rstrip().split()[-1]
            ## no problem with duplicate
            signals[ PATH_TO_APPEND + "."+ net_name] = []
            line = input_fl.readline()
    if is_sff: 
        with open(output_file,"w") as strobe_out_f:
            strobe_out_f.write("Strobe{\n")
            for net_name in signals:
                strobe_out_f.write(" \"" + net_name.replace("/",".")  +"\"\n")
            strobe_out_f.write("}\n")
    else: 
        # normal 
        with open(output_file,"w") as strobe_out_f:
            for net_name in signals:
                strobe_out_f.write( net_name.replace("/",".")  +" 1\n")
        
if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-file", type=str,
                        help="input fault list from testmax")
    parser.add_argument("--output-file", type=str,
        help="output strobe point for Z01X ")
    parser.add_argument("--sff", action="store_true",  
                        help="Generate sff or normal strobe file",default=False)
    parser.add_argument("-h|--help", action="store_true",
                        help="show usage")
    args = parser.parse_args()

    generate_full_strobe(args.input_file,args.output_file,args.sff)
    exit()