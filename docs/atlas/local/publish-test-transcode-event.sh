#!/bin/bash
# ============================================================
# PRDV-16216 — publish a fake Nova "video-transcode-completed" event locally
# Replicable test: takes the NEWEST uploaded file in the local DB as the
# "original", uses its own S3 object as the pretend transcoded output
# (so the S3 copy step succeeds), publishes the event to local RabbitMQ,
# then shows whether Callisto created the derived row WITH the copied length.
# Requirements: local stack up (quickstart), a file uploaded via the UI,
# INBOX_ENABLED=true, server running with working AWS creds.
# ============================================================
set -e
PSQL="docker exec callisto-postgres psql -U postgres -d callisto -tA -c"

# 1. Read the newest uploaded file + its proceeding/job/track
ROW=$($PSQL "
SELECT f.id, fa.attached_to_id, p.job_id, fa.track_type_id, t.value,
       f.file_size, COALESCE(f.length::text,''), f.file_path, f.bucket
FROM callisto.files f
JOIN callisto.file_attachments fa ON fa.id = f.file_attachments_id
JOIN callisto.proceedings p ON p.id = fa.attached_to_id
JOIN callisto.file_proceeding_track_types t ON t.id = fa.track_type_id
WHERE f.deleted_at IS NULL
ORDER BY f.id DESC LIMIT 1;")
IFS='|' read -r FILE_ID PROC_ID JOB_ID TRACK_ID TRACK_VAL FSIZE FLEN FPATH FBUCKET <<< "$ROW"
VT=$($PSQL " SELECT id FROM callisto.video_transcodes ORDER BY id LIMIT 1;")
echo "original: fileId=$FILE_ID proceeding=$PROC_ID job=$JOB_ID track=$TRACK_ID($TRACK_VAL) length=$FLEN path=$FPATH"

# 2. Build the event (runbook shape) + publish body, then publish
STAMP=$(date +%s)
node -e "
const crypto = require('crypto');
const d = new Date();
const event = {
  spec: 'com.planetdepos.messaging/1.0', kind: 'event',
  type: 'nova.proceeding.file.video-transcode-completed.v1',
  id: crypto.randomUUID(), time: d.toISOString(), source: 'nova',
  traceId: crypto.randomUUID(), correlationId: crypto.randomUUID(), causationId: null,
  schema: { uri: 'schema://nova/proceeding/file/video-transcode-completed.v1.json', version: 1 },
  data: {
    proceedingId: $PROC_ID, jobId: $JOB_ID, fileId: $FILE_ID, fileSize: $FSIZE,
    year: d.getFullYear(), month: d.getMonth()+1, day: d.getDate(),
    key: '$FPATH', fileName: 'prdv16216-test-$STAMP.mp4',
    bucketName: '$FBUCKET',
    proceedingTrackType: '$TRACK_VAL', proceedingTrackTypeId: $TRACK_ID,
    transcodedfilePath: '$FPATH', transcodedbucketName: '$FBUCKET',
    videoTranscodeValue: 'original', videoTranscodeId: $VT,
    createdAt: d.toISOString(), createdBy: 'nova', createdUserIdentity: 'nova'
  }
};
process.stdout.write(JSON.stringify({
  routing_key: 'callisto.proceeding.file.video-transcode-completed.v1',
  payload: JSON.stringify(event), payload_encoding: 'string', properties: {}
}));" > /tmp/publish-body.json
curl.exe -s -u guest:guest -H "content-type:application/json" \
  -X POST http://localhost:15672/api/exchanges/nova/nova.events/publish \
  -d @/tmp/publish-body.json
echo ""

# 3. Wait for the inbox poller, then verify
sleep 15
echo "=== inbox events (newest) ==="
$PSQL " SELECT id, processed_at IS NOT NULL AS processed, error_message FROM callisto.proceeding_inbox_events ORDER BY id DESC LIMIT 2;" 2>/dev/null \
 || $PSQL " SELECT id, processed_at IS NOT NULL AS processed FROM callisto.proceeding_inbox_events ORDER BY id DESC LIMIT 2;"
echo "=== derived rows (THE FEATURE: length should equal original's $FLEN) ==="
$PSQL "
SELECT d.id, d.file_name, d.length, fd.source_file_id
FROM callisto.files d JOIN callisto.file_derivations fd ON fd.derived_file_id = d.id
ORDER BY d.id DESC LIMIT 3;"
