# SQL Server 2019 — one-day ROD-style drill kit

Use this for the exact T-SQL you need for interviews: joins, `GROUP BY`/`HAVING`, `CASE`, CTEs, window functions, indexes, transactions, execution plans, and duplicate cleanup.

## Start once

```bash
cd /Users/RajeshPareek/Downloads/engineering-lab-fresh/Arena-Backend-Pitch/Hands-On/SQL-Server-2019-Practice
cp .env.example .env
# Edit .env and replace the example with your own local-only strong password.
docker compose up -d
docker ps --filter name=arena-sqlserver-2019
```

The database listens only on `127.0.0.1:1433`; it is not reachable from your network. On this Apple Silicon Mac, first start may take a little longer because SQL Server 2019 runs as an x86_64 Linux container.

## Connect from VS Code (recommended)

1. Install the **MSSQL** extension by Microsoft.
2. Create a SQL connection: server `localhost,1433`, authentication **SQL Login**, user `sa`, password from `.env`, database `master`.
3. Open `01-schema-and-seed.sql` and run it once.
4. Open `02-interview-drills.sql`; solve each block before revealing the answer below it.

## Connect from terminal (optional)

```bash
docker cp 01-schema-and-seed.sql arena-sqlserver-2019:/tmp/seed.sql
docker exec -it arena-sqlserver-2019 /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P "$(grep MSSQL_SA_PASSWORD .env | cut -d= -f2-)" \
  -i /tmp/seed.sql
```

## Reset / stop

```bash
docker compose down                 # keeps your database volume
docker compose down -v              # destroys the practice database completely
```

**Interview line:** “I practise against SQL Server 2019 locally, not only an online editor, so I can validate actual execution plans and index behaviour.”

