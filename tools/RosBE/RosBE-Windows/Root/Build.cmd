::
:: PROJECT:     RosBE - ReactOS Build Environment for Windows
:: LICENSE:     GNU General Public License v2. (see LICENSE.txt)
:: FILE:        Root/Build.cmd
:: PURPOSE:     Perform the build of ReactOS.
:: COPYRIGHT:   Copyright 2007 Daniel Reimer <reimer.daniel@freenet.de>
::                             Colin Finck <mail@colinfinck.de>
::                             Peter Ward <dralnix@gmail.com>
::
::
@echo off
if not defined _ROSBE_DEBUG set _ROSBE_DEBUG=0
if %_ROSBE_DEBUG% == 1 (
    @echo on
)

:: temporary arch definition
if "%ROS_ARCH%" == "" (
    set _TMP_ARCH=i386
) else (
    set _TMP_ARCH=%ROS_ARCH%
)

if %_ROSBE_MODULES% neq 1 (
    if exist "modules\rosapps" (
        if exist "modules\rosapps.bak"   (
            call :DELA            
        )
        echo Renaming rosapps to rosapps.bak...
        ren "modules\rosapps" "rosapps.bak"
    )
    if exist "modules\rostests" (
        if exist "modules\rostests.bak"   (
            call :DELB
        )
        echo Renaming rostests to rostests.bak...
        ren "modules\rostests" "rostests.bak"   
    )
::
:: if there are dirs in obj and output for rosapps and rostests, remove them 
:: to not have them included in iso images   
    if exist "%_ROSBE_OBJPATH%\modules\rostests" (
        echo Removing rostests obj and output files from %_ROSBE_OBJPATH%
        rd /s /q "%_ROSBE_OBJPATH%\modules\rostests"
        rd /s /q "%_ROSBE_OUTPATH%\modules\rostests"
        if exist %_ROSBE_ROSSOURCEDIR%\makefile.auto (
            echo removing makefile.auto
            del %_ROSBE_ROSSOURCEDIR%\makefile.auto
        )       
    ) else (
        if exist "%_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%\modules\rostests" (
            echo Removing rostests obj and output files from %_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%
            rd /q /s %_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%\modules\rostests
            rd /q /s %_ROSBE_ROSSOURCEDIR%\output-%_TMP_ARCH%\modules\rostests
            if exist %_ROSBE_ROSSOURCEDIR%\makefile.auto (
                echo Removing makefile.auto
                del %_ROSBE_ROSSOURCEDIR%\makefile.auto
            )  
        )
    )
    if exist %_ROSBE_OBJPATH%\modules\rosapps (
        echo Removing rosapps obj and output files
        rd /q /s %_ROSBE_OBJPATH%\modules\rosapps
        rd /q /s %_ROSBE_OUTPATH%\modules\rosapps
        if exist %_ROSBE_ROSSOURCEDIR%\makefile.auto (
	    echo removing makefile.auto
            del %_ROSBE_ROSSOURCEDIR%\makefile.auto
        )  
    ) else (
        if exist %_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%\modules\rosapps (
            echo Removing rosapps obj and output files
            rd /q /s %_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%\modules\rosapps
            rd /q /s %_ROSBE_ROSSOURCEDIR%\output-%_TMP_ARCH%\modules\rosapps
            if exist %_ROSBE_ROSSOURCEDIR%\makefile.auto (
                echo Removing makefile.auto
                del %_ROSBE_ROSSOURCEDIR%\makefile.auto
            )  
        )
    )
) else (
    if exist "modules\rosapps.bak" (
        if not exist "modules\rosapps" (
      	    echo Renaming rosapps.bak to rosapps...
            ren "modules\rosapps.bak" "rosapps"
        )
    ) else (
        if not exist "modules\rosapps" set _ROSAPP=1
    )
    if exist "modules\rostests.bak" (
 	      if not exist "modules\rostests" (
            echo Renaming rostests.bak to rostests...
            ren "modules\rostests.bak" "rostests"
        )
    ) else (
        if not exist "modules\rosapps" set _ROSTEST=1
    )
    if not exist "%_ROSBE_OBJPATH%\modules\rostests" (
        if not exist "%_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%\modules\rostests" (
            if not defined _ROSTEST (
	              if exist %_ROSBE_ROSSOURCEDIR%\makefile.auto (
                    echo Removing makefile.auto
                    del %_ROSBE_ROSSOURCEDIR%\makefile.auto
                )
            )       
        )
    )
    if not exist %_ROSBE_OBJPATH%\modules\rosapps (
        if not exist %_ROSBE_ROSSOURCEDIR%\obj-%_TMP_ARCH%\modules\rosapps (
            if not defined _ROSAPP (	
                if exist %_ROSBE_ROSSOURCEDIR%\makefile.auto (
                    echo Removing makefile.auto
                    del %_ROSBE_ROSSOURCEDIR%\makefile.auto
                )
            )
        )
    )
)

::
:: Check if config.template.rbuild is newer than config.rbuild, if it is then
:: abort the build and inform the user.
::
setlocal enabledelayedexpansion
if exist .\config.rbuild (
    "%_ROSBE_BASEDIR%\Tools\chknewer.exe" .\config.template.rbuild .\config.rbuild
    if !errorlevel! == 1 (
        echo.
        echo *** config.template.rbuild is newer than config.rbuild ***
        echo *** aborting build. Please check for changes and       ***
        echo *** update your config.rbuild.                         ***
        echo.
        endlocal
        goto :EOC
    )
)
endlocal

::
:: Check if strip, no Debug Symbols or ccache are being used and set the appropriate options.
::
if .%_ROSBE_NOSTRIP%. == .1. (
    set ROS_BUILDNOSTRIP=yes
) else (
    set ROS_BUILDNOSTRIP=no
)

if .%_ROSBE_STRIP%. == .1. (
    set ROS_LEAN_AND_MEAN=yes
) else (
    set ROS_LEAN_AND_MEAN=no
)

:: Small Security Check to prevent useless apps.
if .%ROS_LEAN_AND_MEAN%. == .yes. (
    if .%ROS_BUILDNOSTRIP%. == .yes. (
        cls
        echo Selecting Stripping and removing Debug Symbols together will most likely cause useless apps. Please deselect one of them.
        goto :EOC
    )
)

if .%_ROSBE_USECCACHE%. == .1. (
    set CCACHE_DIR=%APPDATA%\RosBE\.ccache
    set HOST_CC=ccache gcc
    set HOST_CPP=ccache g++
    set TARGET_CC=ccache gcc
    set TARGET_CPP=ccache g++
    if .%ROS_ARCH%. == .arm. (
        set TARGET_CC=ccache arm-pc-mingw32-gcc
        set TARGET_CPP=ccache arm-pc-mingw32-g++
    )
    if .%ROS_ARCH%. == .amd64. (
        set TARGET_CC=ccache x86_64-pc-mingw32-gcc
        set TARGET_CPP=ccache x86_64-pc-mingw32-g++
    )
    if .%ROS_ARCH%. == .ppc. (
        set TARGET_CC=ccache ppc-pc-mingw32-gcc
        set TARGET_CPP=ccache ppc-pc-mingw32-g++
    )
) else (
    set HOST_CC=gcc
    set HOST_CPP=g++
    set TARGET_CC=gcc
    set TARGET_CPP=g++
    if .%ROS_ARCH%. == .arm. (
        set TARGET_CC=arm-pc-mingw32-gcc
        set TARGET_CPP=arm-pc-mingw32-g++
    )
    if .%ROS_ARCH%. == .amd64. (
        set TARGET_CC=x86_64-pc-mingw32-gcc
        set TARGET_CPP=x86_64-pc-mingw32-g++
    )
    if .%ROS_ARCH%. == .ppc. (
        set TARGET_CC=ppc-pc-mingw32-gcc
        set TARGET_CPP=ppc-pc-mingw32-g++
    )
)

::
:: Check if the user has chosen to use a different object or output path
:: and set it accordingly.
::
if defined _ROSBE_OBJPATH (
    if not exist "%_ROSBE_OBJPATH%\." (
        echo ERROR: The path specified doesn't seem to exist.
        goto :EOC
    ) else (
        set ROS_INTERMEDIATE=%_ROSBE_OBJPATH%
    )
)
if defined _ROSBE_OUTPATH (
    if not exist "%_ROSBE_OUTPATH%\." (
        echo ERROR: The path specified doesn't seem to exist.
        goto :EOC
    ) else (
        set ROS_OUTPUT=%_ROSBE_OUTPATH%
        set ROS_TEMPORARY=%_ROSBE_OUTPATH%
    )
)

::
:: Get the current date and time for use in in our build log's file name.
::
call "%_ROSBE_BASEDIR%\TimeDate.cmd"

::
:: Check if writing logs is enabled, if so check if our log directory
:: exists, if it doesn't, create it.
::
if %_ROSBE_WRITELOG% == 1 (
    if not exist "%_ROSBE_LOGDIR%\." (
        mkdir "%_ROSBE_LOGDIR%" 1> NUL 2> NUL
    )
)

::
:: Check if we are using -j or not.
::
if "%1" == "multi" (
    if not "%2" == "" (
        title 'makex %2' parallel build started: %TIMERAW%   %ROS_ARCH%
    ) else (
        title 'makex' parallel build started: %TIMERAW%   %ROS_ARCH%
    )
    call :BUILDMULTI %*
) else (
    if not "%1" == "" (
        title 'make %1' build started: %TIMERAW%   %ROS_ARCH%
    ) else (
        title 'make' build started: %TIMERAW%   %ROS_ARCH%
    )
    call :BUILD %*
)
goto :EOC

:BUILD
    if %_ROSBE_SHOWTIME% == 1 (
        if %_ROSBE_WRITELOG% == 1 (
            "%_ROSBE_BASEDIR%\Tools\buildtime.exe" "%_ROSBE_MINGWMAKE%" %* 2>&1 | "%_ROSBE_BASEDIR%\Tools\tee.exe" "%_ROSBE_LOGDIR%\BuildLog-%_ROSBE_GCCVERSION%-%DATENAME%-%TIMENAME%.txt"
        ) else (
            "%_ROSBE_BASEDIR%\Tools\buildtime.exe" "%_ROSBE_MINGWMAKE%" %*
        )
    ) else (
        if %_ROSBE_WRITELOG% == 1 (
            "%_ROSBE_MINGWMAKE%" %* 2>&1 | "%_ROSBE_BASEDIR%\Tools\tee.exe" "%_ROSBE_LOGDIR%\BuildLog-%_ROSBE_GCCVERSION%-%DATENAME%-%TIMENAME%.txt"
        ) else (
            "%_ROSBE_MINGWMAKE%" %*
        )
    )
goto :EOF

:BUILDMULTI
    ::
    :: Get the number of CPUs in the system so we know how many jobs to execute.
    :: To modify the number used alter the options used with cpucount:
    :: No Option - Number of CPUs.
    :: -x1       - Number of CPUs, plus 1.
    :: -x2       - Number of CPUs, doubled.
    :: -a        - Determine the cpu count based on the inherited process affinity mask.
    ::
    for /f "usebackq" %%i in (`"%_ROSBE_BASEDIR%\Tools\cpucount.exe" -x1`) do set CPUCOUNT=%%i

    if %_ROSBE_SHOWTIME% == 1 (
        if %_ROSBE_WRITELOG% == 1 (
            "%_ROSBE_BASEDIR%\Tools\buildtime.exe" "%_ROSBE_MINGWMAKE%" -j %CPUCOUNT% %2 %3 %4 %5 %6 %7 %8 %9 2>&1 | "%_ROSBE_BASEDIR%\Tools\tee.exe" "%_ROSBE_LOGDIR%\BuildLog-%_ROSBE_GCCVERSION%-%DATENAME%-%TIMENAME%.txt"
        ) else (
            "%_ROSBE_BASEDIR%\Tools\buildtime.exe" "%_ROSBE_MINGWMAKE%" -j %CPUCOUNT% %2 %3 %4 %5 %6 %7 %8 %9
        )
    ) else (
        if %_ROSBE_WRITELOG% == 1 (
            "%_ROSBE_MINGWMAKE%" -j %CPUCOUNT% %2 %3 %4 %5 %6 %7 %8 %9 2>&1 | "%_ROSBE_BASEDIR%\Tools\tee.exe" "%_ROSBE_LOGDIR%\BuildLog-%_ROSBE_GCCVERSION%-%DATENAME%-%TIMENAME%.txt"
        ) else (
            "%_ROSBE_MINGWMAKE%" -j %CPUCOUNT% %2 %3 %4 %5 %6 %7 %8 %9
        )
    )
goto :EOF


:DELA
set /p ROSA_DEL="rosapps.bak exists! Delete it? [yes/no] "
      if /i "%ROSA_DEL%"=="no" goto :EOC
      if /i "%ROSA_DEL%"=="yes" rd /q /s "modules\rosapps.bak" > rm1.txt
goto :EOF

:DELB
set /p ROSB_DEL="rostests.bak exists! Delete it? [yes/no] "
      if /i "%ROSB_DEL%"=="no" goto :EOC
      if /i "%ROSB_DEL%"=="yes" rd /q /s "modules\rostests.bak" > rm2.txt
goto :EOF

:EOC
::
:: Highlight the fact that building has ended.
::
"%_ROSBE_BASEDIR%\Tools\flash.exe"

if defined _ROSBE_VERSION (
    title ReactOS Build Environment %_ROSBE_VERSION%
)

::
:: Unload all used Vars.
::
set ROS_BUILDNOSTRIP=
set ROS_LEAN_AND_MEAN=
set HOST_CC=
set HOST_CPP=
set TARGET_CC=
set TARGET_CPP=
set ROS_INTERMEDIATE=
set ROS_OUTPUT=
set ROS_TEMPORARY=
set CPUCOUNT=
set CCACHE_DIR=
set ROSA_DEL=
set ROSB_DEL=
set _TMP_ARCH=
set _ROS_TEST=
set _ROS_APP=
