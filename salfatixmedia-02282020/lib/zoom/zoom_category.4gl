IMPORT FGL fgldbutl
IMPORT FGL core_db
IMPORT FGL core_ui

CONSTANT
  C_ICON_CHECKED STRING = "fa-check-square",
  C_ICON_UNCHECKED STRING = "fa-square-o"

SCHEMA salfatixmedia

#+ Select all rows in the "brandcategories" table according to a SQL where part and order by part
#+
#+ @param parec_categories list of record like categories.*
#+ @param pbool_backoffice TRUE:launched from backoffice, FALSE otherwise
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pbool_multiselection TRUE to enable multiple selection, FALSE otherwise
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION display(parec_categories, pbool_backoffice, pstr_where, pbool_multiselection)
  DEFINE
    parec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    pbool_backoffice BOOLEAN,
    pstr_where STRING,
    pbool_multiselection BOOLEAN,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    larec_ret DYNAMIC ARRAY OF RECORD
      category RECORD LIKE categories.*,
      myimage STRING
    END RECORD,
    lint_ret INTEGER,
    lstr_msg STRING,
    i,j INTEGER,
    lbool_found BOOLEAN,
    lbool_is_mobile BOOLEAN,
    lrec_category RECORD LIKE categories.*

  CALL parec_categories.sort("ctgr_name", FALSE)
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  CALL core_db.category_fetch_all_rows(pstr_where, "ORDER BY categories.ctgr_name", larec_categories)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO larec_categories.getLength()
    LET lbool_found = FALSE
    FOR j = 1 TO parec_categories.getLength()
      IF larec_categories[i].ctgr_id == parec_categories[j].ctgr_id THEN
        LET lbool_found = TRUE
        EXIT FOR
      END IF
    END FOR
    LET larec_ret[i].category.* = larec_categories[i].*
    LET larec_ret[i].myimage = IIF(lbool_found, C_ICON_CHECKED,C_ICON_UNCHECKED)
  END FOR

  LET lbool_is_mobile = core_ui.ui_is_mobile()
  OPEN WINDOW w_zoom_category WITH FORM "zoom_category"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY larec_ret TO scrlist_category.*
      ON ACTION selectrow
        LET larec_ret[arr_curr()].myimage = IIF(larec_ret[arr_curr()].myimage==C_ICON_UNCHECKED,C_ICON_CHECKED,C_ICON_UNCHECKED)
        IF NOT pbool_multiselection THEN
          FOR i = 1 TO larec_ret.getLength()
            IF i <> arr_curr() THEN
              LET larec_ret[i].myimage = C_ICON_UNCHECKED
            END IF
          END FOR
        END IF
    END DISPLAY
    ON ACTION accept
      CALL parec_categories.clear()
      FOR i = 1 TO larec_ret.getLength()
        IF larec_ret[i].myimage == C_ICON_CHECKED THEN
          LET parec_categories[parec_categories.getLength()+1].* = larec_ret[i].category.*
        END IF
      END FOR
      EXIT DIALOG
    ON ACTION close
      EXIT DIALOG
    ON ACTION addcategory
      CALL categorygrid_add()
        RETURNING lint_ret, lrec_category.ctgr_id
      IF lint_ret == 0 THEN
        IF lrec_category.ctgr_id IS NOT NULL AND lrec_category.ctgr_id > 0 THEN
          CALL core_db.category_select_row(lrec_category.ctgr_id, FALSE)
            RETURNING lint_ret, lstr_msg, lrec_category.*
          IF lint_ret == 0 THEN
            LET larec_ret[larec_ret.getLength()+1].category.* = lrec_category.*
            LET larec_ret[larec_ret.getLength()].myimage = C_ICON_CHECKED
            CALL DIALOG.setCurrentRow("scrlist_category", larec_ret.getLength())
          END IF
        END IF
      END IF
    BEFORE DIALOG
      CALL DIALOG.setActionActive("close",NOT lbool_is_mobile)
      CALL DIALOG.setActionHidden("close",lbool_is_mobile)
      CALL DIALOG.setActionActive("addcategory",pbool_backoffice)
      CALL core_ui.ui_set_node_attribute("Button","name","addcategory","hidden", NOT pbool_backoffice)
  END DIALOG
  CLOSE WINDOW w_zoom_category
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Add a new category
#+
#+ @returnType INTEGER, RECORD
#+ @return     0|error, category record
FUNCTION categorygrid_add()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_category RECORD LIKE categories.*,
    lstr_tmp STRING,
    lint_status INTEGER

  INITIALIZE lrec_category.* TO NULL
  OPEN WINDOW w_categorygrid WITH FORM "categorygrid"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT lrec_category.* FROM scr_category_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION dialogtouched
      CALL DIALOG.setActionActive("dialogtouched", FALSE)
      CALL DIALOG.setActionHidden("dialogtouched", TRUE)
      CALL DIALOG.setActionActive("accept", TRUE)
    ON ACTION accept
      LET lstr_tmp = lrec_category.ctgr_name
      LET lstr_tmp = lstr_tmp.trim()
      LET lrec_category.ctgr_name = lstr_tmp
      CALL category_validate_data(lrec_category.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      --start a database transaction
      LET lint_ret = DB_START_TRANSACTION()
      LET lstr_msg = SQLERRMESSAGE
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL category_get_next_uiorder()
        RETURNING lint_ret, lstr_msg, lrec_category.ctgr_uiorder
      IF lint_ret == 0 THEN
        CALL core_db.category_insert_row(lrec_category.*)
          RETURNING lint_ret, lstr_msg, lrec_category.ctgr_id
      END IF
      --commit SQL transaction if no error occured, otherwise rollback SQL transaction
      IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
        --commit or rollback failed
        LET lint_ret = lint_status
        LET lstr_msg = SQLERRMESSAGE
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      LET lint_ret = 0
      EXIT DIALOG
    ON ACTION close
      LET lint_ret = -1
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionActive("accept", FALSE)
  END DIALOG
  CLOSE WINDOW w_categorygrid
  RETURN lint_ret, lrec_category.ctgr_id
END FUNCTION

#+ Check business rules of a category
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION category_validate_data(prec_category)
  DEFINE
    prec_category RECORD LIKE categories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE categories.*

  IF prec_category.ctgr_name IS NULL OR LENGTH(prec_category.ctgr_name)==0 THEN
    RETURN -1, %"Category missing"
  END IF
  CALL core_db.category_select_row_by_name(prec_category.ctgr_name, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_data.*
  CASE lint_ret
    WHEN 0
      RETURN -1, %"Category already exists"
    WHEN NOTFOUND
    OTHERWISE
      RETURN lint_ret, lstr_msg
  END CASE
  RETURN 0, NULL
END FUNCTION
