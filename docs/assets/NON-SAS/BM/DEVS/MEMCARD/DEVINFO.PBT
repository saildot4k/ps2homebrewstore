# Crystal Chips BootManager Memory Card driver script. v1.1

KEEP

SET "TITLE" "Memory Card"

# Do not change this.
GOTO "$ARG1$"
RETURN -1

:QUERY
    RETURN 0

:IF_QUERY
    IF EXISTS "mc0:/"
        IF NOT MATCHES "mc0:/*"  "$ARG3$"
	        ADDWIDGET "CALL" "$TITLE$ 1" "$BM.TXT_MC_DESC$ 1" $ARG2$ "mc0" "$ARG3$" "$ARG4$" "$ARG5$" "$ARG6$" "$ARG7$" "$ARG8$" "$ARG9$" "$ARG10$" "$ARG11$"
        ELSEIF MATCHES "mc0:/*"  "$ARG3$"
            ADDWIDGET LABEL "$TITLE$ 1-$BM.TXT_NO_INSTALL$"
        ENDIF
    ENDIF
    IF EXISTS "mc1:/"
        IF NOT MATCHES "mc1:/*"  "$ARG3$"
            ADDWIDGET "CALL" "$TITLE$ 2" "$BM.TXT_MC_DESC$ 2" $ARG2$ "mc1" "$ARG3$" "$ARG4$" "$ARG5$" "$ARG6$" "$ARG7$" "$ARG8$" "$ARG9$" "$ARG10$" "$ARG11$"
        ELSEIF MATCHES "mc1:/*"  "$ARG3$"
            ADDWIDGET LABEL "$TITLE$ 2-$BM.TXT_NO_INSTALL$"
        ENDIF
    ENDIF
    RETURN 0

:CHECK_PRESENT
    RETURN 0

    IF EXISTS "mc0:/"
        IF NEQ "$BM.MC0_PRESENT$" "1"
            LOADEXEC "PBAT" "$BM.SCRIPTS$/BMCONT.PBT" "CHECK" "mc0"
            SET "BM.MC0_PRESENT" "1"
        ENDIF
    ELSEIF EQU "$BM.MC0_PRESENT$" "1"
        SET "BM.MC0_PRESENT" "0"
    ENDIF

    IF EXISTS "mc1:/"
        IF NEQ "$BM.MC1_PRESENT$" "1"
            LOADEXEC "PBAT" "$BM.SCRIPTS$/BMCONT.PBT" "CHECK" "mc1"
            SET "BM.MC1_PRESENT" "1"
        ENDIF
    ELSEIF EQU "$BM.MC1_PRESENT$" "1"
        SET "BM.MC1_PRESENT" "0"
    ENDIF
    RETURN 0

:CHECK
    IF MATCHES "mc?:*" "$ARG2$"
        SET "$ARG3$" "$ARG0$"
    ENDIF
    RETURN 0

:INSTALL
    EXIT 0

:REMOVE
    EXIT 0

:LOAD
    # Memory Card drivers are loaded by default, no loading is needed...
    RETURN 0

:LOADEXEC
    LOADEXEC "EEELF" "moduleload" "-m rom0:SIO2MAN" "-m rom0:MCMAN" "$ARG2$" $ARG3$
    RETURN 0
