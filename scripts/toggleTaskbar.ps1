$p='HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3';
$v=(Get-ItemProperty -Path $p).Settings;
if ($v[8] -contains "2") {
 $v[8]=3;&Set-ItemProperty -Path $p -Name Settings -Value $v;
} else {
 $v[8]=2;&Set-ItemProperty -Path $p -Name Settings -Value $v;
}
Stop-Process -f -ProcessName explorer;