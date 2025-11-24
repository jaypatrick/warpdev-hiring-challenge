BEGIN {
    # Portable (macOS/BSD awk) solution to find the longest successful Mars mission.
    FS = "|"
    
    # Command-line options (set with -v flag)
    verbose += 0      # -v verbose=1 for detailed output
    help += 0         # -v help=1 to show usage
    if (!format) format = "default"  # -v format=json|csv|default
    top += 0          # -v top=N to show top N missions (0 = show only longest)
    
    # Statistics
    total_lines = 0
    data_lines = 0
    mars_missions = 0
    completed_mars = 0
    errors = 0
    
    # Storage for multiple results
    mission_count = 0
    
    # Show help if requested
    showed_help = 0
    if (help) {
        print "Mars Mission Analyzer - Find the longest successful Mars missions"
        print "Usage: awk [OPTIONS] -f mars_mission_analyzer.awk <logfile>"
        print ""
        print "Options:"
        print "  -v verbose=1      Show detailed processing statistics and warnings"
        print "  -v format=FORMAT  Output format: default, json, or csv"
        print "  -v top=N          Show top N longest missions (default: 1)"
        print "  -v help=1         Show this help message"
        print ""
        print "Output Formats:"
        print "  default  Human-readable format (default)"
        print "  json     JSON format for programmatic use"
        print "  csv      CSV format for spreadsheet import"
        print ""
        print "Examples:"
        print "  awk -f mars_mission_analyzer.awk space_missions.log"
        print "  awk -v verbose=1 -f mars_mission_analyzer.awk space_missions.log"
        print "  awk -v format=json -f mars_mission_analyzer.awk space_missions.log"
        print "  awk -v format=csv -v top=5 -f mars_mission_analyzer.awk space_missions.log"
        showed_help = 1
        exit 0
    }
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
        
        # Store mission data
        mission_count++
        missions[mission_count, "duration"] = d
        missions[mission_count, "code"] = code
        missions[mission_count, "line"] = $0
        missions[mission_count, "line_num"] = NR
        missions[mission_count, "date"] = trim($1)
        missions[mission_count, "mission_id"] = trim($2)
        missions[mission_count, "crew_size"] = trim($5)
        missions[mission_count, "success_rate"] = trim($7)
    }
}

END {
    # Skip END if help was shown
    if (showed_help) exit 0
    
    # Report statistics in verbose mode
    if (verbose) {
        print "\n=== Processing Statistics ===" > "/dev/stderr"
        print "Total lines processed:", total_lines > "/dev/stderr"
        print "Data lines:", data_lines > "/dev/stderr"
        print "Total Mars missions:", mars_missions > "/dev/stderr"
        print "Completed Mars missions:", completed_mars > "/dev/stderr"
        print "Valid missions stored:", mission_count > "/dev/stderr"
        print "Errors/warnings:", errors > "/dev/stderr"
        print "============================\n" > "/dev/stderr"
    }
    
    # Error handling: no completed Mars missions found
    if (mission_count == 0) {
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
    
    # Sort missions by duration (descending) using selection sort
    for (i = 1; i < mission_count; i++) {
        max_idx = i
        for (j = i + 1; j <= mission_count; j++) {
            if (missions[j, "duration"] > missions[max_idx, "duration"]) {
                max_idx = j
            }
        }
        if (max_idx != i) {
            # Swap records i and max_idx
            temp_duration = missions[i, "duration"]
            temp_code = missions[i, "code"]
            temp_line = missions[i, "line"]
            temp_line_num = missions[i, "line_num"]
            temp_date = missions[i, "date"]
            temp_mission_id = missions[i, "mission_id"]
            temp_crew_size = missions[i, "crew_size"]
            temp_success_rate = missions[i, "success_rate"]
            
            missions[i, "duration"] = missions[max_idx, "duration"]
            missions[i, "code"] = missions[max_idx, "code"]
            missions[i, "line"] = missions[max_idx, "line"]
            missions[i, "line_num"] = missions[max_idx, "line_num"]
            missions[i, "date"] = missions[max_idx, "date"]
            missions[i, "mission_id"] = missions[max_idx, "mission_id"]
            missions[i, "crew_size"] = missions[max_idx, "crew_size"]
            missions[i, "success_rate"] = missions[max_idx, "success_rate"]
            
            missions[max_idx, "duration"] = temp_duration
            missions[max_idx, "code"] = temp_code
            missions[max_idx, "line"] = temp_line
            missions[max_idx, "line_num"] = temp_line_num
            missions[max_idx, "date"] = temp_date
            missions[max_idx, "mission_id"] = temp_mission_id
            missions[max_idx, "crew_size"] = temp_crew_size
            missions[max_idx, "success_rate"] = temp_success_rate
        }
    }
    
    # Determine how many results to show
    num_to_show = (top > 0 && top < mission_count) ? top : (top > 0 ? mission_count : 1)
    
    # Output based on format
    if (format == "json") {
        # JSON output
        print "{"
        print "  \"statistics\": {"
        print "    \"total_lines\": " total_lines ","
        print "    \"data_lines\": " data_lines ","
        print "    \"mars_missions\": " mars_missions ","
        print "    \"completed_mars_missions\": " completed_mars ","
        print "    \"valid_missions\": " mission_count ","
        print "    \"errors\": " errors
        print "  },"
        print "  \"missions\": ["
        for (i = 1; i <= num_to_show; i++) {
            print "    {"
            print "      \"rank\": " i ","
            print "      \"date\": \"" missions[i, "date"] "\","
            print "      \"mission_id\": \"" missions[i, "mission_id"] "\","
            print "      \"destination\": \"Mars\","
            print "      \"status\": \"Completed\","
            print "      \"crew_size\": " missions[i, "crew_size"] ","
            print "      \"duration_days\": " missions[i, "duration"] ","
            print "      \"success_rate\": " missions[i, "success_rate"] ","
            print "      \"security_code\": \"" missions[i, "code"] "\","
            print "      \"line_number\": " missions[i, "line_num"]
            if (i < num_to_show) {
                print "    },"
            } else {
                print "    }"
            }
        }
        print "  ]"
        print "}"
    } else if (format == "csv") {
        # CSV output
        print "Rank,Date,Mission ID,Destination,Status,Crew Size,Duration (days),Success Rate,Security Code,Line Number"
        for (i = 1; i <= num_to_show; i++) {
            print i "," missions[i, "date"] "," missions[i, "mission_id"] ",Mars,Completed," \
                  missions[i, "crew_size"] "," missions[i, "duration"] "," \
                  missions[i, "success_rate"] "," missions[i, "code"] "," missions[i, "line_num"]
        }
    } else {
        # Default human-readable output
        if (verbose) {
            print "=== Results (Top " num_to_show " Mission" (num_to_show > 1 ? "s" : "") ") ===" > "/dev/stderr"
        }
        
        for (i = 1; i <= num_to_show; i++) {
            if (num_to_show > 1) {
                print "\n--- Rank #" i " ---"
            }
            if (verbose) {
                print "Date:", missions[i, "date"]
                print "Mission ID:", missions[i, "mission_id"]
                print "Crew Size:", missions[i, "crew_size"]
                print "Success Rate:", missions[i, "success_rate"] "%"
                print "Duration:", missions[i, "duration"], "days"
                print "Security Code:", missions[i, "code"]
                print "Found at line:", missions[i, "line_num"]
                # Trim and print full record
                line = missions[i, "line"]
                gsub(/[ \t]+/, " ", line)
                gsub(/^[ \t]+|[ \t]+$/, "", line)
                print "Full Record:", line
            } else {
                print "Security Code:", missions[i, "code"]
                print "Mission Length:", missions[i, "duration"], "days"
            }
        }
    }
    
    # Exit successfully
    exit 0
}

