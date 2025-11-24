BEGIN {
    # Portable (macOS/BSD awk) solution to find the longest successful Mars mission.
    # Defaults: print only the security code; pass -v verbose=1 to print details.
    FS = "|"
    max_duration = -1
    best_code = ""
    verbose += 0
}

# Trim leading/trailing whitespace
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }

# Skip headers, metadata, and blank/comment lines
/^[[:space:]]*#/ { next }
/^SYSTEM:/ { next }
/^CONFIG:/ { next }
/^CHECKSUM:/ { next }
/^[[:space:]]*$/ { next }

# Process data lines
{
    if (NF < 8) next

    destination = trim($3)
    status      = trim($4)
    duration    = trim($6)
    code        = trim($8)

    # Case-insensitive checks via tolower() for portability
    if (tolower(destination) == "mars" && tolower(status) == "completed") {
        d = duration + 0
        if (d > max_duration) {
            max_duration = d
            best_code = code
            best_line = $0
        }
    }
}

END {
    if (max_duration < 0 || best_code == "") {
        print "No completed Mars missions found." > "/dev/stderr"
        exit 1
    }

    if (verbose) {
        print "Duration (days):", max_duration
        print "Security Code:", best_code
        print "Record:", best_line
    } else {
        # Output only the security code as the final answer
        print best_code
    }
}
