BEGIN {
    # Portable (macOS/BSD awk) solution to find the longest successful Mars mission.
    # Defaults: print only the security code; pass -v verbose=1 to print details.
    FS = "|"
    max_duration = -1
    best_code = ""
    verbose += 0
    total_lines = 0
    data_lines = 0
    mars_missions = 0
    completed_mars = 0
    errors = 0
}

# Trim leading/trailing whitespace
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

# Validate security code format (ABC-123-XYZ)
function is_valid_code(code) {
    return code ~ /^[A-Z]{3}-[0-9]{3}-[A-Z]{3}$/
}

# Skip headers, metadata, and blank/comment lines
/^[[:space:]]*#/ { total_lines++; next }
/^SYSTEM:/ { total_lines++; next }
/^CONFIG:/ { total_lines++; next }
/^CHECKSUM:/ { total_lines++; next }
/^[[:space:]]*$/ { total_lines++; next }

# Process data lines
{
    total_lines++
    
    # Check minimum number of fields
    if (NF < 8) {
        if (verbose) {
            print "Warning: Line", NR, "has only", NF, "fields (expected 8)" > "/dev/stderr"
        }
        errors++
        next
    }
    
    data_lines++
    
    destination = trim($3)
    status      = trim($4)
    duration    = trim($6)
    code        = trim($8)
    
    # Track Mars missions
    if (tolower(destination) == "mars") {
        mars_missions++
    }
    
    # Case-insensitive checks via tolower() for portability
    if (tolower(destination) == "mars" && tolower(status) == "completed") {
        completed_mars++
        
        # Validate duration is a positive number
        d = duration + 0
        if (d <= 0) {
            if (verbose) {
                print "Warning: Line", NR, "has invalid duration:", duration > "/dev/stderr"
            }
            errors++
            next
        }
        
        # Validate security code format
        if (!is_valid_code(code)) {
            if (verbose) {
                print "Warning: Line", NR, "has invalid security code format:", code > "/dev/stderr"
            }
            errors++
            next
        }
        
        # Track the longest mission
        if (d > max_duration) {
            max_duration = d
            best_code = code
            best_line = $0
            best_line_num = NR
        }
    }
}

END {
    # Report statistics in verbose mode
    if (verbose) {
        print "\n=== Processing Statistics ===" > "/dev/stderr"
        print "Total lines processed:", total_lines > "/dev/stderr"
        print "Data lines:", data_lines > "/dev/stderr"
        print "Total Mars missions:", mars_missions > "/dev/stderr"
        print "Completed Mars missions:", completed_mars > "/dev/stderr"
        print "Errors/warnings:", errors > "/dev/stderr"
        print "============================\n" > "/dev/stderr"
    }
    
    # Error handling: no completed Mars missions found
    if (max_duration < 0 || best_code == "") {
        print "ERROR: No valid completed Mars missions found." > "/dev/stderr"
        if (data_lines == 0) {
            print "ERROR: No data lines were processed. Check file format." > "/dev/stderr"
        } else if (mars_missions == 0) {
            print "ERROR: No Mars missions found in the log file." > "/dev/stderr"
        } else if (completed_mars == 0) {
            print "ERROR: Mars missions found but none with 'Completed' status." > "/dev/stderr"
        } else {
            print "ERROR: Completed Mars missions found but all had invalid data." > "/dev/stderr"
        }
        exit 1
    }
    
    # Success: output results
    if (verbose) {
        print "=== Result ===" > "/dev/stderr"
        print "Found at line:", best_line_num > "/dev/stderr"
        print "Duration (days):", max_duration
        print "Security Code:", best_code
        print "Full Record:", best_line
    } else {
        # Output the security code and mission length
        print "Security Code:", best_code
        print "Mission Length:", max_duration, "days"
    }
    
    # Exit successfully (warnings don't prevent finding the answer)
    exit 0
}
