IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL campaignposttypes
IMPORT FGL combobox
IMPORT FGL setup
IMPORT util
IMPORT os
IMPORT FGL campaignposts_commons

SCHEMA salfatixmedia

TYPE
  t_campaignpostlist_mobile RECORD
    campaignpost RECORD LIKE campaignposts.*,
    pic_value LIKE pics.pic_value,
    status_label STRING
  END RECORD
TYPE
  t_campaignpostgrid_mobile RECORD
    campaignpost RECORD LIKE campaignposts.*,
    pic_value LIKE pics.pic_value,
    status_label STRING
  END RECORD

DEFINE
  marec_campaignpost_mobile DYNAMIC ARRAY OF t_campaignpostlist_mobile,
  mint_campaign_id LIKE campaigns.cmp_id,
  mint_usr_id LIKE users.usr_id,
  mint_campaignpost_id LIKE campaignposts.cmppost_id
DEFINE
  mrec_campaignpost_mobile t_campaignpostgrid_mobile,
  mrec_db_campaignpost_mobile RECORD LIKE campaignposts.*
DEFINE
  m_dialogtouched BOOLEAN

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
FUNCTION campaignpostlistmobile_open_form_by_key(pint_campaign_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET mint_campaign_id = pint_campaign_id
  LET mint_usr_id = pint_usr_id
  LET lint_action = C_APPACTION_UNDEFINED
  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL campaignpostlist_get_data_mobile(mint_campaign_id, mint_usr_id, marec_campaignpost_mobile)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      IF marec_campaignpost_mobile.getLength() == 0 THEN
        OPEN WINDOW w_campaignpostlist_empty WITH FORM "campaignposts_empty_mobile"
        CALL campaignpostlist_empty_mobile()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_campaignpostlist_empty
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_VIEWLIST THEN
            LET lbool_exit = FALSE
          END IF
        END IF
      ELSE
        OPEN WINDOW w_campaignpost_list WITH FORM "campaignposts_list_mobile"
        CALL campaignpostlist_display_mobile()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_campaignpost_list
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

#+ Dialog an empty campaign list
#+
#+ @param pint_type list type
#+
#+ @returnType SMALLINT
#+ @return     the list type of the displayed list
FUNCTION campaignpostlist_empty_mobile()
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT,
    lint_campaignpost_id LIKE campaignposts.cmppost_id

  LET lint_action = C_APPACTION_UNDEFINED
  CALL FGL_SETTITLE(%"Posts")
  MENU ""
    ON ACTION add_post
      CALL campaignpostgrid_open_form_by_key_mobile(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_campaignpost_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_CANCEL
          WHEN C_APPACTION_ACCEPT
            LET lint_action = C_APPACTION_VIEWLIST
            EXIT MENU
          OTHERWISE
            EXIT MENU
        END CASE
      END IF
    ON ACTION cancel
      LET lint_action = C_APPACTION_CANCEL
      EXIT MENU
    BEFORE MENU
      CALL campaignpostmenu_ui_set_action_state_mobile(DIALOG)
  END MENU
  RETURN lint_ret, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignpostmenu_ui_set_action_state_mobile(p_dialog)
  DEFINE
    p_dialog ui.DIALOG,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lbool_allow_add_post BOOLEAN
  LET lbool_allow_add_post = FALSE
  CALL core_db.campaigns_select_row(mint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret == 0 THEN
    IF lrec_campaign.cmp_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
      LET lbool_allow_add_post = TRUE
    END IF
  END IF
  CALL p_dialog.setActionActive("add_post", lbool_allow_add_post)
  CALL core_ui.ui_set_node_attribute("Button","name","add_post","hidden",NOT lbool_allow_add_post)
END FUNCTION

#+ Display the user social networks list
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION campaignpostlist_display_mobile()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_campaignpost_id LIKE campaignposts.cmppost_id,
    i INTEGER,
    ff_formtitle STRING,
    lint_app_state SMALLINT

  LET lint_action = C_APPACTION_CANCEL
  LET ff_formtitle = %"Posts"
  CALL FGL_SETTITLE(ff_formtitle)

  DISPLAY ARRAY marec_campaignpost_mobile TO scr_campaignpost_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY
      CALL campaignpost_combobox_initializer_mobile()
      CALL campaignpostlist_ui_set_action_state_mobile(DIALOG)
    ON ACTION delete ATTRIBUTES (ROWBOUND)
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        IF marec_campaignpost_mobile[i].campaignpost.cmppost_id > 0 THEN
          IF marec_campaignpost_mobile[i].campaignpost.cmppost_ispublic <> C_POST_ISPUBLIC_VERIFIEDBYSALFATIX THEN
            CALL campaignpost_delete_from_dabatase_mobile(marec_campaignpost_mobile[i].campaignpost.cmppost_id)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              CALL DIALOG.deleteRow("scr_campaignpost_list", i)
              CALL campaignpostlist_ui_set_action_state_mobile(DIALOG)
              IF marec_campaignpost_mobile.getLength() == 0 THEN
                LET lint_action = C_APPACTION_VIEWEMPTY
                EXIT DISPLAY
              END IF
            END IF
          END IF
        END IF
      END IF
    ON ACTION addpost
      CALL campaignpostgrid_open_form_by_key_mobile(0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_campaignpost_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            CALL campaignpostlist_get_data_by_key_mobile(lint_campaignpost_id, marec_campaignpost_mobile, marec_campaignpost_mobile.getLength()+1)
              RETURNING lint_ret, lstr_msg
            CALL campaignpostlist_ui_set_action_state_mobile(DIALOG)
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION editpost
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        LET lint_app_state = IIF(marec_campaignpost_mobile[i].campaignpost.cmppost_ispublic <> C_POST_ISPUBLIC_VERIFIEDBYSALFATIX, C_APPSTATE_UPDATE, C_APPSTATE_DISPLAY)
        CALL campaignpostgrid_open_form_by_key_mobile(marec_campaignpost_mobile[i].campaignpost.cmppost_id, lint_app_state)
          RETURNING lint_ret, lint_action, lint_campaignpost_id
        IF lint_ret == 0 THEN
          CASE lint_action
            WHEN C_APPACTION_ACCEPT
            WHEN C_APPACTION_CANCEL
            OTHERWISE --custom action
              EXIT DISPLAY
          END CASE
          IF lint_app_state == C_APPSTATE_UPDATE THEN
            CALL campaignpostlist_get_data_by_key_mobile(lint_campaignpost_id, marec_campaignpost_mobile, i)
              RETURNING lint_ret, lstr_msg
            CALL campaignpostlist_ui_set_action_state_mobile(DIALOG)
          END IF
        END IF
      END IF
    ON ACTION cancel
      LET lint_action = C_APPACTION_CANCEL
      EXIT DISPLAY
    END DISPLAY
  RETURN lint_ret, lint_action
END FUNCTION

#+ Get the selected influencer list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of selectable influencer t_brandlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_get_data_mobile(pint_campaign_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id, parec_campaignpost_mobile DYNAMIC ARRAY OF t_campaignpostlist_mobile)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_campaignpost_mobile DYNAMIC ARRAY OF RECORD LIKE campaignposts.*,
    i INTEGER

  CALL parec_campaignpost_mobile.clear()
  CALL core_db.campaignposts_fetch_all_rows(SFMT("WHERE campaignposts.cmppost_campaign_id = %1 AND campaignposts.cmppost_usr_id = %2", pint_campaign_id, pint_usr_id), NULL, larec_campaignpost_mobile)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    IF larec_campaignpost_mobile.getLength() > 0 THEN
      FOR i = 1 TO larec_campaignpost_mobile.getLength()
        LET parec_campaignpost_mobile[i].campaignpost.* = larec_campaignpost_mobile[i].*
        IF parec_campaignpost_mobile[i].pic_value IS NOT NULL THEN FREE parec_campaignpost_mobile[i].pic_value END IF
        IF larec_campaignpost_mobile[i].cmppost_filename IS NOT NULL THEN
          LET parec_campaignpost_mobile[i].pic_value = campaignposts_commons.campaignpost_load_image(larec_campaignpost_mobile[i].cmppost_filename, larec_campaignpost_mobile[i].cmppost_posttype_id)
        END IF
        LET parec_campaignpost_mobile[i].status_label = _get_label(larec_campaignpost_mobile[i].cmppost_isacceptedbysalfatix, larec_campaignpost_mobile[i].cmppost_isacceptedbybrand, larec_campaignpost_mobile[i].cmppost_ispublic)
      END FOR
    END IF
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Get the selected influencer list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of selectable influencer t_brandlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_get_data_by_key_mobile(pint_campaignpost_id LIKE campaignposts.cmppost_id, parec_list DYNAMIC ARRAY OF t_campaignpostlist_mobile, pint_index INTEGER)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*

  CALL core_db.campaignposts_select_row(pint_campaignpost_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignpost.*
  LET parec_list[pint_index].campaignpost.* = lrec_campaignpost.*
  IF parec_list[pint_index].pic_value IS NOT NULL THEN FREE parec_list[pint_index].pic_value END IF
  IF lrec_campaignpost.cmppost_filename IS NOT NULL THEN
    LET parec_list[pint_index].pic_value = campaignposts_commons.campaignpost_load_image(lrec_campaignpost.cmppost_filename, lrec_campaignpost.cmppost_posttype_id)
  END IF
  LET parec_list[pint_index].status_label = _get_label(lrec_campaignpost.cmppost_isacceptedbysalfatix, lrec_campaignpost.cmppost_isacceptedbybrand, lrec_campaignpost.cmppost_ispublic)
  RETURN 0, NULL
END FUNCTION

PRIVATE FUNCTION _get_label(p_isacceptedbysalfatix LIKE campaignposts.cmppost_isacceptedbysalfatix, p_isacceptedbybrand LIKE campaignposts.cmppost_isacceptedbybrand, p_ispublic LIKE campaignposts.cmppost_ispublic)
  CASE
    WHEN p_isacceptedbysalfatix IS NULL
      RETURN %"Waiting validation."
    WHEN p_isacceptedbysalfatix = 0
      RETURN %"Post rejected."
    WHEN p_isacceptedbysalfatix = 1
      CASE
        WHEN p_isacceptedbybrand IS NULL
          RETURN %"Waiting validation."
        WHEN p_isacceptedbybrand = 0
          RETURN %"Post rejected."
        WHEN p_isacceptedbybrand = 1
          CASE p_ispublic
            WHEN C_POST_ISPUBLIC_NO
              RETURN %"Time to publish."
            WHEN C_POST_ISPUBLIC_YES
              RETURN %"Post published."
            WHEN C_POST_ISPUBLIC_VERIFIEDBYSALFATIX
              RETURN %"Post published."
            OTHERWISE
              RETURN %"Post validated."
          END CASE
      END CASE
  END CASE
  RETURN NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignpostlist_ui_set_action_state_mobile(p_dialog)
  DEFINE
    p_dialog ui.DIALOG,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lbool_allow_addpost BOOLEAN,
    lbool_allow_editpost BOOLEAN

  LET lbool_allow_addpost = FALSE
  LET lbool_allow_editpost = TRUE

  CALL core_db.campaigns_select_row(mint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret == 0 THEN
    IF lrec_campaign.cmp_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
      LET lbool_allow_addpost = TRUE
    END IF
  END IF
  CALL p_dialog.setActionActive("editpost", (marec_campaignpost_mobile.getLength()>0) AND lbool_allow_editpost)
  CALL p_dialog.setActionActive("addpost", lbool_allow_addpost)
  CALL p_dialog.setActionHidden("addpost", NOT lbool_allow_addpost)
END FUNCTION

#+ Fetch and display user social network
#+
#+ @param pint_usrscl_id user social network
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION campaignpostgrid_open_form_by_key_mobile(pint_campaignpost_id LIKE campaignposts.cmppost_id, pint_state SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT

  LET mint_campaignpost_id = pint_campaignpost_id
  LET lint_action = C_APPACTION_UNDEFINED
  CASE pint_state
    WHEN C_APPSTATE_ADD
      CALL campaignpostgrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL campaignpostgrid_update(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_DISPLAY
      CALL campaignpostgrid_display() RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  RETURN lint_ret, lint_action, mint_campaignpost_id
END FUNCTION

#+ Display a user social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpostgrid_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT

  LET lint_action = C_APPACTION_CANCEL
  CALL fgl_settitle(%"Post")
  --initialize the add/update record data
  CALL campaignpostgrid_initialize_data_mobile(mint_campaignpost_id, C_DIALOGSTATE_DISPLAY)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  OPEN WINDOW w_campaignpostgrid_display_mobile WITH FORM "campaignposts_grid_mobile"
  MENU ""
    ON ACTION cancel
      EXIT MENU
    BEFORE MENU
      CALL campaignpost_combobox_initializer_mobile()
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignposts.cmppost_ispublic","hidden","1")
      DISPLAY mrec_campaignpost_mobile.* TO scr_campaignpost_grid.*
  END MENU
  CLOSE WINDOW w_campaignpostgrid_display_mobile
  RETURN lint_ret, lint_action
END FUNCTION

#+ Create a user social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpostgrid_create(pint_state SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL campaignpostgrid_input_mobile(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a user social network
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpostgrid_update(pint_state SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT
  CALL campaignpostgrid_input_mobile(C_DIALOGSTATE_UPDATE)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the user input
#+
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION campaignpostgrid_input_mobile(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    lstr_filename STRING

  LET lint_action = C_APPACTION_CANCEL
  LET ff_formtitle = IIF(pint_dialog_state==C_DIALOGSTATE_ADD, %"Add post",%"Edit post")

  --initialize the add/update record data
  LET m_dialogtouched = FALSE
  CALL campaignpostgrid_initialize_data_mobile(mint_campaignpost_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  OPEN WINDOW w_campaignpostgrid_input_mobile WITH FORM "campaignposts_grid_mobile"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaignpost_mobile.* FROM scr_campaignpost_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL campaignpost_combobox_initializer_mobile()
    END INPUT
    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL campaignpostgrid_ui_set_action_state_mobile(DIALOG, pint_dialog_state, m_dialogtouched)
    ON ACTION upload_media
      CASE
        WHEN mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id == C_POSTTYPE_INSTAGRAM_PUBLICATION
          CALL upload_media("choosePhoto")
            RETURNING lint_ret, lstr_filename
        WHEN mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id == C_POSTTYPE_INSTAGRAM_INSTASTORY
          CALL upload_media("choosePhoto")
            RETURNING lint_ret, lstr_filename
        WHEN mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id == C_POSTTYPE_YOUTUBE
          CALL upload_media("chooseVideo")
            RETURNING lint_ret, lstr_filename
        OTHERWISE
          MESSAGE %"Please select a post type first"
          CONTINUE DIALOG
      END CASE
      IF lint_ret == 0 THEN
        IF pint_dialog_state == C_DIALOGSTATE_ADD THEN --erase previous uploaded file
          CALL _delete_file_on_disk(mrec_campaignpost_mobile.campaignpost.cmppost_filename)
        ELSE --update
          --delete file in case the file has been changed more than once
          IF mrec_db_campaignpost_mobile.cmppost_filename <> mrec_campaignpost_mobile.campaignpost.cmppost_filename THEN
            CALL _delete_file_on_disk(mrec_campaignpost_mobile.campaignpost.cmppost_filename)
          END IF
        END IF
        LET mrec_campaignpost_mobile.campaignpost.cmppost_filename = lstr_filename
        LET mrec_campaignpost_mobile.pic_value = campaignposts_commons.campaignpost_load_image(mrec_campaignpost_mobile.campaignpost.cmppost_filename, mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id)
        LET m_dialogtouched = TRUE
        CALL campaignpostgrid_ui_set_action_state_mobile(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF
    ON ACTION save_mobile
      CALL campaignpostgrid_process_data_mobile(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaignpost_id = mrec_campaignpost_mobile.campaignpost.cmppost_id
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION cancel
      CALL campaignpostgrid_process_data_mobile(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaignpost_id = mrec_campaignpost_mobile.campaignpost.cmppost_id
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL campaignpostgrid_ui_set_action_state_mobile(DIALOG, pint_dialog_state, m_dialogtouched)
  END DIALOG
  CLOSE WINDOW w_campaignpostgrid_input_mobile
  RETURN lint_ret, lint_action
END FUNCTION

#+ Initializer of the campaign brand combobox
#+
FUNCTION campaignpost_combobox_initializer_mobile()
  DEFINE
    p_combo ui.ComboBox,
    lstr_sql STRING,
    lrec_posttype RECORD LIKE posttypes.*
  TRY
    LET p_combo = ui.ComboBox.forName("campaignposts.cmppost_posttype_id")
  CATCH
    RETURN
  END TRY
  IF p_combo IS NOT NULL THEN
    CALL p_combo.clear()
    LET lstr_sql = "SELECT posttypes.*"
     ," FROM posttypes, campaignposttypes"
     ," WHERE posttypes.pstt_id = campaignposttypes.cmppst_posttype_id"
     ,SFMT(" AND campaignposttypes.cmppst_campaign_id = %1", mint_campaign_id)
     ," ORDER BY posttypes.pstt_uiorder ASC"
    TRY
      DECLARE c_campaignpost_combobox_initializer_mobile CURSOR FROM lstr_sql
      FOREACH c_campaignpost_combobox_initializer_mobile
        INTO lrec_posttype.*
        CALL p_combo.addItem(lrec_posttype.pstt_id, LSTR(lrec_posttype.pstt_name))
      END FOREACH
      FREE c_campaignpost_combobox_initializer_mobile
    CATCH
      CALL p_combo.clear()
      RETURN
    END TRY
  END IF
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION campaignpostgrid_ui_set_action_state_mobile(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT,
    lbool_allow_ispublic BOOLEAN

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("dialogtouched", TRUE)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save_mobile", pbool_dialog_touched)
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignposts.cmppost_ispublic","noEntry","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignposts.cmppost_url","hidden","1")

    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("dialogtouched", TRUE)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save_mobile", pbool_dialog_touched)
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignposts.cmppost_posttype_id","noEntry","1")
      LET lbool_allow_ispublic = IIF(mrec_campaignpost_mobile.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX, FALSE, TRUE)
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignposts.cmppost_ispublic","noEntry",NOT lbool_allow_ispublic)
  END CASE

END FUNCTION

#+ Initializes the user social network business record
#+
#+ @param pint_usrscl_id user social network id
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER
#+ @return     0|error
FUNCTION campaignpostgrid_initialize_data_mobile(pint_campaignpost_id LIKE campaignposts.cmppost_id, pint_dialog_state SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  INITIALIZE mrec_campaignpost_mobile.* TO NULL
  INITIALIZE mrec_db_campaignpost_mobile.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_campaignpost_mobile.campaignpost.cmppost_id = 0
      LET mrec_campaignpost_mobile.campaignpost.cmppost_campaign_id = mint_campaign_id
      LET mrec_campaignpost_mobile.campaignpost.cmppost_usr_id = mint_usr_id
      LET mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id = _get_post_type(mint_campaign_id)
      LET mrec_campaignpost_mobile.campaignpost.cmppost_status_id =  C_CAMPAIGNPOSTSTATUS_INFL_CREATED
      LET mrec_campaignpost_mobile.campaignpost.cmppost_ispublic = C_POST_ISPUBLIC_NO
      CALL _get_default_add_photo()
        RETURNING lint_ret, lstr_msg, mrec_campaignpost_mobile.pic_value
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    WHEN C_DIALOGSTATE_UPDATE
      CALL campaignpostgrid_get_data_by_key_mobile(pint_campaignpost_id)
        RETURNING lint_ret, lstr_msg, mrec_campaignpost_mobile.*, mrec_db_campaignpost_mobile.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    WHEN C_DIALOGSTATE_DISPLAY
      CALL campaignpostgrid_get_data_by_key_mobile(pint_campaignpost_id)
        RETURNING lint_ret, lstr_msg, mrec_campaignpost_mobile.*, mrec_db_campaignpost_mobile.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Returns the default add photo picture in case the given parameter is NULL
#+
#+ @returnType INTEGER, STRING, INTEGER, BYTE
#+ @return     0|error, error message, picture id, picture value
PRIVATE FUNCTION _get_default_add_photo()
  DEFINE
    lrec_pic RECORD LIKE pics.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.pics_select_row(C_PIC_DEFAULTADDPHOTO, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  RETURN lint_ret, lstr_msg, lrec_pic.pic_value
END FUNCTION


#+ Get the data for the record type t_usersocialnetworkgrid
#+
#+ @param pint_usrscl_id user social network id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_usersocialnetworkgrid business record, usersocialnetwork database record
FUNCTION campaignpostgrid_get_data_by_key_mobile(pint_campaignpost_id LIKE campaignposts.cmppost_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE campaignposts.*,
    lrec_ui_campaignpost t_campaignpostgrid_mobile,
    lrec_db_data RECORD LIKE campaignposts.*

  INITIALIZE lrec_ui_campaignpost.* TO NULL

  CALL core_db.campaignposts_select_row(pint_campaignpost_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_data.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaignpost.*, lrec_db_data.*
  END IF
  LET lrec_ui_campaignpost.campaignpost.* = lrec_data.*
  LET lrec_db_data.* = lrec_data.*
  IF lrec_data.cmppost_filename IS NOT NULL THEN
    LET lrec_ui_campaignpost.pic_value = campaignposts_commons.campaignpost_load_image(lrec_data.cmppost_filename, lrec_data.cmppost_posttype_id)
  END IF
  LET lrec_ui_campaignpost.status_label = _get_label(lrec_data.cmppost_isacceptedbysalfatix, lrec_data.cmppost_isacceptedbybrand, lrec_data.cmppost_ispublic)

  RETURN lint_ret, lstr_msg, lrec_ui_campaignpost.*, lrec_db_data.*
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
FUNCTION campaignpostgrid_process_data_mobile(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_id LIKE campaignposts.cmppost_id

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
    CALL campaignpost_validate_data_mobile(C_DIALOGSTATE_ADD)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL campaignpost_insert_into_dabatase_mobile()
      RETURNING lint_ret, lstr_msg, lint_id
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_campaignpost_mobile.campaignpost.cmppost_id = lint_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_update_data THEN
    CALL campaignpost_validate_data_mobile(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL campaignpost_update_into_dabatase_mobile()
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_restore_data THEN
    CALL campaignpostgrid_initialize_data_mobile(mrec_campaignpost_mobile.campaignpost.cmppost_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL campaignpostgrid_ui_set_action_state_mobile(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_campaignpost_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL campaignpostgrid_initialize_data_mobile(mrec_campaignpost_mobile.campaignpost.cmppost_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL campaignpostgrid_ui_set_action_state_mobile(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_campaignpost_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a user social network into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, user social network id
FUNCTION campaignpost_insert_into_dabatase_mobile()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_campaignpost.cmppost_id
  END IF
  INITIALIZE lrec_campaignpost.* TO NULL
  LET lrec_campaignpost.* = mrec_campaignpost_mobile.campaignpost.*
  LET lrec_campaignpost.cmppost_creationdate = CURRENT
  CALL core_db.campaignposts_insert_row(lrec_campaignpost.*)
    RETURNING lint_ret, lstr_msg, lrec_campaignpost.cmppost_id
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_campaignpost.cmppost_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_campaignpost.cmppost_id
END FUNCTION

#+ Update a user social network into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpost_update_into_dabatase_mobile()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*,
    lint_status INTEGER,
    l_timestamp LIKE campaignposts.cmppost_onlinedate

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET l_timestamp = CURRENT
  INITIALIZE lrec_campaignpost.* TO NULL
  LET lrec_campaignpost.* = mrec_campaignpost_mobile.campaignpost.*
  --in case the post URL has been set or changed, then update the post online date
  IF lrec_campaignpost.cmppost_url IS NOT NULL THEN
    IF (mrec_db_campaignpost_mobile.cmppost_url IS NULL) --post URL has been set
      OR (mrec_db_campaignpost_mobile.cmppost_url IS NOT NULL
        AND mrec_db_campaignpost_mobile.cmppost_url <> lrec_campaignpost.cmppost_url) --post URL has changed
    THEN
      LET lrec_campaignpost.cmppost_onlinedate = l_timestamp
    END IF
  END IF
  CALL core_db.campaignposts_update_row(mrec_db_campaignpost_mobile.*, lrec_campaignpost.*, l_timestamp)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    IF mrec_db_campaignpost_mobile.cmppost_filename <> lrec_campaignpost.cmppost_filename THEN 
      CALL _delete_file_on_disk(mrec_db_campaignpost_mobile.cmppost_filename)
    END IF
  END IF
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
FUNCTION campaignpost_delete_from_dabatase_mobile(pint_campaignpost_id LIKE campaignposts.cmppost_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    lrec_campaignpost RECORD LIKE campaignposts.*

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.campaignposts_select_row(pint_campaignpost_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignpost.*
  IF lint_ret == 0 THEN
    CALL _delete_file_on_disk(lrec_campaignpost.cmppost_filename)
    CALL core_db.campaignposts_delete_row(pint_campaignpost_id)
      RETURNING lint_ret, lstr_msg
  END IF
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
FUNCTION campaignpost_validate_data_mobile(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_campaignpost_mobile.campaignpost.cmppost_id IS NULL OR mrec_campaignpost_mobile.campaignpost.cmppost_id==0 THEN
      RETURN -1, %"Id missing"
    END IF
  END IF
  IF mrec_campaignpost_mobile.campaignpost.cmppost_campaign_id IS NULL OR mrec_campaignpost_mobile.campaignpost.cmppost_campaign_id==0 THEN
    RETURN -1, %"Campaign missing"
  END IF
  IF mrec_campaignpost_mobile.campaignpost.cmppost_usr_id IS NULL OR mrec_campaignpost_mobile.campaignpost.cmppost_usr_id==0 THEN
    RETURN -1, %"User missing"
  END IF
  IF mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id IS NULL OR mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id==0 THEN
    RETURN -1, %"Post Type missing"
  END IF
  IF mrec_campaignpost_mobile.campaignpost.cmppost_ispublic IS NOT NULL THEN
    IF mrec_campaignpost_mobile.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_YES
      AND mrec_campaignpost_mobile.campaignpost.cmppost_url IS NULL
    THEN
      RETURN -1, %"Url of the post is missing"
    END IF
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Get the first social network that is not already created
#+
#+ @param pint_user_id user id
#+
#+ @returnType INTEGER
#+ @return     social network id
FUNCTION _get_post_type(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_id LIKE posttypes.pstt_id

  LET lstr_sql = "SELECT posttypes.pstt_id"
   ," FROM posttypes, campaignposttypes"
   ," WHERE posttypes.pstt_id = campaignposttypes.cmppst_posttype_id"
   ,SFMT(" AND campaignposttypes.cmppst_campaign_id = %1", pint_campaign_id)
   ," ORDER BY posttypes.pstt_uiorder ASC"
  LET lint_id = 0
  TRY
    DECLARE c__get_post_type CURSOR FROM lstr_sql
    FOREACH c__get_post_type
      INTO lint_id
      EXIT FOREACH
    END FOREACH
    FREE c__get_post_type
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_id
END FUNCTION

#+ Upload an image/photo on the client side
#+ The given BYTE is only changed when the user uploads an image
#+
#+ @param p_image BYTE image
#+
#+ @returnType BYTE
#+ @return     image/photo binary, NULL in case of cancel
FUNCTION upload_media(method STRING)
  DEFINE
    lint_ret INTEGER,
    lstr_client_filename STRING,
    lstr_server_filename STRING,
    lstr_server_filepath STRING

  TRY
    CALL ui.interface.frontcall("mobile",method,[],[lstr_client_filename])
  CATCH
  END TRY
  IF lstr_client_filename.getLength() = 0 THEN --user cancels the directory selection
    RETURN -1, NULL
  END IF
  LET lstr_server_filename = _build_uniq_filename(lstr_client_filename)
  LET lstr_server_filepath = campaignposts_commons.campaignpost_build_filepath(lstr_server_filename)
  TRY
    CALL FGL_GETFILE(lstr_client_filename,lstr_server_filepath)
  CATCH
    LET lint_ret = STATUS
  END TRY
  RETURN lint_ret, lstr_server_filename

END FUNCTION

PRIVATE FUNCTION _build_uniq_filename(pstr_uiclient_filename STRING)
  DEFINE
    lstr_filename STRING,
    lstr_fileextension STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_posttype RECORD LIKE posttypes.*
  CALL core_db.posttype_select_row(mrec_campaignpost_mobile.campaignpost.cmppost_posttype_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_posttype.*
  IF lrec_posttype.pstt_name IS NULL THEN
    LET lrec_posttype.pstt_name = "media_upload"
  END IF
  LET lstr_fileextension = pstr_uiclient_filename.subString(pstr_uiclient_filename.getIndexOf("&ext=",1)+5,pstr_uiclient_filename.getLength())
  LET lstr_fileextension = lstr_fileextension.toLowerCase()
  LET lstr_filename = SFMT("%1_%2_%3_%4.%5", lrec_posttype.pstt_name, mint_campaign_id, mint_usr_id, util.Datetime.format(CURRENT, "%Y%m%d%H%M%S%F")
    , lstr_fileextension)
  RETURN lstr_filename
END FUNCTION

PRIVATE FUNCTION _delete_file_on_disk(p_filename STRING)
  DEFINE
    lstr_filepath STRING
  IF p_filename IS NOT NULL THEN
    LET lstr_filepath = campaignposts_commons.campaignpost_build_filepath(p_filename)
    IF os.Path.exists(lstr_filepath) THEN
      IF os.Path.delete(lstr_filepath) THEN END IF
    END IF
  END IF
END FUNCTION
