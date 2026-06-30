# C:\dustin-thomason\scripts\gitcommit.d\git-maintenance.ps1

function Invoke-GitCommitMaintenance {
    Remove-DisposableCodexRefs
  }
  
  function Remove-DisposableCodexRefs {
    $gitDirOutput = & git rev-parse --git-dir 2>$null
  
    if ($LASTEXITCODE -ne 0) {
      return
    }
  
    $gitDir = ($gitDirOutput | Select-Object -First 1).Trim()
  
    if ([string]::IsNullOrWhiteSpace($gitDir)) {
      return
    }
  
    if (-not [System.IO.Path]::IsPathRooted($gitDir)) {
      $gitDir = Join-Path (Get-Location).ProviderPath $gitDir
    }
  
    $removedSomething = $false

    $codexRefsPath = Join-Path $gitDir "refs\codex"

    # Codex checkpoint refs nest two 64-char SHAs deep, so the full path routinely
    # exceeds the Windows 260-char MAX_PATH limit. A plain Remove-Item silently fails
    # on those (and -ErrorAction SilentlyContinue hid it), leaving broken refs behind
    # that make `git pull --rebase` fatal with "bad object refs/codex/...".
    # The \\?\ extended-length prefix bypasses MAX_PATH so the delete actually lands.
    if (Test-Path -LiteralPath $codexRefsPath) {
      Write-Host "`nRemoving disposable Codex Git refs:" -ForegroundColor Yellow
      Write-Host $codexRefsPath -ForegroundColor DarkYellow

      $longPath = "\\?\" + $codexRefsPath
      Remove-Item -LiteralPath $longPath -Recurse -Force -ErrorAction SilentlyContinue

      if (Test-Path -LiteralPath $codexRefsPath) {
        # Fall back to git, which can prune the broken refs when long paths are allowed.
        $refFiles = @(Get-ChildItem -LiteralPath $longPath -Recurse -File -ErrorAction SilentlyContinue)
        foreach ($refFile in $refFiles) {
          $refName = "refs/codex/" + ($refFile.FullName.Substring($codexRefsPath.Length).TrimStart('\', '/') -replace '\\', '/')
          & git -c core.longpaths=true update-ref -d $refName 2>$null
        }
        Remove-Item -LiteralPath $longPath -Recurse -Force -ErrorAction SilentlyContinue
      }

      if (Test-Path -LiteralPath $codexRefsPath) {
        Write-Host "Warning: some Codex refs could not be removed. Run with long paths enabled or delete refs\codex manually." -ForegroundColor Red
      }
      else {
        $removedSomething = $true
      }
    }
  
    $packedRefsPath = Join-Path $gitDir "packed-refs"
  
    if (Test-Path -LiteralPath $packedRefsPath) {
      $originalLines = @(Get-Content -LiteralPath $packedRefsPath)
      $filteredLines = @()
      $skipPeeledLine = $false
  
      foreach ($line in $originalLines) {
        if ($line -match '\srefs/codex/') {
          $skipPeeledLine = $true
          $removedSomething = $true
          continue
        }
  
        if ($skipPeeledLine -and $line -match '^\^') {
          continue
        }
  
        $skipPeeledLine = $false
        $filteredLines += $line
      }
  
      if ($filteredLines.Count -ne $originalLines.Count) {
        Write-Host "`nRemoving disposable Codex refs from packed-refs." -ForegroundColor Yellow
        $filteredLines | Set-Content -LiteralPath $packedRefsPath -Encoding ascii
      }
    }
  
    if ($removedSomething) {
      Write-Host "Codex refs cleaned. Normal Git refs were left untouched." -ForegroundColor Green
    }
  }