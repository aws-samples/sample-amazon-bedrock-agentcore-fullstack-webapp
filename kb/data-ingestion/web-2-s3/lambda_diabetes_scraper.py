#!/usr/bin/env python3
"""
AWS Lambda function for weekly diabetes scraper
"""

import json
import os
from diabetes_scraper_scheduler_lambda import incremental_scrape_diabetes_webmd


def lambda_handler(event, context):
    """
    AWS Lambda handler for scheduled diabetes scraping
    """
    try:
        # Get configuration from event or environment variables
        bucket_name = event.get('bucket_name') or os.environ.get('S3_BUCKET_NAME', 'mihc-diabetes-kb')
        print(f"Using S3 bucket: {bucket_name}")
        
        if not bucket_name:
            return {
                'statusCode': 400,
                'body': json.dumps({
                    'error': 'S3_BUCKET_NAME not provided in event or environment variables'
                })
            }
        
        # Configuration - simplified search queries for development
        search_queries = event.get('search_queries', [
            "diabetes symptoms",
            "diabetes treatment",
            "diabetes diet",
            "type 1 diabetes",
            "type 2 diabetes",
            "diabetes medication"
        ])
        
        max_results_per_query = event.get('max_results_per_query', 5)  # Reduced for development
        s3_prefix = event.get('s3_prefix', 'diabetes-webmd-weekly')
        force_update = event.get('force_update', False)
        
        print(f"Starting incremental scrape for bucket: {bucket_name}")
        print(f"Search queries: {len(search_queries)}")
        print(f"Max results per query: {max_results_per_query}")
        
        # Run the incremental scraping
        result = incremental_scrape_diabetes_webmd(
            bucket_name=bucket_name,
            search_queries=search_queries,
            max_results_per_query=max_results_per_query,
            s3_prefix=s3_prefix,
            force_update=force_update
        )
        
        # Prepare response
        response_body = {
            'success': True,
            'execution_time': context.get_remaining_time_in_millis() if context else 'unknown',
            'results': {
                'new_documents_found': result.new_documents_found,
                'new_documents_scraped': result.new_documents_scraped,
                'updated_documents': result.updated_documents,
                'skipped_existing': result.skipped_existing,
                'total_s3_objects': len(result.s3_objects_created) + len(result.s3_objects_updated),
                'errors_count': len(result.errors),
                'next_run_scheduled': result.next_run_scheduled
            },
            'details': {
                's3_objects_created': result.s3_objects_created[:10],  # Limit for response size
                's3_objects_updated': result.s3_objects_updated[:10],
                'errors': result.errors[:5]  # Limit errors shown
            }
        }
        
        # Log summary
        print(f"✅ Scraping completed successfully")
        print(f"📊 New documents: {result.new_documents_scraped}")
        print(f"📝 Updated documents: {result.updated_documents}")
        print(f"⏭️  Skipped existing: {result.skipped_existing}")
        print(f"❌ Errors: {len(result.errors)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(response_body, indent=2)
        }
        
    except Exception as e:
        error_message = f"Lambda execution failed: {str(e)}"
        print(f"❌ {error_message}")
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': error_message,
                'execution_time': context.get_remaining_time_in_millis() if context else 'unknown'
            })
        }


# For local testing
if __name__ == "__main__":
    # Test event
    test_event = {
        'bucket_name': 'your-diabetes-research-bucket',
        'search_queries': [
            'diabetes symptoms',
            'diabetes treatment'
        ],
        'max_results_per_query': 3,
        'force_update': False
    }
    
    # Mock context
    class MockContext:
        def get_remaining_time_in_millis(self):
            return 300000  # 5 minutes
    
    result = lambda_handler(test_event, MockContext())
    print(json.dumps(result, indent=2))