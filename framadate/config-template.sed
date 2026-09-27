# sed script applied to the upstream /config.php envsubst template at build
# time (see framadate/Dockerfile). Kept as a file to avoid shell-escaping.
#
# 1. Drive use_smtp from the USE_SMTP environment variable. Upstream
#    hardcodes true, and with PHPMailer exceptions enabled an unreachable
#    relay fatal-errors poll creation. Shipped with USE_SMTP=false; users
#    opt in by setting USE_SMTP=true plus the SMTP_* variables.
s/'use_smtp' => true/'use_smtp' => ${USE_SMTP}/
#
# 2. Default the UI language to English (upstream ships French).
s/const DEFAULT_LANGUAGE = 'fr'/const DEFAULT_LANGUAGE = 'en'/
