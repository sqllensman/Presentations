# Prepare For Script - 15.RecoverLog..sql
# Copy Required Objects
Copy-Item "C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\Original\CorruptionChallenge7.mdf" "C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\ReadLog" -Force
Copy-Item "C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\Original\CorruptionChallenge7_log.ldf" "C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\ReadLog" -Force
Copy-Item "C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\Original\UserObjects.ndf" "C:\SQLSaturday\DBFiles\SampleDB\CorruptionChallenge7\ReadLog" -Force


