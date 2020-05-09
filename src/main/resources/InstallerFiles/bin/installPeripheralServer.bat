@echo OFF
SETLOCAL EnableDelayedExpansion

PushD "%~dp0"

SET logFileName=..\logs\peripheralInstaller.log
SET STRING_TO_REPLACE_ARGUMENTS=arguments
SET STRING_TO_REPLACE_LOGS=logpath
SET STRING_TO_REPLACE_ENVIRONMENT_VARIABLE=env
SET ENVRIONMENT_VARIABLE_NAME=
SET InstallerJARName=
SET INSTALLATION_LOCATION_INPUT=%1
SET PERIPHERAL_SERVER_SERVICE_PORT=8080
SET PERIPHERAL_SERVER_ACTIVE_PROFILE=peripheral-server,peripheral-service
SET LAUNCH_DIRECTORY= %~dp0

rem Config XML path *******************************************************************
SET INTIALLER_INITIALIZATION_CONFIG_XML=..\config\peripheralInitializationInstaller.xml
SET INTIALLER_CONFIG_XML=..\config\peripheralInstaller.xml
SET INSTALLER_CONFIG_PROPERTY=..\config\peripheralServerInstaller.properties
SET PERIPHERAL_SERVER_INSTALLER_XML=..\serviceInstaller\peripheral-server
SET PERIPHERAL_SERVER_INSTALLER_XML_NAME=peripheral-server
rem Config XML path *******************************************************************

echo **************************************************************>>!logFileName!
echo *************                                     ************>>!logFileName!
echo ************* Running peripheral server installer ************>>!logFileName!
echo *************                                     ************>>!logFileName!
echo **************************************************************>>!logFileName!

echo **************************************************************>>!logFileName!
echo *************       Get Installation Path         ************>>!logFileName!
echo **************************************************************>>!logFileName!

For /F "tokens=1* delims==" %%A IN (!INSTALLER_CONFIG_PROPERTY!) DO (
	rem this operation checks if installation path has been provided via command line, if not get value of installation path from property file
    IF "%%A"=="peripheral.installer.installationLocation" IF [%1] == [] SET INSTALLATION_LOCATION_INPUT=%%B
    rem get enviornment variable name from property file
    IF "%%A"=="peripheral.environmentvariablename.InstalledLocation" SET ENVRIONMENT_VARIABLE_NAME=%%B
)

echo **************************************************************>>!logFileName!
echo ************* Installation Folder: %INSTALLATION_LOCATION_INPUT% **********>>!logFileName!
echo ************* Peripheral Server service port: %PERIPHERAL_SERVER_SERVICE_PORT% **********>>!logFileName!
echo ************* Peripheral Server active spring profile: %PERIPHERAL_SERVER_ACTIVE_PROFILE% **********>>!logFileName!
echo **************************************************************>>!logFileName!

rem identifyPeripheralServerInstallerJAR start--------------
:identifyPeripheralServerInstallerJAR

pushd ..
pushd lib
SET PERIPHERAL_SERVER_INSTALLER_JAR=%CD%
echo **************************************************************>>!logFileName!
echo **** Identify Peripheral Server Installer Artifacts : %PERIPHERAL_SERVER_INSTALLER_JAR%**********>>!logFileName!
echo **************************************************************>>!logFileName!

FOR /f "usebackq tokens=* delims=" %%I in (`dir *installer*.jar /b /a-d`) DO (
	SET InstallerJARName=%%I
)

echo **************************************************************>>!logFileName!
echo **** Installer Jar : !InstallerJARName!  **>>!logFileName!
echo **************************************************************>>!logFileName!
rem identifyPeripheralServerInstallerJAR end--------------

echo **************************************************************>>!logFileName!
echo ***  Identify to trigger full build or incremental build  ***>>!logFileName!
echo **************************************************************>>!logFileName!

java -classpath %PERIPHERAL_SERVER_INSTALLER_JAR%\!InstallerJARName! com.fedex.peripherals.installer.PeripheralServerInstaller "!INTIALLER_INITIALIZATION_CONFIG_XML!" "!INSTALLER_CONFIG_PROPERTY!" "!INSTALLATION_LOCATION_INPUT!">>!logFileName! 2>&1

rem checking if errorlevel is 0 or not start----------
echo **************************************************************>>!logFileName!
echo **** Error level recieved after calling peripheralInitializationInstaller.xml is: !errorlevel!>>!logFileName!
echo **************************************************************>>!logFileName!
rem IF NOT "[!errorlevel!]"=="[0]" (
rem Exit /b 1
rem )
echo errorlevel recieved !errorlevel!
IF "[!errorlevel!]"=="[2]" (
rem Error Level 2 means it is a full installation. Call the relevant actions for full installation
    echo **************************************************************>>!logFileName!
    echo Starting full build installation on location: !INSTALLATION_LOCATION_INPUT!>>!logFileName!
	echo **************************************************************>>!logFileName!
	goto :createEnvironmentvariable>>!logFileName!
) Else IF "[!errorlevel!]"=="[3]" (
rem Error Level 3 means it is a incremental installation. Call the relevant actions for full installation
	call SET INSTALLATION_LOCATION_INPUT=!%ENVRIONMENT_VARIABLE_NAME%!
	echo **************************************************************>>!logFileName!
    echo Starting incremental build installation on location: !INSTALLATION_LOCATION_INPUT!>>!logFileName!
	echo **************************************************************>>!logFileName!
    goto :startInstallation>>!logFileName!
) ELSE (
    Exit 1
)
rem checking if errorlevel is 0 or not end------------

:createEnvironmentvariable
rem create enviornment variable for peripheral server installed location -----

echo **************************************************************>>!logFileName!
echo ***  Create Enviornment Variable for Peripheral Server Installed Location  ***>>!logFileName!
echo **************************************************************>>!logFileName!
SET !ENVRIONMENT_VARIABLE_NAME! !INSTALLATION_LOCATION_INPUT!
SETX -m !ENVRIONMENT_VARIABLE_NAME! !INSTALLATION_LOCATION_INPUT! >>!logFileName!
goto :startInstallation

rem create enviornment variable for peripheral server installed location -----

:startInstallation
echo ************* Start Peripheral Server Installation ************ >>!logFileName!
java -classpath %PERIPHERAL_SERVER_INSTALLER_JAR%\!InstallerJARName! com.fedex.peripherals.installer.PeripheralServerInstaller "!INTIALLER_CONFIG_XML!" "!INSTALLER_CONFIG_PROPERTY!" "%INSTALLATION_LOCATION_INPUT%">>!logFileName! 2>&1

