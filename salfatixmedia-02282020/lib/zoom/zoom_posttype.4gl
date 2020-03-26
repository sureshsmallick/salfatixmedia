IMPORT FGL core_db
IMPORT FGL core_ui

CONSTANT
  C_ICON_CHECKED STRING = "fa-check-square",
  C_ICON_UNCHECKED STRING = "fa-square-o"

SCHEMA salfatixmedia

#+ Select all rows in the "brandposttypes" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of record like brandposttypes.*
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION display(parec_posttypes)
  DEFINE
    parec_posttypes DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    larec_posttypes DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    larec_ret DYNAMIC ARRAY OF RECORD
      posttype RECORD LIKE posttypes.*,
      myimage STRING
    END RECORD,
    lint_ret INTEGER,
    lstr_msg STRING,
    i,j INTEGER,
    lbool_found BOOLEAN,
    lbool_is_mobile BOOLEAN

  CALL parec_posttypes.sort("pstt_name", FALSE)
  CALL core_db.posttype_fetch_all_rows(NULL, "ORDER BY posttypes.pstt_uiorder", larec_posttypes)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO larec_posttypes.getLength()
    LET lbool_found = FALSE
    FOR j = 1 TO parec_posttypes.getLength()
      IF larec_posttypes[i].pstt_id == parec_posttypes[j].pstt_id THEN
        LET lbool_found = TRUE
        EXIT FOR
      END IF
    END FOR
    LET larec_ret[i].posttype.* = larec_posttypes[i].*
    LET larec_ret[i].myimage = IIF(lbool_found, C_ICON_CHECKED,C_ICON_UNCHECKED)
  END FOR

  LET lbool_is_mobile = core_ui.ui_is_mobile()
  OPEN WINDOW w_zoom_posttype WITH FORM "zoom_posttype"
  IF lbool_is_mobile THEN
    DIALOG
      ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
      DISPLAY ARRAY larec_ret TO scrlist_posttype.*
        ON ACTION selectrow
          LET larec_ret[arr_curr()].myimage = IIF(larec_ret[arr_curr()].myimage==C_ICON_UNCHECKED,C_ICON_CHECKED,C_ICON_UNCHECKED)
      END DISPLAY
      ON ACTION accept
        CALL parec_posttypes.clear()
        FOR i = 1 TO larec_ret.getLength()
          IF larec_ret[i].myimage == C_ICON_CHECKED THEN
            LET parec_posttypes[parec_posttypes.getLength()+1].* = larec_ret[i].posttype.*
          END IF
        END FOR
        EXIT DIALOG
    END DIALOG
  ELSE
    DIALOG
      ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
      DISPLAY ARRAY larec_ret TO scrlist_posttype.*
        ON ACTION selectrow
          LET larec_ret[arr_curr()].myimage = IIF(larec_ret[arr_curr()].myimage==C_ICON_UNCHECKED,C_ICON_CHECKED,C_ICON_UNCHECKED)
      END DISPLAY
      ON ACTION accept
        CALL parec_posttypes.clear()
        FOR i = 1 TO larec_ret.getLength()
          IF larec_ret[i].myimage == C_ICON_CHECKED THEN
            LET parec_posttypes[parec_posttypes.getLength()+1].* = larec_ret[i].posttype.*
          END IF
        END FOR
        EXIT DIALOG
      ON ACTION close
        EXIT DIALOG
    END DIALOG
  END IF
  CLOSE WINDOW w_zoom_posttype
  RETURN lint_ret, lstr_msg
END FUNCTION