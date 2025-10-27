# Diabetes Web Scraper (Simplified)

A clean, AgentCore-free diabetes content scraper for WebMD that stores content in S3. This streamlined version works without external dependencies and provides automated weekly content collection.

## Overview

### ✅ What's Included:
- **Direct WebMD scraping** - No external APIs required
- **Lambda deployment** - Serverless execution
- **S3 storage** - JSON content storage
- **Incremental updates** - Avoids duplicate content
- **Weekly scheduling** - Automated via EventBridge
- **Cost-effective** - ~$1.50/month

### ❌ What's Removed:
- **Strands/AgentCore** - No agent framework dependencies
- **Tavily API** - No external search API required
- **Complex AI processing** - Simple content extraction
- **Bedrock models** - No LLM dependencies

## Architecture

```
EventBridge (Weekly) → Lambda Function → WebMD Direct Scraping → S3 Storage
```

## Files Overview

| File | Purpose |
|------|---------|
| `lambda_diabetes_scraper.py` | AWS Lambda entry point |
| `diabetes_scraper_scheduler_lambda.py` | Core scraping logic |
| `deploy_weekly_scraper.py` | Automated deployment script |
| `test_scraper.py` | Local testing script |
| `requirements_scraper.txt` | Python dependencies |

## Quick Setup

### 1. Prerequisites
```bash
# Ensure AWS credentials are configured
aws configure list

# Set your S3 bucket name (optional - defaults to mihc-diabetes-kb)
export S3_BUCKET_NAME=mihc-diabetes-kb
```

### 2. Test Locally
```bash
cd kb/data-ingestion/web-2-s3
python test_scraper.py
```

### 3. Deploy to AWS
```bash
python deploy_weekly_scraper.py mihc-diabetes-kb
```

## Configuration

### Search Queries
The scraper searches for these diabetes-related topics:
- "diabetes symptoms"
- "diabetes treatment" 
- "diabetes diet"
- "type 1 diabetes"
- "type 2 diabetes"
- "diabetes medication"

### Lambda Settings
- **Runtime**: Python 3.9
- **Memory**: 512 MB
- **Timeout**: 15 minutes
- **Schedule**: Every 7 days
- **Max results per query**: 5 (for development)

## Output Structure

Content is stored in S3 with the following structure:
```
s3://mihc-diabetes-kb/
├── diabetes-webmd-weekly/
│   ├── 20241027_143022_a1b2c3d4.json
│   ├── 20241027_143045_e5f6g7h8.json
│   └── ...
└── diabetes-scraper/
    └── tracker.json
```

### Content JSON Schema
```json
{
  "title": "Article Title",
  "content": "Full article text content...",
  "url": "https://www.webmd.com/diabetes/...",
  "published_date": "2024-01-15",
  "scraped_at": "2024-10-27T14:30:22.123456",
  "source": "WebMD",
  "content_length": 2847,
  "search_query": "diabetes symptoms"
}
```

### Tracker JSON Schema
```json
{
  "url_hashes": ["hash1", "hash2", "..."],
  "content_hashes": ["hash1", "hash2", "..."],
  "last_run": "2024-10-27T14:30:22.123456",
  "total_documents": 156
}
```

## Monitoring

### CloudWatch Logs
```bash
# View logs
aws logs tail /aws/lambda/diabetes-scraper-weekly --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/diabetes-scraper-weekly \
  --filter-pattern "ERROR"
```

### Success Indicators
```json
{
  "statusCode": 200,
  "body": {
    "success": true,
    "results": {
      "new_documents_scraped": 5,
      "updated_documents": 2,
      "skipped_existing": 15,
      "errors_count": 0
    }
  }
}
```

## Cost Estimate

**Monthly AWS costs**: ~$1.50
- **Lambda**: $0.50 (4 weekly runs, 5 min each)
- **S3 Storage**: $1.00 (1000 articles, 2KB each)
- **EventBridge**: $0.10 (4 weekly triggers)

## Troubleshooting

### Common Issues

#### 1. S3 Permission Errors
```
Error: Access Denied
```
**Solution**: Check IAM role permissions
```bash
aws iam get-role-policy \
  --role-name DiabetesScraperLambdaRole \
  --policy-name DiabetesScraperLambdaRolePolicy
```

#### 2. Timeout Errors
```
Error: Task timed out after 900.00 seconds
```
**Solution**: Reduce `max_results_per_query` or increase timeout

#### 3. Rate Limiting
```
Error: 429 Too Many Requests
```
**Solution**: Built-in delays (1-2 seconds) handle this automatically

### Debug Mode
```bash
# Test with verbose output
python test_scraper.py

# Manual Lambda invocation
aws lambda invoke \
  --function-name diabetes-scraper-weekly \
  --payload '{"bucket_name":"mihc-diabetes-kb","max_results_per_query":3}' \
  output.json
```

## Customization

### Adding New Search Queries
Edit the default queries in `lambda_diabetes_scraper.py`:
```python
search_queries = event.get('search_queries', [
    "diabetes symptoms",
    "your custom query here"
])
```

### Changing Scraping Frequency
Update EventBridge rule:
```bash
aws events put-rule \
  --name diabetes-scraper-weekly-weekly-schedule \
  --schedule-expression "rate(3 days)"  # Every 3 days instead of 7
```

## Security

### IAM Permissions
The Lambda function requires minimal permissions:
- `s3:GetObject`, `s3:PutObject`, `s3:ListBucket` on target bucket
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

### Data Privacy
- No personal information is collected
- Only public WebMD articles are scraped
- Content is stored in your private S3 bucket

### Rate Limiting
- Built-in delays between requests (1-2 seconds)
- Respectful scraping practices
- User-Agent headers identify the scraper

## Maintenance

### Regular Tasks
1. **Monitor S3 costs** - Archive old content if needed
2. **Review error logs** - Address any recurring issues
3. **Update search queries** - Keep content relevant
4. **Check content quality** - Verify scraping accuracy

### Updates
To update the scraper:
1. Modify the code files
2. Run `python deploy_weekly_scraper.py mihc-diabetes-kb`
3. Test with `python test_scraper.py`

---

*This simplified approach provides the same functionality without the complexity of AgentCore dependencies.*