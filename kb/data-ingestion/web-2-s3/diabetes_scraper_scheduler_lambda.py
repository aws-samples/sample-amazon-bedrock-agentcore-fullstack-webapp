#!/usr/bin/env python3
"""
Lambda-compatible Weekly Diabetes WebMD Scraper with Incremental Updates
Tracks existing content and only scrapes new/updated articles
"""

import json
import boto3
import requests
from datetime import datetime, timedelta
from typing import List, Dict, Any, Set
from urllib.parse import urlparse
import hashlib
import time
import os
from bs4 import BeautifulSoup
class ContentTracker:
    """Model for tracking scraped content"""
    def __init__(self, url_hashes=None, content_hashes=None, last_run=None, total_documents=0):
        self.url_hashes = url_hashes or set()
        self.content_hashes = content_hashes or set()
        self.last_run = last_run
        self.total_documents = total_documents
    
    def dict(self):
        return {
            'url_hashes': self.url_hashes,
            'content_hashes': self.content_hashes,
            'last_run': self.last_run,
            'total_documents': self.total_documents
        }


class IncrementalScrapingResult:
    """Model for incremental scraping results"""
    def __init__(self):
        self.new_documents_found = 0
        self.new_documents_scraped = 0
        self.updated_documents = 0
        self.skipped_existing = 0
        self.s3_objects_created = []
        self.s3_objects_updated = []
        self.errors = []
        self.next_run_scheduled = ""
    
    def dict(self):
        return {
            'new_documents_found': self.new_documents_found,
            'new_documents_scraped': self.new_documents_scraped,
            'updated_documents': self.updated_documents,
            'skipped_existing': self.skipped_existing,
            's3_objects_created': self.s3_objects_created,
            's3_objects_updated': self.s3_objects_updated,
            'errors': self.errors,
            'next_run_scheduled': self.next_run_scheduled
        }


# Initialize AWS clients
s3_client = boto3.client('s3')


def search_webmd_diabetes(query: str, max_results: int = 10) -> List[Dict[str, Any]]:
    """Search WebMD for diabetes-related content"""
    
    search_url = "https://www.webmd.com/search/search_results/default.aspx"
    params = {
        'query': f"{query} diabetes",
        'sourceType': 'undefined'
    }
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        response = requests.get(search_url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        results = []
        
        # Find search result links
        search_results = soup.find_all('a', class_='search-result-link') or soup.find_all('a', href=True)
        
        for link in search_results[:max_results]:
            href = link.get('href', '')
            if href and 'webmd.com' in href and '/diabetes' in href.lower():
                title = link.get_text(strip=True) or 'No title'
                
                # Make URL absolute
                if href.startswith('/'):
                    href = f"https://www.webmd.com{href}"
                
                results.append({
                    'title': title,
                    'url': href,
                    'source': 'WebMD',
                    'search_query': query
                })
        
        return results
        
    except Exception as e:
        print(f"Error searching WebMD for '{query}': {str(e)}")
        return []


def scrape_webmd_article(url: str) -> Dict[str, Any]:
    """Scrape content from a WebMD article"""
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Extract title
        title = soup.find('h1') or soup.find('title')
        title_text = title.get_text(strip=True) if title else 'No title'
        
        # Extract main content
        content_selectors = [
            '.article-content',
            '.content-body',
            '.main-content',
            'article',
            '.article-body'
        ]
        
        content_text = ""
        for selector in content_selectors:
            content_div = soup.select_one(selector)
            if content_div:
                # Remove script and style elements
                for script in content_div(["script", "style"]):
                    script.decompose()
                content_text = content_div.get_text(strip=True)
                break
        
        if not content_text:
            # Fallback: get all paragraph text
            paragraphs = soup.find_all('p')
            content_text = ' '.join([p.get_text(strip=True) for p in paragraphs])
        
        # Extract metadata
        published_date = None
        date_selectors = [
            'meta[name="publish-date"]',
            'meta[property="article:published_time"]',
            '.publish-date',
            '.date'
        ]
        
        for selector in date_selectors:
            date_elem = soup.select_one(selector)
            if date_elem:
                published_date = date_elem.get('content') or date_elem.get_text(strip=True)
                break
        
        return {
            'title': title_text,
            'content': content_text,
            'url': url,
            'published_date': published_date,
            'scraped_at': datetime.now().isoformat(),
            'source': 'WebMD',
            'content_length': len(content_text)
        }
        
    except Exception as e:
        print(f"Error scraping {url}: {str(e)}")
        return {
            'title': 'Error',
            'content': f"Failed to scrape: {str(e)}",
            'url': url,
            'scraped_at': datetime.now().isoformat(),
            'source': 'WebMD',
            'error': str(e)
        }


def get_content_hash(content: str) -> str:
    """Generate hash for content deduplication"""
    return hashlib.md5(content.encode('utf-8')).hexdigest()


def get_url_hash(url: str) -> str:
    """Generate hash for URL"""
    return hashlib.md5(url.encode('utf-8')).hexdigest()


def load_content_tracker(bucket_name: str, tracker_key: str = "diabetes-scraper/tracker.json") -> ContentTracker:
    """Load content tracker from S3"""
    
    try:
        response = s3_client.get_object(Bucket=bucket_name, Key=tracker_key)
        tracker_data = json.loads(response['Body'].read().decode('utf-8'))
        
        # Convert lists back to sets
        tracker_data['url_hashes'] = set(tracker_data.get('url_hashes', []))
        tracker_data['content_hashes'] = set(tracker_data.get('content_hashes', []))
        
        return ContentTracker(
            url_hashes=set(tracker_data.get('url_hashes', [])),
            content_hashes=set(tracker_data.get('content_hashes', [])),
            last_run=tracker_data.get('last_run'),
            total_documents=tracker_data.get('total_documents', 0)
        )
        
    except s3_client.exceptions.NoSuchKey:
        # First run - create new tracker
        return ContentTracker(
            last_run=datetime.now().isoformat(),
            total_documents=0
        )
    except Exception as e:
        print(f"Error loading tracker: {e}")
        return ContentTracker(
            last_run=datetime.now().isoformat(),
            total_documents=0
        )


def save_content_tracker(tracker: ContentTracker, bucket_name: str, tracker_key: str = "diabetes-scraper/tracker.json"):
    """Save content tracker to S3"""
    
    try:
        # Convert sets to lists for JSON serialization
        tracker_data = tracker.dict()
        tracker_data['url_hashes'] = list(tracker_data['url_hashes'])
        tracker_data['content_hashes'] = list(tracker_data['content_hashes'])
        
        s3_client.put_object(
            Bucket=bucket_name,
            Key=tracker_key,
            Body=json.dumps(tracker_data, indent=2),
            ContentType='application/json'
        )
        
    except Exception as e:
        print(f"Error saving tracker: {e}")


def incremental_scrape_diabetes_webmd(
    bucket_name: str,
    search_queries: List[str],
    max_results_per_query: int = 10,
    s3_prefix: str = "diabetes-webmd-weekly",
    force_update: bool = False
) -> IncrementalScrapingResult:
    """Perform incremental scraping of diabetes content from WebMD"""
    
    print(f"Starting incremental scrape for bucket: {bucket_name}")
    print(f"Search queries: {search_queries}")
    print(f"Max results per query: {max_results_per_query}")
    
    # Load existing content tracker
    tracker = load_content_tracker(bucket_name)
    
    result = IncrementalScrapingResult()
    result.new_documents_found = 0
    result.new_documents_scraped = 0
    result.updated_documents = 0
    result.skipped_existing = 0
    result.s3_objects_created = []
    result.s3_objects_updated = []
    result.errors = []
    result.next_run_scheduled = (datetime.now() + timedelta(days=7)).isoformat()
    
    try:
        # Search for articles
        all_articles = []
        for query in search_queries:
            print(f"Searching for: {query}")
            articles = search_webmd_diabetes(query, max_results_per_query)
            all_articles.extend(articles)
            time.sleep(1)  # Be respectful to the server
        
        # Remove duplicates based on URL
        unique_articles = {}
        for article in all_articles:
            unique_articles[article['url']] = article
        
        result.new_documents_found = len(unique_articles)
        print(f"Found {len(unique_articles)} unique articles")
        
        # Process each article
        for url, article_info in unique_articles.items():
            url_hash = get_url_hash(url)
            
            # Check if we've already processed this URL
            if url_hash in tracker.url_hashes and not force_update:
                result.skipped_existing += 1
                continue
            
            print(f"Scraping: {url}")
            
            # Scrape the article
            scraped_content = scrape_webmd_article(url)
            
            if 'error' in scraped_content:
                result.errors.append(f"Failed to scrape {url}: {scraped_content['error']}")
                continue
            
            # Check content hash for updates
            content_hash = get_content_hash(scraped_content['content'])
            is_new_content = content_hash not in tracker.content_hashes
            
            if is_new_content or force_update:
                # Save to S3
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                s3_key = f"{s3_prefix}/{timestamp}_{url_hash[:8]}.json"
                
                try:
                    s3_client.put_object(
                        Bucket=bucket_name,
                        Key=s3_key,
                        Body=json.dumps(scraped_content, indent=2),
                        ContentType='application/json'
                    )
                    
                    if url_hash in tracker.url_hashes:
                        result.updated_documents += 1
                        result.s3_objects_updated.append(s3_key)
                    else:
                        result.new_documents_scraped += 1
                        result.s3_objects_created.append(s3_key)
                    
                    # Update tracker
                    tracker.url_hashes.add(url_hash)
                    tracker.content_hashes.add(content_hash)
                    tracker.total_documents += 1
                    
                    print(f"Saved to S3: {s3_key}")
                    
                except Exception as e:
                    error_msg = f"Failed to save {url} to S3: {str(e)}"
                    result.errors.append(error_msg)
                    print(f"Error: {error_msg}")
            
            time.sleep(2)  # Be respectful to the server
        
        # Update tracker with current run time
        tracker.last_run = datetime.now().isoformat()
        
        # Save updated tracker
        save_content_tracker(tracker, bucket_name)
        
        print(f"Scraping completed:")
        print(f"  New documents: {result.new_documents_scraped}")
        print(f"  Updated documents: {result.updated_documents}")
        print(f"  Skipped existing: {result.skipped_existing}")
        print(f"  Errors: {len(result.errors)}")
        
        return result
        
    except Exception as e:
        error_msg = f"Scraping failed: {str(e)}"
        result.errors.append(error_msg)
        print(f"Error: {error_msg}")
        return result


if __name__ == "__main__":
    # Test the scraper
    test_result = incremental_scrape_diabetes_webmd(
        bucket_name="test-diabetes-bucket",
        search_queries=["diabetes symptoms", "diabetes treatment"],
        max_results_per_query=3
    )
    
    print(json.dumps(test_result.dict(), indent=2))