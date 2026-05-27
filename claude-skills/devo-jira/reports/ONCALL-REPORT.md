# On-Call Report Generator - Quick Reference

**Last Updated:** 2026-03-02

## Quick Start

```bash
# Generate report from CSV alert data
bash ~/Documents/Scripts/jira-platform/oncall-report-generator.sh

# View output
open /Users/vikash.jaiswal/Documents/Repository/oncall_report.md
```

## Prerequisites

1. CSV alert data: `/Users/vikash.jaiswal/Downloads/finalAlertData.csv`
2. Jira credentials: `~/.devo/credentials` (already configured)
3. Python 3 with requests library

## What It Does

1. **Extracts ISM tickets** from CSV alert data
2. **Fetches ticket details** from Jira API using batch processing (50 tickets per call)
3. **Calculates durations** using MINIMUM of 5 methods:
   - Created → Resolved
   - Created → Last Updated
   - First Comment → Resolved
   - First Comment → Last Comment
   - Last Updated → Resolved
4. **Categorizes tickets:**
   - **P1:** High/Critical priority + all "Dropped Datanodes"
   - **P2:** Medium/Normal priority
   - **False Positive:** Common false alarms (set to 10 min each)
5. **Generates markdown report** with Confluence-compatible tables

## Report Structure

```markdown
# On-call Report | Vikash Jaiswal | Feb 2-8, 2026

## P1 Cases (High/Critical Priority)
| Date | Ticket Number | Summary | Duration |
|------|---------------|---------|----------|
| 02-Feb-2026 | [ISM-14311](link) | Summary | 19 min |
| | | **Total Time:** | **159 Hours 6 Minutes** |

## P2 Cases (Medium/Normal Priority)
...

## False Positive Cases
...

## Summary
- **Total P1 Cases:** 43
- **Total P2 Cases:** 41
- **Total False Positive Cases:** 48
- **Total Time (Overall):** 293 Hours 4 Minutes
```

## Duration Rules

- ✅ Use **MINIMUM** duration from 5 calculation methods
- ✅ Cap all durations at **5 hours maximum**
- ✅ False positives set to **10 minutes** each
- ✅ Exclude tickets created outside on-call period

## Common False Positives

Automatically identified patterns:
- `noc_batrasio_connection_error` - Transient connection issues
- `noc_backendpipilene_detectInactivity` - Pipeline self-healing
- `noc_chasys_serreacluster` - Serrea cluster transient errors
- `noc_batrasio_workers_decrease` - Auto-scaled adjustments
- `Lookup stuck in Updating` - Normal update delays
- `Low disk space` - Auto-cleanup triggered
- `devo.mason.sync.errors` - Temporary sync failures
- `Lomana: Healthcheck` - Transient health check failures

## CSV Format

Expected columns:
```
Alert ID, Alias, TinyID, Message, Status, IsSeen, Acknowledged, Snoozed,
CreatedAt, CreatedAtDate, UpdatedAt, UpdatedAtDate, Count, Owner, Teams
```

Example:
```csv
ISM-14311,66896,IBM-EU Caixa | noc_daily_tasks_failed,closed,true,...
```

## Customization

### Change Output Location

Edit script line 7:
```bash
OUTPUT_FILE="/path/to/your/oncall_report.md"
```

### Add Manual Tickets

Edit Python section around line 149:
```python
# Add manual P1 ticket
p1_tickets.append({
    'date': '02-Feb-2026',
    'key': 'CHG-10216',
    'summary': 'Scheduled maintenance',
    'duration': '4h 30 min',
    'duration_minutes': 270
})
```

### Filter Date Range

Edit Python section around line 121:
```python
created_dt = datetime.fromisoformat(created.replace('Z', '+00:00'))

# Only include Feb 2-8, 2026
if not (datetime(2026, 2, 2) <= created_dt <= datetime(2026, 2, 8, 23, 59, 59)):
    continue
```

## Troubleshooting

### Issue: Duration too high (hundreds of hours)

**Cause:** Alert creation to closure time includes waiting periods
**Solution:** Minimum calculation automatically selects shortest duration

### Issue: ISM tickets return 404

**Cause:** ISM tickets may not be accessible via standard Jira API
**Solution:** Script continues with CSV data (sufficient for reporting)

### Issue: Pipe characters breaking Confluence tables

**Cause:** Summaries like "IBM-EU Caixa | noc_daily_tasks" contain `|`
**Solution:** Script automatically replaces ` | ` with ` - `

### Issue: Old tickets included

**Cause:** Filtering by alert trigger date, not ticket creation date
**Solution:** Script filters by Jira ticket creation date

## Performance

- **Batch Processing:** ~10 seconds for 100 tickets (recommended)
- **Individual Queries:** ~1 minute for 100 tickets

Batch processing uses JQL: `key in (ISM-1,ISM-2,...)`

## File Locations

```
~/Documents/Scripts/jira-platform/
├── oncall-report-generator.sh      # Main script
├── process_oncall_data.sh          # Processing utilities
├── process_oncall_fast.sh          # Fast processing mode
└── process_oncall_fixed.sh         # Fixed processing mode

~/Documents/Repository/
└── oncall_report.md                # Generated output

~/Downloads/
└── finalAlertData.csv              # Input CSV data

~/.jira/
├── credentials                     # Jira API credentials
└── jira-helper.sh                  # Helper functions
```

## Workflow

### 1. Export CSV from Opsgenie

Filter settings:
- Owner: `vikash.jaiswal@devo.com`
- Date Range: Your on-call period (e.g., Feb 2-8, 2026)
- Status: All (closed, open, acknowledged)

Save as: `~/Downloads/finalAlertData.csv`

### 2. Generate Report

```bash
bash ~/Documents/Scripts/jira-platform/oncall-report-generator.sh
```

Output:
```
Processing on-call data (Fast Mode)...
Extracting ISM tickets from CSV...
Found 120 unique ISM tickets
Processing 120 tickets...
Fetching batch 1/3...
  → Fetched 50 tickets
...
✅ Report generated successfully!
   P1 Cases: 43 (159 Hours 6 Minutes)
   P2 Cases: 41 (133 Hours 58 Minutes)
   Total Time: 293 Hours 4 Minutes
   Output: /Users/vikash.jaiswal/Documents/Repository/oncall_report.md
```

### 3. Review and Adjust

Open report:
```bash
open /Users/vikash.jaiswal/Documents/Repository/oncall_report.md
```

Manual adjustments:
1. Review P1/P2 categorization
2. Move "Dropped Datanodes" to P1 if needed (script does this automatically)
3. Add false positive tickets
4. Adjust durations if needed
5. Verify summary totals

### 4. Upload to Confluence

1. Open Confluence page editor
2. Copy/paste entire markdown content
3. Confluence will render tables automatically
4. Review formatting and adjust if needed

## Tips

✅ **Before Generation:**
- Ensure CSV contains only your on-call period
- Verify Owner field matches your email
- Check CSV has all required columns

✅ **After Generation:**
- Review all "Dropped Datanodes" are in P1
- Verify false positive identification
- Check duration calculations look reasonable
- Ensure hyperlinks work correctly

✅ **For Next On-Call:**
- Update false positive patterns in script
- Save common adjustments as script defaults
- Keep reference examples for comparison

## Quick Commands

```bash
# Count tickets in CSV
grep -c "ISM-" ~/Downloads/finalAlertData.csv

# Extract unique ISM tickets
awk -F',' '{print $2}' ~/Downloads/finalAlertData.csv | grep "ISM-" | sort -u

# Test single ticket in Jira
source ~/.zshrc && jira issue ISM-14311

# View report
cat ~/Documents/Repository/oncall_report.md

# Open in default editor
open ~/Documents/Repository/oncall_report.md

# Copy to clipboard (macOS)
pbcopy < ~/Documents/Repository/oncall_report.md
```

## Related Documentation

- **Main README:** `~/.claude/skills/devo-jira/README.md`
- **Jira Helper Functions:** `~/Documents/Scripts/jira-platform/jira-helper.sh`
- **Confluence Pages:** https://devoinc.atlassian.net/wiki/spaces/GLBREP

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review main README: `~/.claude/skills/devo-jira/README.md`
3. Test Jira connection: `source ~/.zshrc && jira status`

---

**Status:** ✅ Production Ready
**Last Tested:** 2026-03-02
**User:** Vikash Jaiswal (vikash.jaiswal@devo.com)
