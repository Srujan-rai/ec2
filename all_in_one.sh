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
client = pymongo.MongoClient(f"mongodb://{username}:{password}@demo2.cluster-c7yrno5pngaa.ap-south-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile={CA_FILE_PATH}&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false")

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

# Step 4: Load the collection info from the JSON file
collection_info=$(cat "docdb_collection_info_$(date +%Y%m%d).json")

# Step 5: Merge instance details and collection info
instance_details_json=$(cat <<EOF
{
  "InstanceDetails": $instances,
  $collection_info
}
EOF
)

# Step 6: Save merged data to JSON
echo "$instance_details_json" > documentdb_details.json
echo "Data has been saved to documentdb_details.json"

# Python script to format the JSON and export to Excel
EXCEL_SCRIPT=$(cat <<'EOF'
import json
import pandas as pd

def format_json_to_excel(json_data, output_path):
    instance_details = json_data.get("InstanceDetails", [{}])
    
    instance_details_df = pd.DataFrame(instance_details)
    
    # Combine Count and Storage columns
    instance_details_df['CountStorage'] = instance_details_df[['Count', 'Storage']].apply(lambda x: ', '.join(x.dropna().astype(str)), axis=1)
    
    # Drop unneeded columns
    instance_details_df = instance_details_df.drop(columns=['Count', 'Storage'])

    # Create structured data for final Excel output
    structured_data = {
        'InstanceDetails': ['Name', 'Type', 'CountStorage', '', ''],
        'Details': [
            instance_details_df['Name'][0],
            instance_details_df['Type'][0],
            instance_details_df['CountStorage'][0],
            '',
            ''
        ],
        'Collections': ['Collections', '', '', 'TotalCollectionSize', ''],
        'Values': [
            json_data.get("number_of_collections", "null"),
            '',
            '',
            json_data.get("total_size_MB", "null"),
            ''
        ]
    }

    # Create DataFrame and save as Excel
    final_df = pd.DataFrame(structured_data)
    final_df.to_excel(output_path, sheet_name="FormattedData", index=False)

# Load the data from documentdb_details.json
with open('documentdb_details.json', 'r') as f:
    json_data = json.load(f)

# Define output path for the Excel file
output_path = 'formatted_output.xlsx'

# Format the JSON data and write to Excel
format_json_to_excel(json_data, output_path)
print(f"Excel file saved to: {output_path}")
EOF
)

# Step 7: Create Python file for JSON to Excel conversion
echo "$EXCEL_SCRIPT" > format_json_to_excel.py

# Step 8: Run the Python script to format JSON and export to Excel
python3 format_json_to_excel.py

# Clean up
rm collect.py format_json_to_excel.py

echo "Process complete. Excel file generated as formatted_output.xlsx"
