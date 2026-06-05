# .\scripts\gitcommit.ps1
# & "C:\Users\dustin.thomason\dustin-thomason\scripts\gitcommit.ps1"

$ErrorActionPreference = "Stop"

function Confirm-YesNo {
  param(
    [string]$Question,
    [bool]$DefaultYes = $true
  )

  $suffix = if ($DefaultYes) { "[Y/n]" } else { "[y/N]" }
  $answer = Read-Host "$Question $suffix"

  if ([string]::IsNullOrWhiteSpace($answer)) {
    return $DefaultYes
  }

  return $answer -match '^(y|yes)$'
}

function Invoke-GitCommand {
  param(
    [string[]]$GitArgs
  )

  Write-Host "`n> git $($GitArgs -join ' ')" -ForegroundColor Cyan
  & git @GitArgs

  if ($LASTEXITCODE -ne 0) {
    Write-Host "`nStopped because Git returned an error." -ForegroundColor Red
    exit $LASTEXITCODE
  }
}

function Get-TrimmedFirstLine {
  param(
    [object]$Value
  )

  if ($null -eq $Value) {
    return $null
  }

  $firstLine = $Value | Select-Object -First 1

  if ($null -eq $firstLine) {
    return $null
  }

  $text = ([string]$firstLine).Trim()

  if ([string]::IsNullOrWhiteSpace($text)) {
    return $null
  }

  return $text
}

function Test-GitHubRemoteUrl {
  param(
    [string]$Url
  )

  if ([string]::IsNullOrWhiteSpace($Url)) {
    return $false
  }

  $trimmedUrl = $Url.Trim()

  return (
    $trimmedUrl -match '^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?/?$' -or
    $trimmedUrl -match '^git@github\.com:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?$' -or
    $trimmedUrl -match '^ssh://git@github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(\.git)?/?$'
  )
}

function Read-GitHubRemoteUrl {
  param(
    [string]$Prompt = "`nGitHub remote URL for origin (leave blank for local-only commit)"
  )

  while ($true) {
    $remoteUrl = Read-Host $Prompt

    if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
      return $null
    }

    $remoteUrl = $remoteUrl.Trim()

    if (Test-GitHubRemoteUrl $remoteUrl) {
      Write-Host "`nRemote URL:" -ForegroundColor Yellow
      Write-Host $remoteUrl

      $useRemoteUrl = Confirm-YesNo "Use this as origin?" $true

      if ($useRemoteUrl) {
        return $remoteUrl
      }

      continue
    }

    Write-Host "`nThat does not look like a GitHub repository remote URL." -ForegroundColor Red
    Write-Host "Use the repository URL, not a commits URL, branch URL, browser page URL, or commit message." -ForegroundColor Yellow
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  https://github.com/OWNER/REPO.git"
    Write-Host "  https://github.com/OWNER/REPO"
    Write-Host "  git@github.com:OWNER/REPO.git"

    $tryAgain = Confirm-YesNo "Enter the remote URL again? No = continue local-only" $true

    if (-not $tryAgain) {
      return $null
    }
  }
}

$startingPath = (Get-Location).ProviderPath
$repoRootOutput = & git -C $startingPath rev-parse --show-toplevel 2>$null
$repoRoot = $null

if ($LASTEXITCODE -eq 0) {
  $repoRoot = Get-TrimmedFirstLine $repoRootOutput
}

if (-not $repoRoot) {
  Write-Host "`nThe current folder is not initialized as a Git repository:" -ForegroundColor Yellow
  Write-Host $startingPath

  $initializeRepo = Confirm-YesNo "Initialize this folder as a Git repository?" $false

  if (-not $initializeRepo) {
    Write-Host "`nStopped. No Git repository was initialized." -ForegroundColor Red
    exit 1
  }

  Invoke-GitCommand @("-C", $startingPath, "init")
  Invoke-GitCommand @("-C", $startingPath, "symbolic-ref", "HEAD", "refs/heads/main")

  $repoRoot = $startingPath
}

Push-Location $repoRoot

try {
  Write-Host "`nRepo: $repoRoot" -ForegroundColor Yellow

  $currentBranchOutput = & git branch --show-current
  $currentBranch = Get-TrimmedFirstLine $currentBranchOutput

  if (-not $currentBranch) {
    Write-Host "You appear to be in detached HEAD state. Stopping." -ForegroundColor Red
    exit 1
  }

  Write-Host "Current branch: $currentBranch" -ForegroundColor Yellow

  if ($currentBranch -eq "main") {
    $targetBranch = "main"
    Write-Host "Already on main." -ForegroundColor Yellow
  } else {
    $useCurrentBranch = Confirm-YesNo "Commit to current branch '$currentBranch'? No = switch to main"

    if ($useCurrentBranch) {
      $targetBranch = $currentBranch
    } else {
      $targetBranch = "main"
      Invoke-GitCommand @("switch", "main")
    }
  }

  $remoteAvailable = $false
  $originUrlOutput = & git remote get-url origin 2>$null
  $originUrl = $null

  if ($LASTEXITCODE -eq 0) {
    $originUrl = Get-TrimmedFirstLine $originUrlOutput
  }

  if ($originUrl) {
    if (Test-GitHubRemoteUrl $originUrl) {
      Write-Host "Origin remote: $originUrl" -ForegroundColor Yellow
      $remoteAvailable = $true
    } else {
      Write-Host "`nThe existing origin remote is not a valid GitHub repository URL:" -ForegroundColor Red
      Write-Host $originUrl

      $replaceOrigin = Confirm-YesNo "Replace the invalid origin now?" $true

      if ($replaceOrigin) {
        $remoteUrl = Read-GitHubRemoteUrl "`nCorrect GitHub remote URL for origin (leave blank to remove origin and commit locally)"

        if ($remoteUrl) {
          Invoke-GitCommand @("remote", "set-url", "origin", $remoteUrl)
          $remoteAvailable = $true
        } else {
          Invoke-GitCommand @("remote", "remove", "origin")
          Write-Host "`nRemoved invalid origin. This commit will remain local." -ForegroundColor Yellow
        }
      } else {
        $removeOrigin = Confirm-YesNo "Remove invalid origin and continue local-only?" $true

        if ($removeOrigin) {
          Invoke-GitCommand @("remote", "remove", "origin")
          Write-Host "`nRemoved invalid origin. This commit will remain local." -ForegroundColor Yellow
        } else {
          Write-Host "`nStopped. Origin is invalid and was not changed." -ForegroundColor Red
          exit 1
        }
      }
    }
  } else {
    $remoteUrl = Read-GitHubRemoteUrl

    if ($remoteUrl) {
      Invoke-GitCommand @("remote", "add", "origin", $remoteUrl)
      $remoteAvailable = $true
    } else {
      Write-Host "`nNo origin remote configured. This commit will remain local." -ForegroundColor Yellow
    }
  }

  $message = Read-Host "`nCommit message"

  if ([string]::IsNullOrWhiteSpace($message)) {
    Write-Host "`nStopped. Commit message cannot be blank." -ForegroundColor Red
    exit 1
  }

  Invoke-GitCommand @("add", "-A")
  Invoke-GitCommand @("commit", "-m", $message)

  if ($remoteAvailable) {
    & git ls-remote --exit-code --heads origin $targetBranch >$null 2>$null
    $lsRemoteExitCode = $LASTEXITCODE

    if ($lsRemoteExitCode -eq 0) {
      Invoke-GitCommand @("pull", "--rebase", "origin", $targetBranch)
    } elseif ($lsRemoteExitCode -eq 2) {
      Write-Host "`nRemote branch origin/$targetBranch does not exist. Skipping pull/rebase for first push." -ForegroundColor Yellow
    } else {
      Write-Host "`nStopped because the origin remote could not be checked." -ForegroundColor Red
      exit $lsRemoteExitCode
    }

    Invoke-GitCommand @("push", "-u", "origin", "HEAD")
  } else {
    Write-Host "`nSkipping pull and push because no origin remote is configured." -ForegroundColor Yellow
  }

  $commitShaOutput = & git rev-parse HEAD
  $commitSha = Get-TrimmedFirstLine $commitShaOutput
  $commitSha | Set-Clipboard

  if ($remoteAvailable) {
    Write-Host "`nCommitted and pushed:" -ForegroundColor Green
  } else {
    Write-Host "`nCommitted locally:" -ForegroundColor Green
  }

  Write-Host $commitSha
  Write-Host "Commit SHA copied to clipboard." -ForegroundColor Green
}
finally {
  Pop-Location
}