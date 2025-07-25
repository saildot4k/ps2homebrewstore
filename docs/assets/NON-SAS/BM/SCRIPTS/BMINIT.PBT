# Crystal Chips BootManager Initialization PBAT Script v2.2
# (c) 2005-2007 Crystal Chips - http://www.crystal-chips.com/
# For use only with Crystal Chips hardware and software.
#
# Modification Info:
# This file is modified by R3Z3N.  If you modify this script and distribute it,
# please edit this text.  Please do not change the copyright information.
# Line 37 changed to set driver path to where BM is executed from.
# However the FW still looks for USB drivers from mc0:/BM/SHARED when booted from mass:/ and pfs0:/ (mass:/ broken) which can be edited.
# Disabled HDD init for v14+ even if autoload hdd is enabled in config. Saved variable is not changed so moving memory card between CC1.X and CC2.0
# work as desired.
#
# Description:
# This script is used by BootManager(BM) to load and execute modules which are
# required by BM, as well as to set up some environmental variables.
# You can modify this script to load additional modules, add new devices, etc.
# on BM startup.

ECHO "Initializing BootManager..."

SET "BM.SCRIPTS" "$BM.BM_PATH$/SCRIPTS"

IF MATCHES "dffs:*" "$PWD$"
    # Drivers are stored on DFFS if that's where BM is loaded from.
    SET "BM.DRIVER_PATH" "dffs:/BM/SHARED"
    SET "BM.DRIVER_DEV_DRIVERS" ""
ELSEIF MATCHES "host:*" "$PWD$"
    SET "BM.DRIVER_PATH" "host:/BM/SHARED"
    SET "BM.DRIVER_DEV_DRIVERS" ""
ELSE
    # Drivers are stored on MC0 (line 32) or device BM is loaded from (line 33) for all other devices.
    # SET "BM.DRIVER_PATH" "mc0:/BM/SHARED"
    SET "BM.DRIVER_PATH" "$BM.BM_PATH$/SHARED"
    SET "BM.DRIVER_DEV_DRIVERS" "^"-m rom0:SIO2MAN^" ^"-m rom0:MCMAN^""
ENDIF

IF MATCHES "host:*" "$PWD$"
# Do not reboot the IOP if loaded from host(naplink/ps2link)
# Change this to "0" if you wish to install applications from ps2link.
# IMPORTANT: Make sure you're using the latest PS2LINK and ps2client since up until July 12 2006
# ps2client and ps2link had bugs which prevented them from working properly.
#    SET "BM.INSTALLER_MODE" "1"
    LOADEXEC "IRX" "rom0:XSIO2MAN"
    LOADEXEC "IRX" "rom0:XMCMAN"
    LOADEXEC "IRX" "rom0:XPADMAN"
ELSEIF MATCHES "pfs0:*" "$PWD$"        #TEST subsection
    LOADEXEC "IRX" "rom0:XSIO2MAN"
    LOADEXEC "IRX" "rom0:XMCMAN"
    LOADEXEC "IRX" "rom0:XPADMAN"
ELSEIF MATCHES "mass:*" "$PWD$"        #TEST subsection
    LOADEXEC "IRX" "rom0:XSIO2MAN"
    LOADEXEC "IRX" "rom0:XMCMAN"
    LOADEXEC "IRX" "rom0:XPADMAN"
ELSE
    ECHO "Rebooting IOP... $PWD$"
    # Reboot the IOP

    REBOOTIOP "rom0:UDNL rom0:OSDCNF"

    IF MATCHES "cdrom?:*" "$PWD$"
        SET "BM.INSTALLER_MODE" "1"
    ENDIF

ENDIF

#################################################################################################################################################

ECHO "Loading device drivers..."
LOADEXEC "PBATS" "$BM.BM_PATH$/DEVS/*/DEVINFO.PBT" "LOAD"

# Theme related init.
ECHO "Loading Theme..."

IF EQU "$BM.CNF_THEME_SCRIPT$" ""
    SET "BM.CNF_THEME_SCRIPT" "$BM.BM_PATH$/THMS/DEFAULT/THMINFO.PBT"
ENDIF

IF NOT EQU "$BM.CNF_THEME_SCRIPT$" "$BM.LOADED_THEME_SCRIPT$"
    IF FAIL LOADEXEC "PBAT" "$BM.CNF_THEME_SCRIPT$" "LOAD"
        ECHO "Failed loading theme!"
    ELSE
        ECHO "Loaded theme script successfully!"
    ENDIF
ENDIF

ECHO "Loading theme configuration..."
LOADEXEC "PBAT" "$BM.BM_PATH$/CONFIG/THMCONF.PBT"

# Network related init.

IF EQU "$BM.CNF_AUTO_NET_EN$" "1"
    LOADEXEC "PBAT" "$BM.SCRIPTS$/LOADNET.PBT"
ENDIF

IF EQU "$BM.CNF_AUTO_HOST_EN$" "1"
    LOADEXEC "PBAT" "$BM.SCRIPTS$/LOADHOST.PBT"
ENDIF

IF EQU "$BM.CNF_AUTO_FTPD_EN$" "1"
    LOADEXEC "PBAT" "$BM.SCRIPTS$/LOADFTPD.PBT"
ENDIF

# HDD(Hard Drive) related init. Disables HDD for v14+ and hides HDD Menu in CONFMENU.PBT
# This way the same config file can be used betweeen CC 1.x and 2.0 without having to change config file

IF LTE "$BM.BIOS_MAJOR_VER$$BM.BIOS_MINOR_VER$" "200"
    ECHO "BOOTROM 2.00 or lower, checking HDD Autoload..."
    IF EQU "$BM.CNF_AUTO_HDD_EN$" "1"
        ECHO "HDD autoload enabled!"
        LOADEXEC "PBAT" "$BM.SCRIPTS$/LOADHDD.PBT"
    ELSEIF EQU "$BM.CNF_AUTO_HDD_EN$" "0"
        ECHO "HDD autoload disabled!"
    ENDIF
ENDIF

IF EXISTS "$BM.BM_PATH$/CONFIG/MACROS.PBT"
    LOADEXEC "PBAT" "$BM.BM_PATH$/CONFIG/MACROS.PBT"
ENDIF
