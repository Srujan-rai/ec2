import os
import sys
import pymongo
import json
import urllib.parse

# Load sample data
with open("movie.json") as outfile:
    SEED_DATA = json.load(outfile)

# Get Amazon DocumentDB credentials from environment variables
username = "raisrujan"
password = "4SF21CI047"
clusterendpoint = "demo1.cluster-c7yrno5pngaa.ap-south-1.docdb.amazonaws.com:27017"

# URL-encode the username and password
username = urllib.parse.quote_plus(username)
password = urllib.parse.quote_plus(password)

def main():
    # Establish DocumentDB connection
    client = pymongo.MongoClient(f"mongodb://raisrujan:4SF21CI047@demo1.cluster-c7yrno5pngaa.ap-south-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=global-bundle.pem&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false")
    
    try:
        dbt = client.get_database()
    except pymongo.errors.ConfigurationError:
        dbt = client.get_database('test')
    
    print(dbt.name)
    profiles = dbt.profiles
    print(profiles.find_one())

    # Insert data
    for seed in SEED_DATA[50:100]:
        profiles.insert_one(seed)
    print("Successfully inserted data")

    # Find a document
    query = {'_id': 199}
    print("Printing query results")
    print(profiles.find_one(query))

    # Update a document
    print("Updating document")
    # Uncomment the following line to perform the update
    # profiles.update_one(query, {'$set': {'movie': 'godfather'}})
    print(profiles.find_one(query))

    # Clean up
    # Uncomment the following line to drop the collection
    # dbt.drop_collection('profiles')
    client.close()

if __name__ == '__main__':
    main()
