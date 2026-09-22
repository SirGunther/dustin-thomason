"use strict";

const fs = require("fs");
const path = require("path");

const BLOCK_REASON =
  "LANGUAGE_POLICY_VIOLATION: The response contains a prohibited stock phrase. " +
  "Rewrite the affected response without that construction. " +
  "Do not defend the wording, mention this policy, or substitute additional commentary. " +
  "State the underlying point directly and stop when the requested answer is complete.";

let input = "";

process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  input += chunk;
});

process.stdin.on("end", () => {
  let event;
  try {
    event = JSON.parse(input);
  } catch {
    // A malformed event should not prevent Claude Code from completing a response.
    process.exitCode = 0;
    return;
  }

  const response = String(event.last_assistant_message || "").toLocaleLowerCase();
  const phraseFile = path.join(__dirname, "banned-phrases.txt");

  let banned;
  try {
    banned = fs
      .readFileSync(phraseFile, "utf8")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line && !line.startsWith("#"));
  } catch {
    // Fail open if the policy file is unavailable; a broken hook must not trap a session.
    process.exitCode = 0;
    return;
  }

  const match = banned.find((phrase) => response.includes(phrase.toLocaleLowerCase()));
  if (!match) {
    process.exitCode = 0;
    return;
  }

  process.stdout.write(
    JSON.stringify({
      decision: "block",
      reason: BLOCK_REASON,
    }),
  );
});
