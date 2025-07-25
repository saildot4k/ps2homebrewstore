# SAS (Save Application Support) compliant BM Script:
# Due to wildcard bug on memory card, APPINFO.PBT can not be in root folders where elf exists, so APPINFO.PBT will be in mc?:/BM/APPS/
# Memory Card structure mc?:/BM/APPS/$SAS$/APPINFO.PBT and elf in mc?:/$SAS$/APPINFO.PBT
# Non-Memory Card Structure: device:/$SAS$/APPINFO.PBT or device:/APPS/$SAS$/APPINFO.PBT NOTE: $PWD$ should work for both.

# Change this information to describe the application and where it should be ran from for memcard (SAS) or other devices (SAS_NON_MC)
# SAS is the App folder name. SAS_NON_MC defines if app is in root of non-memcard device (non_mc:/$SAS$) or APP folder (non_mc:/APPS/$SAS$)
# This is so that you do not have to edit any info below line 29.
#
# Some devices are case sensitive! Make sure your case matches!
#
# Source: https://github.com/Spaghetticode-Boon-Tobias/RETROLauncher
SET "TITLE" "[EMU] RETROLauncher"
SET "VERSION" "1.0"
SET "AUTHOR" "github.com/bucanero"
SET "DESC" "Manage save-game files on the PlayStation 2. This allows you to download, unlock, patch and resign save-game files directly on your PS2."
SET "ELF" "RETROLauncher.elf"
SET "SAS" "RETROLauncher"
# Comment out 1 of the 2 lines below. If app is in non-mc:/$SAS$ comment out the first, if in non-mc:/APPS/$SAS$ comment out the second
SET "SAS_NON_MC" "$SAS$"
# SET "SAS_NON_MC" "APPS/$SAS$"
#
# If an app does not boot, then one of these compatibility options may need to be set to 0, 1, 2 or 3
# 0= No compatibility options, 1= SHUTDOWN "MM", 2= SET "BM.AUTOLOAD_FSD_EN" "0", 3= sets both 1 and 2 (untested)
SET "COMP_MODE_MC" "1"
SET "COMP_MODE_MMCE" "1"
SET "COMP_MODE_USB" "1"
SET "COMP_MODE_HDD_APA" "1"
SET "COMP_MODE_DFFS" "1"
#

# Do not change these 2 lines!
GOTO "$ARG1$"
RETURN -1

# Used for Autoboot Labels
:LABEL_NAME
    ADDWIDGET "LABEL" "$ARG2$$TITLE$ v$VERSION$"
    EXIT 0

:QUERY
    IF MATCHES "RUN" "$ARG3$"
        ADDWIDGET "CALL" "$TITLE$" "$BM.TXT_VERSION$: $VERSION$ $BM.TXT_AUTHOR$: $AUTHOR$ $BM.TXT_DESC$: $DESC$" $ARG2$ "$ARG0$" "$ARG3$" "$ARG4$" "$ARG5$" "$TITLE$" "$PWD$" "$SAS$" "$SAS_NON_MC$"
    ENDIF
    EXIT 0

:INSTALL
        IF MATCHES "mc?" "$ARG2$"
            GOTO "INSTALL_TO_MC"
        ELSEIF NOT MATCHES "mc?" "$ARG2$"
            GOTO "INSTALL_TO_NONMC"
        ENDIF

:INSTALL_TO_MC
    IF FAIL COPY "$PWD$" "$ARG2$:/$SAS$"
        ECHO "Failed installing $TITLE$"
        MESSAGE "Failed installing $TITLE$"
        RRM "$ARG2$:/$SAS$"
        RETURN -1
    ENDIF
    EXIT 0

:INSTALL_TO_NONMC
    IF FAIL COPY "$PWD$" "$ARG2$:/$SAS_NON_MC$"
        ECHO "Failed installing $TITLE$"
        MESSAGE "Failed installing $TITLE$"
        RRM "$ARG2$:/$SAS_NON_MC$"
        RETURN -1
    ENDIF
    EXIT 0

:REMOVE
    IF FAIL RRM "$PWD$"
        GOTO "REMOVE_TRY_AGAIN"
    ENDIF
    EXIT 0

# Damn bugs...
:REMOVE_TRY_AGAIN
    IF FAIL RRM "$PWD$"
        MESSAGE "Failed removing $TITLE$"
        RETURN -1
    ENDIF
    EXIT 0

:RUN
    IF MATCHES "mc?:/*" "$PWD$"
        GOTO "RUN_ERROR"
    ELSEIF MATCHES "mmce?:/*" "$PWD$"
        GOTO "RUN_ERROR"
    ELSEIF MATCHES "mass:/*" "$PWD$"
        GOTO "RUN_USB"
    ELSEIF MATCHES "pfs0:/*" "$PWD$"
        GOTO "RUN_ERROR"
    ELSEIF MATCHES "dffs:/*" "$PWD$"
        GOTO "RUN_ERROR"
    ENDIF

:RUN_ERROR
    MESSAGE "Run from USB instead!"
    EXIT 0

:RUN_USB
    IF EQU "$COMP_MODE_USB$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_USB$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_USB$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_COMP_MODE
    LOADEXEC "PBAT" "$BM.SCRIPTS$/LOADEXEC.PBT" "$PWD$/$ELF$"
    EXIT 0