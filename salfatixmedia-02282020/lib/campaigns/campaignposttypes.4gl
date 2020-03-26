IMPORT FGL fgldbutl
IMPORT FGL core_db
IMPORT FGL core_automaton
IMPORT FGL core_ui
IMPORT FGL setup
IMPORT FGL string

SCHEMA salfatixmedia

TYPE
  t_campaignposttypes RECORD
    campaignposttype RECORD LIKE campaignposttypes.*,
    posttype RECORD LIKE posttypes.*
  END RECORD

#+ Open campaign post types
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_campaignlocations list of already selected locations
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION open_posttypes(pint_campaign_id, parec_campaignposttypes)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    larec_displayedlist DYNAMIC ARRAY OF t_campaignposttypes,
    larec_posttypes DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i,j INTEGER,
    lbool_found BOOLEAN,
    l_dialogtouched BOOLEAN

  LET lint_action = C_APPACTION_CLOSE
  CALL core_db.posttype_fetch_all_rows(NULL, "ORDER BY posttypes.pstt_uiorder", larec_posttypes)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  FOR i = 1 TO larec_posttypes.getLength()
    LET lbool_found = FALSE
    FOR j = 1 TO parec_campaignposttypes.getLength()
      IF larec_posttypes[i].pstt_id == parec_campaignposttypes[j].cmppst_posttype_id THEN
        LET lbool_found = TRUE
        EXIT FOR
      END IF
    END FOR
    INITIALIZE larec_displayedlist[i].* TO NULL
    LET larec_displayedlist[i].posttype.* = larec_posttypes[i].*
    IF lbool_found THEN
      LET larec_displayedlist[i].campaignposttype.* = parec_campaignposttypes[j].*
    ELSE
      LET larec_displayedlist[i].campaignposttype.cmppst_quantity = 0
      LET larec_displayedlist[i].campaignposttype.cmppst_tovalidate = 1
    END IF
  END FOR
  OPEN WINDOW w_campaignposttypes WITH FORM "campaignposttypes"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT ARRAY larec_displayedlist FROM scrlist_campaignposttypes.*
      ATTRIBUTES (AUTO APPEND=FALSE, APPEND ROW=FALSE, DELETE ROW=FALSE, INSERT ROW=FALSE, WITHOUT DEFAULTS)
    END INPUT
    ON ACTION dialogtouched
      LET l_dialogtouched = TRUE
      CALL campaignposttypes_set_action_state(DIALOG, l_dialogtouched)
    ON ACTION accept
      CALL parec_campaignposttypes.clear()
      LET j = 0
      FOR i = 1 TO larec_displayedlist.getLength()
        IF larec_displayedlist[i].campaignposttype.cmppst_quantity > 0 THEN
          LET j = j + 1
          LET parec_campaignposttypes[j].cmppst_campaign_id = pint_campaign_id
          LET parec_campaignposttypes[j].cmppst_posttype_id = larec_displayedlist[i].posttype.pstt_id
          LET parec_campaignposttypes[j].cmppst_quantity = larec_displayedlist[i].campaignposttype.cmppst_quantity
          LET parec_campaignposttypes[j].cmppst_tovalidate = larec_displayedlist[i].campaignposttype.cmppst_tovalidate
        ELSE --ignore record when other values in quantity (null, <0, ==0)
        END IF
      END FOR
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      LET lint_action = C_APPACTION_CLOSE
      EXIT DIALOG
    BEFORE DIALOG
      LET l_dialogtouched = FALSE
      CALL campaignposttypes_set_action_state(DIALOG, l_dialogtouched)
  END DIALOG
  CLOSE WINDOW w_campaignposttypes
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION campaignposttypes_set_action_state(p_dialog, p_dialogtouched)
  DEFINE
    p_dialog ui.Dialog,
    p_dialogtouched BOOLEAN

  CALL p_dialog.setActionActive("accept",p_dialogtouched)
  CALL p_dialog.setActionActive("dialogtouched",NOT p_dialogtouched)
  IF NOT setup.g_app_backoffice THEN
    CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignposttypes.cmppst_tovalidate","hidden", TRUE)
  END IF

END FUNCTION

#+ Get post types from a list of campaign post types.
#+ This string is used to be displayed inside buttonedit fields
#+
#+ @param parec_data list of campaign post types
#+
#+ @returnType STRING
#+ @return     list of post types
PUBLIC FUNCTION serialize_campaignposttypes(parec_data)
  DEFINE
    parec_data DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    lstr_ret STRING,
    i,s INTEGER

  LET s = parec_data.getLength()
  FOR i = 1 TO s
    LET lstr_ret = string.concat_with_delim(lstr_ret, SFMT("%1 (%2)", _get_posttype_name(parec_data[i].cmppst_posttype_id), parec_data[i].cmppst_quantity),"\n")
  END FOR
  RETURN lstr_ret
END FUNCTION

Public Function getPostTypeName(p_key)
  DEFINE
    p_key LIKE posttypes.pstt_id

  Return _get_posttype_name(p_key)
End Function

#+ Get the name of a post type
#+
#+ @param p_key post type id
#+
#+ @returnType STRING
#+ @return     country string
PRIVATE FUNCTION _get_posttype_name(p_key)
  DEFINE
    p_key LIKE posttypes.pstt_id,
    lstr_ret STRING,
    lstr_name LIKE posttypes.pstt_name

  IF p_key IS NULL THEN RETURN NULL END IF
  TRY
    SELECT posttypes.pstt_name
      INTO lstr_name
    FROM posttypes
    WHERE posttypes.pstt_id = p_key
    LET lstr_ret = lstr_name
  CATCH
  END TRY
  RETURN lstr_ret
END FUNCTION
