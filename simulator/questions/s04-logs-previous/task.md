The Deployment `ledger` in namespace `s04-crash` is running again, but its container crashed once shortly after the Pod started. Find out why.

1. Write the **complete log output of the crashed container instance** (not the currently running one) into `/opt/course/s04-crash/crash.log`.
2. Write the **exit code** of that crashed instance into `/opt/course/s04-crash/exit-code.txt`.
3. Write the **migration number** the application reported as failed into `/opt/course/s04-crash/migration.txt` (only the number, e.g. `0001`).

Do not restart, delete or modify the Pod or the Deployment — the evidence must stay available.
