# Script to organize loose PowerShell scripts into proper subdirectories

$scriptsRoot = "d:\Projects\project-exploration\interactive_pc\talk2windows\scripts"
Set-Location $scriptsRoot

# Define patterns for each category
$greetings = @("hello", "hi", "hey", "good-morning", "good-afternoon", "good-evening", "good-night", "bye", "goodbye", "ciao", "see-you", "howdy", "morning")
$responses = @("thank-you", "thanks", "sorry", "excuse-me", "congratulations", "well-done", "you-are-", "are-you-", "can-you-", "do-you-", "how-are-you", "how-do-you", "nice-to-meet-you", "i-am-", "everything-ok", "you-alright", "radio-check")
$fun = @("tell-me-a-joke", "tell-me-a-quote", "roll-a-dice", "count-down", "lets-play", "that-is-funny", "that-is-perfect", "i-love-", "i-miss-you", "give-me-five", "talk-to-me", "what-is-up", "come-on")
$insert = @("insert-")
$browser = @("next-tab", "previous-tab", "last-tab", "tab-", "next-page", "previous-page", "reload-page", "close-tab", "scroll-", "zoom-", "minimize-all-windows")
$reminders = @("remind-me-", "remember-number", "when-is-", "set-timer", "what-was-the-number")
$questions = @("how-is-", "how-late-", "how-much-", "how-old-", "what-date-", "what-is-the-", "what-time-", "what-about-", "where-am-i", "where-are-you", "where-is-", "who-is-")
$commands = @("be-quiet", "shut-up", "hush", "stop-talking", "louder", "softer", "turn-volume-", "set-volume-", "empty-", "save-screenshot", "take-screenshot", "copy-it", "paste-it", "enable-god-mode", "remove-print-jobs", "update-repository", "wakeup-", "call-the-police", "locate-my-phone", "read-the-news")
$show = @("show-", "moon", "spell-")
$list = @("list-")

Write-Host "Organizing scripts..." -ForegroundColor Cyan

# Move greeting scripts
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $greetings | Where-Object { $name -like "*$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\greetings\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\greetings\" -Force
}

# Move response scripts
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $responses | Where-Object { $name -like "*$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\responses\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\responses\" -Force
}

# Move fun scripts
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $fun | Where-Object { $name -like "*$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\fun\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\fun\" -Force
}

# Move insert scripts
Get-ChildItem -Path . -Filter "insert-*.ps1" -File | ForEach-Object {
    Write-Host "  Moving $($_.Name) to utilities\insert\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "utilities\insert\" -Force
}

# Move browser scripts
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $browser | Where-Object { $name -like "$_*" -or $name -like "*$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to utilities\browser\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "utilities\browser\" -Force
}

# Move reminder scripts  
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $reminders | Where-Object { $name -like "$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to utilities\reminders\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "utilities\reminders\" -Force
}

# Move question/info scripts to interaction/responses
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $questions | Where-Object { $name -like "$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\responses\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\responses\" -Force
}

# Move show/display scripts to interaction/responses
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $show | Where-Object { $name -like "$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\responses\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\responses\" -Force
}

# Move list scripts to interaction/responses
Get-ChildItem -Path . -Filter "list-*.ps1" -File | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\responses\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\responses\" -Force
}

# Move remaining command scripts to interaction/responses
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $name = $_.Name
    $commands | Where-Object { $name -like "*$_*" } | Select-Object -First 1
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\responses\" -ForegroundColor Gray
    Move-Item -Path $_.FullName -Destination "interaction\responses\" -Force
}

# Move any remaining utility scripts
Get-ChildItem -Path . -Filter "*.ps1" -File | Where-Object {
    $_.Name -like "*-*"
} | ForEach-Object {
    Write-Host "  Moving $($_.Name) to interaction\responses\ (catch-all)" -ForegroundColor Yellow
    Move-Item -Path $_.FullName -Destination "interaction\responses\" -Force
}

Write-Host ""
Write-Host "✅ Script organization complete!" -ForegroundColor Green
