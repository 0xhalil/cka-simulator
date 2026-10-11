In namespace `s05-init` the Pods of Deployment `orders` never start: they are stuck in the `Init` phase.

The two init containers are intended to:
1. `wait-for-db`: wait until the database Service `orders-db` can be resolved via DNS,
2. `migrate`: write the file `/work/migrated` that the main container `orders` reads at startup.

The database itself (Deployment `orders-db`, image `redis:7-alpine`, listening on port `6379`) is already running.

Find and fix all problems so that the Pods of `orders` are `Running` and the log of container `orders` contains the line `migration done`.

Do not remove, rename or reorder the init containers and do not change their commands or images.
