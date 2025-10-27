#!/usr/bin/env python3
"""
Simple test script for the diabetes scraper (without AgentCore)
"""

import json
from diabetes_scraper_scheduler_lambda import incremental_scrape_diabetes_webmd


def test_scraper():
    """Test the scraper functionality locally"""
    
    print("🧪 Testing Diabetes Scraper")
    print("=" * 40)
    
    # Test configuration
    bucket_name = "mihc-diabetes-kb"
    search_queries = [
        "diabetes symptoms",
        "diabetes treatment"
    ]
    max_results_per_query = 2  # Small number for testing
    
    print(f"📦 Bucket: {bucket_name}")
    print(f"🔍 Queries: {search_queries}")
    print(f"📊 Max results per query: {max_results_per_query}")
    print()
    
    try:
        # Run the scraper
        result = incremental_scrape_diabetes_webmd(
            bucket_name=bucket_name,
            search_queries=search_queries,
            max_results_per_query=max_results_per_query,
            s3_prefix="diabetes-webmd-test",
            force_update=False
        )
        
        # Display results
        print("📊 Test Results:")
        print(f"  New documents found: {result.new_documents_found}")
        print(f"  New documents scraped: {result.new_documents_scraped}")
        print(f"  Updated documents: {result.updated_documents}")
        print(f"  Skipped existing: {result.skipped_existing}")
        print(f"  Errors: {len(result.errors)}")
        
        if result.s3_objects_created:
            print(f"  S3 objects created: {len(result.s3_objects_created)}")
            for obj in result.s3_objects_created[:3]:  # Show first 3
                print(f"    - {obj}")
        
        if result.errors:
            print("  Errors encountered:")
            for error in result.errors[:3]:  # Show first 3
                print(f"    - {error}")
        
        print(f"  Next run scheduled: {result.next_run_scheduled}")
        
        return True
        
    except Exception as e:
        print(f"❌ Test failed: {e}")
        return False


if __name__ == "__main__":
    success = test_scraper()
    if success:
        print("\n✅ Test completed successfully!")
        print("💡 The scraper is working without AgentCore dependencies")
    else:
        print("\n❌ Test failed!")
        print("💡 Check the error messages above")