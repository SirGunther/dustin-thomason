# Codex + Cursor Quick Fix Reference

Known working Codex version:

```text
26.715.61943
```

## 1. Check installed Codex versions

```powershell
Get-ChildItem "$env:USERPROFILE\.cursor\extensions" -Directory -Filter "openai.chatgpt*" |
Select-Object Name, FullName
```

## 2. Check whether the Windows editor-route bug is present

```powershell
Get-ChildItem "$env:USERPROFILE\.cursor\extensions\openai.chatgpt*\out\extension.js" -ErrorAction SilentlyContinue |
ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName)
    [PSCustomObject]@{
        Extension = $_.Directory.Parent.Name
        HasFsPathRoute = $text.Contains("fsPath,conversationId")
    }
}
```

If the active version returns `True`, continue.

## 3. Back up the working extension

```powershell
$ext = "$env:USERPROFILE\.cursor\extensions\openai.chatgpt-26.715.61943-win32-x64\out\extension.js"

Copy-Item $ext "$ext.backup"
```

## 4. Apply the fix

Close Cursor first, then run:

```powershell
$ext = "$env:USERPROFILE\.cursor\extensions\openai.chatgpt-26.715.61943-win32-x64\out\extension.js"

$text = [System.IO.File]::ReadAllText($ext)

$old = '{path:t.fsPath,conversationId:s}'
$new = '{path:n,conversationId:s}'

$count = ([regex]::Matches($text, [regex]::Escape($old))).Count
Write-Host "Occurrences before patch:" $count

if ($count -ne 1) {
    throw "Expected exactly one matching route. Nothing was changed."
}

$text = $text.Replace($old, $new)

[System.IO.File]::WriteAllText(
    $ext,
    $text,
    [System.Text.UTF8Encoding]::new($false)
)

$text2 = [System.IO.File]::ReadAllText($ext)

Write-Host "Old marker remaining:" ([regex]::Matches($text2, [regex]::Escape($old))).Count
Write-Host "New marker present:" ([regex]::Matches($text2, [regex]::Escape($new))).Count
```

Expected result:

```text
Occurrences before patch: 1
Old marker remaining: 0
New marker present: 1
```

## 5. Test

Restart Cursor and run:

```text
Codex: New Codex Agent
```

The Codex editor tab should render normally instead of going blank.

## Important

An extension update or reinstall can overwrite this patch.

The newer `26.721.30844` build had a separate problem in Cursor where Codex would not load properly at all. This quick fix was specifically confirmed working with `26.715.61943`.
