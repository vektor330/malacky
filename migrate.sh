#!/bin/bash

echo "Environment migration script."
echo
echo "1. Run migrate-database.sh to get the source DB dump and the raw DB diff file."
echo "2. Run try-upgrade.sh and tune the DB diff file."
echo "3. Run migrate-patch-database.sh with the updated diff file."
echo "4. Run migrate-server.sh to finish the migration."
