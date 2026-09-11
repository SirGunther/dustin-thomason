# Robocopy Backup and Verification with PowerShell

Use this process when copying a large folder to another drive, especially when:

* Most files may already have been copied.
* Windows Explorer failed on long file paths.
* You want to copy only files Robocopy considers missing or different.
* You want to verify the backup before erasing or formatting the source drive.
* You want the Robocopy results automatically copied to the clipboard.

---

## 1. Identify the Source and Destination

The **source** is the folder containing the original files.

The **destination** is the matching folder where the backup should exist.

Example:

```text
Source:
D:\Old Computer BackUp

Destination:
C:\Users\USERNAME\Desktop\Drive Backup\Old Computer BackUp
```

### Important: Match the Folder Levels

The source and destination should represent the same folder.

Correct:

```text
D:\Movies
```

to:

```text
C:\Backup\Movies
```

Not:

```text
D:\Movies
```

to:

```text
C:\Backup
```

If the destination level is wrong, Robocopy may incorrectly report that every file needs to be copied.

---

# 2. First Run: Check Only

Always start with a dry run.

Open PowerShell (`pwsh`) and run:

```powershell
robocopy "SOURCE" "DESTINATION" /E /L /R:2 /W:2 /XJ | Tee-Object -Variable results
$results | Set-Clipboard
```

Replace `SOURCE` and `DESTINATION` with the actual paths.

Example:

```powershell
robocopy "D:\Movies" "C:\Backup\Movies" /E /L /R:2 /W:2 /XJ | Tee-Object -Variable results
$results | Set-Clipboard
```

The output will also automatically be copied to the Windows clipboard.

### Why this is safe

The important option is:

```text
/L
```

`/L` means **list only**.

Robocopy examines everything and reports what it *would* do, but it does not copy, modify, move, or delete files.

---

# 3. Read the Summary

At the bottom, Robocopy displays something like:

```text
               Total    Copied   Skipped  Mismatch    FAILED    Extras
Dirs :           500         2       498         0         0         0
Files:         10000        15      9985         0         0         0
Bytes:          50 g       5 m      50 g         0         0         0
```

The important columns are:

* **Total** — everything Robocopy found in the source.
* **Copied** — files that need to be copied.
* **Skipped** — files Robocopy considers already present and matching.
* **Mismatch** — files with conflicting metadata.
* **FAILED** — files or directories Robocopy could not process.
* **Extras** — things that exist in the destination but not in the source.

A result like this is good:

```text
Files : 155418       27    155391       0       0       0
```

It means only 27 of 155,418 files still need to be copied.

---

# 4. Perform the Actual Copy

Once the dry run looks correct, run the same operation **without `/L`**:

```powershell
robocopy "SOURCE" "DESTINATION" /E /Z /R:2 /W:2 /XJ | Tee-Object -Variable results
$results | Set-Clipboard
```

Example:

```powershell
robocopy "D:\Old Computer BackUp" "C:\Backup\Old Computer BackUp" /E /Z /R:2 /W:2 /XJ | Tee-Object -Variable results
$results | Set-Clipboard
```

Robocopy will compare the two locations and normally skip files that already match.

It will copy files it determines are missing or different.

### Options being used

```text
/E
```

Include all subfolders, including empty ones.

```text
/Z
```

Use restartable copying.

```text
/R:2
```

Retry a failed copy twice.

```text
/W:2
```

Wait two seconds between retries.

```text
/XJ
```

Exclude directory junctions. This helps avoid accidentally following certain Windows links into other locations or loops.

---

# 5. Final Verification

After the actual copy finishes, perform another dry run.

For a cleaner final report without thousands of filenames:

```powershell
robocopy "SOURCE" "DESTINATION" /E /L /R:0 /W:0 /XJ /NFL /NDL /NP | Tee-Object -Variable results
$results | Set-Clipboard
```

Example:

```powershell
robocopy "D:\Old Computer BackUp" "C:\Backup\Old Computer BackUp" /E /L /R:0 /W:0 /XJ /NFL /NDL /NP | Tee-Object -Variable results
$results | Set-Clipboard
```

The ideal result is:

```text
               Total    Copied   Skipped  Mismatch    FAILED    Extras
Files :        155418         0    155418         0         0         0
```

You want:

```text
Copied   = 0
Mismatch = 0
FAILED   = 0
```

and ideally every source file under:

```text
Skipped
```

This means Robocopy does not see anything remaining that needs to be copied.

---

# 6. Check the Root of the Drive Before Formatting

If you intend to erase or format the source drive, also check for files sitting directly at the root of the drive.

Example for `D:\`:

```powershell
$results = Get-ChildItem -LiteralPath "D:\" -Force |
    Select-Object Name, Length, Attributes |
    Format-Table -AutoSize |
    Out-String

$results
$results | Set-Clipboard
```

This displays:

* Normal folders
* Loose files
* Hidden files
* System items

Normal Windows entries may include:

```text
$RECYCLE.BIN
System Volume Information
```

Other application metadata may also appear.

Make sure every folder or file containing data you care about has been accounted for before formatting the drive.

---

# Long File Paths

Robocopy can handle paths that Windows Explorer may refuse to copy because they are too long.

If Windows long-path support needs to be enabled, run PowerShell or Command Prompt as Administrator and use:

```powershell
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f
```

Then restart Windows.

Do **not** add Robocopy's `/256` option. `/256` specifically disables support for paths longer than 256 characters.

---

# Important Safety Rules

## Do Not Use `/MIR`

Avoid:

```text
/MIR
```

unless you specifically intend to make the destination an exact mirror of the source.

`/MIR` can **delete files from the destination** that do not exist in the source.

For this backup/recovery workflow, that is unnecessary and potentially dangerous.

Also avoid:

```text
/PURGE
```

for the same reason.

---

## Copy First, Delete Later

When preparing a drive for formatting:

1. Copy the files.
2. Run the final verification.
3. Check the root of the source drive.
4. Confirm `FAILED = 0`.
5. Only then erase or format the source drive.

Do not use Robocopy to automatically delete the original files during this process.

---

# What "Skipped" Actually Means

Robocopy does not normally calculate a cryptographic hash of every file.

It compares file information such as:

* File name
* File size
* Timestamps
* Other relevant metadata

So:

```text
Skipped
```

means Robocopy considers the source and destination files equivalent according to its comparison rules.

For normal backup and migration work, this is a very useful verification method.

A true byte-for-byte integrity audit would require hashing the files separately.

---

# Quick Reference

## Safe Dry Run

```powershell
robocopy "SOURCE" "DESTINATION" /E /L /R:2 /W:2 /XJ | Tee-Object -Variable results
$results | Set-Clipboard
```

## Actual Copy

```powershell
robocopy "SOURCE" "DESTINATION" /E /Z /R:2 /W:2 /XJ | Tee-Object -Variable results
$results | Set-Clipboard
```

## Clean Final Verification

```powershell
robocopy "SOURCE" "DESTINATION" /E /L /R:0 /W:0 /XJ /NFL /NDL /NP | Tee-Object -Variable results
$results | Set-Clipboard
```

## Inspect Everything at the Root of a Drive

```powershell
$results = Get-ChildItem -LiteralPath "D:\" -Force |
    Select-Object Name, Length, Attributes |
    Format-Table -AutoSize |
    Out-String

$results
$results | Set-Clipboard
```

---

# Recommended Workflow

```text
Identify correct source and destination
            ↓
Run Robocopy with /L
            ↓
Check that most existing files are Skipped
            ↓
Remove /L and perform the copy
            ↓
Run another /L verification
            ↓
Confirm Copied = 0 and FAILED = 0
            ↓
Inspect the root of the source drive
            ↓
Only then erase or format the source drive
```
