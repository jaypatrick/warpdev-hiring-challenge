use clap::{Parser, ValueEnum};
use regex::Regex;
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::{BufRead, BufReader};
use std::path::PathBuf;
use std::process;

#[derive(Debug, Clone, Copy, ValueEnum)]
enum OutputFormat {
    Default,
    Json,
    Csv,
}

#[derive(Parser, Debug)]
#[command(name = "mars-mission-analyzer")]
#[command(about = "Find the longest successful Mars missions", long_about = None)]
struct Args {
    /// Input log file to analyze
    input_file: Option<PathBuf>,

    /// Show detailed processing statistics and warnings
    #[arg(short, long)]
    verbose: bool,

    /// Output format: default, json, or csv
    #[arg(short, long, value_enum, default_value = "default")]
    format: OutputFormat,

    /// Show top N longest missions (default: 1)
    #[arg(short, long, default_value = "1")]
    top: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Mission {
    date: String,
    mission_id: String,
    destination: String,
    status: String,
    crew_size: u32,
    duration: u32,
    success_rate: f64,
    security_code: String,
    line_number: usize,
}

#[derive(Debug, Default, Serialize)]
struct Statistics {
    total_lines: usize,
    data_lines: usize,
    mars_missions: usize,
    completed_mars_missions: usize,
    valid_missions: usize,
    errors: usize,
}

#[derive(Debug, Serialize)]
struct JsonOutput {
    statistics: Statistics,
    missions: Vec<MissionOutput>,
}

#[derive(Debug, Serialize)]
struct MissionOutput {
    rank: usize,
    date: String,
    mission_id: String,
    destination: String,
    status: String,
    crew_size: u32,
    duration_days: u32,
    success_rate: f64,
    security_code: String,
    line_number: usize,
}

impl Mission {
    fn from_line(line: &str, line_number: usize) -> Option<Self> {
        let parts: Vec<&str> = line.split('|').collect();

        if parts.len() < 8 {
            return None;
        }

        let date = parts[0].trim().to_string();
        let mission_id = parts[1].trim().to_string();
        let destination = parts[2].trim().to_string();
        let status = parts[3].trim().to_string();

        let crew_size = parts[4].trim().parse::<u32>().ok()?;
        let duration = parts[5].trim().parse::<u32>().ok()?;
        let success_rate = parts[6].trim().parse::<f64>().ok()?;
        let security_code = parts[7].trim().to_string();

        Some(Mission {
            date,
            mission_id,
            destination,
            status,
            crew_size,
            duration,
            success_rate,
            security_code,
            line_number,
        })
    }

    fn is_valid_security_code(&self) -> bool {
        let re = Regex::new(r"^[A-Z]{3}-[0-9]{3}-[A-Z]{3}$").unwrap();
        re.is_match(&self.security_code)
    }

    #[allow(dead_code)]
    fn is_completed_mars_mission(&self) -> bool {
        self.destination.eq_ignore_ascii_case("mars")
            && self.status.eq_ignore_ascii_case("completed")
            && self.duration > 0
            && self.is_valid_security_code()
    }
}

fn is_comment_or_metadata(line: &str) -> bool {
    let trimmed = line.trim();
    trimmed.is_empty()
        || trimmed.starts_with('#')
        || trimmed.starts_with("SYSTEM:")
        || trimmed.starts_with("CONFIG:")
        || trimmed.starts_with("CHECKSUM:")
}

fn process_file(file_path: &PathBuf, verbose: bool) -> Result<(Vec<Mission>, Statistics), String> {
    let file = File::open(file_path)
        .map_err(|e| format!("Failed to open file: {}", e))?;

    let reader = BufReader::new(file);
    let mut missions = Vec::new();
    let mut stats = Statistics::default();

    for (idx, line_result) in reader.lines().enumerate() {
        let line_number = idx + 1;
        stats.total_lines += 1;

        let line = match line_result {
            Ok(l) => l,
            Err(e) => {
                if verbose {
                    eprintln!("Warning: Failed to read line {}: {}", line_number, e);
                }
                stats.errors += 1;
                continue;
            }
        };

        // Skip comments and metadata
        if is_comment_or_metadata(&line) {
            continue;
        }

        stats.data_lines += 1;

        // Parse the mission
        let mission = match Mission::from_line(&line, line_number) {
            Some(m) => m,
            None => {
                if verbose {
                    eprintln!("Warning: Line {} has invalid format or missing fields", line_number);
                }
                stats.errors += 1;
                continue;
            }
        };

        // Check if it's a Mars mission
        if !mission.destination.eq_ignore_ascii_case("mars") {
            continue;
        }
        stats.mars_missions += 1;

        // Check if it's completed
        if !mission.status.eq_ignore_ascii_case("completed") {
            continue;
        }
        stats.completed_mars_missions += 1;

        // Validate duration
        if mission.duration == 0 {
            if verbose {
                eprintln!("Warning: Line {} has invalid duration: 0", line_number);
            }
            stats.errors += 1;
            continue;
        }

        // Validate security code
        if !mission.is_valid_security_code() {
            if verbose {
                eprintln!("Warning: Line {} has invalid security code format: {}",
                         line_number, mission.security_code);
            }
            stats.errors += 1;
            continue;
        }

        stats.valid_missions += 1;
        missions.push(mission);
    }

    Ok((missions, stats))
}

fn print_default_output(missions: &[Mission], verbose: bool, stats: &Statistics) {
    if verbose {
        eprintln!("\n=== Processing Statistics ===");
        eprintln!("Total lines processed: {}", stats.total_lines);
        eprintln!("Data lines: {}", stats.data_lines);
        eprintln!("Total Mars missions: {}", stats.mars_missions);
        eprintln!("Completed Mars missions: {}", stats.completed_mars_missions);
        eprintln!("Valid missions stored: {}", stats.valid_missions);
        eprintln!("Errors/warnings: {}", stats.errors);
        eprintln!("============================\n");
    }

    let num_to_show = missions.len();

    if verbose {
        eprintln!("=== Results (Top {} Mission{}) ===",
                 num_to_show, if num_to_show > 1 { "s" } else { "" });
    }

    for (idx, mission) in missions.iter().enumerate() {
        if num_to_show > 1 {
            println!("\n--- Rank #{} ---", idx + 1);
        }

        if verbose {
            println!("Date: {}", mission.date);
            println!("Mission ID: {}", mission.mission_id);
            println!("Crew Size: {}", mission.crew_size);
            println!("Success Rate: {}%", mission.success_rate);
            println!("Duration: {} days", mission.duration);
            println!("Security Code: {}", mission.security_code);
            println!("Found at line: {}", mission.line_number);
        } else {
            println!("Security Code: {}", mission.security_code);
            println!("Mission Length: {} days", mission.duration);
        }
    }
}

fn print_json_output(missions: &[Mission], stats: &Statistics) {
    let mission_outputs: Vec<MissionOutput> = missions
        .iter()
        .enumerate()
        .map(|(idx, m)| MissionOutput {
            rank: idx + 1,
            date: m.date.clone(),
            mission_id: m.mission_id.clone(),
            destination: "Mars".to_string(),
            status: "Completed".to_string(),
            crew_size: m.crew_size,
            duration_days: m.duration,
            success_rate: m.success_rate,
            security_code: m.security_code.clone(),
            line_number: m.line_number,
        })
        .collect();

    let output = JsonOutput {
        statistics: Statistics {
            total_lines: stats.total_lines,
            data_lines: stats.data_lines,
            mars_missions: stats.mars_missions,
            completed_mars_missions: stats.completed_mars_missions,
            valid_missions: stats.valid_missions,
            errors: stats.errors,
        },
        missions: mission_outputs,
    };

    match serde_json::to_string_pretty(&output) {
        Ok(json) => println!("{}", json),
        Err(e) => eprintln!("Error serializing to JSON: {}", e),
    }
}

fn print_csv_output(missions: &[Mission]) {
    println!("Rank,Date,Mission ID,Destination,Status,Crew Size,Duration (days),Success Rate,Security Code,Line Number");

    for (idx, mission) in missions.iter().enumerate() {
        println!("{},{},{},Mars,Completed,{},{},{},{},{}",
                 idx + 1,
                 mission.date,
                 mission.mission_id,
                 mission.crew_size,
                 mission.duration,
                 mission.success_rate,
                 mission.security_code,
                 mission.line_number);
    }
}

fn main() {
    let args = Args::parse();

    // Check if input file is provided
    let file_path = match args.input_file {
        Some(path) => path,
        None => {
            eprintln!("ERROR: No input file provided.");
            eprintln!("Usage: mars-mission-analyzer <input_file> [OPTIONS]");
            eprintln!("Try 'mars-mission-analyzer --help' for more information.");
            process::exit(1);
        }
    };

    // Process the file
    let (mut missions, stats) = match process_file(&file_path, args.verbose) {
        Ok(result) => result,
        Err(e) => {
            eprintln!("ERROR: {}", e);
            process::exit(1);
        }
    };

    // Check if we found any valid missions
    if missions.is_empty() {
        eprintln!("ERROR: No valid completed Mars missions found.");
        if stats.data_lines == 0 {
            eprintln!("ERROR: No data lines were processed. Check file format.");
        } else if stats.mars_missions == 0 {
            eprintln!("ERROR: No Mars missions found in the log file.");
        } else if stats.completed_mars_missions == 0 {
            eprintln!("ERROR: Mars missions found but none with 'Completed' status.");
        } else {
            eprintln!("ERROR: Completed Mars missions found but all had invalid data.");
        }
        process::exit(1);
    }

    // Sort missions by duration (descending)
    missions.sort_by(|a, b| b.duration.cmp(&a.duration));

    // Limit to top N
    let num_to_show = args.top.min(missions.len());
    missions.truncate(num_to_show);

    // Output based on format
    match args.format {
        OutputFormat::Default => print_default_output(&missions, args.verbose, &stats),
        OutputFormat::Json => print_json_output(&missions, &stats),
        OutputFormat::Csv => print_csv_output(&missions),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_mission_from_line_valid() {
        let line = "2045-07-12 | KLM-1234 | Mars | Completed | 5 | 387 | 98.7 | TRX-842-YHG";
        let mission = Mission::from_line(line, 1).unwrap();

        assert_eq!(mission.date, "2045-07-12");
        assert_eq!(mission.mission_id, "KLM-1234");
        assert_eq!(mission.destination, "Mars");
        assert_eq!(mission.status, "Completed");
        assert_eq!(mission.crew_size, 5);
        assert_eq!(mission.duration, 387);
        assert_eq!(mission.success_rate, 98.7);
        assert_eq!(mission.security_code, "TRX-842-YHG");
        assert_eq!(mission.line_number, 1);
    }

    #[test]
    fn test_mission_from_line_with_whitespace() {
        let line = "  2045-07-12  |  KLM-1234  |  Mars  |  Completed  |  5  |  387  |  98.7  |  TRX-842-YHG  ";
        let mission = Mission::from_line(line, 5).unwrap();

        assert_eq!(mission.date, "2045-07-12");
        assert_eq!(mission.mission_id, "KLM-1234");
        assert_eq!(mission.security_code, "TRX-842-YHG");
    }

    #[test]
    fn test_mission_from_line_insufficient_fields() {
        let line = "2045-07-12 | KLM-1234 | Mars";
        let mission = Mission::from_line(line, 1);

        assert!(mission.is_none());
    }

    #[test]
    fn test_mission_from_line_invalid_numbers() {
        let line = "2045-07-12 | KLM-1234 | Mars | Completed | abc | 387 | 98.7 | TRX-842-YHG";
        let mission = Mission::from_line(line, 1);

        assert!(mission.is_none());
    }

    #[test]
    fn test_is_valid_security_code_valid() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "Mars".to_string(),
            status: "Completed".to_string(),
            crew_size: 5,
            duration: 387,
            success_rate: 98.7,
            security_code: "TRX-842-YHG".to_string(),
            line_number: 1,
        };

        assert!(mission.is_valid_security_code());
    }

    #[test]
    fn test_is_valid_security_code_invalid_formats() {
        let test_cases = vec![
            "TRX-842-YH",      // Too short
            "TRX-842-YHGG",    // Too long
            "trx-842-yhg",     // Lowercase
            "TRX-84-YHG",      // Wrong middle part
            "TX-842-YHG",      // Wrong first part
            "TRX842YHG",       // No dashes
            "TRX-ABC-YHG",     // Letters in middle
        ];

        for code in test_cases {
            let mission = Mission {
                date: "2045-07-12".to_string(),
                mission_id: "KLM-1234".to_string(),
                destination: "Mars".to_string(),
                status: "Completed".to_string(),
                crew_size: 5,
                duration: 387,
                success_rate: 98.7,
                security_code: code.to_string(),
                line_number: 1,
            };

            assert!(!mission.is_valid_security_code(), "Expected {} to be invalid", code);
        }
    }

    #[test]
    fn test_is_completed_mars_mission_valid() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "Mars".to_string(),
            status: "Completed".to_string(),
            crew_size: 5,
            duration: 387,
            success_rate: 98.7,
            security_code: "TRX-842-YHG".to_string(),
            line_number: 1,
        };

        assert!(mission.is_completed_mars_mission());
    }

    #[test]
    fn test_is_completed_mars_mission_case_insensitive() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "MARS".to_string(),
            status: "COMPLETED".to_string(),
            crew_size: 5,
            duration: 387,
            success_rate: 98.7,
            security_code: "TRX-842-YHG".to_string(),
            line_number: 1,
        };

        assert!(mission.is_completed_mars_mission());
    }

    #[test]
    fn test_is_completed_mars_mission_wrong_destination() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "Jupiter".to_string(),
            status: "Completed".to_string(),
            crew_size: 5,
            duration: 387,
            success_rate: 98.7,
            security_code: "TRX-842-YHG".to_string(),
            line_number: 1,
        };

        assert!(!mission.is_completed_mars_mission());
    }

    #[test]
    fn test_is_completed_mars_mission_wrong_status() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "Mars".to_string(),
            status: "Failed".to_string(),
            crew_size: 5,
            duration: 387,
            success_rate: 98.7,
            security_code: "TRX-842-YHG".to_string(),
            line_number: 1,
        };

        assert!(!mission.is_completed_mars_mission());
    }

    #[test]
    fn test_is_completed_mars_mission_zero_duration() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "Mars".to_string(),
            status: "Completed".to_string(),
            crew_size: 5,
            duration: 0,
            success_rate: 98.7,
            security_code: "TRX-842-YHG".to_string(),
            line_number: 1,
        };

        assert!(!mission.is_completed_mars_mission());
    }

    #[test]
    fn test_is_completed_mars_mission_invalid_code() {
        let mission = Mission {
            date: "2045-07-12".to_string(),
            mission_id: "KLM-1234".to_string(),
            destination: "Mars".to_string(),
            status: "Completed".to_string(),
            crew_size: 5,
            duration: 387,
            success_rate: 98.7,
            security_code: "INVALID".to_string(),
            line_number: 1,
        };

        assert!(!mission.is_completed_mars_mission());
    }

    #[test]
    fn test_is_comment_or_metadata() {
        assert!(is_comment_or_metadata("# This is a comment"));
        assert!(is_comment_or_metadata("  # Comment with leading space"));
        assert!(is_comment_or_metadata("SYSTEM: Something"));
        assert!(is_comment_or_metadata("CONFIG: value"));
        assert!(is_comment_or_metadata("CHECKSUM: 12345"));
        assert!(is_comment_or_metadata(""));
        assert!(is_comment_or_metadata("   "));

        assert!(!is_comment_or_metadata("2045-07-12 | KLM-1234 | Mars | Completed | 5 | 387 | 98.7 | TRX-842-YHG"));
    }

    #[test]
    fn test_mission_sorting() {
        let mut missions = vec![
            Mission {
                date: "2045-07-12".to_string(),
                mission_id: "M1".to_string(),
                destination: "Mars".to_string(),
                status: "Completed".to_string(),
                crew_size: 5,
                duration: 100,
                success_rate: 98.7,
                security_code: "TRX-842-YHG".to_string(),
                line_number: 1,
            },
            Mission {
                date: "2046-07-12".to_string(),
                mission_id: "M2".to_string(),
                destination: "Mars".to_string(),
                status: "Completed".to_string(),
                crew_size: 5,
                duration: 500,
                success_rate: 98.7,
                security_code: "ABC-123-XYZ".to_string(),
                line_number: 2,
            },
            Mission {
                date: "2047-07-12".to_string(),
                mission_id: "M3".to_string(),
                destination: "Mars".to_string(),
                status: "Completed".to_string(),
                crew_size: 5,
                duration: 300,
                success_rate: 98.7,
                security_code: "DEF-456-GHI".to_string(),
                line_number: 3,
            },
        ];

        missions.sort_by(|a, b| b.duration.cmp(&a.duration));

        assert_eq!(missions[0].duration, 500);
        assert_eq!(missions[1].duration, 300);
        assert_eq!(missions[2].duration, 100);
    }
}
