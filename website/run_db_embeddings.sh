#!/bin/bash
set -e

# Trigger the db-sync before app start
cd import
python3 -m stats.main --mode=customdc --input_dir=$INPUT_DIR --output_dir="${OUTPUT_DIR}/datacommons/"
cd ../

# Build the embeddings
python3 -m tools.nl.embeddings.build_embeddings \
    --embeddings_name=user_all_minilm_mem \
    --output_dir="${OUTPUT_DIR}/datacommons/nl/embeddings" \
    --additional_catalog_path=$ADDITIONAL_CATALOG_PATH

# Clear any stale cached embeddings so the NL server downloads the freshly built version.
# gcs.maybe_download caches at /tmp (used by build_embeddings) and /workspace/nl_cache (used by NL server).
# The empty embeddings.csv created by stats.main may have been cached before build_embeddings populated it.
if [[ -d /workspace/nl_cache ]]; then
    echo "Clearing NL cache to ensure fresh embeddings are loaded."
    find /workspace/nl_cache -name "embeddings.csv" -delete 2>/dev/null || true
fi
if [[ -d /tmp ]]; then
    find /tmp -path "*/nl/embeddings/embeddings.csv" -delete 2>/dev/null || true
fi
