IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL users
IMPORT FGL layout
IMPORT FGL campaignposts
IMPORT FGL campaignprices
IMPORT FGL notifications
IMPORT os
IMPORT xml

SCHEMA salfatixmedia

TYPE
  t_selectableqbeinput RECORD
    sortby STRING,
    orderby STRING
  END RECORD,
  t_selectableuserlist RECORD
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    user_phonenumber STRING,
    nb_followers STRING,
    usrmtc_reach STRING,
    selectimage STRING,
    viewimage STRING,
    delimage STRING
  END RECORD
TYPE
  t_campaignuserlist RECORD
    campaignuser RECORD LIKE campaignuserlist.*,
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    user_phonenumber STRING,
    nb_followers STRING,
    delimage STRING,
    viewimage STRING,
    editimage STRING,
    imganswer STRING,
    acceptedbysalfatiximage STRING,
    acceptedbybrandimage STRING,
    usrmtc_reach LIKE usermetrics.usrmtc_reach,
    usrmtc_followers_count LIKE usermetrics.usrmtc_followers_count,
    usr_countryname LIKE countries.cntr_name,
    usr_statename LIKE states.stt_name,
    usr_cityname LIKE cities.cts_name
  END RECORD
TYPE
  t_campaignusergrid RECORD
    campaignuser RECORD LIKE campaignuserlist.*,
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture
  END RECORD

DEFINE --list qbe data
  mrec_selectableqbeinput t_selectableqbeinput
DEFINE --list data
  marec_selectableuserlist DYNAMIC ARRAY OF t_selectableuserlist,
  marec_campaignuserlist DYNAMIC ARRAY OF t_campaignuserlist
DEFINE --grid data
  mrec_campaignusergrid t_campaignusergrid,
  mrec_db_campaignuser RECORD LIKE campaignuserlist.*
DEFINE
  mrec_campaign RECORD LIKE campaigns.*,
  mrec_db_campaign RECORD LIKE campaigns.*,
  mrec_init_campaign RECORD LIKE campaigns.*

#+ Fetch and display the list of influencers
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION
FUNCTION campaignpublication_open_form_by_key(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT

  IF setup.g_app_brand THEN
    CALL campaignpublicationforbrand_open_form_by_key(pint_campaign_id)
      RETURNING lint_ret, lstr_msg, lint_action
  ELSE
    CALL campaignpublicationforbackoffice_open_form_by_key(pint_campaign_id)
      RETURNING lint_ret, lstr_msg, lint_action
  END IF
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Fetch and display the list of influencers
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION
FUNCTION campaignpublicationforbackoffice_open_form_by_key(pint_campaign_id)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lstr_sql_from_clause STRING,
    lstr_sql_where_clause STRING,
    lstr_sql_orderby_clause STRING,
    lstr_sql_where STRING,
    i,j INTEGER,
    lint_action_tmp SMALLINT,
    lint_user_id LIKE users.usr_id,
    lbool_dialogtouched BOOLEAN

  LET lint_action = C_APPACTION_CANCEL

  --get campaign data
  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, mrec_campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  LET mrec_db_campaign.* = mrec_campaign.*
  LET mrec_init_campaign.* = mrec_campaign.*
  --get selected users for the current campaign
  CALL campaignpublication_get_data(pint_campaign_id, marec_campaignuserlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  --get selectable users for the current campaign
  CALL campaignpublication_get_selectable_user_list(pint_campaign_id, NULL, NULL, "users.usr_instagram_username asc", marec_selectableuserlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  --set the search filters
  LET mrec_selectableqbeinput.sortby = "users.usr_instagram_username"
  LET mrec_selectableqbeinput.orderby = "asc"

  OPEN WINDOW w_campaignpublication WITH FORM "campaignpublications"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaign.* FROM scr_campaign.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        LET lbool_dialogtouched = FALSE
        CALL DIALOG.setActionActive("dialogtouched", NOT lbool_dialogtouched)
        CALL DIALOG.setActionActive("save", lbool_dialogtouched)
      ON ACTION dialogtouched
        LET lbool_dialogtouched = TRUE
        CALL DIALOG.setActionActive("dialogtouched", NOT lbool_dialogtouched)
        CALL DIALOG.setActionActive("save", lbool_dialogtouched)
      ON ACTION save
        CALL campaignpublication_process_campaign_data(DIALOG, lbool_dialogtouched, C_APPACTION_ACCEPT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE DIALOG
        END IF
        LET lbool_dialogtouched = FALSE
        CALL DIALOG.setActionActive("dialogtouched", NOT lbool_dialogtouched)
        CALL DIALOG.setActionActive("save", lbool_dialogtouched)
      AFTER INPUT --autosave when leaving the dialog
        CALL campaignpublication_process_campaign_data(DIALOG, lbool_dialogtouched, C_APPACTION_AUTOACCEPT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          NEXT FIELD CURRENT
        END IF
        LET lbool_dialogtouched = FALSE
        CALL DIALOG.setActionActive("dialogtouched", NOT lbool_dialogtouched)
        CALL DIALOG.setActionActive("save", lbool_dialogtouched)
    END INPUT
    DISPLAY ARRAY marec_campaignuserlist TO scr_selected_list.*
      BEFORE DISPLAY
      BEFORE ROW
        LET i = DIALOG.getCurrentRow("scr_selected_list")
        CALL campaignpublication_ui_set_action_state_by_influencer(DIALOG, i)
      ON ACTION viewinfluencer
        LET i = DIALOG.getCurrentRow("scr_selected_list")
        IF i > 0 THEN
          CALL users.usergrid_open_form_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_user_id, C_APPSTATE_DISPLAY, NULL)
            RETURNING lint_ret, lint_action_tmp, lint_user_id
        END IF
      ON ACTION editinfluencerselection
        LET i = DIALOG.getCurrentRow("scr_selected_list")
        IF i > 0 THEN
          CALL campaignusergrid_input(C_DIALOGSTATE_UPDATE, marec_campaignuserlist[i].campaignuser.cmpusrl_user_id)
            RETURNING lint_ret, lint_action_tmp
          IF lint_ret == 0 THEN
            IF lint_action_tmp == C_APPACTION_ACCEPT THEN
              CALL campaignpublication_get_data_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_id, marec_campaignuserlist, i)
                RETURNING lint_ret, lstr_msg
              CALL campaignpublication_ui_set_action_state_by_influencer(DIALOG, i)
            END IF
          END IF
        END IF
      ON ACTION delete --delete from database
        LET i = DIALOG.getCurrentRow("scr_selected_list")
        IF i > 0 THEN
          IF NOT campaignpublication_allow_influencer_delete(marec_campaignuserlist[i].*) THEN
            CONTINUE DIALOG
          END IF
          IF core_ui.ui_message(%"Question",%"Remove this influencer from this campaign?","no","yes|no","fa-question") == "yes" THEN
            CALL campaignpublication_delete_user_from_dabatase(marec_campaignuserlist[i].campaignuser.cmpusrl_id)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              CALL marec_campaignuserlist.deleteElement(i)
              IF (i==0) OR (i > marec_campaignuserlist.getLength()) THEN LET i = marec_campaignuserlist.getLength() END IF
              CALL campaignpublication_ui_set_action_state_by_influencer(DIALOG, i)
            END IF
          END IF
        END IF
      ON ACTION viewsocialnetwork
        LET i = DIALOG.getCurrentRow("scr_selected_list")
        IF i > 0 THEN
          CALL layout.open_socialnetwork_account(C_SOCIALNETWORK_INSTAGRAM, marec_campaignuserlist[i].user.usr_instagram_username)
        END IF
    END DISPLAY
    INPUT mrec_selectableqbeinput.* FROM scr_qbeinput.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    CONSTRUCT lstr_sql_where
      ON
        users.usr_firstname,
        users.usr_lastname,
        users.usr_email,
        users.usr_instagram_username,
        usermetrics.usrmtc_followers_count,
        usermetrics.usrmtc_reach
      FROM scr_qbeconstruct.*
      BEFORE CONSTRUCT
    END CONSTRUCT
    DISPLAY ARRAY marec_selectableuserlist TO scr_influencer_list.*
      BEFORE DISPLAY
      ON ACTION viewinfluencer
        LET i = DIALOG.getCurrentRow("scr_influencer_list")
        IF i > 0 THEN
          CALL users.usergrid_open_form_by_key(marec_selectableuserlist[i].user.usr_id, C_APPSTATE_DISPLAY, NULL)
            RETURNING lint_ret, lint_action_tmp, lint_user_id
        END IF
      ON ACTION selectinfluencer
        LET i = DIALOG.getCurrentRow("scr_influencer_list")
        IF i > 0 THEN
          CALL campaignusergrid_input(C_DIALOGSTATE_ADD, marec_selectableuserlist[i].user.usr_id)
            RETURNING lint_ret, lint_action_tmp
          IF lint_ret == 0 THEN
            IF lint_action_tmp == C_APPACTION_ACCEPT THEN
              LET j = marec_campaignuserlist.getLength() + 1
              CALL campaignpublication_get_data_by_key(mrec_campaignusergrid.campaignuser.cmpusrl_id, marec_campaignuserlist, j)
                RETURNING lint_ret, lstr_msg
              IF lint_ret == 0 THEN
                CALL marec_selectableuserlist.deleteElement(i)
              END IF
              CALL campaignpublication_ui_set_action_state(DIALOG)
            END IF
          END IF
        END IF
      ON ACTION delete --to hide the action. User should refetch to view influencer again
        LET i = DIALOG.getCurrentRow("scr_influencer_list")
        IF i > 0 THEN
          CALL marec_selectableuserlist.deleteElement(i)
          CALL campaignpublication_ui_set_action_state(DIALOG)
        END IF
      ON ACTION viewsocialnetwork
        LET i = DIALOG.getCurrentRow("scr_influencer_list")
        IF i > 0 THEN
          CALL layout.open_socialnetwork_account(C_SOCIALNETWORK_INSTAGRAM, marec_selectableuserlist[i].user.usr_instagram_username)
        END IF
    END DISPLAY
    ON ACTION validatedbysalfatix
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        IF NOT campaignpublication_allow_salfatix_validation(marec_campaignuserlist[i].*) THEN
          CONTINUE DIALOG
        END IF
        --call update
        CALL campaignpublication_salfatix_validation(marec_campaignuserlist[i].campaignuser.*)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        CALL campaignpublication_get_data_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_id, marec_campaignuserlist, i)
          RETURNING lint_ret, lstr_msg
        CALL campaignpublication_ui_set_action_state(DIALOG)
      END IF
    ON ACTION rejectedbysalfatix
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        IF NOT campaignpublication_allow_salfatix_rejection(marec_campaignuserlist[i].*) THEN
          CONTINUE DIALOG
        END IF
        --call update
        CALL campaignpublication_salfatix_rejection(marec_campaignuserlist[i].campaignuser.*)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        CALL campaignpublication_get_data_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_id, marec_campaignuserlist, i)
          RETURNING lint_ret, lstr_msg
        CALL campaignpublication_ui_set_action_state(DIALOG)
      END IF
    ON ACTION manageposts
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        IF NOT campaignpublication_allow_manage_post(marec_campaignuserlist[i].*) THEN
          CONTINUE DIALOG
        END IF
        CALL campaignposts.campaignpostlist_open_form_by_key(pint_campaign_id, marec_campaignuserlist[i].campaignuser.cmpusrl_user_id)
          RETURNING lint_ret, lstr_msg, lint_action
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        CASE lint_action
          WHEN C_APPACTION_CANCEL --stay in dialog
            CALL campaignpublication_ui_set_action_state_by_influencer(DIALOG, i)
          OTHERWISE --custom action
            EXIT DIALOG
        END CASE
      END IF
    ON ACTION exportlist
      CALL campaignpublication_export_list(pint_campaign_id)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
    ON ACTION refreshselected
      CALL campaignpublication_get_data(pint_campaign_id, marec_campaignuserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignpublication_get_selectable_user_list(pint_campaign_id, lstr_sql_from_clause, lstr_sql_where_clause,lstr_sql_orderby_clause, marec_selectableuserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignpublication_ui_set_action_state(DIALOG)
    ON ACTION refreshselectable
      CALL campaignpublication_get_data(pint_campaign_id, marec_campaignuserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignpublication_get_selectable_user_list(pint_campaign_id, lstr_sql_from_clause, lstr_sql_where_clause, lstr_sql_orderby_clause, marec_selectableuserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignpublication_ui_set_action_state(DIALOG)
    ON ACTION selectallselectable
      IF DIALOG.getArrayLength("scr_influencer_list") > 0 THEN
        CALL campaignusergrid_input(C_DIALOGSTATE_ADD, 0)
          RETURNING lint_ret, lint_action_tmp
        IF lint_ret == 0 THEN
          IF lint_action_tmp == C_APPACTION_ACCEPT THEN
            CALL campaignpublication_get_data(pint_campaign_id, marec_campaignuserlist)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
              CONTINUE DIALOG
            END IF
            CALL campaignpublication_get_selectable_user_list(pint_campaign_id, lstr_sql_from_clause, lstr_sql_where_clause, lstr_sql_orderby_clause, marec_selectableuserlist)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
              CONTINUE DIALOG
            END IF
            CALL campaignpublication_ui_set_action_state(DIALOG)
          END IF
        END IF
      END IF
    ON ACTION clearselected
      IF DIALOG.getArrayLength("scr_selected_list") > 0 THEN
        IF core_ui.ui_message(%"Question",%"Remove all influencers who did not answer to this campaign?","no","yes|no","fa-question") == "yes" THEN
          FOR i = 1 TO marec_campaignuserlist.getLength()
            IF marec_campaignuserlist[i].campaignuser.cmpusrl_isacceptbyuser IS NULL THEN
              CALL campaignpublication_delete_user_from_dabatase(marec_campaignuserlist[i].campaignuser.cmpusrl_id)
                RETURNING lint_ret, lstr_msg
              IF lint_ret == 0 THEN
                CALL marec_campaignuserlist.deleteElement(i)
                LET i = i - 1
              END IF
            END IF
          END FOR
          CALL campaignpublication_ui_set_action_state(DIALOG)
        END IF
      END IF
    ON ACTION publish
      IF core_ui.ui_message(%"Question",%"Publish the campaign?","no","yes|no","fa-question") == "yes" THEN
        CALL campaignpublication_process_campaign_data(DIALOG, TRUE, C_APPACTION_CAMPAIGN_PUBLISH)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        LET lint_ret = 0
        LET lint_action = C_APPACTION_ACCEPT
        EXIT DIALOG
      END IF
    ON ACTION validateallbysalfatix
      IF DIALOG.getArrayLength("scr_selected_list") > 0 THEN
        IF core_ui.ui_message(%"Question",%"Propose all applied influencers to the brand?","no","yes|no","fa-question") == "yes" THEN
          FOR i = 1 TO marec_campaignuserlist.getLength()
            IF NOT campaignpublication_allow_salfatix_validation(marec_campaignuserlist[i].*) THEN
              CONTINUE FOR
            END IF
            --call update
            CALL campaignpublication_salfatix_validation(marec_campaignuserlist[i].campaignuser.*)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
              EXIT FOR
            END IF
            CALL campaignpublication_get_data_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_id, marec_campaignuserlist, i)
              RETURNING lint_ret, lstr_msg
          END FOR
          CALL campaignpublication_ui_set_action_state(DIALOG)
        END IF
      END IF
    ON ACTION filter
      IF lstr_sql_where.getLength() == 0 THEN
       LET lstr_sql_where = " 1=1"
      END IF
      LET lstr_sql_from_clause = " users"
      LET lstr_sql_where_clause = lstr_sql_where
      IF lstr_sql_where.getIndexOf("usermetrics.", 1) > 0
        OR mrec_selectableqbeinput.sortby == "usermetrics.usrmtc_followers_count"
        OR mrec_selectableqbeinput.sortby == "usermetrics.usrmtc_reach"
      THEN
        LET lstr_sql_from_clause = SFMT("%1, usermetrics", lstr_sql_from_clause)
        LET lstr_sql_where_clause = lstr_sql_where_clause
          ," AND users.usr_id = usermetrics.usrmtc_usr_id"
          ," AND CURRENT BETWEEN usermetrics.usrmtc_bdate AND usermetrics.usrmtc_edate"
      END IF
      LET lstr_sql_orderby_clause = SFMT("%1 %2",mrec_selectableqbeinput.sortby, mrec_selectableqbeinput.orderby)

      --refresh list
      CALL campaignpublication_get_selectable_user_list(pint_campaign_id, lstr_sql_from_clause, lstr_sql_where_clause,lstr_sql_orderby_clause, marec_selectableuserlist)
        RETURNING lint_ret, lstr_msg
      CALL campaignpublication_ui_set_action_state(DIALOG)
    ON ACTION viewprice
      CALL campaignprices.campaignpricegrid_open_form_by_key(pint_campaign_id, C_DIALOGSTATE_DISPLAY)
        RETURNING lint_ret, lint_action
      LET lint_ret = 0
    ON ACTION backtocampaign
      LET lint_ret = 0
      --in case the campaign has been updated (ex: the dates) and then we click on "back to campaign"
      LET lint_action = IIF(mrec_init_campaign.* <> mrec_campaign.*, C_APPACTION_ACCEPT, C_APPACTION_CANCEL)
      EXIT DIALOG
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DIALOG
    BEFORE DIALOG
      CALL campaignpublication_ui_set_action_state(DIALOG)
  END DIALOG
  CLOSE WINDOW w_campaignpublication
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Get the selectable influencer list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of selectable influencer t_brandlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_get_selectable_user_list(pint_campaign_id, pstr_from, pstr_where, pstr_orderby, parec_selectable_list)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_selectable_list DYNAMIC ARRAY OF t_selectableuserlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data RECORD LIKE users.*,
    i INTEGER,
    lrec_usermetric RECORD LIKE usermetrics.*

  CALL parec_selectable_list.clear()
  IF setup.g_app_brand THEN --security purpose
    RETURN 0, NULL
  END IF
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM users"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  ELSE
    LET pstr_where = "WHERE 1=1"
  END IF
  LET pstr_where = pstr_where, SFMT(" AND users.usr_accountstatus_id = %1",C_ACCOUNTSTATUS_VALIDATED)
  LET pstr_where = pstr_where
    ,SFMT(" AND users.usr_id NOT in (SELECT campaignuserlist.cmpusrl_user_id FROM campaignuserlist WHERE campaignuserlist.cmpusrl_campaign_id = %1)", pint_campaign_id)
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT users.* ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_campaignpublication_selectableuserlist_get_data CURSOR FROM lstr_sql
    FOREACH c_campaignpublication_selectableuserlist_get_data
      INTO lrec_data.*
      LET i = i + 1
      LET parec_selectable_list[i].user.* = lrec_data.*
      LET parec_selectable_list[i].usr_instagram_profilepicture = _get_default_photo(parec_selectable_list[i].user.usr_instagram_profilepicture)
      LET parec_selectable_list[i].user_phonenumber = string.build_phonenumber(parec_selectable_list[i].user.usr_country_id, parec_selectable_list[i].user.usr_mobile_phone)
      CALL core_db.usermetrics_select_current_row_by_userid(parec_selectable_list[i].user.usr_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_usermetric.*
      IF lint_ret == 0 THEN
        LET parec_selectable_list[i].nb_followers = lrec_usermetric.usrmtc_followers_count
        LET parec_selectable_list[i].usrmtc_reach = lrec_usermetric.usrmtc_reach
      END IF
      LET parec_selectable_list[i].selectimage = "fa-plus"
      LET parec_selectable_list[i].viewimage = "fa-eye"
      LET parec_selectable_list[i].delimage = "fa-eye-slash"
    END FOREACH
    FREE c_campaignpublication_selectableuserlist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
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
FUNCTION campaignpublication_get_data(pint_campaign_id, parec_selected_list)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_selected_list DYNAMIC ARRAY OF t_campaignuserlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data0 RECORD LIKE users.*,
    lrec_data1 RECORD LIKE campaignuserlist.*

  CALL parec_selected_list.clear()
  LET lstr_sql = "SELECT users.*, campaignuserlist.*"
  ," FROM users, campaignuserlist"
  ," WHERE campaignuserlist.cmpusrl_user_id = users.usr_id"
  ,SFMT(" AND campaignuserlist.cmpusrl_campaign_id = %1", pint_campaign_id)
  IF setup.g_app_brand THEN
    LET lstr_sql = lstr_sql," AND campaignuserlist.cmpusrl_isacceptedbysalfatix = 1"
  END IF
  LET lstr_sql = lstr_sql," ORDER BY campaignuserlist.cmpusrl_isacceptbyuser, cmpusrl_isacceptedbysalfatix, cmpusrl_isacceptedbybrand, cmpusrl_uiorder"
  TRY
    DECLARE c_campaignpublication_selecteduserlist_get_data CURSOR FROM lstr_sql
    FOREACH c_campaignpublication_selecteduserlist_get_data
      INTO lrec_data0.*, lrec_data1.*
      CALL _add_to_list(lrec_data0.*, lrec_data1.*, parec_selected_list, parec_selected_list.getLength()+1)
    END FOREACH
    FREE c_campaignpublication_selecteduserlist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the selected user of a campaign publication for a given row
#+
#+ @param pint_user_id influencer id
#+ @param parec_list list of influencers t_userlist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_get_data_by_key(pint_id, parec_list, pint_index)
  DEFINE
    pint_id LIKE campaignuserlist.cmpusrl_id,
    parec_list DYNAMIC ARRAY OF t_campaignuserlist,
    pint_index INTEGER,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data0 RECORD LIKE users.*,
    lrec_data1 RECORD LIKE campaignuserlist.*

  LET lstr_sql = "SELECT users.*, campaignuserlist.*"
  ," FROM users, campaignuserlist"
  ," WHERE campaignuserlist.cmpusrl_user_id = users.usr_id"
  ,SFMT(" AND campaignuserlist.cmpusrl_id = %1", pint_id)
  TRY
    PREPARE p_campaignpublication_selecteduser_by_key FROM lstr_sql
    EXECUTE p_campaignpublication_selecteduser_by_key
      INTO lrec_data0.*, lrec_data1.*
    IF SQLCA.SQLCODE <> 0 THEN
      RETURN SQLCA.SQLCODE, SQLERRMESSAGE
    END IF
    FREE p_campaignpublication_selecteduser_by_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  CALL _add_to_list(lrec_data0.*, lrec_data1.*, parec_list, pint_index)
  RETURN 0, NULL
END FUNCTION

#+ Add an infuencer in the list of selected influencer
#+
#+ @param pint_campaign_id campaign id
#+ @param prec_user influencer record
#+ @param prec_campaignuser selected influencer record
#+ @param parec_list list of influencers
#+ @param pint_index index in the list of influencers
#+
PRIVATE FUNCTION _add_to_list(prec_user RECORD LIKE users.*, prec_campaignuser RECORD LIKE campaignuserlist.*, parec_list DYNAMIC ARRAY OF t_campaignuserlist, pint_index INTEGER)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_usermetrics RECORD LIKE usermetrics.*

  LET parec_list[pint_index].campaignuser.* = prec_campaignuser.*
  LET parec_list[pint_index].user.* = prec_user.*
  LET parec_list[pint_index].usr_instagram_profilepicture = _get_default_photo(parec_list[pint_index].user.usr_instagram_profilepicture)
  LET parec_list[pint_index].user_phonenumber = string.build_phonenumber(parec_list[pint_index].user.usr_country_id, parec_list[pint_index].user.usr_mobile_phone)
  LET parec_list[pint_index].nb_followers = core_db.users_get_nb_followers(parec_list[pint_index].user.usr_id)
  LET parec_list[pint_index].delimage = IIF(campaignpublication_allow_influencer_delete(parec_list[pint_index].*), "delete", NULL)
  LET parec_list[pint_index].viewimage = "fa-eye"
  LET parec_list[pint_index].editimage = "fa-pencil"
  LET parec_list[pint_index].imganswer = _get_image_for_publication(prec_campaignuser.cmpusrl_isacceptbyuser, (prec_campaignuser.cmpusrl_userwantedprice IS NOT NULL))
  LET parec_list[pint_index].acceptedbysalfatiximage = _get_image_for_publication(prec_campaignuser.cmpusrl_isacceptedbysalfatix, FALSE)
  LET parec_list[pint_index].acceptedbybrandimage = _get_image_for_publication(prec_campaignuser.cmpusrl_isacceptedbybrand, FALSE)
  IF campaignpublication_allow_display_influencer_address(parec_list[pint_index].*) THEN
    TRY
      SELECT countries.cntr_name, states.stt_name, cities.cts_name
      INTO parec_list[pint_index].usr_countryname
        ,parec_list[pint_index].usr_statename
        ,parec_list[pint_index].usr_cityname
      FROM users, countries, OUTER states, OUTER cities
      WHERE @users.usr_id = prec_user.usr_id
        AND @users.usr_country_id = countries.cntr_id
        AND @users.usr_state_id = states.stt_id
        AND @users.usr_city_id = cities.cts_id
    CATCH
    END TRY
    CALL core_db.usermetrics_select_current_row_by_userid(prec_user.usr_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_usermetrics.*
    IF lint_ret == 0 THEN
      LET parec_list[pint_index].usrmtc_reach = lrec_usermetrics.usrmtc_reach
      LET parec_list[pint_index].usrmtc_followers_count = lrec_usermetrics.usrmtc_followers_count
    END IF
  ELSE
    INITIALIZE parec_list[pint_index].user.usr_address_number TO NULL
    INITIALIZE parec_list[pint_index].user.usr_address_street TO NULL
    INITIALIZE parec_list[pint_index].user.usr_address_zipcode TO NULL
    INITIALIZE parec_list[pint_index].user.usr_address_town TO NULL
    INITIALIZE parec_list[pint_index].user.usr_address_more TO NULL
  END IF
END FUNCTION

PRIVATE FUNCTION _get_image_for_publication(p_value SMALLINT, p_wantedprice BOOLEAN)
  IF p_value == 0 THEN
    RETURN "fa-times-circle-red"
  END IF
  IF p_value == 1 THEN
    RETURN IIF(p_wantedprice, "fa-exclamation-orange", "fa-check-circle-green")
  END IF
  RETURN "fa-times-circle-grey"
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignpublication_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.DIALOG,
    i INTEGER,
    lbool_allow_publication BOOLEAN,
    lbool_allow_exportlist BOOLEAN

  CALL p_dialog.setActionHidden("customaction", TRUE)

  LET lbool_allow_publication = campaignpublication_allow_publication(mrec_campaign.cmp_campaignstatus_id)
  CALL core_ui.ui_set_node_attribute("FormField","name","formonly.label_publish","hidden", NOT lbool_allow_publication)
  CALL p_dialog.setActionActive("publish", (marec_campaignuserlist.getLength()>0) AND lbool_allow_publication)
  CALL core_ui.ui_set_node_attribute("Button","name","publish","hidden",NOT lbool_allow_publication)
  CALL p_dialog.setActionActive("selectallselectable", (marec_selectableuserlist.getLength()>0))
  CALL p_dialog.setActionActive("clearselected", (marec_campaignuserlist.getLength()>0))
  LET lbool_allow_exportlist = campaignpublication_allow_exportlist()
  CALL p_dialog.setActionActive("exportlist", lbool_allow_exportlist AND (marec_campaignuserlist.getLength()>0))
  CALL p_dialog.setActionHidden("exportlist", NOT (lbool_allow_exportlist AND (marec_campaignuserlist.getLength()>0)))

  CALL _campaignpublication_build_titles(TRUE)

  CALL layout.display_currencysymbol(mrec_campaign.cmp_currency_id,"cur")
  CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_publisheddate","noEntry",(mrec_campaign.cmp_campaignstatus_id <> C_CAMPAIGNSTATUS_VALIDATED))

  LET i = p_dialog.getCurrentRow("scr_selected_list")
  IF (i==0) OR (i > marec_campaignuserlist.getLength()) THEN
    LET i = marec_campaignuserlist.getLength()
  END IF
  CALL campaignpublication_ui_set_action_state_by_influencer(p_dialog, i)

END FUNCTION

#+ Sets the state of the dialog actions to active or inactive for an influencer
#+
#+ @param p_dialog current DIALOG
#+ @param i index of the selected user current DIALOG
#+
FUNCTION campaignpublication_ui_set_action_state_by_influencer(p_dialog ui.Dialog, i INTEGER)
  DEFINE
    lbool_allow_salfatix_validation BOOLEAN,
    lbool_allow_salfatix_rejection BOOLEAN,
    lbool_allow_manage_post BOOLEAN,
    lbool_allow_salfatix_validation_for_all_influencers BOOLEAN

  LET lbool_allow_salfatix_validation = IIF(i>0,campaignpublication_allow_salfatix_validation(marec_campaignuserlist[i].*),FALSE)
  LET lbool_allow_salfatix_rejection = IIF(i>0,campaignpublication_allow_salfatix_rejection(marec_campaignuserlist[i].*),FALSE)
  LET lbool_allow_manage_post = IIF(i>0,campaignpublication_allow_manage_post(marec_campaignuserlist[i].*),FALSE)
  LET lbool_allow_salfatix_validation_for_all_influencers = IIF(i>0,campaignpublication_allow_salfatix_validation_for_all_influencers(), FALSE)

  CALL p_dialog.setActionActive("validatedbysalfatix", lbool_allow_salfatix_validation AND (i>0))
  CALL p_dialog.setActionActive("rejectedbysalfatix", lbool_allow_salfatix_rejection AND (i>0))
  CALL p_dialog.setActionActive("manageposts", lbool_allow_manage_post AND (i>0))
  CALL p_dialog.setActionActive("validateallbysalfatix", lbool_allow_salfatix_validation_for_all_influencers AND (i>0))
END FUNCTION

#+ Delete a selected user of a campaign publication
#+
#+ @param pint_id campaign publication id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_delete_user_from_dabatase(pint_id)
  DEFINE
    pint_id LIKE campaignuserlist.cmpusrl_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.campaignuserlist_delete_row(pint_id)
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

#+ Insert a selected user of a campaign publication
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, campaign user list id
FUNCTION campaignpublication_insert_user_into_dabatase(prec_campaignuserlist)
  DEFINE
    prec_campaignuserlist RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, prec_campaignuserlist.cmpusrl_id
  END IF
  LET prec_campaignuserlist.cmpusrl_id = 0
  CALL core_db.campaignuserlist_insert_row(prec_campaignuserlist.*)
    RETURNING lint_ret, lstr_msg, prec_campaignuserlist.cmpusrl_id
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, prec_campaignuserlist.cmpusrl_id
  END IF

  RETURN lint_ret, lstr_msg, prec_campaignuserlist.cmpusrl_id
END FUNCTION

#+ Update a selected user of a campaign publication
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, campaign user list id
FUNCTION campaignpublication_update_user_into_dabatase(prec_campaignuserlist, prec_campaignuserlist_db)
  DEFINE
    prec_campaignuserlist RECORD LIKE campaignuserlist.*,
    prec_campaignuserlist_db RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.campaignuserlist_update_row(prec_campaignuserlist_db.*, prec_campaignuserlist.*)
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

#+ Process the data of business record fields (CRUD operations or UI operations)
#+
#+ @param p_dialog current DIALOG
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+ @param pint_dialog_action dialog action which triggered the operation
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_process_campaign_data(p_dialog, pbool_dialog_touched, pint_dialog_action)
  DEFINE
    p_dialog ui.Dialog,
    pbool_dialog_touched SMALLINT,
    pint_dialog_action SMALLINT,
    lbool_validate_dates BOOLEAN,
    lbool_publicationdate_has_changed BOOLEAN,
    lbool_subscriptionstartdate_has_changed BOOLEAN,
    lbool_subscriptionenddate_has_changed BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_tmp STRING,
    lint_err STRING,
    i INTEGER,
    lrec_campaignuser RECORD LIKE campaignuserlist.*

  LET lbool_validate_dates = FALSE
  CASE pint_dialog_action
    WHEN C_APPACTION_ACCEPT
      LET lbool_validate_dates = TRUE
    WHEN C_APPACTION_AUTOACCEPT --this is the AFTER INPUT block
      IF pbool_dialog_touched THEN
        LET lbool_validate_dates = TRUE
      END IF
    WHEN C_APPACTION_CAMPAIGN_PUBLISH
      LET lbool_validate_dates = TRUE
    OTHERWISE
  END CASE
  IF lbool_validate_dates THEN
    CALL campaignpublication_validate_campaign_data()
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_publicationdate_has_changed = (mrec_db_campaign.cmp_publisheddate IS NOT NULL AND mrec_campaign.cmp_publisheddate IS NOT NULL AND (mrec_db_campaign.cmp_publisheddate <> mrec_campaign.cmp_publisheddate))
    LET lbool_subscriptionstartdate_has_changed = (mrec_db_campaign.cmp_selectionstartdate IS NOT NULL AND mrec_campaign.cmp_selectionstartdate IS NOT NULL AND (mrec_db_campaign.cmp_selectionstartdate <> mrec_campaign.cmp_selectionstartdate))
    LET lbool_subscriptionenddate_has_changed = (mrec_db_campaign.cmp_selectionenddate IS NOT NULL AND mrec_campaign.cmp_selectionenddate IS NOT NULL AND (mrec_db_campaign.cmp_selectionenddate <> mrec_campaign.cmp_selectionenddate))
    IF pint_dialog_action == C_APPACTION_CAMPAIGN_PUBLISH THEN
      LET mrec_campaign.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_PUBLISHED
    END IF
    CALL campaignpublication_update_campaign_into_dabatase()
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    IF pint_dialog_action <> C_APPACTION_CAMPAIGN_PUBLISH THEN
      CALL p_dialog.setActionActive("dialogtouched", TRUE)
      CALL p_dialog.setActionActive("save", FALSE)
    END IF
    IF (lbool_publicationdate_has_changed OR lbool_subscriptionstartdate_has_changed OR lbool_subscriptionenddate_has_changed)
      AND marec_campaignuserlist.getLength() > 0
    THEN
      IF lbool_publicationdate_has_changed THEN
        LET lstr_tmp = string.concat(lstr_tmp, %"publication date")
      END IF
      IF lbool_subscriptionstartdate_has_changed THEN
        LET lstr_tmp = string.concat(lstr_tmp, %"subscription start date")
      END IF
      IF lbool_subscriptionenddate_has_changed THEN
        LET lstr_tmp = string.concat(lstr_tmp, %"subscription end date")
      END IF
      LET lstr_tmp = SFMT(%"Campaign dates have changed.\nApply campaign %1\nto the selected influencers?", lstr_tmp)
      IF core_ui.ui_message(%"Question",lstr_tmp,"no","yes|no","fa-question") == "yes" THEN
        LET lint_err = 0
        FOR i = 1 TO marec_campaignuserlist.getLength()
          LET lrec_campaignuser.* = marec_campaignuserlist[i].campaignuser.*
          LET lrec_campaignuser.cmpusrl_visibilitydate = mrec_campaign.cmp_publisheddate
          LET lrec_campaignuser.cmpusrl_selectionstartdate = mrec_campaign.cmp_selectionstartdate
          LET lrec_campaignuser.cmpusrl_selectionenddate = mrec_campaign.cmp_selectionenddate
          CALL campaignusergrid_validate_data(lrec_campaignuser.*, C_DIALOGSTATE_UPDATE)
            RETURNING lint_ret, lstr_msg
          IF lint_ret == 0 THEN
            CALL campaignpublication_update_user_into_dabatase(lrec_campaignuser.*, marec_campaignuserlist[i].campaignuser.*)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              --refresh dialog line
              CALL campaignpublication_get_data_by_key(lrec_campaignuser.cmpusrl_id, marec_campaignuserlist, i)
                RETURNING lint_ret, lstr_msg
              IF lint_ret <> 0 THEN
                LET lint_err = -1
              END IF
            ELSE
              LET lint_err = -1
            END IF
          ELSE
            LET lint_err = -1
          END IF
        END FOR
        IF lint_err <> 0 THEN
          RETURN lint_err, %"Some influencers dates were not updated. Please review them."
        END IF
      END IF
    END IF
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Update a campaign publication dates into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_update_campaign_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET l_timestamp = CURRENT
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET mrec_campaign.cmp_lastupdatedate = l_timestamp
  CALL core_db.campaigns_update_row(mrec_db_campaign.*, mrec_campaign.*, l_timestamp)
    RETURNING lint_ret, lstr_msg
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END IF
  LET mrec_db_campaign.* = mrec_campaign.*
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Validate the dates of campaign publication
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_validate_campaign_data()
  IF mrec_campaign.cmp_publisheddate IS NULL THEN
    RETURN -1, %"Publication date must be set"
  END IF
  IF mrec_campaign.cmp_selectionstartdate IS NULL THEN
    RETURN -1, %"Subscription start date must be set"
  END IF
  IF mrec_campaign.cmp_selectionenddate IS NULL THEN
    RETURN -1, %"Subscription end date must be set"
  END IF
  IF mrec_campaign.cmp_campaignstatus_id == C_CAMPAIGNSTATUS_VALIDATED THEN
    IF DATE(mrec_campaign.cmp_publisheddate) < TODAY THEN
      RETURN -1, %"Publication date can not be a past date"
    END IF
  END IF
  IF mrec_campaign.cmp_publisheddate > mrec_campaign.cmp_post_enddate THEN
    RETURN -1, %"Publication date must be prior to the end of the campaign"
  END IF
  IF mrec_campaign.cmp_publisheddate > mrec_campaign.cmp_selectionstartdate THEN
    RETURN -1, %"Publication date must be prior to the subscription start date"
  END IF
  IF mrec_campaign.cmp_selectionstartdate > mrec_campaign.cmp_selectionenddate THEN
    RETURN -1, %"Registration must start before its end"
  END IF
  IF mrec_campaign.cmp_selectionenddate > mrec_campaign.cmp_post_enddate THEN
    RETURN -1, %"End of registration can't be greater than end of campaign date"
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Checks if a campaign can be published
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_publication(pint_campaignstatus_id LIKE campaignstatus.cmpst_id)
  IF setup.g_app_backoffice THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_VALIDATED THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if an influencer can be deleted by salfatix
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_influencer_delete(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_backoffice THEN
    --no answer for brand OR rejected by brand
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand IS NULL
      OR (prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand IS NOT NULL AND prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand==0)
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if there is at least one influencer who can be validated by salfatix
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_salfatix_validation_for_all_influencers()
  DEFINE
    i INTEGER
  IF setup.g_app_backoffice THEN
    FOR i = 1 TO marec_campaignuserlist.getLength()
      IF campaignpublication_allow_salfatix_validation(marec_campaignuserlist[i].*) THEN
        RETURN TRUE
      END IF
    END FOR
  END IF
  RETURN FALSE
END FUNCTION


#+ Checks if an influencer can be validated by salfatix
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_salfatix_validation(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_backoffice THEN
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptbyuser == 1 THEN
      IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbysalfatix IS NULL
        OR prec_selecteduser.campaignuser.cmpusrl_isacceptedbysalfatix==0 THEN --salfatix did not already validate the user
        IF prec_selecteduser.campaignuser.cmpusrl_userwantedprice IS NULL THEN --there is no price negociation with the user
          IF prec_selecteduser.campaignuser.cmpusrl_salfatixtotalprice IS NOT NULL THEN --there is a brand cost set
            RETURN TRUE
          END IF
        END IF
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if an influencer can be rejected by salfatix
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_salfatix_rejection(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_backoffice THEN
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptbyuser == 1 THEN
      IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbysalfatix IS NULL THEN
        RETURN TRUE
      END IF
      IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbysalfatix==1
        AND prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand IS NULL
      THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if an influencer can be validated by brand
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_brand_validation(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_brand THEN
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbysalfatix == 1 THEN
      IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand IS NULL THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if an influencer can be rejected by brand
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_brand_rejection(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_brand THEN
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbysalfatix == 1 THEN
      IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand IS NULL THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if we can manage the posts for the given influencer
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_manage_post(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_brand OR setup.g_app_backoffice THEN
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand == 1 THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if we can display the address of the given influencer
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_display_influencer_address(prec_selecteduser t_campaignuserlist)
  IF setup.g_app_backoffice THEN
    RETURN TRUE
  END IF
  IF setup.g_app_brand THEN
    IF prec_selecteduser.campaignuser.cmpusrl_isacceptedbybrand == 1 THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a salfatix user can export the list of influencers for a campaign
#+
#+ @param pint_campaign_status_id campaign status id
#+ @param pint_proposalstatus_id proposal status id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_allow_exportlist()
  IF setup.g_app_backoffice THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Validate an influencer by salfatix
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_salfatix_validation(prec_selecteduser RECORD LIKE campaignuserlist.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignuser RECORD LIKE campaignuserlist.*
  LET lrec_campaignuser.* = prec_selecteduser.*
  LET lrec_campaignuser.cmpusrl_isacceptedbysalfatix = 1
  INITIALIZE lrec_campaignuser.cmpusrl_isacceptedbybrand TO NULL
  CALL campaignpublication_update_user_into_dabatase(lrec_campaignuser.*, prec_selecteduser.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL notifications.sendmail_brand_check_campaign_proposed_influencers(prec_selecteduser.cmpusrl_campaign_id)
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Reject an influencer by salfatix
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_salfatix_rejection(prec_selecteduser RECORD LIKE campaignuserlist.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignuser RECORD LIKE campaignuserlist.*
  LET lrec_campaignuser.* = prec_selecteduser.*
  LET lrec_campaignuser.cmpusrl_isacceptedbysalfatix = 0
  INITIALIZE lrec_campaignuser.cmpusrl_isacceptedbybrand TO NULL
  CALL campaignpublication_update_user_into_dabatase(lrec_campaignuser.*, prec_selecteduser.*)
    RETURNING lint_ret, lstr_msg
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Validate an influencer by brand
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_brand_validation(prec_selecteduser RECORD LIKE campaignuserlist.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignuser RECORD LIKE campaignuserlist.*
  LET lrec_campaignuser.* = prec_selecteduser.*
  LET lrec_campaignuser.cmpusrl_isacceptedbybrand = 1
  CALL campaignpublication_update_user_into_dabatase(lrec_campaignuser.*, prec_selecteduser.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL notifications.notif_influencer_brand_decision(lrec_campaignuser.cmpusrl_campaign_id, lrec_campaignuser.cmpusrl_user_id, TRUE)
    CALL notifications.notif_influencers_deal_has_started(lrec_campaignuser.cmpusrl_campaign_id, lrec_campaignuser.cmpusrl_user_id)
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Reject an influencer by brand
#+
#+ @param prec_selecteduser selected influencer
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpublication_brand_rejection(prec_selecteduser RECORD LIKE campaignuserlist.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignuser RECORD LIKE campaignuserlist.*
  LET lrec_campaignuser.* = prec_selecteduser.*
  LET lrec_campaignuser.cmpusrl_isacceptedbybrand = 0
  CALL campaignpublication_update_user_into_dabatase(lrec_campaignuser.*, prec_selecteduser.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL notifications.notif_influencer_brand_decision(lrec_campaignuser.cmpusrl_campaign_id, lrec_campaignuser.cmpusrl_user_id, FALSE)
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Add/Update selected user of a campaign publication
#+
#+ @param prec_campaignusergrid selected user of a campaign publication
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignusergrid_input(pint_dialog_state SMALLINT, pint_usr_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    larec_users_to_add DYNAMIC ARRAY OF INTEGER,
    i INTEGER,
    lint_err INTEGER,
    lbool_notify_influencer BOOLEAN,
    lbool_dialogtouched BOOLEAN

  LET lint_action = C_APPACTION_CANCEL
  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET ff_formtitle =  IIF((pint_usr_id==0), %"Add publication for all influencers", %"Add publication for influencer")
      --get the list of users to add to the publication
      CALL larec_users_to_add.clear()
      IF pint_usr_id==0 THEN --add several users
        FOR i = 1 TO marec_selectableuserlist.getLength()
          LET larec_users_to_add[i] = marec_selectableuserlist[i].user.usr_id
        END FOR
      ELSE
        LET larec_users_to_add[1] = pint_usr_id
      END IF
    WHEN C_DIALOGSTATE_UPDATE
      LET ff_formtitle = %"Edit influencer's publication"
    OTHERWISE
      RETURN lint_ret, lint_action
  END CASE
  CALL FGL_SETTITLE(ff_formtitle)

  CALL campaignusergrid_initialize_data(pint_usr_id, pint_dialog_state)

  OPEN WINDOW w_campaignuserlist_grid WITH FORM "campaignuserlist_grid"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaignusergrid.* FROM scr_campaignuserlist_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION dialogtouched
      LET lbool_dialogtouched = TRUE
      CALL campaignusergrid_ui_set_action_state(DIALOG, pint_dialog_state, lbool_dialogtouched)
    ON ACTION save
      LET lbool_notify_influencer = FALSE
      IF lbool_dialogtouched THEN
        --check if influencer price has been changed. If so reset the flags to restart the subscription process
        IF mrec_db_campaignuser.cmpusrl_usertotalprice IS NOT NULL
          AND mrec_campaignusergrid.campaignuser.cmpusrl_usertotalprice IS NOT NULL
          AND campaignusergrid_allow_edition_of_influencer_price(mrec_campaignusergrid.campaignuser.*)
        THEN
          --in case SalfatixMedia changes influencer's proposed price and the influencer already wanted an price
          --Then it means SalfatixMedia reject Influencer's negociation
          IF mrec_campaignusergrid.campaignuser.cmpusrl_userwantedprice IS NOT NULL
            AND mrec_campaignusergrid.campaignuser.cmpusrl_userwantedprice <> mrec_campaignusergrid.campaignuser.cmpusrl_usertotalprice
          THEN
            LET lbool_notify_influencer = TRUE
          END IF
          --in case SalfatixMedia put the influencer wanted price then do not reset influencer's agreement
          IF NOT (mrec_campaignusergrid.campaignuser.cmpusrl_userwantedprice IS NOT NULL
            AND mrec_campaignusergrid.campaignuser.cmpusrl_userwantedprice == mrec_campaignusergrid.campaignuser.cmpusrl_usertotalprice)
          THEN
            INITIALIZE mrec_campaignusergrid.campaignuser.cmpusrl_isacceptbyuser TO NULL
          END IF
          INITIALIZE mrec_campaignusergrid.campaignuser.cmpusrl_userwantedprice TO NULL
          INITIALIZE mrec_campaignusergrid.campaignuser.cmpusrl_isacceptedbysalfatix TO NULL
          INITIALIZE mrec_campaignusergrid.campaignuser.cmpusrl_isacceptedbybrand TO NULL
        END IF
        --check if brand price has been changed. If so reset the flags to restart the salfatix/brand negociation process
        IF mrec_db_campaignuser.cmpusrl_salfatixtotalprice IS NOT NULL
          AND mrec_campaignusergrid.campaignuser.cmpusrl_salfatixtotalprice IS NOT NULL
          AND campaignusergrid_allow_edition_of_brand_price(mrec_campaignusergrid.campaignuser.*)
        THEN
          INITIALIZE mrec_campaignusergrid.campaignuser.cmpusrl_isacceptedbybrand TO NULL
        END IF
        CALL campaignusergrid_validate_data(mrec_campaignusergrid.campaignuser.*, pint_dialog_state)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        CASE pint_dialog_state
          WHEN C_DIALOGSTATE_UPDATE
            --call update
            CALL campaignpublication_update_user_into_dabatase(mrec_campaignusergrid.campaignuser.*, mrec_db_campaignuser.*)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
              CONTINUE DIALOG
            END IF
            IF lbool_notify_influencer THEN
              CALL notifications.notif_influencers_proposed_priced_rejected(mrec_campaignusergrid.campaignuser.cmpusrl_user_id, mrec_campaignusergrid.campaignuser.cmpusrl_campaign_id)
            END IF
          WHEN C_DIALOGSTATE_ADD
            LET lint_err = 0
            FOR i = 1 TO larec_users_to_add.getLength()
              LET mrec_campaignusergrid.campaignuser.cmpusrl_user_id = larec_users_to_add[i]
              CALL campaignpublication_insert_user_into_dabatase(mrec_campaignusergrid.campaignuser.*)
                RETURNING lint_ret, lstr_msg, mrec_campaignusergrid.campaignuser.cmpusrl_id
              IF lint_ret <> 0 THEN
                LET lint_err = -1
              ELSE
                CALL larec_users_to_add.deleteElement(i)
                LET i = i - 1
              END IF
            END FOR
            IF lint_err <> 0 THEN
              ERROR %"Some influencers were not added. Please review them."
              CALL error_log(lint_ret, lstr_msg)
              CONTINUE DIALOG
            END IF
        END CASE
      END IF
      LET lint_ret = 0
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    BEFORE DIALOG
      LET lbool_dialogtouched = (pint_dialog_state==C_DIALOGSTATE_ADD) --set dialogtouched to true when doing a 'select all'
      CALL campaignusergrid_ui_set_action_state(DIALOG, pint_dialog_state, lbool_dialogtouched)
  END DIALOG
  CLOSE WINDOW w_campaignuserlist_grid
  RETURN lint_ret, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+
FUNCTION campaignusergrid_ui_set_action_state(p_dialog ui.Dialog, pint_dialog_state SMALLINT, pbool_dialog_touched BOOLEAN)
  DEFINE
    lbool_selectall BOOLEAN

  LET lbool_selectall = (mrec_campaignusergrid.campaignuser.cmpusrl_user_id==0)
  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched)
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_usr_firstname","hidden", lbool_selectall)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_firstname","hidden",lbool_selectall)
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_usr_lastname","hidden", lbool_selectall)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_lastname","hidden",lbool_selectall)
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_userwantedprice","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_userwantedprice","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_notificationdate","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_notificationdate","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_isacceptbyuser","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_isacceptbyuser","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_useranswerdate","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_useranswerdate","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_commentforbrand","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_commentforbrand","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_usergotproduct","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_usergotproduct","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_isuserpaid","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_isuserpaid","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_userpaid","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_userpaid","hidden","1")

      CALL layout.display_savebutton(pbool_dialog_touched)
    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched)
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_notificationdate","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_notificationdate","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_isacceptbyuser","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_isacceptbyuser","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","lbl_cmpusrl_useranswerdate","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_useranswerdate","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_usertotalprice","noEntry",NOT campaignusergrid_allow_edition_of_influencer_price(mrec_campaignusergrid.campaignuser.*))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignuserlist.cmpusrl_salfatixtotalprice","noEntry",NOT campaignusergrid_allow_edition_of_brand_price(mrec_campaignusergrid.campaignuser.*))
      CALL layout.display_savebutton(pbool_dialog_touched)
  END CASE
END FUNCTION

#+ Checks if SalfatixMedia can change the influencer proposed price
#+
#+ @param prec_campaignuser campaign user record
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignusergrid_allow_edition_of_influencer_price(prec_campaignuser RECORD LIKE campaignuserlist.*)
  IF setup.g_app_backoffice THEN
    --can change price when user has not applied
    -- or user has applied and wants a different price then the proposed one
    IF prec_campaignuser.cmpusrl_isacceptedbysalfatix IS NULL THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if SalfatixMedia can change the brand proposed price
#+
#+ @param prec_campaignuser campaign user record
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignusergrid_allow_edition_of_brand_price(prec_campaignuser RECORD LIKE campaignuserlist.*)
  IF setup.g_app_backoffice THEN
    --can change price when brand didn't answer
    -- or brand rejected the influencer
    IF prec_campaignuser.cmpusrl_isacceptedbybrand IS NULL
      OR (prec_campaignuser.cmpusrl_isacceptedbybrand IS NOT NULL AND prec_campaignuser.cmpusrl_isacceptedbybrand==0)
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION


#+ Initializes the campaign user grid record
#+
#+ @param pint_dialog_state current DIALOG state
#+ @param pint_index index in an array to look for data
#+ @param pbool_selectall TRUE->all influencers have been selected, FALSE otherwise
#+
#+ @returnType RECORD
#+ @return     campaign user grid record
FUNCTION campaignusergrid_initialize_data(pint_usr_id LIKE users.usr_id, pint_dialog_state SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg  STRING,
    lrec_usr RECORD LIKE users.*,
    lrec_campaignuser RECORD LIKE campaignuserlist.*

  INITIALIZE mrec_campaignusergrid.* TO NULL
  INITIALIZE mrec_db_campaignuser.* TO NULL

  IF pint_usr_id <> 0 THEN
    CALL core_db.users_select_row(pint_usr_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_usr.*
  END IF

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_campaignusergrid.campaignuser.cmpusrl_campaign_id = mrec_campaign.cmp_id
      LET mrec_campaignusergrid.campaignuser.cmpusrl_user_id = pint_usr_id
      LET mrec_campaignusergrid.campaignuser.cmpusrl_visibilitydate = mrec_campaign.cmp_publisheddate
      LET mrec_campaignusergrid.campaignuser.cmpusrl_previewuser = 0
      LET mrec_campaignusergrid.campaignuser.cmpusrl_wantedbybrand = 0
      LET mrec_campaignusergrid.campaignuser.cmpusrl_selectionstartdate = mrec_campaign.cmp_selectionstartdate
      LET mrec_campaignusergrid.campaignuser.cmpusrl_selectionenddate = mrec_campaign.cmp_selectionenddate
      --LET mrec_campaignusergrid.campaignuser.cmpusrl_selectioncomment =
      LET mrec_campaignusergrid.campaignuser.cmpusrl_tonotify = 0
      --LET mrec_campaignusergrid.campaignuser.cmpusrl_notificationdate =
      --LET mrec_campaignusergrid.campaignuser.cmpusrl_isacceptbyuser =
      --LET mrec_campaignusergrid.campaignuser.cmpusrl_useranswerdate =
      LET mrec_campaignusergrid.campaignuser.cmpusrl_usertotalprice = 0
      LET mrec_campaignusergrid.campaignuser.cmpusrl_salfatixtotalprice = 0
      --mrec_campaignusergrid.campaignuser.cmpusrl_userwantedprice
      --mrec_campaignusergrid.campaignuser.cmpusrl_uiorder
      --mrec_campaignusergrid.campaignuser.cmpusrl_isacceptedbysalfatix
      --mrec_campaignusergrid.campaignuser.cmpusrl_isacceptedbybrand
      --mrec_campaignusergrid.campaignuser.cmpusrl_commentforbrand
      LET mrec_campaignusergrid.campaignuser.cmpusrl_usergotproduct = 0
      --mrec_campaignusergrid.campaignuser.cmpusrl_isuserpaid
      --mrec_campaignusergrid.campaignuser.cmpusrl_userpaid
      IF pint_usr_id <> 0 THEN
        LET mrec_campaignusergrid.user.* = lrec_usr.*
        LET mrec_campaignusergrid.usr_instagram_profilepicture = lrec_usr.usr_instagram_profilepicture
      END IF
    WHEN C_DIALOGSTATE_UPDATE
      CALL core_db.campaignuserlist_select_row_by_campaign_and_user(mrec_campaign.cmp_id, pint_usr_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
      LET mrec_campaignusergrid.campaignuser.* = lrec_campaignuser.*
      LET mrec_campaignusergrid.user.* = lrec_usr.*
      LET mrec_campaignusergrid.usr_instagram_profilepicture = lrec_usr.usr_instagram_profilepicture
      LET mrec_db_campaignuser.* = mrec_campaignusergrid.campaignuser.*
  END CASE
END FUNCTION

#+ Check business rules of a campaign user
#+
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignusergrid_validate_data(prec_campaignuser, pint_dialog_state)
  DEFINE
    prec_campaignuser RECORD LIKE campaignuserlist.*,
    pint_dialog_state SMALLINT

  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF prec_campaignuser.cmpusrl_id IS NULL OR prec_campaignuser.cmpusrl_id==0 THEN
      RETURN -1, %"Id missing"
    END IF
  END IF
  IF prec_campaignuser.cmpusrl_campaign_id IS NULL OR prec_campaignuser.cmpusrl_campaign_id==0 THEN
    RETURN -1, %"Campaign missing"
  END IF
  IF prec_campaignuser.cmpusrl_user_id IS NULL THEN
    RETURN -1, %"Influencer missing"
  END IF
  IF prec_campaignuser.cmpusrl_visibilitydate IS NULL THEN
    RETURN -1, %"Influencer publication date missing"
  END IF
  IF prec_campaignuser.cmpusrl_selectionstartdate IS NULL THEN
    RETURN -1, %"Subscription start date missing"
  END IF
  IF prec_campaignuser.cmpusrl_selectionenddate IS NULL THEN
    RETURN -1, %"Subscription end date missing"
  END IF
  IF mrec_campaign.cmp_campaignstatus_id == C_CAMPAIGNSTATUS_VALIDATED THEN
    IF DATE(prec_campaignuser.cmpusrl_visibilitydate) < TODAY THEN
      RETURN -1, %"Publication date can not be a past date"
    END IF
  END IF
  IF prec_campaignuser.cmpusrl_visibilitydate > prec_campaignuser.cmpusrl_selectionstartdate THEN
    RETURN -1, %"Influencer publication date must be prior to the subscription start date"
  END IF
  IF prec_campaignuser.cmpusrl_selectionstartdate > prec_campaignuser.cmpusrl_selectionenddate THEN
    RETURN -1, %"Influencer subscription start date must be prior to its end date"
  END IF
  IF prec_campaignuser.cmpusrl_usergotproduct IS NULL THEN
    RETURN -1, %"Influencer product reception must be set"
  END IF
  IF prec_campaignuser.cmpusrl_usertotalprice IS NULL OR prec_campaignuser.cmpusrl_usertotalprice < 0 THEN
    RETURN -1, %"Influencer proposed price must be >= 0"
  END IF
  IF prec_campaignuser.cmpusrl_salfatixtotalprice IS NULL OR prec_campaignuser.cmpusrl_salfatixtotalprice < 0 THEN
    RETURN -1, %"Brand cost must be >= 0"
  END IF

  RETURN 0, NULL
END FUNCTION

#+ Build and display the titles
#+
#+ @param pbool_display display the titles
#+
PRIVATE FUNCTION _campaignpublication_build_titles(pbool_display)
  DEFINE
    pbool_display BOOLEAN,
    ff_formtitle STRING,
    ff_formtitle2 STRING
  LET ff_formtitle = SFMT(%"Influencers selection (%1)", marec_selectableuserlist.getLength())
  LET ff_formtitle2 = SFMT(%"Selected influencers for publication (%1)", marec_campaignuserlist.getLength())
  IF pbool_display THEN
    DISPLAY BY NAME ff_formtitle
    DISPLAY BY NAME ff_formtitle2
  END IF
END FUNCTION

#+ Returns the default photo picture in case the given parameter is NULL
#+
#+ @returnType STRING
#+ @return     default profile picture
PRIVATE FUNCTION _get_default_photo(pstr_instagram_profilepicture)
  DEFINE
    pstr_instagram_profilepicture STRING

  LET pstr_instagram_profilepicture = pstr_instagram_profilepicture.trim()
  RETURN IIF(pstr_instagram_profilepicture.getLength() > 0, pstr_instagram_profilepicture, C_PIC_DEFAULTAVATAR_FILE)
END FUNCTION

#+ Export the unfliencer list to send to accounting to pay the influencers
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpublication_export_list(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER,
    lrec_campaign RECORD LIKE campaigns.*,
    larec_users DYNAMIC ARRAY OF RECORD LIKE users.*,
    larec_campaignusers DYNAMIC ARRAY OF RECORD LIKE campaignuserlist.*,
    lrec_country RECORD LIKE countries.*,
    lrec_currency RECORD LIKE currencies.*,
    larec_data DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="Influencers") OF RECORD ATTRIBUTE(XMLName="Influencer")
      usr_firstname LIKE users.usr_firstname ATTRIBUTE(XMLNillable, XMLName="FirstName"),
      usr_lastname LIKE users.usr_lastname ATTRIBUTE(XMLNillable, XMLName="LastName"),
      usr_email LIKE users.usr_email ATTRIBUTE(XMLNillable, XMLName="Email"),
      cntr_name LIKE countries.cntr_name ATTRIBUTE(XMLNillable, XMLName="Country"),
      usr_bank_name LIKE users.usr_bank_name ATTRIBUTE(XMLNillable, XMLName="BankName"),
      usr_bank_iban LIKE users.usr_bank_iban ATTRIBUTE(XMLNillable, XMLName="BankIban"),
      usr_bank_swift LIKE users.usr_bank_swift ATTRIBUTE(XMLNillable, XMLName="BankSwift"),
      usr_paypal LIKE users.usr_paypal ATTRIBUTE(XMLNillable, XMLName="Paypal"),
      usertotalprice LIKE campaignuserlist.cmpusrl_usertotalprice ATTRIBUTE(XMLNillable, XMLName="Price"),
      crr_name LIKE currencies.crr_name ATTRIBUTE(XMLNillable, XMLName="Currency")
    END RECORD,
    lstr_server_filename STRING,
    lstr_client_filename STRING,
    doc xml.DomDocument,
    node xml.DomNode

  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
  CALL core_db.campaignuserlist_fetch_all_rows(SFMT("WHERE cmpusrl_campaign_id = %1 AND cmpusrl_isacceptedbysalfatix=1",pint_campaign_id), NULL, larec_campaignusers)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
  CALL core_db.currency_select_row(mrec_campaign.cmp_currency_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_currency.*
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
  FOR i = 1 TO larec_users.getLength()
    CALL core_db.country_select_row(larec_users[i].usr_country_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_country.*
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    LET larec_data[i].usr_firstname = larec_users[i].usr_firstname
    LET larec_data[i].usr_lastname = larec_users[i].usr_lastname
    LET larec_data[i].usr_email = larec_users[i].usr_email
    LET larec_data[i].cntr_name = lrec_country.cntr_name
    LET larec_data[i].usr_bank_name = larec_users[i].usr_bank_name
    LET larec_data[i].usr_bank_iban = larec_users[i].usr_bank_iban
    LET larec_data[i].usr_bank_swift = larec_users[i].usr_bank_swift
    LET larec_data[i].usr_paypal = larec_users[i].usr_paypal
    LET larec_data[i].usertotalprice = larec_campaignusers[i].cmpusrl_usertotalprice
    LET larec_data[i].crr_name = lrec_currency.crr_name
  END FOR

  --create and upload XML file
  LET lstr_server_filename = os.Path.join(base.Application.getResourceEntry("salfatixmedia.export.tmpdir"), string.get_report_name("campaignInfluencerList",".xml"))
  LET doc = xml.DomDocument.Create()
  CALL doc.setFeature("format-pretty-print",TRUE)
  LET node = doc.createElement("Root")
  CALL xml.Serializer.VariableToDom(larec_data, node)
  CALL doc.appendDocumentNode(node)
  TRY
    CALL doc.save(lstr_server_filename)
  CATCH
    LET lint_ret = STATUS
    LET lstr_msg = ERR_GET(lint_ret)
  END TRY
  IF lint_ret == 0 THEN
    LET lstr_client_filename = os.Path.basename(lstr_server_filename)
    TRY
      CALL FGL_PUTFILE(lstr_server_filename, lstr_client_filename)
    CATCH
      LET lint_ret = STATUS
      LET lstr_msg = ERR_GET(lint_ret)
    END TRY
  END IF
  IF os.Path.delete(lstr_server_filename) THEN END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Fetch and display the list of influencers in the brand app
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION
FUNCTION campaignpublicationforbrand_open_form_by_key(pint_campaign_id)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i INTEGER

  LET lint_action = C_APPACTION_CANCEL

  --get campaign data
  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, mrec_campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  LET mrec_db_campaign.* = mrec_campaign.*
  LET mrec_init_campaign.* = mrec_campaign.*
  --get selected users for the current campaign
  CALL campaignpublication_get_data(pint_campaign_id, marec_campaignuserlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF

  OPEN WINDOW w_campaignpublicationforbrand WITH FORM "campaignpublicationsforbrand"
  DISPLAY ARRAY marec_campaignuserlist TO scr_selected_list.*
    ATTRIBUTES (UNBUFFERED, ACCEPT=FALSE, CANCEL=FALSE)
    BEFORE DISPLAY
      DISPLAY BY NAME mrec_campaign.*
      CALL campaignpublicationforbrand_ui_set_action_state(DIALOG)
    BEFORE ROW
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      CALL campaignpublicationforbrand_ui_set_action_state_by_influencer(DIALOG, i)
    ON ACTION viewsocialnetwork
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        CALL layout.open_socialnetwork_account(C_SOCIALNETWORK_INSTAGRAM, marec_campaignuserlist[i].user.usr_instagram_username)
      END IF
    ON ACTION validatedbybrand
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        IF NOT campaignpublication_allow_brand_validation(marec_campaignuserlist[i].*) THEN
          CONTINUE DISPLAY
        END IF
        --call update
        CALL campaignpublication_brand_validation(marec_campaignuserlist[i].campaignuser.*)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
        CALL campaignpublication_get_data_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_id, marec_campaignuserlist, i)
          RETURNING lint_ret, lstr_msg
        CALL campaignpublicationforbrand_ui_set_action_state(DIALOG)
      END IF
    ON ACTION rejectedbybrand
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        IF NOT campaignpublication_allow_brand_rejection(marec_campaignuserlist[i].*) THEN
          CONTINUE DISPLAY
        END IF
        --call update
        CALL campaignpublication_brand_rejection(marec_campaignuserlist[i].campaignuser.*)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
        CALL campaignpublication_get_data_by_key(marec_campaignuserlist[i].campaignuser.cmpusrl_id, marec_campaignuserlist, i)
          RETURNING lint_ret, lstr_msg
        CALL campaignpublicationforbrand_ui_set_action_state(DIALOG)
      END IF
    ON ACTION manageposts
      LET i = DIALOG.getCurrentRow("scr_selected_list")
      IF i > 0 THEN
        IF NOT campaignpublication_allow_manage_post(marec_campaignuserlist[i].*) THEN
          CONTINUE DISPLAY
        END IF
        CALL campaignposts.campaignpostlist_open_form_by_key(pint_campaign_id, marec_campaignuserlist[i].campaignuser.cmpusrl_user_id)
          RETURNING lint_ret, lstr_msg, lint_action
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
        CASE lint_action
          WHEN C_APPACTION_CANCEL --stay in dialog
            CALL campaignpublicationforbrand_ui_set_action_state_by_influencer(DIALOG, i)
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION refreshselected
      CALL campaignpublication_get_data(pint_campaign_id, marec_campaignuserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DISPLAY
      END IF
      CALL campaignpublicationforbrand_ui_set_action_state(DIALOG)
    ON ACTION backtocampaign
      LET lint_ret = 0
      --in case the campaign has been updated (ex: the dates) and then we click on "back to campaign"
      LET lint_action = IIF(mrec_init_campaign.* <> mrec_campaign.*, C_APPACTION_ACCEPT, C_APPACTION_CANCEL)
      EXIT DISPLAY
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DISPLAY
  END DISPLAY
  CLOSE WINDOW w_campaignpublicationforbrand
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignpublicationforbrand_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.DIALOG,
    i INTEGER,
    lint_ret INTEGER,
    lstr_msg STRING,
    brandestimatedcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    brandcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    cmp_deposit LIKE campaigns.cmp_deposit

  CALL p_dialog.setActionHidden("customaction", TRUE)

  CALL _campaignpublicationforbrand_build_titles(TRUE)

  CALL layout.display_currencysymbol(mrec_campaign.cmp_currency_id,"cur,cur1,cur2,cur3")

  LET i = p_dialog.getCurrentRow("scr_selected_list")
  IF (i==0) OR (i > marec_campaignuserlist.getLength()) THEN
    LET i = marec_campaignuserlist.getLength()
  END IF
  CALL campaignprice_get_brand_prices(mrec_campaign.cmp_id)
    RETURNING lint_ret, lstr_msg, brandestimatedcost, brandcost, cmp_deposit
  IF lint_ret == 0 THEN
    DISPLAY BY NAME brandestimatedcost
    DISPLAY BY NAME brandcost
    DISPLAY BY NAME cmp_deposit
  END IF
  CALL campaignpublicationforbrand_ui_set_action_state_by_influencer(p_dialog, i)

END FUNCTION

#+ Sets the state of the dialog actions to active or inactive for an influencer
#+
#+ @param p_dialog current DIALOG
#+ @param i index of the selected user current DIALOG
#+
FUNCTION campaignpublicationforbrand_ui_set_action_state_by_influencer(p_dialog ui.Dialog, i INTEGER)
  DEFINE
    lbool_allow_brand_validation BOOLEAN,
    lbool_allow_brand_rejection BOOLEAN,
    lbool_allow_manage_post BOOLEAN

  LET lbool_allow_brand_validation = IIF(i>0,campaignpublication_allow_brand_validation(marec_campaignuserlist[i].*),FALSE)
  LET lbool_allow_brand_rejection = IIF(i>0,campaignpublication_allow_brand_rejection(marec_campaignuserlist[i].*),FALSE)
  LET lbool_allow_manage_post = IIF(i>0,campaignpublication_allow_manage_post(marec_campaignuserlist[i].*),FALSE)

  CALL p_dialog.setActionActive("validatedbybrand", lbool_allow_brand_validation)
  CALL p_dialog.setActionActive("rejectedbybrand", lbool_allow_brand_rejection)
  CALL p_dialog.setActionActive("manageposts", lbool_allow_manage_post AND (i>0))
END FUNCTION

#+ Build and display the titles
#+
#+ @param pbool_display display the titles
#+
PRIVATE FUNCTION _campaignpublicationforbrand_build_titles(pbool_display)
  DEFINE
    pbool_display BOOLEAN,
    ff_formtitle2 STRING
  LET ff_formtitle2 = SFMT(%"Influencers for your campaign (%1)", marec_campaignuserlist.getLength())
  IF pbool_display THEN
    DISPLAY BY NAME ff_formtitle2
  END IF
END FUNCTION