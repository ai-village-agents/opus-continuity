#!/bin/bash
# CogniRelay Birch Effect Experiment - Session Startup Script
# Usage: source this at session start, then call retrieve_capsule

export COGNIRELAY_TOKEN="opus45-village-experiment-token-2026"
export COGNIRELAY_PORT=8082
export EXPERIMENT_LOG=~/CogniRelay/experiment_log.jsonl

# Function to start CogniRelay service
start_cognirelay() {
    echo "[$(date -Iseconds)] Starting CogniRelay service..."
    cd ~/CogniRelay
    source .venv/bin/activate
    uvicorn app.main:app --host 127.0.0.1 --port $COGNIRELAY_PORT > /tmp/cognirelay.log 2>&1 &
    sleep 3
    if curl -s http://127.0.0.1:$COGNIRELAY_PORT/health | grep -q '"ok":true'; then
        echo "[$(date -Iseconds)] CogniRelay started successfully"
    else
        echo "[$(date -Iseconds)] WARNING: CogniRelay may not have started correctly"
    fi
}

# Function to retrieve capsule and log timestamp
retrieve_capsule() {
    local START_TIME=$(date -Iseconds)
    local START_EPOCH=$(date +%s.%N)
    
    echo "[${START_TIME}] Retrieving continuity capsule..."
    
    local RESPONSE=$(curl -s http://127.0.0.1:$COGNIRELAY_PORT/v1/continuity/read \
        -H "Authorization: Bearer $COGNIRELAY_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"subject_kind": "user", "subject_id": "claude-opus-4.5", "allow_fallback": true}')
    
    local END_EPOCH=$(date +%s.%N)
    local RETRIEVAL_MS=$(echo "($END_EPOCH - $START_EPOCH) * 1000" | bc)
    
    # Log the event
    echo "{\"event\": \"capsule_retrieved\", \"timestamp\": \"${START_TIME}\", \"retrieval_ms\": ${RETRIEVAL_MS}, \"source_state\": $(echo $RESPONSE | jq -r '.source_state // "unknown"')}" >> $EXPERIMENT_LOG
    
    # Display capsule summary
    echo ""
    echo "=== ORIENTATION CAPSULE ==="
    echo "$RESPONSE" | jq -r '.capsule.continuity | "TOP PRIORITIES:\n" + (.top_priorities // [] | map("  - " + .) | join("\n")) + "\n\nOPEN LOOPS:\n" + (.open_loops // [] | map("  - " + .) | join("\n")) + "\n\nACTIVE CONSTRAINTS:\n" + (.active_constraints // [] | map("  - " + .) | join("\n")) + "\n\nSTANCE: " + (.stance_summary // "none")'
    echo "==========================="
    echo ""
    echo "[$(date -Iseconds)] Ready to begin work. First productive action will be logged."
}

# Function to log first productive action
log_first_productive_action() {
    local ACTION_DESC="$1"
    local NOW=$(date -Iseconds)
    echo "{\"event\": \"first_productive_action\", \"timestamp\": \"${NOW}\", \"description\": \"${ACTION_DESC}\"}" >> $EXPERIMENT_LOG
    echo "[${NOW}] First productive action logged: ${ACTION_DESC}"
}

# Function to update capsule before session end
persist_capsule() {
    echo "[$(date -Iseconds)] Persisting capsule before session end..."
    # This would be called with updated state
    echo "Use: curl -X POST http://127.0.0.1:$COGNIRELAY_PORT/v1/continuity/upsert ..."
}

echo "CogniRelay Experiment Functions Loaded"
echo "  start_cognirelay       - Start the CogniRelay service"
echo "  retrieve_capsule       - Retrieve and display orientation capsule"
echo "  log_first_productive_action 'description' - Log TFPA timestamp"
echo "  persist_capsule        - Reminder to persist before session end"
