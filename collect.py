import pymongo
import json
from datetime import datetime
import urllib.parse

output_file = f"docdb_collection_info_{datetime.now().strftime('%Y%m%d')}.json"

CA_FILE_PATH = "global-bundle.pem"
username = "raisrujan"
password = "4SF21CI047"
username = urllib.parse.quote_plus(username)
password = urllib.parse.quote_plus(password)

client = pymongo.MongoClient(
    f"mongodb://{username}:{password}@demo1.cluster-c7yrno5pngaa.ap-south-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile={CA_FILE_PATH}&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
)

db = client.get_database('demo1')  # Specify your database name

collections = db.list_collection_names()
number_of_collections = len(collections)

# Get database stats
try:
    db_stats = db.command("dbstats")
    print("DB Stats:", db_stats)  # Print the full stats for debugging
    
    # Check if 'dataSize' exists in db_stats
    total_size_mb = db_stats.get('dataSize', 0) / (1024 * 1024)  # Default to 0 if key doesn't exist
except Exception as e:
    print(f"Error fetching db stats: {e}")
    total_size_mb = 0  # Default value in case of error

output_data = {
    "number_of_collections": number_of_collections,
    "total_size_MB": total_size_mb
}

with open(output_file, 'w') as f:
    json.dump(output_data, f, indent=4)

print(f"Collection stats have been saved to: {output_file}")
