# Bootstrap baseline — status

Status: **NOT YET EXECUTABLE / recovery in progress**.

The production migration ledger starts after some Lite tables already existed. Therefore, replaying `../history/` alone cannot reconstruct a blank database.

The canonical bootstrap file will be created only after exact recovery of the pre-ledger objects and comparison against the live production schema. It must include all required tables, constraints, indexes, functions, triggers, RLS policies and grants needed to reproduce the approved production baseline without relying on undocumented manual steps.

Until that proof is complete, do not create a guessed `production_schema_20260913.sql` and do not treat historical migrations as a bootstrap chain.

Required proof before this directory becomes executable:

1. complete inventory of live production objects;
2. exact capture of legacy Lite table definitions that predate the migration ledger;
3. exact capture of Phase 1A canonical objects;
4. clean-database install;
5. schema equivalence comparison with the approved production baseline;
6. no synthetic production data included in the bootstrap.
