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
# Source: https://github.com/rickgaiser/neutrino
SET "TITLE" "[APP] XEB+ Xmas Showcase"
SET "VERSION" "1.0"
SET "AUTHOR" "Howling Wolf & Chelsea"
SET "DESC" "Dashboard replacment"
SET "ELF" "XEBPLUS_XMAS.ELF"
SET "SAS" "XEBPLUS"
# Comment out 1 of the 2 lines below. If app is in non-mc:/$SAS$ comment out the first, if in non-mc:/APPS/$SAS$ comment out the second
SET "SAS_NON_MC" "$SAS$"
# SET "SAS_NON_MC" "APPS/$SAS$"
#
# If an app does not boot, then one of these compatibility options may need to be set to 0, 1, 2 or 3
# 0= No compatibility options, 1= SHUTDOWN "MM", 2= SET "BM.AUTOLOAD_FSD_EN" "0", 3= sets both 1 and 2 (untested)
SET "COMP_MODE_MC" "0"
SET "COMP_MODE_MMCE" "0"
SET "COMP_MODE_USB" "1"
SET "COMP_MODE_HDD_APA" "0"
SET "COMP_MODE_DFFS" "0"
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
    MESSAGE "Please install via computer to USB!"
    EXIT 0

:REMOVE
    MESSAGE "Please remove via computer!"
    EXIT 0

:RUN
    IF MATCHES "mc?:*" "$PWD$"
        GOTO "RUN_COMP_MODE_MC"
    ELSEIF MATCHES "mmce?:*" "$PWD$"
        GOTO "RUN_COMP_MODE_MMCE"
    ELSEIF MATCHES "mass:*" "$PWD$"
        GOTO "RUN_COMP_MODE_USB"
    ELSEIF MATCHES "pfs0:*" "$PWD$"
        GOTO "RUN_COMP_MODE_HDD_APA"
    ELSEIF MATCHES "dffs:*" "$PWD$"
        GOTO "RUN_COMP_MODE_DFFS"
    ENDIF

:COMP_MODE_MC
    IF EQU "$COMP_MODE_MC$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_MC$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_MC$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_COMP_MODE_MMCE
    IF EQU "$COMP_MODE_MMCE$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_MMCE$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_MMCE$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_COMP_MODE_USB
    IF EQU "$COMP_MODE_USB$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_USB$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_USB$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_COMP_MODE_HDD_APA
    IF EQU "$COMP_MODE_HDD_APA$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_HDD_APA$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_HDD_APA$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_COMP_MODE_DFFS
    IF EQU "$COMP_MODE_DFFS$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_DFFS$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_DFFS$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_COMP_MODE
    LOADEXEC "PBAT" "$BM.SCRIPTS$/LOADEXEC.PBT" "$PWD$/$ELF$"
    EXIT 0
