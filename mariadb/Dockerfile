# MariaDB backend for Framadate — the ONLY persistence in this stack
# (the Framadate app itself is stateless PHP; all polls/votes/comments
# live in MariaDB on the service volume mounted at /var/lib/mysql).
#
# mariadb:10.11 is safe for Framadate 1.1.19: its Fix_MySQL_No_Zero_Date
# migration (shipped with the app) handles the zero-date incompatibilities.
FROM mariadb:10.11@sha256:7f22313fc130a377a44999965bcb0a08dd5b21e8502824c1b864f792f9bc66ab

# Database + app user are fixed at image level (no deploy-form prompts).
# Passwords are provided as Railway service variables (MARIADB_ROOT_PASSWORD,
# MARIADB_PASSWORD) — set them as ${{secret(...)}} expressions.
ENV MARIADB_DATABASE=framadate \
    MARIADB_USER=framadate
