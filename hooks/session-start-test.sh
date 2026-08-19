#!/bin/bash
# session-start-test.sh - Tests for the SessionStart hook JSON payload

set -euo pipefail

tmp_payload="$(mktemp)"
trap 'rm -f "$tmp_payload"' EXIT

has_jq=0
if command -v jq >/dev/null 2>&1; then
  has_jq=1
fi

payload="$(bash hooks/session-start.sh)"
printf '%s' "$payload" > "$tmp_payload"

HAS_JQ="$has_jq" PAYLOAD_PATH="$tmp_payload" node <<'NODE'
const fs = require('fs');

const payload = JSON.parse(fs.readFileSync(process.env.PAYLOAD_PATH, 'utf8'));
const hasJq = process.env.HAS_JQ === '1';

// Every output path must emit the standard SessionStart envelope. Hosts that
// validate hook output (Codex CLI, Claude Code) reject any other shape.
const output = payload.hookSpecificOutput;

if (!output || typeof output !== 'object') {
  throw new Error('payload is missing the hookSpecificOutput envelope');
}

if (output.hookEventName !== 'SessionStart') {
  throw new Error(`expected SessionStart hookEventName, got ${output.hookEventName}`);
}

if (typeof output.additionalContext !== 'string') {
  throw new Error('additionalContext is missing or not a string');
}

// Guard against a regression to the pre-#465 {priority, message} shape.
for (const legacyKey of ['priority', 'message']) {
  if (legacyKey in payload) {
    throw new Error(`payload still carries the legacy "${legacyKey}" key`);
  }
}

const context = output.additionalContext;

if (hasJq) {
  if (!context.includes('agent-skills loaded.')) {
    throw new Error('additionalContext is missing startup preface');
  }

  if (!context.includes('# Using Agent Skills')) {
    throw new Error('additionalContext is missing using-agent-skills content');
  }
} else {
  if (!context.includes('jq is required')) {
    throw new Error('additionalContext is missing jq fallback guidance');
  }
}

console.log('session-start JSON payload OK');
NODE
