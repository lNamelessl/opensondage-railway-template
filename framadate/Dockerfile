# OpenSondage / Framadate on Railway
#
# Base: xgaia/framadate 1.1.19 — the final upstream release (2021-12-23).
# Upstream (framagit.org/framasoft/framadate) is effectively unmaintained;
# the image is pinned by digest for reproducibility.
FROM xgaia/framadate:1.1.19@sha256:edf6890dcd676b50adf7d3bdd82a2bd7c285ec7544adc9ac837de78b15e8c718

# Railway platform fix (pre-approved): force exactly one Apache MPM. Some
# platform builds boot with more than one MPM loaded and crash-loop with
# "AH00534: apache2: Configuration error: More than one MPM loaded."
# mod_php in this image requires the prefork MPM.
RUN a2dismod mpm_event || true; a2dismod mpm_worker || true; a2enmod mpm_prefork

# Ship with SMTP disabled by default. Upstream hardcodes use_smtp=true and
# points SMTP_HOST at an unreachable example relay; PHPMailer is instantiated
# with exceptions enabled and the poll-creation scripts do not catch the
# exception, so an unreachable relay turns every poll creation into a fatal
# error. Set USE_SMTP=true plus the SMTP_* variables to enable mail delivery.
ENV USE_SMTP=false

# Patch the config template (envsubst'ed at boot by railway-start.sh):
#   - make use_smtp driven by the USE_SMTP variable
#   - default the UI language to English (upstream ships French)
COPY config-template.sed /tmp/config-template.sed
RUN sed -i -f /tmp/config-template.sed /config.php && rm -f /tmp/config-template.sed

# Lightweight liveness endpoint for the Railway healthcheck (no DB access).
COPY health.php /usr/local/framadate/health.php

# Boot wrapper: regenerate the admin htpasswd + config from environment
# (replicating the upstream image CMD), then auto-run the idempotent
# database schema migration through the admin panel.
COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod +x /usr/local/bin/railway-start.sh

ENTRYPOINT ["docker-php-entrypoint"]
CMD ["/usr/local/bin/railway-start.sh"]
