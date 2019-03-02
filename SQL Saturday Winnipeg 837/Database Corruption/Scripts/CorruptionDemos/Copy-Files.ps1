# Tail of Log Backup of Damaged File

Remove-Item -Path "C:\SQLSaturday\DBFiles\Data\CorruptionChallenge3.mdf" -Force

Copy-Item "C:\SQLSaturday\DBFiles\Backup\CorruptionChallenge3_log.ldf" "C:\SQLSaturday\DBFiles\Log" -Force
