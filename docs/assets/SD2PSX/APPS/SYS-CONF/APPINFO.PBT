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
SET "TITLE" "SYS-CONF"
SET "VERSION" ""
SET "AUTHOR" ""
SET "DESC" "Memory Card folder for shared files, alter as needed"
SET "ELF" ""
SET "SAS" "SYS-CONF"
# Comment out 1 of the 2 lines below. If app is in non-mc:/$SAS$ comment out the first, if in non-mc:/APPS/$SAS$ comment out the second
# SET "SAS_NON_MC" "$SAS$"
SET "SAS_NON_MC" "APPS/$SAS$"
#

# Do not change these 2 lines!
GOTO "$ARG1$"
RETURN -1

# Used for Autoboot Labels
:LABEL_NAME
    ADDWIDGET "LABEL" "$ARG2$$TITLE$ v$VERSION$"
    EXIT 0

:QUERY
    IF NOT MATCHES "RUN" "$ARG3$"
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
        IF FAIL RRM "$PWD$"
            IF FAIL RRM "$PWD$"
                MESSAGE "Failed removing $TITLE$"
                RETURN -1
            ENDIF
        ENDIF
    ENDIF
    EXIT 0

:RUN
   EXIT 0
