#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="$ROOT/.env"
if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

: "${OSS_BUCKET:?Set OSS_BUCKET in .env (see .env.example)}"
: "${OSS_ENDPOINT:?Set OSS_ENDPOINT in .env}"
: "${OSS_ACCESS_KEY_ID:?Set OSS_ACCESS_KEY_ID in .env}"
: "${OSS_ACCESS_KEY_SECRET:?Set OSS_ACCESS_KEY_SECRET in .env}"

if [[ -z "${OSS_REGION:-}" ]]; then
  endpoint_host="${OSS_ENDPOINT#https://}"
  endpoint_host="${endpoint_host#http://}"
  endpoint_host="${endpoint_host%%/*}"
  if [[ "$endpoint_host" =~ ^oss-([a-z0-9-]+)\.aliyuncs\.com$ ]]; then
    OSS_REGION="${BASH_REMATCH[1]}"
  else
    echo "Set OSS_REGION in .env (could not derive from OSS_ENDPOINT)." >&2
    exit 1
  fi
fi

OSSUTIL="$ROOT/bin/ossutil"
if [[ ! -x "$OSSUTIL" ]]; then
  if command -v ossutil >/dev/null 2>&1; then
    OSSUTIL="ossutil"
  else
    echo "ossutil not found. Run ./scripts/setup.sh first." >&2
    exit 1
  fi
fi

CONFIG_FILE="$ROOT/.ossutilconfig"
cat > "$CONFIG_FILE" <<EOF
[default]
accessKeyID = ${OSS_ACCESS_KEY_ID}
accessKeySecret = ${OSS_ACCESS_KEY_SECRET}
region = ${OSS_REGION}
endpoint = ${OSS_ENDPOINT}
EOF
chmod 600 "$CONFIG_FILE"

export JEKYLL_ENV=production
export SITE_URL="${SITE_URL:-https://shadowstitch.cn}"

PROD_OVERRIDE="$ROOT/.jekyll-prod.override.yml"
cat > "$PROD_OVERRIDE" <<EOF
url: '${SITE_URL}'
EOF

echo "==> Building Jekyll site (production, url=${SITE_URL})"
bundle exec jekyll build --config _config.yml,_config.prod.yml,"$PROD_OVERRIDE"

DEST="oss://${OSS_BUCKET}/"
echo "==> Syncing _site/ -> ${DEST}"
"$OSSUTIL" -c "$CONFIG_FILE" sync "$ROOT/_site/" "$DEST" --delete --force

# Keep static website subdirectory index enabled (needed for /coutto/ -> index.html).
echo "==> Ensuring OSS static website (SupportSubDir)"
"$OSSUTIL" -c "$CONFIG_FILE" api put-bucket-website --bucket "${OSS_BUCKET}" --website-configuration "$(cat <<'EOF'
{"IndexDocument":{"Suffix":"index.html","SupportSubDir":"true","Type":"1"},"ErrorDocument":{"Key":"404.html","HttpStatus":"404"}}
EOF
)" >/dev/null

# Keep both URL forms for key landings:
# - /page/ needs the directory marker "page/" + page/index.html (OSS SupportSubDir)
# - /page  needs a file object "page" (Universal Links / no-trailing-slash)
# Do NOT delete the "page/" marker; removing it makes HEAD /page/ 404 and can
# break CDN/browser navigation even when GET somehow still returns HTML.
echo "==> Fixing landing object keys (dir marker + no-trailing-slash)"
for page in "coutto" "en/coutto" "contact" "en/contact" "en/designer" "products/knitto/privacy" "en/products/knitto/privacy" "products/coutto/privacy" "en/products/coutto/privacy" "products/coutto/terms-of-service" "en/products/coutto/terms-of-service"; do
  if [[ -f "$ROOT/_site/${page}/index.html" ]]; then
    "$OSSUTIL" -c "$CONFIG_FILE" cp "$ROOT/_site/${page}/index.html" "oss://${OSS_BUCKET}/${page}/index.html" \
      --content-type "text/html; charset=utf-8" -f
    "$OSSUTIL" -c "$CONFIG_FILE" api put-object \
      --bucket "${OSS_BUCKET}" \
      --key "${page}/" \
      --body "" \
      --content-type "application/x-directory" >/dev/null
    "$OSSUTIL" -c "$CONFIG_FILE" cp "$ROOT/_site/${page}/index.html" "oss://${OSS_BUCKET}/${page}" \
      --content-type "text/html; charset=utf-8" -f
  fi
done

echo "==> Deploy complete."
if [[ -n "${OSS_WEBSITE_URL:-}" ]]; then
  echo "    ${OSS_WEBSITE_URL}"
fi
