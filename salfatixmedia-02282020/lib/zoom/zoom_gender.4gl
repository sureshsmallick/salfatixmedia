IMPORT FGL fgldbutl
IMPORT FGL core_db
IMPORT FGL core_ui

CONSTANT
  C_ICON_CHECKED STRING = "fa-check-square",
  C_ICON_UNCHECKED STRING = "fa-square-o"

SCHEMA salfatixmedia

#+ Select all rows in the "brandgenders" table according to a SQL where part and order by part
#+
#+ @param parec_genders list of record like genders.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION display(parec_genders)
  DEFINE
    parec_genders DYNAMIC ARRAY OF RECORD LIKE genders.*,
    larec_genders DYNAMIC ARRAY OF RECORD LIKE genders.*,
    larec_ret DYNAMIC ARRAY OF RECORD
      gender RECORD LIKE genders.*,
      myimage STRING
    END RECORD,
    lint_ret INTEGER,
    lstr_msg STRING,
    i,j INTEGER,
    lbool_found BOOLEAN,
    lbool_is_mobile BOOLEAN

  CALL parec_genders.sort("gnd_name", FALSE)
  CALL core_db.gender_fetch_all_rows(NULL, "ORDER BY genders.gnd_uiorder", larec_genders)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO larec_genders.getLength()
    LET lbool_found = FALSE
    FOR j = 1 TO parec_genders.getLength()
      IF larec_genders[i].gnd_id == parec_genders[j].gnd_id THEN
        LET lbool_found = TRUE
        EXIT FOR
      END IF
    END FOR
    LET larec_ret[i].gender.* = larec_genders[i].*
    LET larec_ret[i].myimage = IIF(lbool_found, C_ICON_CHECKED,C_ICON_UNCHECKED)
  END FOR

  LET lbool_is_mobile = core_ui.ui_is_mobile()
  OPEN WINDOW w_zoom_gender WITH FORM "zoom_gender"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY larec_ret TO scrlist_gender.*
      ON ACTION selectrow
        LET larec_ret[arr_curr()].myimage = IIF(larec_ret[arr_curr()].myimage==C_ICON_UNCHECKED,C_ICON_CHECKED,C_ICON_UNCHECKED)
    END DISPLAY
    ON ACTION accept
      CALL parec_genders.clear()
      FOR i = 1 TO larec_ret.getLength()
        IF larec_ret[i].myimage == C_ICON_CHECKED THEN
          LET parec_genders[parec_genders.getLength()+1].* = larec_ret[i].gender.*
        END IF
      END FOR
      EXIT DIALOG
    ON ACTION close
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionActive("close",NOT lbool_is_mobile)
      CALL DIALOG.setActionHidden("close",lbool_is_mobile)
  END DIALOG
  CLOSE WINDOW w_zoom_gender
  RETURN lint_ret, lstr_msg
END FUNCTION

