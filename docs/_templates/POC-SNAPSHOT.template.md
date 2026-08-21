# {{PROJECT}} POC Snapshot

## Snapshot identity

| Field | Value |
| --- | --- |
| Snapshot | `{{SNAPSHOT_NAME}}` |
| Captured | {{DATE}}, {{TIMEZONE}} |
| Source | `{{REPO_PATH}}` |
| Runtime used | {{RUNTIME}} |
| Source files | {{FILE_COUNT}} |
| Source bytes | {{BYTE_COUNT}} |
| Verification | {{VERIFICATION}} |

This directory is a historical snapshot, not the live development project. Continue
implementation in the original `{{PROJECT}}` folder. Do not update this copy to match later
work; create a new named snapshot instead.

{{NARRATIVE}}

## Verify this snapshot

From the snapshot directory:

```powershell
{{VERIFY_COMMANDS}}
```

To verify file integrity, recompute SHA-256 for each file listed in `SHA256SUMS.txt`. The
ZIP's checksum is stored beside the ZIP rather than inside this folder. Both are UTF-8
without a BOM, so `sha256sum -c` accepts them directly.

## Archive policy

The folder and ZIP are marked read-only as an accidental-edit deterrent. This is not
cryptographic immutability. The SHA-256 manifest makes later changes detectable; durable
version history should eventually move into source control or append-only artifact storage.
