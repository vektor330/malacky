This is a set of scripts to allow easier manipulation of several environments
running on Tomcat and Postgres.

Database upgrade procedure:

  1. Run db-diff.sh to get the raw DB diff file.
  2. Run try-upgrade.sh and tune the DB diff file.
  3. Manually apply the DB diff to the target DB.

Environment migration procedure:

  1. Run migrate-database.sh to get the source DB dump and the raw DB diff file.
     The contents of conf/patch.sql is automatically appended to the end of the DB 
     diff file.
  2. Run try-upgrade.sh (source dump vs. diff file) and tune the DB diff file.
  3. Run migrate-patch-database.sh with the tuned diff file.
  4. Run migrate-server.sh to finish the migration. Make sure the backup DB
     is deleted. Make sure not clients are connected to the DB (for example 
     by restarting the DB server).

