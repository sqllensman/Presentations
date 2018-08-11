# Prepare For Script - 15.RecoverLog..sql
# Copy Required Objects
Copy-Item "C:\SQLSaturday\DBFiles\Backup\CC\CC_7\CorruptionChallenge7.mdf" "C:\SQLSaturday\DBFiles\Backup\CC\CC_7\ReadLog" -Force
Copy-Item "C:\SQLSaturday\DBFiles\Backup\CC\CC_7\CorruptionChallenge7_log.ldf" "C:\SQLSaturday\DBFiles\Backup\CC\CC_7\ReadLog" -Force
Copy-Item "C:\SQLSaturday\DBFiles\Backup\CC\CC_7\UserObjects.ndf" "C:\SQLSaturday\DBFiles\Backup\CC\CC_7\ReadLog" -Force
