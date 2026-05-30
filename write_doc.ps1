$parts = @()
$parts += Get-Content "E:\yxts-llm\doc_part1.txt" -Raw -Encoding UTF8
$parts += Get-Content "E:\yxts-llm\doc_part2.txt" -Raw -Encoding UTF8
$parts += Get-Content "E:\yxts-llm\doc_part3.txt" -Raw -Encoding UTF8
$parts += Get-Content "E:\yxts-llm\doc_part4.txt" -Raw -Encoding UTF8
$parts += Get-Content "E:\yxts-llm\doc_part5.txt" -Raw -Encoding UTF8
$parts += Get-Content "E:\yxts-llm\doc_part6.txt" -Raw -Encoding UTF8
$parts += Get-Content "E:\yxts-llm\doc_part7.txt" -Raw -Encoding UTF8
$fullContent = $parts -join ''
[System.IO.File]::WriteAllText('E:\yxts-llm-godot\doc\01_worldview.md', $fullContent, [System.Text.Encoding]::UTF8)
Write-Output "File written successfully"
