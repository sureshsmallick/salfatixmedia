IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
IMPORT FGL setup
IMPORT FGL layout

SCHEMA salfatixmedia

TYPE
  t_brandsocialnetworklist RECORD
    brandsocialnetwork RECORD LIKE brandsocialnetworks.*,
    scl_img LIKE socialnetworks.scl_img,
    delimage STRING,
    editimage STRING,
    viewimage STRING
  END RECORD
TYPE
  t_brandsocialnetworkgrid RECORD
    brandsocialnetwork RECORD LIKE brandsocialnetworks.*
  END RECORD

DEFINE
  m_dialogtouched SMALLINT

DEFINE --list data
  marec_brandsocialnetworklist DYNAMIC ARRAY OF t_brandsocialnetworklist
DEFINE --grid data
  mint_brandsocialnetwork_brndscl_id LIKE brandsocialnetworks.brndscl_id,
  mint_brandsocialnetwork_brand_id LIKE brandsocialnetworks.brndscl_brand_id,
  mrec_brandsocialnetworkgrid t_brandsocialnetworkgrid,
  mrec_copy_brandsocialnetworkgrid t_brandsocialnetworkgrid,
  mrec_db_brandsocialnetwork RECORD LIKE brandsocialnetworks.*

#+ Fetch and display the list of social networks
#+
#+ @param pint_brand_id brand id
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
#+ output FROM EMPTY : CANCEL|VIEWLIST|CUSTOMACTION
#+ output FROM LIST : CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION brandsocialnetworklist_open_form_by_key(pint_brand_id)
  DEFINE
    pint_brand_id LIKE brandsocialnetworks.brndscl_brand_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lint_action = C_APPACTION_UNDEFINED
  LET mint_brandsocialnetwork_brand_id = pint_brand_id

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL brandsocialnetworklist_get_data("brandsocialnetworks, socialnetworks", SFMT("brandsocialnetworks.brndscl_brand_id=%1 AND brandsocialnetworks.brndscl_socialnetwork_id = socialnetworks.scl_id", pint_brand_id), "socialnetworks.scl_uiorder", marec_brandsocialnetworklist)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      IF marec_brandsocialnetworklist.getLength() == 0 THEN
        OPEN WINDOW w_brandsocialnetwork_empty WITH FORM "brandsocialnetwork_empty"
        CALL brandsocialnetworklist_empty()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_brandsocialnetwork_empty
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_VIEWLIST THEN
            LET lbool_exit = FALSE
          END IF
        END IF
      ELSE
        OPEN WINDOW w_brandsocialnetwork_list WITH FORM "brandsocialnetwork_list"
        CALL brandsocialnetworklist_display()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_brandsocialnetwork_list
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_VIEWEMPTY THEN
            LET lbool_exit = FALSE
          END IF
        END IF
      END IF
    END IF
  END WHILE

  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog an empty list of social networks
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (CANCEL|VIEWLIST|CUSTOMACTION)
FUNCTION brandsocialnetworklist_empty()
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT,
    ff_formtitle STRING,
    lint_brndscl_id LIKE brandsocialnetworks.brndscl_id

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Social Networks"
  CALL FGL_SETTITLE(ff_formtitle)
  MENU ""
    ON ACTION addsocialnetwork
      CALL brandsocialnetworkgrid_open_form_by_key(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_brndscl_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            LET lint_action = C_APPACTION_VIEWLIST
            EXIT MENU
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT MENU
        END CASE
      END IF
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT MENU
    ON ACTION cancel
      LET lint_action = C_APPACTION_CANCEL
      EXIT MENU
    BEFORE MENU
      CALL DIALOG.setActionHidden("customaction", TRUE)
  END MENU
  RETURN lint_ret, lint_action
END FUNCTION

#+ Display the brand social networks list
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION brandsocialnetworklist_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_brndscl_id LIKE brandsocialnetworks.brndscl_id,
    i INTEGER,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Social Networks"
  CALL FGL_SETTITLE(ff_formtitle)

  DISPLAY ARRAY marec_brandsocialnetworklist TO scr_brandsocialnetwork_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY
      CALL brandsocialnetworklist_ui_set_action_state(DIALOG)
      DISPLAY BY NAME ff_formtitle
    ON ACTION delete
      LET i = DIALOG.getCurrentRow("scr_brandsocialnetwork_list")
      IF i > 0 THEN
        CALL brandsocialnetwork_delete_from_dabatase(marec_brandsocialnetworklist[i].brandsocialnetwork.brndscl_id)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          CALL DIALOG.deleteRow("scr_brandsocialnetwork_list", i)
          CALL brandsocialnetworklist_ui_set_action_state(DIALOG)
          IF marec_brandsocialnetworklist.getLength() == 0 THEN
            LET lint_action = C_APPACTION_VIEWEMPTY
            EXIT DISPLAY
          END IF
        END IF
      END IF
    ON ACTION addsocialnetwork
      CALL brandsocialnetworkgrid_open_form_by_key(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_brndscl_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            CALL brandsocialnetworklist_get_data_by_key(lint_brndscl_id, marec_brandsocialnetworklist, marec_brandsocialnetworklist.getLength()+1)
              RETURNING lint_ret, lstr_msg
            CALL brandsocialnetworklist_ui_set_action_state(DIALOG)
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION editsocialnetwork
      LET i = DIALOG.getCurrentRow("scr_brandsocialnetwork_list")
      IF i > 0 THEN
        CALL brandsocialnetworkgrid_open_form_by_key(marec_brandsocialnetworklist[i].brandsocialnetwork.brndscl_id, C_APPSTATE_UPDATE)
          RETURNING lint_ret, lint_action, lint_brndscl_id
        IF lint_ret == 0 THEN
          CASE lint_action
            WHEN C_APPACTION_ACCEPT
            WHEN C_APPACTION_CANCEL
            OTHERWISE --custom action
              EXIT DISPLAY
          END CASE
          CALL brandsocialnetworklist_get_data_by_key(lint_brndscl_id, marec_brandsocialnetworklist, i)
            RETURNING lint_ret, lstr_msg
          CALL brandsocialnetworklist_ui_set_action_state(DIALOG)
        END IF
      END IF
    ON ACTION viewsocialnetwork
      LET i = DIALOG.getCurrentRow("scr_brandsocialnetwork_list")
      IF i > 0 THEN
        CALL layout.open_socialnetwork_account(marec_brandsocialnetworklist[i].brandsocialnetwork.brndscl_socialnetwork_id, marec_brandsocialnetworklist[i].brandsocialnetwork.brndscl_accountname)
      END IF
    ON ACTION cancel
      LET lint_action = C_APPACTION_CANCEL
      EXIT DISPLAY
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DISPLAY
    END DISPLAY
  RETURN lint_ret, lint_action
END FUNCTION

#+ Get the brand social networks list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of t_brandsocialnetworklist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandsocialnetworklist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_brandsocialnetworklist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_brndscl_id LIKE brandsocialnetworks.brndscl_id

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM brandsocialnetworks"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT brandsocialnetworks.brndscl_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_brandsocialnetworklist_get_data CURSOR FROM lstr_sql
    FOREACH c_brandsocialnetworklist_get_data
      INTO lint_brndscl_id
      CALL brandsocialnetworklist_get_data_by_key(lint_brndscl_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END FOREACH
    FREE c_brandsocialnetworklist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the brand social networks list data for a given row
#+
#+ @param pint_brndscl_id brand social network id
#+ @param parec_list list of influencers t_brandsocialnetworklist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandsocialnetworklist_get_data_by_key(pint_brndscl_id, parec_list, pint_index)
  DEFINE
    pint_brndscl_id LIKE brandsocialnetworks.brndscl_id,
    parec_list DYNAMIC ARRAY OF t_brandsocialnetworklist,
    pint_index INTEGER,
    lrec_brandsocialnetwork RECORD LIKE brandsocialnetworks.*,
    lrec_socialnetwork RECORD LIKE socialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.brandsocialnetworks_select_row(pint_brndscl_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_brandsocialnetwork.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.socialnetwork_select_row(lrec_brandsocialnetwork.brndscl_socialnetwork_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_socialnetwork.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET parec_list[pint_index].brandsocialnetwork.* = lrec_brandsocialnetwork.*
  LET parec_list[pint_index].scl_img = lrec_socialnetwork.scl_img
  LET parec_list[pint_index].delimage = "delete"
  LET parec_list[pint_index].editimage = "fa-pencil"
  LET parec_list[pint_index].viewimage = "fa-eye"
  RETURN 0, NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION brandsocialnetworklist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.DIALOG
  CALL p_dialog.setActionHidden("cancel", TRUE)
  CALL p_dialog.setActionHidden("customaction", TRUE)
  CALL p_dialog.setActionActive("delete", (marec_brandsocialnetworklist.getLength()>0))
  CALL p_dialog.setActionActive("editsocialnetwork", (marec_brandsocialnetworklist.getLength()>0))
  CALL p_dialog.setActionActive("viewsocialnetwork", (marec_brandsocialnetworklist.getLength()>0))
END FUNCTION

#+ Fetch and display brand social network
#+
#+ @param pint_brndscl_id brand social network
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION brandsocialnetworkgrid_open_form_by_key(pint_brndscl_id, pint_state)
  DEFINE
    pint_brndscl_id LIKE brandsocialnetworks.brndscl_id,
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  LET mint_brandsocialnetwork_brndscl_id = pint_brndscl_id
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_brandsocialnetwork_grid WITH FORM "brandsocialnetwork_grid"
  CASE pint_state
    WHEN C_APPSTATE_ADD
      CALL brandsocialnetworkgrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL brandsocialnetworkgrid_update(pint_state) RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_brandsocialnetwork_grid
  RETURN lint_ret, lint_action, mint_brandsocialnetwork_brndscl_id
END FUNCTION

#+ Create a brand social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandsocialnetworkgrid_create(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL brandsocialnetworkgrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a brand social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandsocialnetworkgrid_update(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL brandsocialnetworkgrid_input(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lint_action
    --we want to stay in the edition
    IF lint_ret == 0 AND lint_action == C_APPACTION_ACCEPT THEN
      LET lbool_exit = FALSE
    END IF
  END WHILE
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the brand input
#+
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION brandsocialnetworkgrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = IIF(pint_dialog_state==C_DIALOGSTATE_ADD, %"Add social network",%"Edit social network")
  CALL FGL_SETTITLE(ff_formtitle)

  LET m_dialogtouched = FALSE
  CALL brandsocialnetworkgrid_initialize_data(mint_brandsocialnetwork_brndscl_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_brandsocialnetworkgrid.* FROM scr_brandsocialnetwork_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL socialnetworks_combobox_initializer()
      AFTER INPUT
      ON CHANGE brndscl_socialnetwork_id
        LET m_dialogtouched = TRUE
        CALL brandsocialnetworkgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    END INPUT
    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL brandsocialnetworkgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    ON ACTION save
      CALL brandsocialnetworkgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_brandsocialnetwork_brndscl_id = mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION cancel ATTRIBUTE(TEXT=%"Cancel")
      CALL brandsocialnetworkgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_brandsocialnetwork_brndscl_id = mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    ON ACTION customaction
      CALL brandsocialnetworkgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      LET mint_brandsocialnetwork_brndscl_id = mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id
      EXIT DIALOG
    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL brandsocialnetworkgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      DISPLAY BY NAME ff_formtitle
  END DIALOG
  RETURN lint_ret, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION brandsocialnetworkgrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched)

      CALL layout.display_savebutton(pbool_dialog_touched)

    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched)

      CALL layout.display_savebutton(pbool_dialog_touched)

  END CASE

END FUNCTION

#+ Initializes the brand social network business record
#+
#+ @param pint_brndscl_id brand social network id
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER
#+ @return     0|error
FUNCTION brandsocialnetworkgrid_initialize_data(pint_brndscl_id, pint_dialog_state)
  DEFINE
    pint_brndscl_id LIKE brandsocialnetworks.brndscl_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING

  INITIALIZE mrec_brandsocialnetworkgrid.* TO NULL
  INITIALIZE mrec_copy_brandsocialnetworkgrid.* TO NULL
  INITIALIZE mrec_db_brandsocialnetwork.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id = 0
      LET mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_brand_id = mint_brandsocialnetwork_brand_id
      LET mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_socialnetwork_id = get_first_socialnetwork(mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_brand_id)
      --mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_accountname
      --mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_comment
    WHEN C_DIALOGSTATE_UPDATE
      CALL brandsocialnetworkgrid_get_data_by_key(pint_brndscl_id)
        RETURNING lint_ret, lstr_msg, mrec_brandsocialnetworkgrid.*, mrec_db_brandsocialnetwork.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_copy_brandsocialnetworkgrid.* = mrec_brandsocialnetworkgrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_brandsocialnetworkgrid
#+
#+ @param pint_brndscl_id brand social network id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_brandsocialnetworkgrid business record, brandsocialnetwork database record
FUNCTION brandsocialnetworkgrid_get_data_by_key(pint_brndscl_id)
  DEFINE
    pint_brndscl_id LIKE brandsocialnetworks.brndscl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE brandsocialnetworks.*,
    lrec_ui_brandsocialnetwork t_brandsocialnetworkgrid,
    lrec_db_data RECORD LIKE brandsocialnetworks.*

  INITIALIZE lrec_ui_brandsocialnetwork.* TO NULL

  CALL core_db.brandsocialnetworks_select_row(pint_brndscl_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_data.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_brandsocialnetwork.*, lrec_db_data.*
  END IF
  LET lrec_ui_brandsocialnetwork.brandsocialnetwork.* = lrec_data.*
  LET lrec_db_data.* = lrec_data.*
  RETURN lint_ret, lstr_msg, lrec_ui_brandsocialnetwork.*, lrec_db_data.*
END FUNCTION

#+ Process the data of business record fields (CRUD operations or UI operations)
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+ @param pint_dialog_action dialog action which triggered the operation
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandsocialnetworkgrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT,
    pint_dialog_action SMALLINT,
    lbool_insert_data BOOLEAN,
    lbool_update_data BOOLEAN,
    lbool_restore_data BOOLEAN,
    lbool_refresh_data BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_brndscl_id LIKE brandsocialnetworks.brndscl_id

  --DISPLAY SFMT("brand_process_data = pint_dialog_state=%1 pbool_dialog_touched=%2 pint_dialog_action=%3",pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
  LET lbool_insert_data = FALSE
  LET lbool_update_data = FALSE
  LET lbool_restore_data = FALSE
  LET lbool_refresh_data = FALSE
  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CASE pint_dialog_action
        WHEN C_APPACTION_ACCEPT
          LET lbool_insert_data = TRUE
        WHEN C_APPACTION_CANCEL
          --do nothing
      END CASE
    WHEN C_DIALOGSTATE_UPDATE
      CASE pint_dialog_action
        WHEN C_APPACTION_ACCEPT
        LET lbool_update_data = TRUE
        WHEN C_APPACTION_CANCEL
          IF pbool_dialog_touched THEN
            IF core_ui.ui_message(%"Question ?",%"Abort edition?","no","yes|no","fa-question") == "yes" THEN
              LET lbool_restore_data = TRUE
            END IF
          END IF
    END CASE
    OTHERWISE --do nothing
      RETURN 0, NULL
  END CASE
  IF lbool_insert_data THEN
    CALL brandsocialnetwork_validate_data(C_DIALOGSTATE_ADD)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL brandsocialnetwork_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_brndscl_id
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Social network registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id = lint_brndscl_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_update_data THEN
    CALL brandsocialnetwork_validate_data(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL brandsocialnetwork_update_into_dabatase()
      RETURNING lint_ret, lstr_msg
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Social network updated","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_restore_data THEN
    CALL brandsocialnetworkgrid_initialize_data(mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL brandsocialnetworkgrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_brandsocialnetwork_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL brandsocialnetworkgrid_initialize_data(mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL brandsocialnetworkgrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_brandsocialnetwork_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a brand social network into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, brand social network id
FUNCTION brandsocialnetwork_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brandsocialnetwork RECORD LIKE brandsocialnetworks.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_brandsocialnetwork.brndscl_id
  END IF
  INITIALIZE lrec_brandsocialnetwork.* TO NULL
  LET lrec_brandsocialnetwork.* = mrec_brandsocialnetworkgrid.brandsocialnetwork.*
  CALL core_db.brandsocialnetworks_insert_row(lrec_brandsocialnetwork.*)
    RETURNING lint_ret, lstr_msg, lrec_brandsocialnetwork.brndscl_id
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_brandsocialnetwork.brndscl_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_brandsocialnetwork.brndscl_id
END FUNCTION

#+ Update a brand social network into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandsocialnetwork_update_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brandsocialnetwork RECORD LIKE brandsocialnetworks.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  INITIALIZE lrec_brandsocialnetwork.* TO NULL
  LET lrec_brandsocialnetwork.* = mrec_brandsocialnetworkgrid.brandsocialnetwork.*
  CALL core_db.brandsocialnetworks_update_row(mrec_db_brandsocialnetwork.*, lrec_brandsocialnetwork.*)
    RETURNING lint_ret, lstr_msg
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete a brand social network from database
#+
#+ @param pint_brndscl_id brand social network id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandsocialnetwork_delete_from_dabatase(pint_brndscl_id)
  DEFINE
    pint_brndscl_id LIKE brandsocialnetworks.brndscl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.brandsocialnetworks_delete_row(pint_brndscl_id)
    RETURNING lint_ret, lstr_msg
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Check business rules of a brand social network
#+
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION brandsocialnetwork_validate_data(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    i INTEGER

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id IS NULL OR mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_id==0 THEN
      RETURN -1, %"Id missing"
    END IF
  END IF
  IF mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_brand_id IS NULL OR mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_brand_id==0 THEN
    RETURN -1, %"brand missing"
  END IF
  IF mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_socialnetwork_id IS NULL OR mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_socialnetwork_id==0 THEN
    RETURN -1, %"Network missing"
  END IF
  IF mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_accountname IS NULL THEN
    RETURN -1, %"Account missing"
  END IF
  TRY
    SELECT brandsocialnetworks.brndscl_id INTO i
    FROM brandsocialnetworks
    WHERE brndscl_brand_id = mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_brand_id
      AND brndscl_socialnetwork_id = mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_socialnetwork_id
      AND brndscl_accountname = mrec_brandsocialnetworkgrid.brandsocialnetwork.brndscl_accountname
    CASE SQLCA.SQLCODE
      WHEN 0
        IF pint_dialog_state == C_DIALOGSTATE_ADD THEN
          RETURN -1, %"Record already exists"
        ELSE --update
          IF i <> mrec_db_brandsocialnetwork.brndscl_id THEN
            RETURN -1, %"Record already exists"
          END IF
        END IF
      WHEN NOTFOUND
      OTHERWISE
        RETURN -1, %"Record already exists"
    END CASE
  CATCH
    RETURN -1, SQLERRMESSAGE
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the first social network that is not already created
#+
#+ @param pint_brand_id brand id
#+
#+ @returnType INTEGER
#+ @return     social network id
FUNCTION get_first_socialnetwork(pint_brand_id)
  DEFINE
    pint_brand_id LIKE brandsocialnetworks.brndscl_brand_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_socialnetwork_id LIKE socialnetworks.scl_id

  LET lstr_sql = "SELECT socialnetworks.scl_id"
    ," FROM socialnetworks"
    ," WHERE socialnetworks.scl_id NOT IN "
    ,SFMT("(SELECT brandsocialnetworks.brndscl_socialnetwork_id FROM brandsocialnetworks WHERE brandsocialnetworks.brndscl_brand_id=%1)", pint_brand_id)
    ," ORDER BY socialnetworks.scl_uiorder"
  LET lint_socialnetwork_id = 0
  TRY
    DECLARE c_get_first_socialnetwork CURSOR FROM lstr_sql
    FOREACH c_get_first_socialnetwork
      INTO lint_socialnetwork_id
      EXIT FOREACH
    END FOREACH
    FREE c_get_first_socialnetwork
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  IF lint_socialnetwork_id IS NULL OR lint_socialnetwork_id==0 THEN
    LET lint_socialnetwork_id = C_SOCIALNETWORK_YOUTUBE
  END IF
  RETURN lint_socialnetwork_id
END FUNCTION

#+ Initializer of the country combobox
#+
FUNCTION socialnetworks_combobox_initializer()
  CALL combobox.socialnetwork_initializer(ui.ComboBox.forName("brandsocialnetworks.brndscl_socialnetwork_id"))
END FUNCTION

