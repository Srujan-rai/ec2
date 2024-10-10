#!/bin/bash

# Set the DocumentDB details
ENDPOINT="demo2.cluster-c7yrno5pngaa.ap-south-1.docdb.amazonaws.com"
PORT=27017
USERNAME="raisrujan"
PASSWORD="4SF21CI047"
DB_NAME="demo2"
CA_FILE_PATH="global-bundle.pem"

# Python script for collecting database stats
PYTHON_SCRIPT=$(cat <<'EOF'
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

# MongoDB client connection string
client = pymongo.MongoClient(f"mongodb://{username}:{password}@{ENDPOINT}:{PORT}/?tls=true&tlsCAFile={CA_FILE_PATH}&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false")

# Connect to the database
db = client.get_database('demo1')

# Get collection information
collections = db.list_collection_names()
number_of_collections = len(collections)

# Get database stats
db_stats = db.command("dbstats")
total_size_mb = db_stats.get('dataSize', 0) / (1024 * 1024)  # Convert bytes to MB if available
# Create output data
output_data = {
    "number_of_collections": number_of_collections,
    "total_size_MB": total_size_mb
}

# Write the data to JSON file
with open(output_file, 'w') as f:
    json.dump(output_data, f, indent=4)

print(f"Collection stats have been saved to: {output_file}")
EOF
)

# Step 1: Create Python file for collecting collection stats
echo "$PYTHON_SCRIPT" > collect.py

# Step 2: Run the Python script to gather collection info
python3 collect.py

# Step 3: Get instance details from AWS DocumentDB
instances=$(aws docdb describe-db-instances --query 'DBInstances[*].{Name:DBInstanceIdentifier, Type:DBInstanceClass, Count:DBInstanceStatus, Storage:AllocatedStorage}' --output json)

# Print instance details for debugging
echo "Instances JSON: $instances"

# Step 4: Load the collection info from the JSON file
collection_info=$(cat "docdb_collection_info_$(date +%Y%m%d).json")

# Create temporary files for merging
echo "$instances" > temp_instances.json
echo "$collection_info" > temp_collection_info.json

# Step 5: Merge instance details and collection info using Python
merged_json=$(python3 - <<EOF
import json

# Load the instances and collection info
with open("temp_instances.json") as instances_file:
    instances = json.load(instances_file)

with open("temp_collection_info.json") as collection_info_file:
    collection_info = json.load(collection_info_file)

# Merge data
merged_data = {
    "InstanceDetails": instances,
    **collection_info  # Assuming collection_info has flat structure to merge
}

# Print merged data as JSON
print(json.dumps(merged_data))
EOF
)

# Step 6: Save merged data to JSON
echo "$merged_json" > documentdb_details.json
echo "Data has been saved to documentdb_details.json"

