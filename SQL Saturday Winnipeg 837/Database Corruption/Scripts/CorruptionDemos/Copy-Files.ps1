# Tail of Log Backup of Damaged File

Remove-Item -Path "C:\DPS2018\DBFiles\Data\CorruptionChallenge3.mdf" -Force

Copy-Item "C:\DPS2018\DBFiles\Backup\CorruptionChallenge3_log.ldf" "C:\DPS2018\DBFiles\Log" -Force
