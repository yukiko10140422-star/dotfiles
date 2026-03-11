# claude-skills リポジトリを自動 clone / pull する
$repoUrl = "https://github.com/yukiko10140422-star/claude-skills.git"
$targetDir = "$env:USERPROFILE\claude-skills"

if (Test-Path $targetDir) {
    Write-Host "claude-skills: pulling latest..."
    git -C $targetDir pull --ff-only
} else {
    Write-Host "claude-skills: cloning..."
    git clone $repoUrl $targetDir
}
