IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
--IMPORT FGL string
IMPORT FGL setup
--IMPORT FGL passwords
--IMPORT FGL emails
IMPORT FGL layout

SCHEMA salfatixmedia

TYPE
  t_usersocialnetworklist RECORD
    usersocialnetwork RECORD LIKE usersocialnetworks.*,
    scl_img LIKE socialnetworks.scl_img,
    delimage STRING,
    editimage STRING,
    viewimage STRING
  END RECORD
TYPE
  t_usersocialnetworkgrid RECORD
    usersocialnetwork RECORD LIKE usersocialnetworks.*
  END RECORD

--type used for dynamic UI
TYPE
  t_dynfield_grid RECORD
    name STRING, -- a column name
    type STRING  -- a column type
  END RECORD,
  t_socialnetwork_image RECORD
    socialnetwork RECORD LIKE socialnetworks.*,
    actionname STRING,
    selectedimage STRING,
    unselectedimage STRING,
    isselected BOOLEAN
  END RECORD

DEFINE
  m_dialogtouched SMALLINT

DEFINE --list data
  marec_usersocialnetworklist DYNAMIC ARRAY OF t_usersocialnetworklist
DEFINE --grid data
  mint_usersocialnetwork_usrscl_id LIKE usersocialnetworks.usrscl_id,
  mint_usersocialnetwork_usr_id LIKE usersocialnetworks.usrscl_usr_id,
  mrec_usersocialnetworkgrid t_usersocialnetworkgrid,
  mrec_copy_usersocialnetworkgrid t_usersocialnetworkgrid,
  mrec_db_usersocialnetwork RECORD LIKE usersocialnetworks.*,
  mint_influencer_instagram_accountname LIKE users.usr_instagram_username

#+ Fetch and display the list of social networks
#+
#+ @param pint_user_id user id
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
#+ output FROM EMPTY : CANCEL|VIEWLIST|CUSTOMACTION
#+ output FROM LIST : CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION usersocialnetworklist_open_form_by_key(pint_user_id)
  DEFINE
    pint_user_id LIKE usersocialnetworks.usrscl_usr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lbool_exit BOOLEAN,
    lrec_user RECORD LIKE users.*

  LET lint_action = C_APPACTION_UNDEFINED
  CALL core_db.users_select_row(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  LET mint_usersocialnetwork_usr_id = lrec_user.usr_id
  LET mint_influencer_instagram_accountname = lrec_user.usr_instagram_username

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL usersocialnetworklist_get_data("usersocialnetworks, socialnetworks", SFMT("usersocialnetworks.usrscl_usr_id=%1 AND usersocialnetworks.usrscl_socialnetwork_id = socialnetworks.scl_id", pint_user_id), "socialnetworks.scl_uiorder", marec_usersocialnetworklist)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      IF marec_usersocialnetworklist.getLength() == 0 AND setup.g_app_backoffice THEN
        OPEN WINDOW w_usersocialnetwork_empty WITH FORM "usersocialnetwork_empty"
        CALL usersocialnetworklist_empty()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_usersocialnetwork_empty
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_VIEWLIST THEN
            LET lbool_exit = FALSE
          END IF
        END IF
      ELSE
        OPEN WINDOW w_usersocialnetwork_list WITH FORM SFMT("usersocialnetwork_list%1", IIF(setup.g_app_is_mobile, "_mobile",NULL))
        CALL usersocialnetworklist_display()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_usersocialnetwork_list
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
FUNCTION usersocialnetworklist_empty()
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT,
    ff_formtitle STRING,
    lint_usrscl_id LIKE usersocialnetworks.usrscl_id

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Social Networks"
  CALL FGL_SETTITLE(ff_formtitle)
  MENU ""
    ON ACTION addsocialnetwork
      CALL usersocialnetworkgrid_open_form_by_key(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_usrscl_id
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

#+ Display the user social networks list
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION usersocialnetworklist_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    i INTEGER,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Social Networks"
  CALL FGL_SETTITLE(ff_formtitle)

  Display "footer-socialnetworks-1.jpg" To foot

  DISPLAY ARRAY marec_usersocialnetworklist TO scr_usersocialnetwork_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY
      CALL usersocialnetworklist_ui_set_action_state(DIALOG)
      IF setup.g_app_backoffice THEN
        DISPLAY BY NAME ff_formtitle
      END IF
    ON ACTION delete ATTRIBUTES (ROWBOUND)
      LET i = DIALOG.getCurrentRow("scr_usersocialnetwork_list")
      IF i > 0 THEN
        IF marec_usersocialnetworklist[i].usersocialnetwork.usrscl_id > 0 THEN
          CALL usersocialnetwork_delete_from_dabatase(marec_usersocialnetworklist[i].usersocialnetwork.usrscl_id)
            RETURNING lint_ret, lstr_msg
          IF lint_ret == 0 THEN
            CALL DIALOG.deleteRow("scr_usersocialnetwork_list", i)
            CALL usersocialnetworklist_ui_set_action_state(DIALOG)
            IF marec_usersocialnetworklist.getLength() == 0 AND setup.g_app_backoffice THEN
              LET lint_action = C_APPACTION_VIEWEMPTY
              EXIT DISPLAY
            END IF
          END IF
        END IF
      END IF
    ON ACTION addsocialnetwork
      CALL usersocialnetworkgrid_open_form_by_key(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_usrscl_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            CALL usersocialnetworklist_get_data_by_key(lint_usrscl_id, marec_usersocialnetworklist, marec_usersocialnetworklist.getLength()+1)
              RETURNING lint_ret, lstr_msg
            CALL usersocialnetworklist_ui_set_action_state(DIALOG)
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION addsocialnetworkmobile
      CALL usersocialnetworkgrid_open_form_by_key(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_usrscl_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            CALL usersocialnetworklist_get_data_by_key(lint_usrscl_id, marec_usersocialnetworklist, marec_usersocialnetworklist.getLength()+1)
              RETURNING lint_ret, lstr_msg
            CALL usersocialnetworklist_ui_set_action_state(DIALOG)
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION editsocialnetwork
      LET i = DIALOG.getCurrentRow("scr_usersocialnetwork_list")
      IF i > 0 THEN
        IF marec_usersocialnetworklist[i].usersocialnetwork.usrscl_id > 0 THEN
          CALL usersocialnetworkgrid_open_form_by_key(marec_usersocialnetworklist[i].usersocialnetwork.usrscl_id, C_APPSTATE_UPDATE)
            RETURNING lint_ret, lint_action, lint_usrscl_id
          IF lint_ret == 0 THEN
            CASE lint_action
              WHEN C_APPACTION_ACCEPT
              WHEN C_APPACTION_CANCEL
              OTHERWISE --custom action
                EXIT DISPLAY
            END CASE
            CALL usersocialnetworklist_get_data_by_key(lint_usrscl_id, marec_usersocialnetworklist, i)
              RETURNING lint_ret, lstr_msg
            CALL usersocialnetworklist_ui_set_action_state(DIALOG)
          END IF
        ELSE
          IF setup.g_app_influencer AND (i==1) THEN --logged-in instagram account
            CALL core_ui.ui_launch_url(SFMT("instagram://user?username=%1",marec_usersocialnetworklist[i].usersocialnetwork.usrscl_accountname))
          END IF
        END IF
      END IF
    ON ACTION viewsocialnetwork
      LET i = DIALOG.getCurrentRow("scr_usersocialnetwork_list")
      IF i > 0 THEN
        CALL layout.open_socialnetwork_account(marec_usersocialnetworklist[i].usersocialnetwork.usrscl_socialnetwork_id, marec_usersocialnetworklist[i].usersocialnetwork.usrscl_accountname)
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

#+ Get the user social networks list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of t_usersocialnetworklist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION usersocialnetworklist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_usersocialnetworklist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    lrec_socialnetwork RECORD LIKE socialnetworks.*

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM usersocialnetworks"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT usersocialnetworks.usrscl_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_usersocialnetworklist_get_data CURSOR FROM lstr_sql
    FOREACH c_usersocialnetworklist_get_data
      INTO lint_usrscl_id
      CALL usersocialnetworklist_get_data_by_key(lint_usrscl_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END FOREACH
    FREE c_usersocialnetworklist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  IF setup.g_app_influencer THEN
    --add influencer instagram account in the list of social networks
    CALL core_db.socialnetwork_select_row(C_SOCIALNETWORK_INSTAGRAM, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_socialnetwork.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL parec_list.insertElement(1)
    INITIALIZE parec_list[1].* TO NULL
    LET parec_list[1].usersocialnetwork.usrscl_usr_id = mint_usersocialnetwork_usr_id
    LET parec_list[1].usersocialnetwork.usrscl_accountname = mint_influencer_instagram_accountname
    LET parec_list[1].usersocialnetwork.usrscl_socialnetwork_id = lrec_socialnetwork.scl_id
    LET parec_list[1].scl_img = lrec_socialnetwork.scl_img
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Get the user social networks list data for a given row
#+
#+ @param pint_usrscl_id user social network id
#+ @param parec_list list of influencers t_usersocialnetworklist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION usersocialnetworklist_get_data_by_key(pint_usrscl_id, parec_list, pint_index)
  DEFINE
    pint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    parec_list DYNAMIC ARRAY OF t_usersocialnetworklist,
    pint_index INTEGER,
    lrec_usersocialnetwork RECORD LIKE usersocialnetworks.*,
    lrec_socialnetwork RECORD LIKE socialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.usersocialnetworks_select_row(pint_usrscl_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_usersocialnetwork.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.socialnetwork_select_row(lrec_usersocialnetwork.usrscl_socialnetwork_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_socialnetwork.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET parec_list[pint_index].usersocialnetwork.* = lrec_usersocialnetwork.*
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
FUNCTION usersocialnetworklist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.DIALOG
  CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden",setup.g_app_influencer)
  CALL p_dialog.setActionHidden("cancel", TRUE)
  CALL p_dialog.setActionHidden("customaction", TRUE)
  CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)
  CALL p_dialog.setActionActive("delete", (marec_usersocialnetworklist.getLength()>0))
  CALL p_dialog.setActionActive("editsocialnetwork", (marec_usersocialnetworklist.getLength()>0))
  CALL p_dialog.setActionActive("addsocialnetwork", setup.g_app_backoffice)
  CALL core_ui.ui_set_node_attribute("Image","name","addsocialnetwork","hidden", setup.g_app_influencer)
  CALL p_dialog.setActionActive("addsocialnetworkmobile", setup.g_app_influencer)
  CALL p_dialog.setActionHidden("addsocialnetworkmobile", setup.g_app_backoffice)
  CALL p_dialog.setActionActive("viewsocialnetwork", setup.g_app_backoffice)
  CALL p_dialog.setActionHidden("viewsocialnetwork", NOT setup.g_app_backoffice)
END FUNCTION

#+ Fetch and display user social network
#+
#+ @param pint_usrscl_id user social network
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION usersocialnetworkgrid_open_form_by_key(pint_usrscl_id, pint_state)
  DEFINE
    pint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  LET mint_usersocialnetwork_usrscl_id = pint_usrscl_id
  LET lint_action = C_APPACTION_UNDEFINED
  CASE pint_state
    WHEN C_APPSTATE_ADD
      CALL usersocialnetworkgrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL usersocialnetworkgrid_update(pint_state) RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  RETURN lint_ret, lint_action, mint_usersocialnetwork_usrscl_id
END FUNCTION

#+ Create a user social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION usersocialnetworkgrid_create(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL usersocialnetworkgrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a user social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION usersocialnetworkgrid_update(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL usersocialnetworkgrid_input(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lint_action
    --we want to stay in the edition
    IF lint_ret == 0 AND lint_action == C_APPACTION_ACCEPT THEN
      IF setup.g_app_backoffice THEN
        LET lbool_exit = FALSE
      END IF
    END IF
  END WHILE
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the user input
#+
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION usersocialnetworkgrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    i INTEGER,
    larec_images DYNAMIC ARRAY OF t_socialnetwork_image,
    larec_dynfields DYNAMIC ARRAY OF t_dynfield_grid,
    l_dialog ui.DIALOG,
    lstr_event STRING,
    lstr_selected_socialnetwork STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = IIF(pint_dialog_state==C_DIALOGSTATE_ADD, %"Add social network",%"Edit social network")

  --initialize the add/update record data
  LET m_dialogtouched = FALSE
  CALL usersocialnetworkgrid_initialize_data(mint_usersocialnetwork_usrscl_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  --get the dictionnary which will bind the dialog action with the social network record 
  CALL _initialize_images(larec_images)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  --set the selected social network
  FOR i = 1 TO larec_images.getLength()
    IF larec_images[i].socialnetwork.scl_id == mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id THEN
      LET larec_images[i].isselected = TRUE
      EXIT FOR
    END IF
  END FOR
  
  OPEN WINDOW w_xyz WITH 1 ROWS, 1 COLUMNS
  CALL FGL_SETTITLE(ff_formtitle)
  CALL _dynform_build(larec_dynfields, larec_images)
  LET l_dialog = ui.Dialog.createInputByName(larec_dynfields)
  CALL l_dialog.addTrigger("ON ACTION dialogtouched")
  CALL l_dialog.addTrigger("ON ACTION save")
  CALL l_dialog.addTrigger("ON ACTION save_mobile")
  CALL l_dialog.addTrigger("ON ACTION cancel")
  CALL l_dialog.addTrigger("ON ACTION close")
  CALL l_dialog.addTrigger("ON ACTION customaction")
  FOR i = 1 TO larec_images.getLength()
    CALL l_dialog.addTrigger("ON ACTION "||larec_images[i].actionname)
  END FOR
  --set the default values for the usersocialnetworks record
  CALL _dynform_record_to_ui(l_dialog, larec_dynfields)

  WHILE TRUE
    LET lstr_event = l_dialog.nextEvent()
    CASE lstr_event
      WHEN "ON ACTION dialogtouched"
        LET m_dialogtouched = TRUE
        CALL usersocialnetworkgrid_ui_set_action_state(l_dialog, pint_dialog_state, m_dialogtouched)
      WHEN "ON ACTION save_mobile" --save on mobile
        CALL _dynform_ui_to_record(l_dialog, larec_dynfields)
        CALL usersocialnetworkgrid_process_data(l_dialog, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL l_dialog.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE WHILE
        END IF
        LET mint_usersocialnetwork_usrscl_id = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id
        LET lint_action = C_APPACTION_ACCEPT
        EXIT WHILE
      WHEN "ON ACTION save"
        CALL _dynform_ui_to_record(l_dialog, larec_dynfields)
        CALL usersocialnetworkgrid_process_data(l_dialog, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL l_dialog.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE WHILE
        END IF
        LET mint_usersocialnetwork_usrscl_id = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id
        LET lint_action = C_APPACTION_ACCEPT
        EXIT WHILE
      WHEN "ON ACTION cancel"
        CALL usersocialnetworkgrid_process_data(l_dialog, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL l_dialog.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE WHILE
        END IF
        LET mint_usersocialnetwork_usrscl_id = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id
        LET lint_action = C_APPACTION_CANCEL
        EXIT WHILE
      WHEN "ON ACTION customaction"
        CALL usersocialnetworkgrid_process_data(l_dialog, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL l_dialog.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE WHILE
        END IF
        LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
        LET mint_usersocialnetwork_usrscl_id = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id
        EXIT WHILE
      WHEN "BEFORE INPUT"
        LET m_dialogtouched = FALSE
        CALL usersocialnetworkgrid_ui_set_action_state(l_dialog, pint_dialog_state, m_dialogtouched)
        IF setup.g_app_backoffice THEN
          DISPLAY BY NAME ff_formtitle
        END IF
        --display the selected social network image
        FOR i = 1 TO larec_images.getLength()
          IF larec_images[i].isselected THEN
            CALL core_ui.ui_set_node_attribute("Image","name",larec_images[i].actionname,"image", larec_images[i].selectedimage)
            EXIT FOR
          END IF
        END FOR
      WHEN "AFTER INPUT"
        EXIT WHILE
      OTHERWISE
        IF lstr_event.getIndexOf("ON ACTION socialnetwork", 1) > 0 THEN
          LET lstr_selected_socialnetwork = lstr_event.subString(11, lstr_event.getLength()) --get the action name
          FOR i = 1 TO larec_images.getLength()
            IF larec_images[i].actionname == lstr_selected_socialnetwork THEN
              IF NOT larec_images[i].isselected THEN
                LET larec_images[i].isselected = TRUE
                CALL l_dialog.setFieldValue(larec_dynfields[3].name, larec_images[i].socialnetwork.scl_id) 
                LET m_dialogtouched = TRUE
                CALL usersocialnetworkgrid_ui_set_action_state(l_dialog, pint_dialog_state, m_dialogtouched)
                CALL core_ui.ui_set_node_attribute("Image","name",larec_images[i].actionname,"image", larec_images[i].selectedimage)
              END IF
            ELSE
              IF larec_images[i].isselected THEN
                LET larec_images[i].isselected = FALSE
                CALL core_ui.ui_set_node_attribute("Image","name",larec_images[i].actionname,"image", larec_images[i].unselectedimage)
              END IF
            END IF
          END FOR
        END IF
    END CASE
  END WHILE
  CALL l_dialog.close()
  LET l_dialog = NULL
  CLOSE WINDOW w_xyz
  RETURN lint_ret, lint_action
END FUNCTION

PRIVATE FUNCTION _initialize_images(larec_images DYNAMIC ARRAY OF t_socialnetwork_image)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_socialnetworks DYNAMIC ARRAY OF RECORD LIKE socialnetworks.*,
    i INTEGER
  CALL larec_images.clear()
  --fetch the list of available socialnetworks
  CALL core_db.socialnetwork_fetch_all_rows(NULL, "ORDER BY socialnetworks.scl_uiorder", larec_socialnetworks)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO larec_socialnetworks.getLength()
    LET larec_images[i].socialnetwork.* = larec_socialnetworks[i].*
    LET larec_images[i].actionname = "socialnetwork"||i
    LET larec_images[i].selectedimage = larec_socialnetworks[i].scl_img
    LET larec_images[i].unselectedimage = _get_unselectedimage_name(larec_socialnetworks[i].scl_img)
    LET larec_images[i].isselected = FALSE
  END FOR
  RETURN 0, NULL
END FUNCTION

PRIVATE FUNCTION _get_unselectedimage_name(pstr_image_name STRING)
  DEFINE
    i INTEGER
  IF pstr_image_name.getLength()==0 THEN RETURN NULL END IF
  IF pstr_image_name.subString(1,3) == "fa-" THEN
    RETURN pstr_image_name||"-grey"
  ELSE
    LET i = pstr_image_name.getIndexOf(".",1)
    IF i > 0 THEN
      RETURN pstr_image_name.subString(1,i-1) || "-grey"
    END IF  
  END IF
  RETURN NULL
END FUNCTION

PRIVATE FUNCTION _dynform_record_to_ui(p_dialog ui.DIALOG, parec_dynfields DYNAMIC ARRAY OF t_dynfield_grid)
  CALL p_dialog.setFieldValue(parec_dynfields[1].name, mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id)
  CALL p_dialog.setFieldValue(parec_dynfields[2].name, mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id)
  CALL p_dialog.setFieldValue(parec_dynfields[3].name, mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id)
  CALL p_dialog.setFieldValue(parec_dynfields[4].name, mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_accountname)
  CALL p_dialog.setFieldValue(parec_dynfields[5].name, mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_comment)
END FUNCTION

PRIVATE FUNCTION _dynform_ui_to_record(p_dialog ui.DIALOG, parec_dynfields DYNAMIC ARRAY OF t_dynfield_grid)
  LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id = p_dialog.getFieldValue(parec_dynfields[1].name)
  LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id = p_dialog.getFieldValue(parec_dynfields[2].name)
  LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id = p_dialog.getFieldValue(parec_dynfields[3].name)
  LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_accountname = p_dialog.getFieldValue(parec_dynfields[4].name)
  LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_comment = p_dialog.getFieldValue(parec_dynfields[5].name)
END FUNCTION

PRIVATE FUNCTION _dynform_build(parec_dynfields DYNAMIC ARRAY OF t_dynfield_grid, parec_images DYNAMIC ARRAY OF t_socialnetwork_image)
  DEFINE
    w ui.window,
    f ui.form,
    form, grid, screenRecordFormOnly, screenRecordGrid, formfield, phantomField, phantomEdit, edit, textEdit, l_label, link, image om.DomNode,
    i,fieldId,posY,posX,tabIndex,nbImagePerLine,currentLine INTEGER

  LET posY = 0
  LET fieldId = -1
  LET tabIndex = 0
  CALL parec_dynfields.clear()
  LET w = ui.Window.getCurrent()
  LET f = w.createForm("foobar")
  LET form = f.getNode()

  LET grid = form.createChild("Grid")
  CALL grid.setAttribute("name", "salfatixmedia1")
  CALL grid.setAttribute("width", 37)
  CALL grid.setAttribute("height", 23)

  LET screenRecordFormOnly = form.createChild("RecordView")
  CALL screenRecordFormOnly.setAttribute("tabName", "formonly")

  LET screenRecordGrid = form.createChild("RecordView")
  CALL screenRecordGrid.setAttribute("tabName", "scr_usersocialnetwork_grid")

  IF setup.g_app_backoffice THEN
    --FormField ff_formtitle
    LET posY = 0
    LET tabIndex = tabIndex + 1
    LET fieldId = fieldId + 1
    LET formfield = grid.createChild("FormField")
    CALL formfield.setAttribute("name", "formonly.ff_formtitle")
    CALL formfield.setAttribute("colName", "ff_formtitle")
    CALL formfield.setAttribute("fieldId", fieldId)
    CALL formfield.setAttribute("sqlTabName", "formonly")
    CALL formfield.setAttribute("noEntry", "1")
    CALL formfield.setAttribute("tabIndex", tabIndex)
    LET l_label = formfield.createChild("Label")
    CALL l_label.setAttribute("width", "35")
    CALL l_label.setAttribute("justify", "center")
    CALL l_label.setAttribute("style", "ff_formtitle")
    CALL l_label.setAttribute("posY", posY)
    CALL l_label.setAttribute("posX", "1")
    CALL l_label.setAttribute("gridWidth", "35")
    LET link = screenRecordFormOnly.createChild("Link")
    CALL link.setAttribute("colName", "ff_formtitle")
    CALL link.setAttribute("fieldIdRef", fieldId)

    --Image img_back
    LET posY = posY + 1
    LET image = grid.createChild("Image")
    CALL image.setAttribute("name", "img_back")
    CALL image.setAttribute("width", "5")
    CALL image.setAttribute("height", "3")
    CALL image.setAttribute("action", "cancel")
    CALL image.setAttribute("image", "fa-arrow-circle-left")
    CALL image.setAttribute("autoScale", "1")
    CALL image.setAttribute("sizePolicy", "fixed")
    CALL image.setAttribute("style", "no_border")
    CALL image.setAttribute("comment", "Back")
    CALL image.setAttribute("posY", posY)
    CALL image.setAttribute("posX", "1")
    CALL image.setAttribute("gridWidth", "5")
    CALL image.setAttribute("gridHeight", "3")

    --FormField ffimage_value
    LET posY = 1
    LET fieldId = fieldId + 1
    LET tabIndex = tabIndex + 1
    LET formfield = grid.createChild("FormField")
    CALL formfield.setAttribute("name", "formonly.ffimage_value")
    CALL formfield.setAttribute("colName", "ffimage_value")
    CALL formfield.setAttribute("fieldId", fieldId)
    CALL formfield.setAttribute("sqlTabName", "formonly")
    CALL formfield.setAttribute("noEntry", "1")
    CALL formfield.setAttribute("tabIndex", tabIndex)
    LET image = grid.createChild("Image")
    CALL image.setAttribute("width", "5")
    CALL image.setAttribute("height", "3")
    CALL image.setAttribute("action", "save")
    CALL image.setAttribute("autoScale", "1")
    CALL image.setAttribute("sizePolicy", "fixed")
    CALL image.setAttribute("style", "no_border")
    CALL image.setAttribute("comment", "Save")
    CALL image.setAttribute("posY", posY)
    CALL image.setAttribute("posX", "31")
    CALL image.setAttribute("gridWidth", "5")
    CALL image.setAttribute("gridHeight", "3")
    LET link = screenRecordFormOnly.createChild("Link")
    CALL link.setAttribute("colName", "ffimage_value")
    CALL link.setAttribute("fieldIdRef", fieldId)
  END IF
  LET nbImagePerLine = 4
  LET currentLine = 0
  LET posY = posY + IIF(setup.g_app_backoffice, 3, 0)
  LET posX = 1
  FOR i = 1 TO parec_images.getLength()
    LET currentLine = currentLine + 1
    IF currentLine > nbImagePerLine THEN
      LET posY = posY + 2
      LET currentLine = 1
    END IF
    LET image = grid.createChild("Image")
    CALL image.setAttribute("name", parec_images[i].actionname)
    CALL image.setAttribute("width", "8")
    CALL image.setAttribute("height", "2")
    CALL image.setAttribute("action", parec_images[i].actionname)
    CALL image.setAttribute("image", parec_images[i].unselectedimage)
    CALL image.setAttribute("autoScale", "1")
    CALL image.setAttribute("sizePolicy", "fixed")
    CALL image.setAttribute("style", "no_border")
    CALL image.setAttribute("comment",  parec_images[i].socialnetwork.scl_name)
    CALL image.setAttribute("posY", posY)
    CALL image.setAttribute("posX", posX+9*(currentLine-1))
    CALL image.setAttribute("gridWidth", "8")
    CALL image.setAttribute("gridHeight", "2")
  END FOR

  --FormField usersocialnetworks.usrscl_id
  LET fieldId = fieldId + 1
  LET phantomField = grid.createChild("PhantomFormField")
  CALL phantomField.setAttribute("name", "usersocialnetworks.usrscl_id")
  CALL phantomField.setAttribute("colName", "usrscl_id")
  CALL phantomField.setAttribute("fieldId", fieldId)
  CALL phantomField.setAttribute("sqlTabName", "usersocialnetworks")
  CALL phantomField.setAttribute("sqlType", "INTEGER")
  CALL phantomField.setAttribute("noEntry", "1")
  CALL phantomField.setAttribute("required", "1")
  CALL phantomField.setAttribute("notNull", "1")
  LET phantomEdit = phantomField.createChild("PhantomEdit")
  CALL phantomEdit.setAttribute("width", "1")
  LET link = screenRecordGrid.createChild("Link")
  CALL link.setAttribute("colName", "usrscl_id")
  CALL link.setAttribute("fieldIdRef", fieldId)
  LET parec_dynfields[parec_dynfields.getLength()+1].name = "usrscl_id"
  LET parec_dynfields[parec_dynfields.getLength()].type = "INTEGER"

  --FormField usersocialnetworks.usrscl_usr_id
  LET fieldId = fieldId + 1
  LET phantomField = grid.createChild("PhantomFormField")
  CALL phantomField.setAttribute("name", "usersocialnetworks.usrscl_usr_id")
  CALL phantomField.setAttribute("colName", "usrscl_usr_id")
  CALL phantomField.setAttribute("fieldId", fieldId)
  CALL phantomField.setAttribute("sqlTabName", "usersocialnetworks")
  CALL phantomField.setAttribute("sqlType", "INTEGER")
  CALL phantomField.setAttribute("noEntry", "1")
  CALL phantomField.setAttribute("required", "1")
  CALL phantomField.setAttribute("notNull", "1")
  LET phantomEdit = phantomField.createChild("PhantomEdit")
  CALL phantomEdit.setAttribute("width", "1")
  LET link = screenRecordGrid.createChild("Link")
  CALL link.setAttribute("colName", "usrscl_usr_id")
  CALL link.setAttribute("fieldIdRef", fieldId)
  LET parec_dynfields[parec_dynfields.getLength()+1].name = "usrscl_usr_id"
  LET parec_dynfields[parec_dynfields.getLength()].type = "INTEGER"

  --FormField usersocialnetworks.usrscl_socialnetwork_id
  LET fieldId = fieldId + 1
  LET phantomField = grid.createChild("PhantomFormField")
  CALL phantomField.setAttribute("name", "usersocialnetworks.usrscl_socialnetwork_id")
  CALL phantomField.setAttribute("colName", "usrscl_socialnetwork_id")
  CALL phantomField.setAttribute("fieldId", fieldId)
  CALL phantomField.setAttribute("sqlTabName", "usersocialnetworks")
  CALL phantomField.setAttribute("sqlType", "INTEGER")
  CALL phantomField.setAttribute("noEntry", "1")
  CALL phantomField.setAttribute("required", "1")
  CALL phantomField.setAttribute("notNull", "1")
  LET phantomEdit = phantomField.createChild("PhantomEdit")
  CALL phantomEdit.setAttribute("width", "1")
  LET link = screenRecordGrid.createChild("Link")
  CALL link.setAttribute("colName", "usrscl_socialnetwork_id")
  CALL link.setAttribute("fieldIdRef", fieldId)
  LET parec_dynfields[parec_dynfields.getLength()+1].name = "usrscl_socialnetwork_id"
  LET parec_dynfields[parec_dynfields.getLength()].type = "INTEGER"

  --Label usersocialnetworks_usrscl_socialnetwork_id_label
  LET posY = posY + 3
  LET l_label = grid.createChild("Label")
  CALL l_label.setAttribute("name", "usersocialnetworks_usrscl_accountname_label")
  CALL l_label.setAttribute("width", "35")
  CALL l_label.setAttribute("text", %"Account")
  CALL l_label.setAttribute("posY", posY)
  CALL l_label.setAttribute("posX", "1")
  CALL l_label.setAttribute("gridWidth", "35")

  LET posY = posY + 1
  LET fieldId = fieldId + 1
  LET tabIndex = tabIndex + 1
  LET formfield = grid.createChild("FormField")
  CALL formfield.setAttribute("name", "usersocialnetworks.usrscl_accountname")
  CALL formfield.setAttribute("colName", "usrscl_accountname")
  CALL formfield.setAttribute("fieldId", fieldId)
  CALL formfield.setAttribute("sqlType", "VARCHAR(255)")
  CALL formfield.setAttribute("required", "1")
  CALL formfield.setAttribute("notNull", "1")
  CALL formfield.setAttribute("sqlTabName", "usersocialnetworks")
  CALL formfield.setAttribute("tabIndex", tabIndex)
  LET edit = formfield.createChild("Edit")
  CALL edit.setAttribute("width", "35")
  CALL edit.setAttribute("scroll", "1")
  CALL edit.setAttribute("posY", posY)
  CALL edit.setAttribute("posX", "1")
  CALL edit.setAttribute("gridWidth", "35")
  LET link = screenRecordGrid.createChild("Link")
  CALL link.setAttribute("colName", "usrscl_accountname")
  CALL link.setAttribute("fieldIdRef", fieldId)
  LET parec_dynfields[parec_dynfields.getLength()+1].name = "usrscl_accountname"
  LET parec_dynfields[parec_dynfields.getLength()].type = "VARCHAR(255)"

  IF setup.g_app_backoffice THEN
    --Label usersocialnetworks_usrscl_comment_label
    LET posY = posY + 1
    LET l_label = grid.createChild("Label")
    CALL l_label.setAttribute("name", "usersocialnetworks_usrscl_comment_label")
    CALL l_label.setAttribute("width", "35")
    CALL l_label.setAttribute("text", %"Comment")
    CALL l_label.setAttribute("posY", posY)
    CALL l_label.setAttribute("posX", "1")
    CALL l_label.setAttribute("gridWidth", "35")

    LET posY = posY + 1
    LET fieldId = fieldId + 1
    LET tabIndex = tabIndex + 1
    LET formfield = grid.createChild("FormField")
    CALL formfield.setAttribute("name", "usersocialnetworks.usrscl_comment")
    CALL formfield.setAttribute("colName", "usrscl_comment")
    CALL formfield.setAttribute("fieldId", fieldId)
    CALL formfield.setAttribute("sqlType", "VARCHAR(255)")
    CALL formfield.setAttribute("sqlTabName", "usersocialnetworks")
    CALL formfield.setAttribute("tabIndex", tabIndex)
    LET textEdit = formfield.createChild("TextEdit")
    CALL textEdit.setAttribute("width", "35")
    CALL textEdit.setAttribute("height", "3")
    CALL textEdit.setAttribute("wantReturns", "1")
    CALL textEdit.setAttribute("scroll", "1")
    CALL textEdit.setAttribute("posY", posY)
    CALL textEdit.setAttribute("posX", "1")
    CALL textEdit.setAttribute("gridWidth", "35")
    CALL textEdit.setAttribute("gridHeight", "3")
    LET link = screenRecordGrid.createChild("Link")
    CALL link.setAttribute("colName", "usrscl_comment")
    CALL link.setAttribute("fieldIdRef", fieldId)
    LET parec_dynfields[parec_dynfields.getLength()+1].name = "usrscl_comment"
    LET parec_dynfields[parec_dynfields.getLength()].type = "VARCHAR(255)"
  END IF
  IF setup.g_app_influencer THEN
    LET fieldId = fieldId + 1
    LET formfield = grid.createChild("PhantomFormField")
    CALL formfield.setAttribute("name", "usersocialnetworks.usrscl_comment")
    CALL formfield.setAttribute("colName", "usrscl_comment")
    CALL formfield.setAttribute("fieldId", fieldId)
    CALL formfield.setAttribute("sqlTabName", "usersocialnetworks")
    CALL formfield.setAttribute("sqlType", "VARCHAR(255)")
    CALL formfield.setAttribute("noEntry", "1")
    LET phantomEdit = formfield.createChild("PhantomEdit")
    CALL phantomEdit.setAttribute("width", "1")
    LET link = screenRecordGrid.createChild("Link")
    CALL link.setAttribute("colName", "usrscl_comment")
    CALL link.setAttribute("fieldIdRef", fieldId)
    LET parec_dynfields[parec_dynfields.getLength()+1].name = "usrscl_comment"
    LET parec_dynfields[parec_dynfields.getLength()].type = "VARCHAR(255)"
  END IF
  --CALL form.writeXml("toto.42f")
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION usersocialnetworkgrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("dialogtouched", TRUE)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save_mobile", pbool_dialog_touched AND setup.g_app_is_mobile)
      CALL p_dialog.setActionHidden("save_mobile", NOT setup.g_app_is_mobile)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("save", NOT setup.g_app_backoffice)

      IF setup.g_app_backoffice THEN
        CALL layout.display_savebutton(pbool_dialog_touched)
      END IF
      
      CALL p_dialog.setActionActive("customaction", setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("customaction", NOT setup.g_app_backoffice)

    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("dialogtouched", TRUE)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save_mobile", pbool_dialog_touched AND setup.g_app_is_mobile)
      CALL p_dialog.setActionHidden("save_mobile", NOT setup.g_app_is_mobile)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("save", NOT setup.g_app_backoffice)

      IF setup.g_app_backoffice THEN
        CALL layout.display_savebutton(pbool_dialog_touched)
      END IF

      CALL p_dialog.setActionActive("customaction", setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("customaction", NOT setup.g_app_backoffice)
  END CASE

END FUNCTION

#+ Initializes the user social network business record
#+
#+ @param pint_usrscl_id user social network id
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER
#+ @return     0|error
FUNCTION usersocialnetworkgrid_initialize_data(pint_usrscl_id, pint_dialog_state)
  DEFINE
    pint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING

  INITIALIZE mrec_usersocialnetworkgrid.* TO NULL
  INITIALIZE mrec_copy_usersocialnetworkgrid.* TO NULL
  INITIALIZE mrec_db_usersocialnetwork.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id = 0
      LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id = mint_usersocialnetwork_usr_id
      LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id = get_first_socialnetwork(mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id)
      --mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_accountname
      --mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_comment
    WHEN C_DIALOGSTATE_UPDATE
      CALL usersocialnetworkgrid_get_data_by_key(pint_usrscl_id)
        RETURNING lint_ret, lstr_msg, mrec_usersocialnetworkgrid.*, mrec_db_usersocialnetwork.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_copy_usersocialnetworkgrid.* = mrec_usersocialnetworkgrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_usersocialnetworkgrid
#+
#+ @param pint_usrscl_id user social network id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_usersocialnetworkgrid business record, usersocialnetwork database record
FUNCTION usersocialnetworkgrid_get_data_by_key(pint_usrscl_id)
  DEFINE
    pint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE usersocialnetworks.*,
    lrec_ui_usersocialnetwork t_usersocialnetworkgrid,
    lrec_db_data RECORD LIKE usersocialnetworks.*

  INITIALIZE lrec_ui_usersocialnetwork.* TO NULL

  CALL core_db.usersocialnetworks_select_row(pint_usrscl_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_data.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_usersocialnetwork.*, lrec_db_data.*
  END IF
  LET lrec_ui_usersocialnetwork.usersocialnetwork.* = lrec_data.*
  LET lrec_db_data.* = lrec_data.*
  RETURN lint_ret, lstr_msg, lrec_ui_usersocialnetwork.*, lrec_db_data.*
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
FUNCTION usersocialnetworkgrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_usrscl_id LIKE usersocialnetworks.usrscl_id

  --DISPLAY SFMT("user_process_data = pint_dialog_state=%1 pbool_dialog_touched=%2 pint_dialog_action=%3",pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    CALL usersocialnetwork_validate_data(C_DIALOGSTATE_ADD)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL usersocialnetwork_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_usrscl_id
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Social network registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id = lint_usrscl_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_update_data THEN
    CALL usersocialnetwork_validate_data(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL usersocialnetwork_update_into_dabatase()
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
    CALL usersocialnetworkgrid_initialize_data(mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL usersocialnetworkgrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_usersocialnetwork_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL usersocialnetworkgrid_initialize_data(mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL usersocialnetworkgrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_usersocialnetwork_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a user social network into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, user social network id
FUNCTION usersocialnetwork_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_usersocialnetwork RECORD LIKE usersocialnetworks.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_usersocialnetwork.usrscl_id
  END IF
  INITIALIZE lrec_usersocialnetwork.* TO NULL
  LET lrec_usersocialnetwork.* = mrec_usersocialnetworkgrid.usersocialnetwork.*
  CALL core_db.usersocialnetworks_insert_row(lrec_usersocialnetwork.*)
    RETURNING lint_ret, lstr_msg, lrec_usersocialnetwork.usrscl_id
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_usersocialnetwork.usrscl_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_usersocialnetwork.usrscl_id
END FUNCTION

#+ Update a user social network into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION usersocialnetwork_update_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_usersocialnetwork RECORD LIKE usersocialnetworks.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  INITIALIZE lrec_usersocialnetwork.* TO NULL
  LET lrec_usersocialnetwork.* = mrec_usersocialnetworkgrid.usersocialnetwork.*
  CALL core_db.usersocialnetworks_update_row(mrec_db_usersocialnetwork.*, lrec_usersocialnetwork.*)
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

#+ Delete a user social network from database
#+
#+ @param pint_usrscl_id user social network id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION usersocialnetwork_delete_from_dabatase(pint_usrscl_id)
  DEFINE
    pint_usrscl_id LIKE usersocialnetworks.usrscl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.usersocialnetworks_delete_row(pint_usrscl_id)
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

#+ Check business rules of a user social network
#+
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION usersocialnetwork_validate_data(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    i INTEGER

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id IS NULL OR mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_id==0 THEN
      RETURN -1, %"Id missing"
    END IF
  END IF
  IF mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id IS NULL OR mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id==0 THEN
    RETURN -1, %"User missing"
  END IF
  IF mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id IS NULL OR mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id==0 THEN
    RETURN -1, %"Network missing"
  END IF
  IF mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_accountname IS NULL THEN
    RETURN -1, %"Account missing"
  END IF
  --can not add the instagram account of the influencer 
  IF mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id == C_SOCIALNETWORK_INSTAGRAM
    AND mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_accountname == mint_influencer_instagram_accountname
  THEN
    RETURN -1, %"Instagram account already exists"
  END IF
  TRY
    SELECT usersocialnetworks.usrscl_id INTO i
    FROM usersocialnetworks
    WHERE usrscl_usr_id = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_usr_id
      AND usrscl_socialnetwork_id = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_socialnetwork_id
      AND usrscl_accountname = mrec_usersocialnetworkgrid.usersocialnetwork.usrscl_accountname
    CASE SQLCA.SQLCODE
      WHEN 0
        IF pint_dialog_state == C_DIALOGSTATE_ADD THEN
          RETURN -1, %"Record already exists"
        ELSE --update
          IF i <> mrec_db_usersocialnetwork.usrscl_id THEN
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
#+ @param pint_user_id user id
#+
#+ @returnType INTEGER
#+ @return     social network id
FUNCTION get_first_socialnetwork(pint_user_id)
  DEFINE
    pint_user_id LIKE usersocialnetworks.usrscl_usr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_socialnetwork_id LIKE socialnetworks.scl_id

  LET lstr_sql = "SELECT socialnetworks.scl_id"
    ," FROM socialnetworks"
    ," WHERE socialnetworks.scl_id NOT IN "
    ,SFMT("(SELECT usersocialnetworks.usrscl_socialnetwork_id FROM usersocialnetworks WHERE usersocialnetworks.usrscl_usr_id=%1)", pint_user_id)
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
  CALL combobox.socialnetwork_initializer(ui.ComboBox.forName("usersocialnetworks.usrscl_socialnetwork_id"))
END FUNCTION
