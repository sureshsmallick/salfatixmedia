IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL users
IMPORT FGL layout
IMPORT FGL notifications
IMPORT os
IMPORT xml

SCHEMA salfatixmedia

TYPE
  t_proposeduserlist RECORD
    campaignproposeduser RECORD LIKE campaignproposedusers.*,
    user RECORD LIKE users.*,
    usrmtc_reach LIKE usermetrics.usrmtc_reach,
    usrmtc_followers_count LIKE usermetrics.usrmtc_followers_count,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    usr_countryname LIKE countries.cntr_name,
    usr_statename LIKE states.stt_name,
    usr_cityname LIKE cities.cts_name,
    delimage STRING,
    viewimage STRING,
    editimage STRING
  END RECORD

TYPE
  t_proposedusergrid RECORD
    campaignproposeduser RECORD LIKE campaignproposedusers.*,
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    crr_symbol LIKE currencies.crr_name,
    salfatixcrr_symbol LIKE currencies.crr_name--,
    --usrprices VARCHAR(255),
    --salfatixprices VARCHAR(255)
  END RECORD

TYPE
  t_campaignproposalgrid RECORD
    campaign RECORD LIKE campaigns.*,
    campaignproposal RECORD LIKE campaignproposals.*,
    crr_symbol LIKE currencies.crr_name, --currency symbol next to campaign budget
    crr_symbol1 LIKE currencies.crr_name --currency symbol next to campaign budget
  END RECORD

DEFINE
  m_dialogtouched SMALLINT

DEFINE --list data
  marec_proposeduserlist DYNAMIC ARRAY OF t_proposeduserlist
DEFINE
  mrec_campaignproposalgrid t_campaignproposalgrid,
  mrec_db_campaignproposal RECORD LIKE campaignproposals.*,
  mrec_db_campaign RECORD LIKE campaigns.*


#+ Fetch and display the list of influencers
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION
FUNCTION campaignproposal_open_form_by_key(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i INTEGER,
    lbool_dialogtouched BOOLEAN,
    dnd ui.DragDrop,
    idx_drag, idx_drop INTEGER,
    lint_action_tmp SMALLINT,
    lint_user_id LIKE users.usr_id,
    lrec_proposedusergrid t_proposedusergrid,
    lbool_selectall BOOLEAN

  LET lint_action = C_APPACTION_CANCEL

  CALL campaignproposal_initialize_data(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF

  OPEN WINDOW w_campaignproposals WITH FORM "campaignproposals"
  CALL FGL_SETTITLE(%"Proposal")
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaignproposalgrid.* FROM scr_campaignproposal.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        LET lbool_dialogtouched = FALSE
        CALL campaignproposalgrid_ui_set_action_state(DIALOG, lbool_dialogtouched)
        CALL formatdecimal(mrec_campaignproposalgrid.campaign.cmp_totalbudget,"campaigns.cmp_totalbudget","######&.&&","######&")
      ON ACTION dialogtouched
        LET lbool_dialogtouched = TRUE
        CALL campaignproposalgrid_ui_set_action_state(DIALOG, lbool_dialogtouched)
      ON ACTION save --salfatix action only
        CALL campaignproposal_process_data(DIALOG, lbool_dialogtouched, C_APPACTION_ACCEPT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE DIALOG
        END IF
        LET lbool_dialogtouched = FALSE
        CALL campaignproposalgrid_ui_set_action_state(DIALOG, lbool_dialogtouched)
      AFTER INPUT --autosave when leaving the dialog
        CALL campaignproposal_process_data(DIALOG, lbool_dialogtouched, C_APPACTION_AUTOACCEPT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          NEXT FIELD CURRENT
        END IF
        LET lbool_dialogtouched = FALSE
        CALL campaignproposalgrid_ui_set_action_state(DIALOG, lbool_dialogtouched)
    END INPUT
    DISPLAY ARRAY marec_proposeduserlist TO scr_campaignproposedusers.*
      ON DRAG_START(dnd) --salfatix action only
        INITIALIZE idx_drag TO NULL
        IF mrec_campaignproposalgrid.campaignproposal.cmpprp_status_id == C_PROPOSALSTATUS_CREATED THEN
          LET idx_drag = ARR_CURR()
        ELSE
          CALL dnd.setOperation(NULL)
        END IF
      ON DRAG_FINISHED(dnd)
        INITIALIZE idx_drag TO NULL
        INITIALIZE idx_drop TO NULL
      ON DRAG_ENTER (dnd)
        IF idx_drag IS NULL THEN
          CALL dnd.setOperation(NULL)
        END IF
      ON DROP (dnd)
        IF idx_drag IS NULL THEN
          CALL dnd.setOperation(NULL)
        END IF
        LET idx_drop = dnd.getLocationRow()
        CALL dnd.dropInternal()
        --update the uiorder
        IF idx_drag <> idx_drop THEN
          CALL campaignproposal_update_uiorder(marec_proposeduserlist)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
            --refetch list to not display a list with obsolete data/uiorder
            CALL campaignproposal_proposeduser_get_list(mrec_campaignproposalgrid.campaignproposal.cmpprp_campaign_id, mrec_campaignproposalgrid.campaignproposal.cmpprp_id, marec_proposeduserlist)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              EXIT DIALOG
            END IF
            CONTINUE DIALOG
          END IF
        END IF
    END DISPLAY
    ON ACTION viewinfluencer --salfatix action only
      LET i = DIALOG.getCurrentRow("scr_campaignproposedusers")
      IF i > 0 THEN
        CALL users.usergrid_open_form_by_key(marec_proposeduserlist[i].campaignproposeduser.cmpprpu_user_id, C_APPSTATE_DISPLAY, NULL)
          RETURNING lint_ret, lint_action_tmp, lint_user_id
      END IF
    ON ACTION editinfluencer --salfatix action only
      LET i = DIALOG.getCurrentRow("scr_campaignproposedusers")
      IF i > 0 THEN
        INITIALIZE lrec_proposedusergrid.* TO NULL
        LET lrec_proposedusergrid.campaignproposeduser.* = marec_proposeduserlist[i].campaignproposeduser.*
        LET lrec_proposedusergrid.user.* = marec_proposeduserlist[i].user.*
        LET lrec_proposedusergrid.usr_instagram_profilepicture = marec_proposeduserlist[i].usr_instagram_profilepicture
        LET lrec_proposedusergrid.crr_symbol = mrec_campaignproposalgrid.crr_symbol
        LET lrec_proposedusergrid.salfatixcrr_symbol = mrec_campaignproposalgrid.crr_symbol
        --CALL _get_prices_string(mrec_campaignproposalgrid.campaignproposal.cmpprp_campaign_id, marec_proposeduserlist[i].campaignproposeduser.cmpprpu_user_id)
          --RETURNING lrec_proposedusergrid.usrprices, lrec_proposedusergrid.salfatixprices
        CALL campaignproposedusergrid_input(lrec_proposedusergrid.*)
          RETURNING lint_ret, lint_action_tmp, lrec_proposedusergrid.*
        IF lint_ret == 0 THEN
          IF lint_action_tmp == C_APPACTION_ACCEPT THEN
            --call update
            CALL campaignproposeduser_update_into_dabatase(lrec_proposedusergrid.campaignproposeduser.*, marec_proposeduserlist[i].campaignproposeduser.*)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
              CONTINUE DIALOG
            END IF
            CALL campaignproposal_proposeduser_get_by_key(mrec_campaignproposalgrid.campaignproposal.cmpprp_campaign_id, lrec_proposedusergrid.campaignproposeduser.cmpprpu_campaignproposal_id, lrec_proposedusergrid.campaignproposeduser.cmpprpu_user_id, marec_proposeduserlist, i)
              RETURNING lint_ret, lstr_msg
          END IF
        END IF
      END IF
    ON ACTION delete  --salfatix action only
      LET i = DIALOG.getCurrentRow("scr_campaignproposedusers")
      IF i > 0 THEN
        CALL campaignproposal_delete_from_database(marec_proposeduserlist[i].campaignproposeduser.cmpprpu_campaignproposal_id, marec_proposeduserlist[i].campaignproposeduser.cmpprpu_user_id)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          CALL marec_proposeduserlist.deleteElement(i)
        END IF
        CALL campaignproposal_ui_set_action_state(DIALOG)
      END IF
    ON ACTION viewsocialnetwork
      LET i = DIALOG.getCurrentRow("scr_campaignproposedusers")
      IF i > 0 THEN
        CALL layout.open_socialnetwork_account(C_SOCIALNETWORK_INSTAGRAM, marec_proposeduserlist[i].user.usr_instagram_username)
      END IF
    ON ACTION submit --salfatix action only
      IF core_ui.ui_message(%"Question",%"Submit this proposal to the brand?","no","yes|no","fa-question") == "yes" THEN
        CALL campaignproposal_update_proposal(C_PROPOSALSTATUS_SUBMITTED)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        LET lint_ret = 0
        LET lint_action = C_APPACTION_ACCEPT
        EXIT DIALOG
      END IF
    ON ACTION importusers --salfatix action only
      CALL campaignproposal_import_influencer_list(mrec_campaignproposalgrid.campaignproposal.cmpprp_campaign_id, mrec_campaignproposalgrid.campaignproposal.cmpprp_id, marec_proposeduserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignproposal_ui_set_action_state(DIALOG)
    ON ACTION backtocampaign
      LET lint_ret = 0
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DIALOG
    ON ACTION toggleall --brand action only
      LET lbool_selectall = (NOT lbool_selectall)
      CALL DIALOG.setSelectionRange("scr_campaignproposedusers", 1, -1, lbool_selectall)
      IF lbool_selectall THEN
        CALL core_ui.ui_set_node_attribute("Button","name","toggleall","text","Deselect all influencers")
      ELSE
        CALL core_ui.ui_set_node_attribute("Button","name","toggleall","text","Select all influencers")
      END IF
      CALL campaignproposal_ui_set_action_state(DIALOG)
    ON ACTION acceptselection --brand action only
      CALL campaignproposal_proposeduser_updateselection(DIALOG, TRUE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignproposal_ui_set_action_state(DIALOG)
    ON ACTION rejectselection --brand action only
      CALL campaignproposal_proposeduser_updateselection(DIALOG, FALSE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignproposal_ui_set_action_state(DIALOG)
    ON ACTION submittosalfatix --brand action only
      IF core_ui.ui_message(%"Question",%"Submit for review by Salfatix Media?","no","yes|no","fa-question") == "yes" THEN
        CALL campaignproposal_update_proposal(C_PROPOSALSTATUS_REJECTED)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        LET lint_ret = 0
        LET lint_action = C_APPACTION_ACCEPT
        EXIT DIALOG
      END IF
    ON ACTION acceptsalfatixproposal --brand action only
      IF core_ui.ui_message(%"Question",%"Accept Salfatix Media proposal?","no","yes|no","fa-question") == "yes" THEN
        CALL campaignproposal_update_proposal(C_PROPOSALSTATUS_VALIDATED)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DIALOG
        END IF
        LET lint_ret = 0
        LET lint_action = C_APPACTION_ACCEPT
        EXIT DIALOG
      END IF
    ON ACTION reviewproposal --salfatix action only
      CALL campaignproposal_initialize_data(pint_campaign_id, TRUE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      CALL campaignproposal_ui_set_action_state(DIALOG)
    ON ACTION exportlist
      CALL campaignproposal_export_list()
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
    BEFORE DIALOG
      LET lbool_selectall = FALSE --flag for brand action to handle the toggleall action
      CALL campaignproposal_ui_set_action_state(DIALOG)
  END DIALOG
  CLOSE WINDOW w_campaignproposals
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignproposal_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.DIALOG,
    lbool_show_influencer_address BOOLEAN,
    lbool_allow_exportlist BOOLEAN

  LET lbool_allow_exportlist = FALSE
  CASE mrec_campaignproposalgrid.campaignproposal.cmpprp_status_id
    WHEN C_PROPOSALSTATUS_CREATED
      CALL core_ui.ui_set_node_attribute("Button","name","save","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel","hidden",NOT (setup.g_app_backoffice))
      CALL p_dialog.setActionActive("importusers", (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Button","name","importusers","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel1","hidden",NOT (setup.g_app_backoffice))
      CALL p_dialog.setActionActive("submit", marec_proposeduserlist.getLength()>0 AND (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Button","name","submit","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel2","hidden",NOT (setup.g_app_backoffice))
      CALL p_dialog.setActionActive("toggleall", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","toggleall","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel4","hidden",TRUE)
      CALL p_dialog.setActionActive("acceptselection", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptselection","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel5","hidden",TRUE)
      CALL p_dialog.setActionActive("rejectselection", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","rejectselection","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel6","hidden",TRUE)
      CALL p_dialog.setActionActive("acceptsalfatixproposal", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptsalfatixproposal","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel3","hidden",TRUE)
      CALL p_dialog.setActionActive("submittosalfatix", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","submittosalfatix","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel7","hidden",TRUE)
      CALL p_dialog.setActionActive("reviewproposal", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","reviewproposal","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel8","hidden",TRUE)
      CALL p_dialog.setActionActive("exportlist", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","exportlist","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel_exportlist","hidden",TRUE)

      CALL p_dialog.setActionActive("delete", (setup.g_app_backoffice))
      CALL p_dialog.setActionActive("viewinfluencer", (setup.g_app_backoffice))
      CALL p_dialog.setActionActive("editinfluencer", (setup.g_app_backoffice))

      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_price","noEntry",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_selectioncomment","noEntry",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.delimage","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.viewinfluencer","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.editinfluencer","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_usertotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_salfatixtotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_notificationdate","hidden",NOT (setup.g_app_backoffice))

      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_countryname","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_statename","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_cityname","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_number","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_street","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_zipcode","hidden", TRUE)
      --CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_town","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_more","hidden", TRUE)
    
    WHEN C_PROPOSALSTATUS_SUBMITTED
      CALL core_ui.ui_set_node_attribute("Button","name","save","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel","hidden",TRUE)
      CALL p_dialog.setActionActive("importusers", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","importusers","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel1","hidden",TRUE)
      CALL p_dialog.setActionActive("submit", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","submit","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel2","hidden",TRUE)
      CALL p_dialog.setActionActive("toggleall", (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Button","name","toggleall","hidden",NOT (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel4","hidden",NOT (setup.g_app_brand))
      CALL p_dialog.setActionActive("acceptselection", (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Button","name","acceptselection","hidden",NOT (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel5","hidden",NOT (setup.g_app_brand))
      CALL p_dialog.setActionActive("rejectselection", (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Button","name","rejectselection","hidden",NOT (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel6","hidden",NOT (setup.g_app_brand))
      CALL p_dialog.setActionActive("acceptsalfatixproposal", (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Button","name","acceptsalfatixproposal","hidden",NOT (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel3","hidden",NOT (setup.g_app_brand))
      CALL p_dialog.setActionActive("submittosalfatix", (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Button","name","submittosalfatix","hidden",NOT (setup.g_app_brand))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel7","hidden",NOT (setup.g_app_brand))
      CALL p_dialog.setActionActive("reviewproposal", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","reviewproposal","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel8","hidden",TRUE)
      CALL p_dialog.setActionActive("exportlist", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","exportlist","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel_exportlist","hidden",TRUE)

      CALL p_dialog.setActionActive("delete", FALSE)
      CALL p_dialog.setActionActive("viewinfluencer", FALSE)
      CALL p_dialog.setActionActive("editinfluencer", FALSE)

      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_price","noEntry",TRUE)
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_selectioncomment","noEntry",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.delimage","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.viewinfluencer","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.editinfluencer","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_usertotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_salfatixtotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_notificationdate","hidden",NOT (setup.g_app_backoffice))

      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_countryname","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_statename","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_cityname","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_number","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_street","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_zipcode","hidden", TRUE)
      --CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_town","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_more","hidden", TRUE)

      CALL p_dialog.setSelectionMode("scr_campaignproposedusers", (setup.g_app_brand))
    WHEN C_PROPOSALSTATUS_REJECTED
      CALL core_ui.ui_set_node_attribute("Button","name","save","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel","hidden",TRUE)
      CALL p_dialog.setActionActive("importusers", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","importusers","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel1","hidden",TRUE)
      CALL p_dialog.setActionActive("submit", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","submit","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel2","hidden",TRUE)
      CALL p_dialog.setActionActive("toggleall", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","toggleall","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel4","hidden",TRUE)
      CALL p_dialog.setActionActive("acceptselection", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptselection","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel5","hidden",TRUE)
      CALL p_dialog.setActionActive("rejectselection", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","rejectselection","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel6","hidden",TRUE)
      CALL p_dialog.setActionActive("acceptsalfatixproposal", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptsalfatixproposal","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel3","hidden",TRUE)
      CALL p_dialog.setActionActive("submittosalfatix", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","submittosalfatix","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel7","hidden",TRUE)
      CALL p_dialog.setActionActive("reviewproposal", (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Button","name","reviewproposal","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel8","hidden",NOT (setup.g_app_backoffice))
      CALL p_dialog.setActionActive("exportlist", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","exportlist","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel_exportlist","hidden",TRUE)

      CALL p_dialog.setActionActive("delete", FALSE)
      CALL p_dialog.setActionActive("viewinfluencer", FALSE)
      CALL p_dialog.setActionActive("editinfluencer", FALSE)

      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_price","noEntry",TRUE)
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_selectioncomment","noEntry",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.delimage","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.viewinfluencer","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.editinfluencer","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_usertotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_salfatixtotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_notificationdate","hidden",NOT (setup.g_app_backoffice))

      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_countryname","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_statename","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_cityname","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_number","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_street","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_zipcode","hidden", TRUE)
      --CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_town","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_more","hidden", TRUE)

    WHEN C_PROPOSALSTATUS_VALIDATED
      CALL core_ui.ui_set_node_attribute("Button","name","save","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel","hidden",TRUE)
      CALL p_dialog.setActionActive("importusers", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","importusers","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel1","hidden",TRUE)
      CALL p_dialog.setActionActive("submit", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","submit","hidden", TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel2","hidden",TRUE)
      CALL p_dialog.setActionActive("toggleall", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","toggleall","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel4","hidden",TRUE)
      CALL p_dialog.setActionActive("acceptselection", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptselection","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel5","hidden",TRUE)
      CALL p_dialog.setActionActive("rejectselection", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","rejectselection","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel6","hidden",TRUE)
      CALL p_dialog.setActionActive("acceptsalfatixproposal", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptsalfatixproposal","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel3","hidden",TRUE)
      CALL p_dialog.setActionActive("submittosalfatix", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","submittosalfatix","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel7","hidden",TRUE)
      CALL p_dialog.setActionActive("reviewproposal", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","reviewproposal","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel8","hidden",TRUE)
      LET lbool_allow_exportlist = campaignproposal_allow_exportlist(mrec_campaignproposalgrid.campaign.cmp_campaignstatus_id, mrec_campaignproposalgrid.campaignproposal.cmpprp_status_id)
      CALL p_dialog.setActionActive("exportlist", (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Button","name","exportlist","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("Label","name","emptylabel_exportlist","hidden",(NOT setup.g_app_backoffice))

      CALL p_dialog.setActionActive("delete", FALSE)
      CALL p_dialog.setActionActive("viewinfluencer", FALSE)
      CALL p_dialog.setActionActive("editinfluencer", FALSE)

      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_price","noEntry",TRUE)
      CALL core_ui.ui_set_node_attribute("FormField","name","campaignproposals.cmpprp_selectioncomment","noEntry",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.delimage","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.viewinfluencer","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.editinfluencer","hidden",TRUE)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_usertotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_salfatixtotalprice","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_notificationdate","hidden",NOT (setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignproposedusers.cmpprpu_isacceptedbybrand","hidden", (setup.g_app_brand))

      LET lbool_show_influencer_address = (setup.g_app_brand) AND  (mrec_campaignproposalgrid.campaign.cmp_campaignstatus_id==C_CAMPAIGNSTATUS_FULLY_PAID) 
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_countryname","hidden", NOT lbool_show_influencer_address)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_statename","hidden", NOT lbool_show_influencer_address)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.usr_cityname","hidden", NOT lbool_show_influencer_address)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_number","hidden", NOT lbool_show_influencer_address)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_street","hidden", NOT lbool_show_influencer_address)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_zipcode","hidden", NOT lbool_show_influencer_address)
      --CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_town","hidden", NOT lbool_show_influencer_address)
      CALL core_ui.ui_set_node_attribute("TableColumn","name","users.usr_address_more","hidden", NOT lbool_show_influencer_address)

  END CASE

  CALL p_dialog.setActionHidden("customaction", TRUE)
  CALL _campaignproposal_build_titles(TRUE)
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION campaignproposalgrid_ui_set_action_state(p_dialog, p_dialogtouched)
  DEFINE
    p_dialog ui.DIALOG,
    p_dialogtouched BOOLEAN,
    lbool_allow_save BOOLEAN

  CALL campaignproposal_ui_set_action_state(p_dialog)
  CALL p_dialog.setActionActive("dialogtouched", NOT p_dialogtouched)
  CASE mrec_campaignproposalgrid.campaignproposal.cmpprp_status_id
    WHEN C_PROPOSALSTATUS_CREATED
      LET lbool_allow_save = (setup.g_app_backoffice)
      CALL p_dialog.setActionActive("save", p_dialogtouched AND lbool_allow_save)
    OTHERWISE
      CALL p_dialog.setActionActive("save", FALSE)
  END CASE
END FUNCTION

#+ Get the proposed influencer list data
#+
#+ @param pint_campaign_id proposal id
#+ @param pint_proposal_id proposal id
#+ @param parec_list list of selectable influencer t_brandlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_proposeduser_get_list(pint_campaign_id, pint_proposal_id, parec_list)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_proposal_id LIKE campaignproposals.cmpprp_id,
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data0 RECORD LIKE users.*,
    lrec_data1 RECORD LIKE campaignproposedusers.*

  CALL parec_list.clear()
  LET lstr_sql = "SELECT users.*, campaignproposedusers.*"
  ," FROM users, campaignproposedusers"
  ," WHERE campaignproposedusers.cmpprpu_user_id = users.usr_id"
  ,SFMT(" AND campaignproposedusers.cmpprpu_campaignproposal_id = %1", pint_proposal_id)
  ," ORDER BY campaignproposedusers.cmpprpu_uiorder"
  TRY
    DECLARE c_campaignproposal_proposeduser_get_list CURSOR FROM lstr_sql
    FOREACH c_campaignproposal_proposeduser_get_list
      INTO lrec_data0.*, lrec_data1.*
      CALL _add_to_list(pint_campaign_id, lrec_data0.*, lrec_data1.*, parec_list, parec_list.getLength()+1)
    END FOREACH
    FREE c_campaignproposal_proposeduser_get_list
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the proposed influencer list data
#+
#+ @param pint_campaign_id campaign id
#+ @param pint_proposal_id proposal id
#+ @param pint_usr_id influencer id
#+ @param parec_list list of proposed influencer
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_proposeduser_get_by_key(pint_campaign_id, pint_proposal_id, pint_usr_id, parec_list, pint_index)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_proposal_id LIKE campaignproposedusers.cmpprpu_campaignproposal_id,
    pint_usr_id LIKE campaignproposedusers.cmpprpu_user_id,
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    pint_index INTEGER,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data0 RECORD LIKE users.*,
    lrec_data1 RECORD LIKE campaignproposedusers.*

  LET lstr_sql = "SELECT users.*, campaignproposedusers.*"
  ," FROM users, campaignproposedusers"
  ," WHERE campaignproposedusers.cmpprpu_user_id = users.usr_id"
  ,SFMT(" AND campaignproposedusers.cmpprpu_campaignproposal_id = %1", pint_proposal_id)
  ,SFMT(" AND campaignproposedusers.cmpprpu_user_id= %1", pint_usr_id)
  TRY
    PREPARE p_campaignproposal_proposeduser_get_by_key FROM lstr_sql
    EXECUTE p_campaignproposal_proposeduser_get_by_key
      INTO lrec_data0.*, lrec_data1.*
    IF SQLCA.SQLCODE <> 0 THEN
      RETURN SQLCA.SQLCODE, SQLERRMESSAGE
    END IF
    CALL _add_to_list(pint_campaign_id, lrec_data0.*, lrec_data1.*, parec_list, pint_index)
    FREE p_campaignproposal_proposeduser_get_by_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Initializes the campaign proposal record
#+
#+ @param pint_campaign_id current campaign
#+ @param pbool_createfromlastproposal TRUE to create a new proposal from the last one, FALSE otherwise
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_initialize_data(pint_campaign_id LIKE campaigns.cmp_id, pbool_createfromlastproposal BOOLEAN)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_old_campaignproposal RECORD LIKE campaignproposals.*,
    lrec_campaignproposal RECORD LIKE campaignproposals.*,
    lrec_new_campaignproposal RECORD LIKE campaignproposals.*,
    larec_old_proposeduserlist DYNAMIC ARRAY OF t_proposeduserlist,
    larec_new_proposeduserlist DYNAMIC ARRAY OF t_proposeduserlist,
    lbool_createproposal BOOLEAN,
    lint_status INTEGER,
    i,j,s INTEGER

  INITIALIZE mrec_campaignproposalgrid.* TO NULL
  INITIALIZE mrec_db_campaign.* TO NULL
  INITIALIZE mrec_db_campaignproposal.* TO NULL
  CALL marec_proposeduserlist.clear()

  --get campaign data
  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  LET lbool_createproposal = FALSE
  --get last proposal data
  CALL core_db.campaignproposals_select_last_row_by_campaign(lrec_campaign.cmp_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_old_campaignproposal.*
  CASE lint_ret
    WHEN 0
      --get proposed influencers for the campaign
      CALL campaignproposal_proposeduser_get_list(lrec_campaign.cmp_id, lrec_old_campaignproposal.cmpprp_id, larec_old_proposeduserlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      IF pbool_createfromlastproposal THEN
        LET lbool_createproposal = TRUE
      ELSE
        LET lrec_new_campaignproposal.* = lrec_old_campaignproposal.*
        CALL larec_old_proposeduserlist.copyTo(larec_new_proposeduserlist)
      END IF
    WHEN NOTFOUND
      LET lbool_createproposal = TRUE
    OTHERWISE
      RETURN lint_ret, lstr_msg
  END CASE
  IF lbool_createproposal THEN
    --start a database transaction
    LET lint_ret = DB_START_TRANSACTION()
    LET lstr_msg = SQLERRMESSAGE
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --update previous campaign proposal if it exist
    IF lrec_old_campaignproposal.cmpprp_id IS NOT NULL AND lrec_old_campaignproposal.cmpprp_id > 0 THEN
      LET lrec_campaignproposal.* = lrec_old_campaignproposal.*
      LET lrec_campaignproposal.cmpprp_islast = 0
      CALL core_db.campaignproposals_update_row(lrec_old_campaignproposal.*, lrec_campaignproposal.*)
        RETURNING lint_ret, lstr_msg
    END IF
    IF lint_ret == 0 THEN
      INITIALIZE lrec_new_campaignproposal.* TO NULL
      LET lrec_new_campaignproposal.cmpprp_id = 0
      LET lrec_new_campaignproposal.cmpprp_campaign_id = lrec_campaign.cmp_id
      LET lrec_new_campaignproposal.cmpprp_creationdate = CURRENT
      LET lrec_new_campaignproposal.cmpprp_status_id = C_PROPOSALSTATUS_CREATED
      LET lrec_new_campaignproposal.cmpprp_islast = 1
      IF lrec_old_campaignproposal.cmpprp_id IS NOT NULL AND lrec_old_campaignproposal.cmpprp_id > 0 THEN
        LET lrec_new_campaignproposal.cmpprp_price = lrec_old_campaignproposal.cmpprp_price
        LET lrec_new_campaignproposal.cmpprp_selectioncomment = lrec_old_campaignproposal.cmpprp_selectioncomment
      END IF
      CALL core_db.campaignproposals_insert_row(lrec_new_campaignproposal.*)
        RETURNING lint_ret, lstr_msg, lrec_new_campaignproposal.cmpprp_id
    END IF
    --commit SQL transaction if no error occured, otherwise rollback SQL transaction
    IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
      --commit or rollback failed
      LET lint_ret = lint_status
      LET lstr_msg = SQLERRMESSAGE
      RETURN lint_ret, lstr_msg
    END IF
    IF lint_ret == 0 THEN
      LET s = larec_old_proposeduserlist.getLength()
      IF s > 0 THEN
        --start a database transaction
        LET lint_ret = DB_START_TRANSACTION()
        LET lstr_msg = SQLERRMESSAGE
        IF lint_ret <> 0 THEN
          RETURN lint_ret, lstr_msg
        END IF
        LET j = 0
        FOR i = 1 TO s
          IF (i MOD 100) == 0 THEN
            --commit SQL transaction each 500 iterations
            IF (lint_status := DB_FINISH_TRANSACTION(TRUE)) <> 0 THEN
              --commit failed
              LET lint_ret = lint_status
              LET lstr_msg = SQLERRMESSAGE
              RETURN lint_ret, lstr_msg
            END IF
            --start a new database transaction
            LET lint_ret = DB_START_TRANSACTION()
            LET lstr_msg = SQLERRMESSAGE
            IF lint_ret <> 0 THEN
              RETURN lint_ret, lstr_msg
            END IF
          END IF
          --get old influencers where there is no answer or the answer is accepted
          IF (larec_old_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand IS NULL)
            OR (larec_old_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand IS NOT NULL
              AND larec_old_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand == 1)
          THEN
            LET j = j + 1
            LET larec_new_proposeduserlist[j].* = larec_old_proposeduserlist[i].*
            LET larec_new_proposeduserlist[j].campaignproposeduser.cmpprpu_campaignproposal_id = lrec_new_campaignproposal.cmpprp_id
            CALL core_db.campaignproposedusers_insert_row(larec_new_proposeduserlist[j].campaignproposeduser.*)
              RETURNING lint_ret, lstr_msg, larec_new_proposeduserlist[j].campaignproposeduser.cmpprpu_campaignproposal_id, larec_new_proposeduserlist[j].campaignproposeduser.cmpprpu_user_id
            IF lint_ret <> 0 THEN
              EXIT FOR
            END IF
          END IF
        END FOR
        --commit SQL transaction if no error occured, otherwise rollback SQL transaction
        IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
          --commit or rollback failed
          LET lint_ret = lint_status
          LET lstr_msg = SQLERRMESSAGE
          RETURN lint_ret, lstr_msg
        END IF
      END IF
    END IF
  END IF
  LET mrec_campaignproposalgrid.campaign.* = lrec_campaign.*
  LET mrec_campaignproposalgrid.campaignproposal.* = lrec_new_campaignproposal.*
  LET mrec_campaignproposalgrid.crr_symbol = core_db.currency_get_symbol(lrec_campaign.cmp_currency_id)
  LET mrec_campaignproposalgrid.crr_symbol1 = mrec_campaignproposalgrid.crr_symbol
  LET mrec_db_campaign.* = lrec_campaign.*
  LET mrec_db_campaignproposal.* = lrec_new_campaignproposal.*
  CALL larec_new_proposeduserlist.copyTo(marec_proposeduserlist)
  RETURN 0, NULL
END FUNCTION

#+ Update the current proposed list of influencers by adding the ones that have applied to the campaign
#+
#+ @param pint_campaign_id proposal id
#+ @param pint_proposal_id proposal id
#+ @param parec_list list of influencer t_proposeduserlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_import_influencer_list(pint_campaign_id, pint_proposal_id, parec_list)
  DEFINE
    pint_campaign_id LIKE campaignproposals.cmpprp_campaign_id,
    pint_proposal_id LIKE campaignproposals.cmpprp_id,
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lrec_data0 RECORD LIKE users.*,
    lrec_data1 RECORD LIKE campaignuserlist.*,
    lrec_campaignproposeduser RECORD LIKE campaignproposedusers.*,
    i,j,uiorder INTEGER,
    larec_to_add DYNAMIC ARRAY OF t_proposeduserlist

  LET uiorder = _get_max_uiorder(parec_list)
  LET lstr_sql = "SELECT users.*, campaignuserlist.*"
  ," FROM users, campaignuserlist"
  ," WHERE campaignuserlist.cmpusrl_user_id = users.usr_id"
  ,SFMT(" AND campaignuserlist.cmpusrl_campaign_id = %1", pint_campaign_id)
  ," AND campaignuserlist.cmpusrl_isacceptbyuser = 1"
  ," AND campaignuserlist.cmpusrl_user_id NOT IN "
  ,"  (SELECT campaignproposedusers.cmpprpu_user_id"
  ,"  FROM campaignproposedusers"
  ,SFMT(" WHERE campaignproposedusers.cmpprpu_campaignproposal_id = %1", pint_proposal_id)
  ,")"
  ," ORDER BY campaignuserlist.cmpusrl_useranswerdate ASC"
  TRY
    DECLARE c_campaignproposal_import_influencer_list CURSOR FROM lstr_sql
    FOREACH c_campaignproposal_import_influencer_list
      INTO lrec_data0.*, lrec_data1.*
      IF _search_influencer(parec_list, lrec_data0.usr_id) == 0 THEN
        INITIALIZE lrec_campaignproposeduser.* TO NULL
        LET lrec_campaignproposeduser.cmpprpu_campaignproposal_id = pint_proposal_id
        LET lrec_campaignproposeduser.cmpprpu_user_id = lrec_data0.usr_id
        LET lrec_campaignproposeduser.cmpprpu_uiorder = (uiorder := uiorder + 10) --offset 10 is to reduce the number of later update due to drag&drop
        --lrec_campaignproposeduser.cmpprpu_isacceptedbybrand
        --lrec_campaignproposeduser.cmpprpu_comment
        --lrec_campaignproposeduser.cmpprpu_notificationdate
        LET lrec_campaignproposeduser.cmpprpu_usertotalprice = lrec_data1.cmpusrl_usertotalprice
        LET lrec_campaignproposeduser.cmpprpu_salfatixtotalprice = lrec_data1.cmpusrl_salfatixtotalprice
        CALL _add_to_list(pint_campaign_id, lrec_data0.*, lrec_campaignproposeduser.*, larec_to_add, larec_to_add.getLength()+1)
      END IF
    END FOREACH
    FREE c_campaignproposal_import_influencer_list
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  --add into database the added influencers
  FOR i = 1 TO larec_to_add.getLength()
    CALL core_db.campaignproposedusers_insert_row(larec_to_add[i].campaignproposeduser.*)
      RETURNING lint_ret, lstr_msg, larec_to_add[i].campaignproposeduser.cmpprpu_campaignproposal_id, larec_to_add[i].campaignproposeduser.cmpprpu_user_id
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET j = parec_list.getLength() + 1
    LET parec_list[j].* = larec_to_add[i].*
  END FOR
  RETURN 0, NULL
END FUNCTION

#+ Check business rules of a campaign proposal
#+
#+ @param prec_campaignproposalgrid proposal
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignproposal_validate_data(prec_campaignproposalgrid)
  DEFINE
    prec_campaignproposalgrid t_campaignproposalgrid
  IF prec_campaignproposalgrid.campaignproposal.cmpprp_id IS NULL THEN
    RETURN -1, %"Proposal Id missing"
  END IF
  IF prec_campaignproposalgrid.campaignproposal.cmpprp_campaign_id IS NULL THEN
    RETURN -1, %"Campaign Id missing"
  END IF
  IF prec_campaignproposalgrid.campaignproposal.cmpprp_status_id IS NULL THEN
    RETURN -1, %"Status Id missing"
  END IF
  IF prec_campaignproposalgrid.campaignproposal.cmpprp_price IS NULL OR prec_campaignproposalgrid.campaignproposal.cmpprp_price < 0 THEN
    RETURN -1, %"Proposed budget missing"
  END IF
  IF prec_campaignproposalgrid.campaignproposal.cmpprp_islast IS NULL OR prec_campaignproposalgrid.campaignproposal.cmpprp_islast==0 THEN
    RETURN -1, %"Inconsistent record"
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Process the data of business record fields (CRUD operations or UI operations)
#+
#+ @param p_dialog current DIALOG
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+ @param pint_dialog_action dialog action which triggered the operation
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_process_data(p_dialog, pbool_dialog_touched, pint_dialog_action)
  DEFINE
    p_dialog ui.Dialog,
    pbool_dialog_touched SMALLINT,
    pint_dialog_action SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.campaignproposals_update_row(mrec_db_campaignproposal.*, mrec_campaignproposalgrid.campaignproposal.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    LET mrec_db_campaignproposal.* = mrec_campaignproposalgrid.campaignproposal.*
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Update the campaign proposal to the brand
#+
#+ @param pint_proposalstatus_id new proposal status
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_update_proposal(pint_proposalstatus_id LIKE proposalstatus.prp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    i INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  CASE pint_proposalstatus_id
    WHEN C_PROPOSALSTATUS_SUBMITTED
      IF NOT campaignproposal_allow_submit(mrec_campaignproposalgrid.campaignproposal.cmpprp_status_id) THEN
        RETURN -1, %"Can not submit this proposal to the brand"
      END IF
      CALL campaignproposal_validate_data(mrec_campaignproposalgrid.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      IF marec_proposeduserlist.getLength()==0 THEN
        RETURN -1, %"Proposed influencers missing"
      END IF
      FOR i = 1 TO marec_proposeduserlist.getLength()
        CALL campaignproposedusergrid_validate_data(marec_proposeduserlist[i].campaignproposeduser.*)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          RETURN lint_ret, SFMT(%"Line %1 : %2",i,lstr_msg)
        END IF
      END FOR
    WHEN C_PROPOSALSTATUS_REJECTED
      IF NOT campaignproposal_allow_submittosalfatix() THEN
        RETURN -1, %"Can not reject a proposal where all influencers are accepted"
      END IF
    WHEN C_PROPOSALSTATUS_VALIDATED
      IF NOT campaignproposal_allow_acceptsalfatixproposal() THEN
        RETURN -1, %"Can not accept a proposal where all influencers are not accepted"
      END IF
  END CASE
  LET lint_ret = DB_START_TRANSACTION()
  LET l_timestamp = CURRENT
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET mrec_campaignproposalgrid.campaignproposal.cmpprp_status_id = pint_proposalstatus_id
  CASE pint_proposalstatus_id
    WHEN C_PROPOSALSTATUS_SUBMITTED --submit to brand
      LET mrec_campaignproposalgrid.campaignproposal.cmpprp_submitteddate = l_timestamp
    WHEN C_PROPOSALSTATUS_REJECTED --rejected by brand
      LET mrec_campaignproposalgrid.campaignproposal.cmpprp_rejecteddate = l_timestamp
    WHEN C_PROPOSALSTATUS_VALIDATED --validated by brand
      LET mrec_campaignproposalgrid.campaignproposal.cmpprp_validationdate = l_timestamp
  END CASE
  CALL core_db.campaignproposals_update_row(mrec_db_campaignproposal.*, mrec_campaignproposalgrid.campaignproposal.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    IF pint_proposalstatus_id == C_PROPOSALSTATUS_VALIDATED THEN
      LET mrec_campaignproposalgrid.campaign.cmp_campaignstatus_id = C_CAMPAIGNSTATUS_INFLUENCERS_VALIDATED
      LET mrec_campaignproposalgrid.campaign.cmp_lastupdatedate = l_timestamp
      CALL core_db.campaigns_update_row(mrec_db_campaign.*, mrec_campaignproposalgrid.campaign.*, l_timestamp)
        RETURNING lint_ret, lstr_msg
    END IF
  END IF
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  IF pint_proposalstatus_id == C_PROPOSALSTATUS_SUBMITTED THEN
    CALL notifications.sendmail_brand_check_campaign_proposal(mrec_campaignproposalgrid.campaign.cmp_id)
  END IF
  LET mrec_db_campaignproposal.* = mrec_campaignproposalgrid.campaignproposal.*
  LET mrec_db_campaign.* = mrec_campaignproposalgrid.campaign.*
  IF pint_proposalstatus_id == C_PROPOSALSTATUS_VALIDATED THEN --validated by brand
    CALL notifications.notif_influencers_brand_decision_for_proposal(mrec_campaignproposalgrid.campaign.cmp_id)
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Update the brand selection for the current campaign proposal
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_proposeduser_updateselection(p_dialog ui.Dialog, pbool_acceptinfluencer BOOLEAN)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lbool_rowselected BOOLEAN,
    i INTEGER,
    lrec_campaignproposeduser RECORD LIKE campaignproposedusers.*

  LET lbool_rowselected = FALSE
  FOR i = 1 TO marec_proposeduserlist.getLength()
    IF p_dialog.isRowSelected("scr_campaignproposedusers", i) THEN
      LET lbool_rowselected = TRUE
      IF (marec_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand IS NOT NULL) 
        AND (marec_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand == pbool_acceptinfluencer)
      THEN --no selection changement for this influencer so do nothing
        CONTINUE FOR
      END IF
      INITIALIZE lrec_campaignproposeduser.* TO NULL
      LET lrec_campaignproposeduser.* = marec_proposeduserlist[i].campaignproposeduser.*
      LET lrec_campaignproposeduser.cmpprpu_isacceptedbybrand = pbool_acceptinfluencer
      CALL campaignproposeduser_update_into_dabatase(lrec_campaignproposeduser.*, marec_proposeduserlist[i].campaignproposeduser.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      CALL campaignproposal_proposeduser_get_by_key(mrec_campaignproposalgrid.campaignproposal.cmpprp_campaign_id, lrec_campaignproposeduser.cmpprpu_campaignproposal_id, lrec_campaignproposeduser.cmpprpu_user_id, marec_proposeduserlist, i)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END IF
  END FOR
  IF NOT lbool_rowselected THEN
    RETURN -1, %"No selected influencer(s)"
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Update the uiorder of the proposed list of influencers
#+
#+ @param parec_list list of influencer t_proposeduserlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_update_uiorder(parec_list)
  DEFINE
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER,
    lrec_campaignproposeduser_db RECORD LIKE campaignproposedusers.*

  --add into database the added influencers
  FOR i = 2 TO parec_list.getLength()
    IF parec_list[i].campaignproposeduser.cmpprpu_uiorder <= parec_list[i-1].campaignproposeduser.cmpprpu_uiorder THEN
      LET lrec_campaignproposeduser_db.* = parec_list[i].campaignproposeduser.*
      LET parec_list[i].campaignproposeduser.cmpprpu_uiorder = parec_list[i-1].campaignproposeduser.cmpprpu_uiorder + 1
      CALL core_db.campaignproposedusers_update_row(lrec_campaignproposeduser_db.*, parec_list[i].campaignproposeduser.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END IF
  END FOR
  RETURN 0, NULL
END FUNCTION

#+ Delete a proposed user from the database
#+
#+ @param pint_proposal_id proposal id
#+ @param parec_list list of influencer t_proposeduserlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_delete_from_database(pint_proposal_id, pint_user_id)
  DEFINE
    pint_proposal_id LIKE campaignproposedusers.cmpprpu_campaignproposal_id,
    pint_user_id LIKE campaignproposedusers.cmpprpu_user_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.campaignproposedusers_delete_row(pint_proposal_id, pint_user_id)
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

#+ Update a proposed user of a campaign proposal
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, campaign user list id
FUNCTION campaignproposeduser_update_into_dabatase(prec_campaignproposeduser, prec_campaignproposeduser_db)
  DEFINE
    prec_campaignproposeduser RECORD LIKE campaignproposedusers.*,
    prec_campaignproposeduser_db RECORD LIKE campaignproposedusers.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.campaignproposedusers_update_row(prec_campaignproposeduser_db.*, prec_campaignproposeduser.*)
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

#+ Build and display the titles
#+
#+ @param pbool_display display the titles
#+
PRIVATE FUNCTION _campaignproposal_build_titles(pbool_display)
  DEFINE
    pbool_display BOOLEAN,
    ff_formtitle STRING
  LET ff_formtitle = SFMT(%"Influencers proposal (%1)", marec_proposeduserlist.getLength())
  IF pbool_display THEN
    DISPLAY BY NAME ff_formtitle
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

#+ Returns the maximum uiorder in the list
#+
#+ @returnType INTEGER
#+ @return     max uiorder
PRIVATE FUNCTION _get_max_uiorder(parec_list)
  DEFINE
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    i,s, max INTEGER

  LET max = 0
  LET s = parec_list.getLength()
  FOR i = 1 TO s
    IF parec_list[i].campaignproposeduser.cmpprpu_uiorder > max THEN
      LET max = parec_list[i].campaignproposeduser.cmpprpu_uiorder
    END IF
  END FOR
  RETURN max
END FUNCTION

#+ Get the index of the given influencer in the proposed list of influencers
#+
#+ @param parec_list proposed list of influencers
#+ @param pint_id influencer id
#+
#+ @returnType INTEGER
#+ @return     0 (not found), > 0 otherwise
PRIVATE FUNCTION _search_influencer(parec_list, pint_id)
  DEFINE
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    pint_id LIKE users.usr_id,
    i INTEGER
  FOR i = 1 TO parec_list.getLength()
    IF parec_list[i].user.usr_id == pint_id THEN
      RETURN i
    END IF
  END FOR
  RETURN 0
END FUNCTION

#+ Add a proposed infuencer in the given array
#+
#+ @param pint_campaign_id campaign id
#+ @param prec_user influencer record
#+ @param prec_campaignproposeduser proposed influencer record
#+ @param parec_list proposed list of influencers
#+ @param pint_index index in the proposed list of influencers
#+
PRIVATE FUNCTION _add_to_list(pint_campaign_id, prec_user, prec_campaignproposeduser, parec_list, pint_index)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    prec_user RECORD LIKE users.*,
    prec_campaignproposeduser RECORD LIKE campaignproposedusers.*,
    parec_list DYNAMIC ARRAY OF t_proposeduserlist,
    pint_index INTEGER,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_usermetrics RECORD LIKE usermetrics.*

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
  LET parec_list[pint_index].campaignproposeduser.* = prec_campaignproposeduser.*
  LET parec_list[pint_index].user.* = prec_user.*
  LET parec_list[pint_index].usr_instagram_profilepicture = _get_default_photo(prec_user.usr_instagram_profilepicture)
  LET parec_list[pint_index].delimage = "delete"
  LET parec_list[pint_index].viewimage = "fa-eye"
  LET parec_list[pint_index].editimage = "fa-pencil"
END FUNCTION

#+ Update proposed user of a campaign proposal
#+
#+ @param prec_proposedusergrid proposed user
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignproposedusergrid_input(prec_proposedusergrid)
  DEFINE
    prec_proposedusergrid t_proposedusergrid,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_CANCEL
  LET ff_formtitle = %"Edit influencer proposal"
  CALL FGL_SETTITLE(ff_formtitle)

  OPEN WINDOW w_campaignuserlist_grid WITH FORM "campaignproposeduser_grid"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT prec_proposedusergrid.* FROM scr_proposedusergrid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION save
      CALL campaignproposedusergrid_validate_data(prec_proposedusergrid.campaignproposeduser.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    BEFORE DIALOG
      CALL campaignproposedusergrid_ui_set_action_state(DIALOG)
  END DIALOG
  CLOSE WINDOW w_campaignuserlist_grid
  RETURN lint_ret, lint_action, prec_proposedusergrid.*
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignproposedusergrid_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.Dialog

  CALL layout.display_savebutton(TRUE)
END FUNCTION

#+ Check business rules of a campaign proposed user
#+
#+ @param prec_proposeduser proposed user record
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignproposedusergrid_validate_data(prec_proposeduser)
  DEFINE
    prec_proposeduser RECORD LIKE campaignproposedusers.*

  IF prec_proposeduser.cmpprpu_campaignproposal_id IS NULL OR prec_proposeduser.cmpprpu_campaignproposal_id==0 THEN
    RETURN -1, %"Proposal Id missing"
  END IF
  IF prec_proposeduser.cmpprpu_user_id IS NULL OR prec_proposeduser.cmpprpu_user_id==0 THEN
    RETURN -1, %"User Id missing"
  END IF
  IF prec_proposeduser.cmpprpu_uiorder IS NULL THEN
    RETURN -1, %"Order missing"
  END IF
  IF prec_proposeduser.cmpprpu_usertotalprice IS NULL OR prec_proposeduser.cmpprpu_usertotalprice < 0 THEN
    RETURN -1, %"Influencer price missing"
  END IF
  IF prec_proposeduser.cmpprpu_salfatixtotalprice IS NULL OR prec_proposeduser.cmpprpu_salfatixtotalprice < 0 THEN
    RETURN -1, %"Salfatix price missing"
  END IF
  IF prec_proposeduser.cmpprpu_salfatixtotalprice < prec_proposeduser.cmpprpu_usertotalprice THEN
    RETURN -1, %"Inconsistent prices"
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Get prices string for decisional making
#+
#+ @param pint_campaign_id campaign id
#+ @param prec_user influencer record
#+ @param prec_campaignproposeduser proposed influencer record
#+ @param parec_list proposed list of influencers
#+
--PRIVATE FUNCTION _get_prices_string(pint_campaign_id, pint_usr_id)
  --DEFINE
    --pint_campaign_id LIKE campaigns.cmp_id,
    --pint_usr_id LIKE users.usr_id,
    --lint_ret INTEGER,
    --lstr_msg STRING,
    --lstr_sql STRING,
    --lstr_tmp STRING,
    --lstr_usrprice STRING,
    --lstr_salfatixprice STRING,
    --posttype_name LIKE posttypes.pstt_name,
    --campaignposttypes_cmppst_quantity LIKE campaignposttypes.cmppst_quantity,
    --campaignuserprices_cmpusrp_price LIKE campaignuserprices.cmpusrp_price,
    --campaignuserprices_cmpusrp_freeofcharge LIKE campaignuserprices.cmpusrp_freeofcharge,
    --lrec_userpostprice RECORD LIKE userpostprices.* ,
    --lstr_salfatixpricerange STRING,
    --d1,d2 LIKE campaignuserprices.cmpusrp_price,
    --salfatixtotalrangemin,salfatixtotalrangemax LIKE campaignuserprices.cmpusrp_price
--
  --LET lstr_sql = "SELECT posttypes.pstt_name, campaignposttypes.cmppst_quantity, campaignuserprices.cmpusrp_price, campaignuserprices.cmpusrp_freeofcharge, userpostprices.*"
    --," FROM campaignuserprices, campaignposttypes, posttypes, userpostprices"
    --," WHERE campaignuserprices.cmpusrp_campaign_id = campaignposttypes.cmppst_campaign_id"
    --,SFMT(" AND campaignuserprices.cmpusrp_campaign_id = %1", pint_campaign_id)
    --,SFMT(" AND campaignuserprices.cmpusrp_usr_id = %1", pint_usr_id)
    --," AND campaignuserprices.cmpusrp_posttype_id = campaignposttypes.cmppst_posttype_id"
    --," AND campaignuserprices.cmpusrp_posttype_id = posttypes.pstt_id"
    --get default prices for the influencer
    --,SFMT(" AND userpostprices.usrpp_usr_id = %1", pint_usr_id)
    --," AND userpostprices.usrpp_posttype_id = campaignuserprices.cmpusrp_posttype_id"
    --," ORDER BY posttypes.pstt_uiorder"
  --LET salfatixtotalrangemin = 0
  --LET salfatixtotalrangemax = 0
  --TRY
    --DECLARE c_get_prices_string CURSOR FROM lstr_sql
    --FOREACH c_get_prices_string
      --INTO posttype_name, campaignposttypes_cmppst_quantity, campaignuserprices_cmpusrp_price, campaignuserprices_cmpusrp_freeofcharge, lrec_userpostprice.*
      --LET lstr_tmp = SFMT("%1 (%2)", posttype_name, campaignposttypes_cmppst_quantity)
      --LET d1 = lrec_userpostprice.usrpp_salfatixminprice * campaignposttypes_cmppst_quantity
      --LET d2 = lrec_userpostprice.usrpp_salfatixmaxprice * campaignposttypes_cmppst_quantity
      --LET salfatixtotalrangemin = d1 + salfatixtotalrangemin
      --LET salfatixtotalrangemax = d2 + salfatixtotalrangemax
      --LET lstr_salfatixpricerange = SFMT("[%1 - %2]", d1, d2)
      --LET lstr_usrprice = string.concat_with_delim(lstr_usrprice, SFMT("%1 : %2", lstr_tmp, IIF(campaignuserprices_cmpusrp_freeofcharge, %"Free", campaignuserprices_cmpusrp_price)), "\n")
      --LET lstr_salfatixprice = string.concat_with_delim(lstr_salfatixprice, SFMT("%1 : %2", lstr_tmp, IIF((campaignuserprices_cmpusrp_freeofcharge AND lrec_userpostprice.usrpp_salfatixfreeofcharge), %"Free", lstr_salfatixpricerange)), "\n")
    --END FOREACH
    --LET lstr_salfatixprice = string.concat_with_delim(lstr_salfatixprice, SFMT("Total range price : [%1 - %2]", salfatixtotalrangemin, salfatixtotalrangemax), "\n")
    --FREE c_get_prices_string
  --CATCH
    --LET lint_ret = SQLCA.SQLCODE
    --LET lstr_msg = SQLERRMESSAGE
    --RETURN NULL, NULL
  --END TRY
  --RETURN lstr_usrprice, lstr_salfatixprice
--END FUNCTION

#+ Checks if a campaign proposal can be submitted to brand
#+
#+ @param pint_status_id proposal status id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignproposal_allow_submit(pint_status_id)
  DEFINE
    pint_status_id LIKE campaignproposals.cmpprp_status_id

  IF setup.g_app_backoffice THEN
    IF pint_status_id == C_PROPOSALSTATUS_CREATED THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a campaign proposal and its proposed influencers can be rejected by a brand
#+
#+ @param pint_status_id proposal status id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignproposal_allow_submittosalfatix()
  DEFINE
    i INTEGER
  IF marec_proposeduserlist.getLength()==0 THEN
    RETURN TRUE
  END IF
  FOR i = 1 TO marec_proposeduserlist.getLength()
    IF marec_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand == 1 THEN
    ELSE --we have at least one influencer who is not validated or whose there is no decision made yet
      RETURN TRUE
    END IF
  END FOR
  RETURN FALSE
END FUNCTION

#+ Checks if a campaign proposal and its proposed influencers can be accepted by a brand
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if allowed, FALSE otherwise
FUNCTION campaignproposal_allow_acceptsalfatixproposal()
  DEFINE
    i INTEGER
  IF marec_proposeduserlist.getLength()==0 THEN
    RETURN FALSE
  END IF
  FOR i = 1 TO marec_proposeduserlist.getLength()
    IF marec_proposeduserlist[i].campaignproposeduser.cmpprpu_isacceptedbybrand == 1 THEN
    ELSE --we have at least one influencer who is not validated or whose there is no decision made yet
      RETURN FALSE
    END IF
  END FOR
  RETURN TRUE
END FUNCTION

#+ Checks if a salfatix user can export the list of influencers for a campaign
#+
#+ @param pint_campaign_status_id campaign status id
#+ @param pint_proposalstatus_id proposal status id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignproposal_allow_exportlist(pint_campaign_status_id LIKE campaigns.cmp_campaignstatus_id, pint_proposalstatus_id LIKE proposalstatus.prp_id)
  IF setup.g_app_backoffice THEN
    IF pint_campaign_status_id == C_CAMPAIGNSTATUS_FULLY_PAID THEN
      IF pint_proposalstatus_id == C_PROPOSALSTATUS_VALIDATED THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Export the proposal list to send to accounting to pay the influencers
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignproposal_export_list()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER,
    larec_users DYNAMIC ARRAY OF RECORD LIKE users.*,
    larec_campaignproposedusers DYNAMIC ARRAY OF RECORD LIKE campaignproposedusers.*,
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
      cmpprpu_usertotalprice LIKE campaignproposedusers.cmpprpu_usertotalprice ATTRIBUTE(XMLNillable, XMLName="Price"),
      crr_name LIKE currencies.crr_name ATTRIBUTE(XMLNillable, XMLName="Currency")
    END RECORD,
    lstr_server_filename STRING,
    lstr_client_filename STRING,
    doc xml.DomDocument,
    node xml.DomNode

  CALL core_db.get_campaign_last_proposed_influencers(mrec_campaignproposalgrid.campaign.cmp_id, larec_users, larec_campaignproposedusers)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
  CALL core_db.currency_select_row(mrec_campaignproposalgrid.campaign.cmp_currency_id, FALSE)
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
    LET larec_data[i].cmpprpu_usertotalprice = larec_campaignproposedusers[i].cmpprpu_usertotalprice
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