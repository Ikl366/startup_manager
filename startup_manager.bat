@echo off
chcp 437 >nul
setlocal EnableDelayedExpansion
title Startup Manager

:menu
cls
set "choice="
echo ============================================
echo         WINDOWS STARTUP MANAGER
echo ============================================
echo.
echo  [0] Show all startup programs
echo  [1] Remove startup programs
echo  [2] Open Startup folders
echo  [3] Exit
echo.
echo ============================================
set /p "choice=Select: "
set "choice=!choice: =!"

if "!choice!"=="0" goto show_all
if "!choice!"=="1" goto remove_interactive
if "!choice!"=="2" goto open_folder
if "!choice!"=="3" exit /b
goto menu

:show_all
cls
call :collect
echo.
echo ============================================
echo  Total: !count! entries
echo ============================================
echo.
pause
goto menu

:remove_interactive
cls
call :collect
if !count! equ 0 (
    echo No entries found.
    pause
    goto menu
)
echo ============================================
echo  Enter numbers to remove (0 = cancel):
echo  Examples: 1,3,5  or  1-5  or  1,3-7,10
echo ============================================
set "raw="
set /p "raw=Numbers: "
set "raw=!raw: =!"

if "!raw!"=="0" goto menu
if "!raw!"=="" goto menu

REM Expand ranges into full list
set "expanded="
set "input=!raw!"
:expand_start
if "!input!"=="" goto expand_done
REM Get first token before comma
for /f "tokens=1 delims=," %%a in ("!input!") do set "tok=%%a"
REM Check if token contains dash (range)
set "has_dash=0"
echo !tok! | findstr /c:"-" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=1,2 delims=-" %%x in ("!tok!") do (
        set /a "lo=%%x"
        set /a "hi=%%y"
        set /a "ri=!lo!"
        :inner_range
        if !ri! leq !hi! (
            if "!expanded!"=="" (
                set "expanded=!ri!"
            ) else (
                set "expanded=!expanded!,!ri!"
            )
            set /a ri+=1
            goto inner_range
        )
    )
) else (
    if "!expanded!"=="" (
        set "expanded=!tok!"
    ) else (
        set "expanded=!expanded!,!tok!"
    )
)
REM Remove processed token from input
set "after="
set "found_delim=0"
set "rest=!input:*%tok%=!"
if not "!rest!"=="" (
    if "!rest:~0,1!"=="," (
        set "after=!rest:~1!"
    ) else (
        set "after=!rest!"
    )
)
set "input=!after!"
goto expand_start

:expand_done
REM Show what will be removed
echo.
echo --------------------------------------------
echo  Will remove:
echo --------------------------------------------
set "ok=1"
set "elist=!expanded!"
:preview_loop
if "!elist!"=="" goto preview_done
for /f "tokens=1 delims=," %%a in ("!elist!") do set "pnum=%%a"
set /a "pn=0"
set /a "pn=!pnum!" 2>nul
if !pn! lss 1 set ok=0
if !pn! gtr !count! set ok=0
if "!k%pn%!"=="" set ok=0
if !ok! equ 1 (
    echo   !pn! ^| !k%pn%! ^| !n%pn%!
) else (
    echo   !pn! ^| INVALID
)
set "after_p="
set "rest_p=!elist:*%pnum%=!"
if not "!rest_p!"=="" (
    if "!rest_p:~0,1!"=="," (
        set "after_p=!rest_p:~1!"
    ) else (
        set "after_p=!rest_p!"
    )
)
set "elist=!after_p!"
goto preview_loop

:preview_done
echo --------------------------------------------
echo.
if "!ok!"=="0" (
    echo Some numbers are invalid!
    pause
    goto remove_interactive
)
set /p "confirm=Confirm removal? (Y/N): "
set "confirm=!confirm: =!"
if /i not "!confirm!"=="Y" (
    echo Cancelled.
    pause
    goto menu
)

REM Actually remove
set "dlist=!expanded!"
:del_loop
if "!dlist!"=="" goto del_done
for /f "tokens=1 delims=," %%a in ("!dlist!") do set "dnum=%%a"
set /a "dn=0"
set /a "dn=!dnum!" 2>nul
call :do_remove !dn!
set "after_d="
set "rest_d=!dlist:*%dnum%=!"
if not "!rest_d!"=="" (
    if "!rest_d:~0,1!"=="," (
        set "after_d=!rest_d:~1!"
    ) else (
        set "after_d=!rest_d!"
    )
)
set "dlist=!after_d!"
goto del_loop

:del_done
echo.
echo ============================================
echo  All done.
echo ============================================
echo.
pause
goto menu

:open_folder
start "" "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
start "" "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup"
goto menu

:do_remove
set /a "idx=%1"
set "rk=!k%idx%!"
set "rn=!n%idx%!"
if "!rk!"=="USERFOLDER" (
    del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\!rn!" 2>nul
) else if "!rk!"=="COMMONFOLDER" (
    del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\!rn!" 2>nul
) else if "!rk!"=="TASK" (
    schtasks /delete /tn "!rn!" /f 2>nul
) else (
    reg delete "!rk!" /v "!rn!" /f 2>nul
)
if !errorlevel! equ 0 (
    echo   [OK] !rn!
) else (
    echo   [FAIL] !rn! (run as Admin?)
)
exit /b

:collect
set count=0
echo.
echo  #  ^| Source           ^| Name
echo  ---+------------------+-----------------------------------

for /f "tokens=1,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    set "n!count!=%%a"
    echo  !count!  ^| HKCU Run        ^| %%a
)

for /f "tokens=1,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKLM\Software\Microsoft\Windows\CurrentVersion\Run"
    set "n!count!=%%a"
    echo  !count!  ^| HKLM Run        ^| %%a
)

for /f "tokens=1,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    set "n!count!=%%a"
    echo  !count!  ^| HKCU RunOnce    ^| %%a
)

for /f "tokens=1,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    set "n!count!=%%a"
    echo  !count!  ^| HKLM RunOnce    ^| %%a
)

for %%f in ("%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\*.*") do (
    set /a count+=1
    set "k!count!=USERFOLDER"
    set "n!count!=%%~nxf"
    echo  !count!  ^| Startup user     ^| %%~nxf
)

for %%f in ("%ProgramData%\Microsoft\Windows\Start Menu\Programs\Startup\*.*") do (
    set /a count+=1
    set "k!count!=COMMONFOLDER"
    set "n!count!=%%~nxf"
    echo  !count!  ^| Startup all      ^| %%~nxf
)

for /f "tokens=1,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    set "n!count!=%%a"
    echo  !count!  ^| Disabled HKCU    ^| %%a
)

for /f "tokens=1,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
    set "n!count!=%%a"
    echo  !count!  ^| Disabled HKLM    ^| %%a
)

for /f "tokens=1,*" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
    set "n!count!=%%a"
    echo  !count!  ^| 32-bit HKCU      ^| %%a
)

for /f "tokens=1,*" %%a in ('reg query "HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32" 2^>nul ^| findstr /v "HKEY_" ^| findstr /v "(Default)"') do (
    set /a count+=1
    set "k!count!=HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
    set "n!count!=%%a"
    echo  !count!  ^| 32-bit HKLM      ^| %%a
)

echo.
echo  --- Scheduled Tasks (non-Microsoft) ---
echo.
for /f "tokens=*" %%t in ('powershell -NoProfile -Command "Get-ScheduledTask | Where-Object {$_.TaskPath -notlike '\Microsoft\*'} | Select-Object -ExpandProperty TaskName" 2^>nul') do (
    set /a count+=1
    set "k!count!=TASK"
    set "n!count!=%%t"
    echo  !count!  ^| Scheduled Task  ^| %%t
)

exit /b
