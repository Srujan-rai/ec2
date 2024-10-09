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
client = pymongo.MongoClient(f"mongodb://raisrujan:4SF21CI047@demo1.cluster-c7yrno5pngaa.ap-south-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false")


db = client.get_database('demo1')

collections = db.list_collection_names()
number_of_collections = len(collections)

db_stats = db.command("dbstats")
total_size_mb = db_stats['dataSize'] / (1024 * 1024) 

output_data = {
    "number_of_collections": number_of_collections,
    "total_size_MB": total_size_mb
}


with open(output_file, 'w') as f:
    json.dump(output_data, f, indent=4)

print(f"Collection stats have been saved to: {output_file}")
