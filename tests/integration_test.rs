use std::fs::File;
use std::io::Write;
use std::process::Command;
use tempfile::TempDir;

#[test]
fn test_basic_execution_with_test_data() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("tests/test_data.log")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success(), "Command should succeed");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Security Code: STU-901-FGH"));
    assert!(stdout.contains("Mission Length: 900 days"));
}

#[test]
fn test_verbose_output() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("--verbose")
        .arg("tests/test_data.log")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("Processing Statistics"));
    assert!(stderr.contains("Total lines processed:"));
    assert!(stderr.contains("Data lines:"));
}

#[test]
fn test_json_output() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("--format")
        .arg("json")
        .arg("tests/test_data.log")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);

    // Verify it's valid JSON
    let json: serde_json::Value = serde_json::from_str(&stdout)
        .expect("Output should be valid JSON");

    // Check structure
    assert!(json.get("statistics").is_some());
    assert!(json.get("missions").is_some());

    let missions = json["missions"].as_array().unwrap();
    assert!(!missions.is_empty());

    let first_mission = &missions[0];
    assert_eq!(first_mission["security_code"], "STU-901-FGH");
    assert_eq!(first_mission["duration_days"], 900);
}

#[test]
fn test_csv_output() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("--format")
        .arg("csv")
        .arg("tests/test_data.log")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);

    // Check CSV header
    assert!(stdout.contains("Rank,Date,Mission ID,Destination,Status,Crew Size,Duration (days),Success Rate,Security Code,Line Number"));

    // Check data row
    assert!(stdout.contains("STU-901-FGH"));
}

#[test]
fn test_top_n_missions() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("--top")
        .arg("3")
        .arg("--format")
        .arg("json")
        .arg("tests/test_data.log")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);
    let json: serde_json::Value = serde_json::from_str(&stdout)
        .expect("Output should be valid JSON");

    let missions = json["missions"].as_array().unwrap();
    assert_eq!(missions.len(), 3, "Should return exactly 3 missions");
}

#[test]
fn test_no_input_file_error() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success(), "Should fail without input file");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("No input file provided"));
}

#[test]
fn test_nonexistent_file_error() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("nonexistent_file.log")
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success(), "Should fail with nonexistent file");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("Failed to open file"));
}

#[test]
fn test_empty_file() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("empty.log");
    File::create(&file_path).unwrap();

    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg(&file_path)
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success(), "Should fail with empty file");

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("No valid completed Mars missions found"));
}

#[test]
fn test_file_with_only_comments() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("comments.log");
    let mut file = File::create(&file_path).unwrap();
    writeln!(file, "# This is a comment").unwrap();
    writeln!(file, "# Another comment").unwrap();
    writeln!(file, "SYSTEM: metadata").unwrap();

    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg(&file_path)
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success());

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("No valid completed Mars missions found"));
}

#[test]
fn test_file_with_no_mars_missions() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("no_mars.log");
    let mut file = File::create(&file_path).unwrap();
    writeln!(file, "2045-07-12 | KLM-1234 | Jupiter | Completed | 5 | 387 | 98.7 | TRX-842-YHG").unwrap();
    writeln!(file, "2045-08-15 | ABC-5678 | Venus | Completed | 3 | 200 | 95.0 | ABC-123-XYZ").unwrap();

    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg(&file_path)
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success());

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("No Mars missions found"));
}

#[test]
fn test_mars_missions_but_none_completed() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("no_completed.log");
    let mut file = File::create(&file_path).unwrap();
    writeln!(file, "2045-07-12 | KLM-1234 | Mars | Failed | 5 | 387 | 98.7 | TRX-842-YHG").unwrap();
    writeln!(file, "2045-08-15 | ABC-5678 | Mars | InProgress | 3 | 200 | 95.0 | ABC-123-XYZ").unwrap();

    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg(&file_path)
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success());

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("none with 'Completed' status"));
}

#[test]
fn test_completed_mars_mission_with_invalid_code() {
    let temp_dir = TempDir::new().unwrap();
    let file_path = temp_dir.path().join("invalid_code.log");
    let mut file = File::create(&file_path).unwrap();
    writeln!(file, "2045-07-12 | KLM-1234 | Mars | Completed | 5 | 387 | 98.7 | INVALID").unwrap();

    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg(&file_path)
        .output()
        .expect("Failed to execute command");

    assert!(!output.status.success());

    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(stderr.contains("all had invalid data"));
}

#[test]
fn test_real_dataset_matches_expected_result() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("data/space_missions.log")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("XRT-421-ZQP"), "Should find the correct security code");
    assert!(stdout.contains("1629 days"), "Should find the correct mission length");
}

#[test]
fn test_help_flag() {
    let output = Command::new("./target/release/mars-mission-analyzer")
        .arg("--help")
        .output()
        .expect("Failed to execute command");

    assert!(output.status.success());

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("Usage:"));
    assert!(stdout.contains("--verbose"));
    assert!(stdout.contains("--format"));
    assert!(stdout.contains("--top"));
}
