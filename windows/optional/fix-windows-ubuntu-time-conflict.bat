# http://ubuntuhandbook.org/index.php/2016/05/time-differences-ubuntu-1604-windows-10/
Reg add HKLM\SYSTEM\CurrentControlSet\Control\TimeZoneInformation /v RealTimeIsUniversal /t REG_QWORD /d 1
