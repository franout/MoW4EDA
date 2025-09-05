# Utility Scripts in `util/`

This directory contains utility scripts used for processing and generating data related to different functionalities.

## Scripts

### 1. `SDF_fuse_slack_sff.py`
This script fuses timing slack information with a fault list in SFF (Stuck-at Fault Format) or Z01X format. It reads a slack report and a fault list, then annotates each fault with its corresponding timing slack, outputting a new fault list with timing information.

**Main features:**
- Reads slack values from a timing report file.
- Reads a fault list file (Z01X format).
- Annotates each fault with its timing slack (rise/fall) in nanoseconds.
- Outputs a new fault list with slack information included.

**Usage:**
```bash
python3 SDF_fuse_slack_sff.py --slack-file <slack_file> --input-fault-list-file <input_fault_list> --output-fault-list-file <output_fault_list>
```

### 2. `generate_full_strobe.py`
This script generates a strobe file for fault simulation tools, either in standard or SFF format. It processes a list of net names and outputs a strobe file with the correct format for the MoW4EDA flow.

**Main features:**
- Reads a list of net names from an input file.
- Generates a strobe file in either standard or SFF format, depending on the flag.
- Appends the top-level module name to each net.

**Usage:**
```bash
python3 generate_full_strobe.py --input-file <input_file> --output-file <output_file> [--sff]
```

- Use `--sff` to generate the strobe file in SFF format.

---

Both scripts rely on environment variables set by the MoW4EDA framework for top-level module names and other configuration.
