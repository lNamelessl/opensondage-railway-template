<?php
// Lightweight liveness endpoint for the Railway healthcheck.
// Deliberately does NOT touch the database: the app container is healthy
// as soon as Apache serves pages; MariaDB readiness is handled by the
// migration retry loop in railway-start.sh.
http_response_code(200);
header('Content-Type: text/plain; charset=utf-8');
echo "OK\n";
