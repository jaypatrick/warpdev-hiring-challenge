# Warp Hiring Challenge

## About
This is a programming challenge for candidates who are interested in applying to Warp. It's meant to be short and fun -- we highly encourage you to use Agent Mode in Warp to solve the challenge! There will be fields in the application for you to share your answer and a link to Warp Shared Block containing the command you used to solve the problem.

Participation in the challenge is optional. You can still submit an application without doing the hiring challenge.

Get started by reading the [challenge description](mission_challenge.md). Good luck!

## Solution

The challenge has been solved using AWK! Run the solution with:

```bash
awk -f src/solution.awk space_missions.log
```

**Answer:**
- Security Code: `XRT-421-ZQP`
- Mission Length: `1629 days`

### Features
- Portable AWK script (works on macOS/BSD and GNU awk)
- Comprehensive error handling and validation
- Verbose mode for debugging: `awk -v verbose=1 -f src/solution.awk space_missions.log`
- Validates data format and security code patterns
- Detailed statistics and error reporting

See [WARP.md](WARP.md) for detailed documentation and architecture notes.
