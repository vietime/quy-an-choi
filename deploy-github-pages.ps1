$ErrorActionPreference = "Stop"

$repoName = "hand-catch-camera-game"
$branch = "main"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "GitHub CLI (gh) chua duoc cai dat."
}

gh auth status

if (-not (Test-Path ".git")) {
  git init
  git branch -M $branch
}

git add index.html styles.css src manifest.webmanifest sw.js icon.svg README.md start-server.ps1
git commit -m "Initial camera hand catch game" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Khong co thay doi moi de commit, tiep tuc deploy..."
}

$owner = (gh api user --jq ".login").Trim()
$repo = "$owner/$repoName"

$exists = $true
gh repo view $repo 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
  $exists = $false
}

if (-not $exists) {
  gh repo create $repoName --public --source . --remote origin --push
} else {
  git remote remove origin 2>$null
  git remote add origin "https://github.com/$repo.git"
  git push -u origin $branch
}

gh api --method POST "repos/$repo/pages" `
  -f "source[branch]=$branch" `
  -f "source[path]=/" 2>$null

Write-Host "Deploy dang duoc GitHub Pages build."
Write-Host "Link se la: https://$owner.github.io/$repoName/"
