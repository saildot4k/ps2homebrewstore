# SAS (Save Application Support) compliant BM Script
# Due to wildcard bug on memory card and mmce, bootdevice:/BM/SCRIPTS/DEFINEDROOTFOLDER.PBT must exist to work. Update as needed

# Change this information to describe the application and where it should be ran from for memcard (SAS) or other devices (SAS_NON_MC)
# SAS is the App folder name. SAS_NON_MC defines if app is in root of non-memcard device (non_mc:/$SAS$) or APP folder (non_mc:/APPS/$SAS$)
# This is so that you do not have to edit any info below line 40.
#
# Some devices are case sensitive! Make sure your case matches!
#
# Source: https://github.com/HiroTex/OSD-XMB
SET "TITLE" "[APP] OSDXMB"
SET "VERSION" "1.91"
SET "AUTHOR" "HiroTex"
SET "DESC" "A user interface resembling PS3/PSP inspired by XMB+."
SET "ELF" ""
SET "SAS" "OSDXMB"
#
# If an app does not boot, then one of these compatibility options may need to be set to 0, 1, 2 or 3
# 0= No compatibility options, 1= SHUTDOWN "MM", 2= SET "BM.AUTOLOAD_FSD_EN" "0", 3= sets both 1 and 2 (untested)
SET "COMP_MODE_MC" "1"
SET "COMP_MODE_MMCE" "1"
SET "COMP_MODE_USB" "1"
SET "COMP_MODE_HDD_APA" "1"
SET "COMP_MODE_DFFS" "1"
#
###############################################################################################


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
    MESSAGE "Please install via computer"
    EXIT 0

:REMOVE
    MESSAGE "Please remove via computer"
    EXIT 0

:RUN
    IF MATCHES "mc?:/*" "$PWD$"
        GOTO "RUN_MC"
    ELSEIF MATCHES "mmce?:/*" "$PWD$"
        GOTO "RUN_MMCE"
    ELSEIF MATCHES "mass:/*" "$PWD$"
        GOTO "RUN_USB"
    ELSEIF MATCHES "pfs0:/*" "$PWD$"
        GOTO "RUN_HDD_APA"
    ELSEIF MATCHES "dffs:/*" "$PWD$"
        GOTO "RUN_DFFS"
    ENDIF

:RUN_MC
    IF EQU "$COMP_MODE_MC$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_MC$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_MC$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_MMCE
    IF EQU "$COMP_MODE_MMCE$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_MMCE$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_MMCE$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

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

:RRUN_HDD_APA
    IF EQU "$COMP_MODE_HDD_APA$" "1"
        SHUTDOWN "MM"
    ELSEIF EQU "$COMP_MODE_HDD_APA$" "2"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ELSEIF EQU "$COMP_MODE_HDD_APA$" "3"
        SHUTDOWN "MM"
        SET "BM.AUTOLOAD_FSD_EN" "0"
    ENDIF
    GOTO "RUN_COMP_MODE"

:RUN_DFFS
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