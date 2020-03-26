IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL zoom_category
IMPORT FGL zoom_posttype
IMPORT FGL zoom_gender
IMPORT FGL campaignlocations
IMPORT FGL campaignpublications
IMPORT FGL campaignposttypes
IMPORT FGL campaignposts
IMPORT FGL campaignprices
IMPORT FGL notifications
IMPORT FGL layout

SCHEMA salfatixmedia

PUBLIC CONSTANT
  C_CAMPAIGNMENU_ALLGROUPS SMALLINT = 0,
  C_CAMPAIGNMENU_DETAILS SMALLINT = 1,
  C_CAMPAIGNMENU_INFLUENCERS SMALLINT = 2,
  C_CAMPAIGNMENU_PRODUCT SMALLINT = 3,
  C_CAMPAIGNMENU_CONTENT SMALLINT = 4,
  C_CAMPAIGNMENU_TAGS SMALLINT = 5,
  C_CAMPAIGNMENU_SCHEDULE SMALLINT = 6

TYPE
  t_campaignmenu_list RECORD
    firstline STRING,
    secondline STRING,
    myimage STRING,
    firstlinedefaulttitle STRING,
    secondlinedefaulttitle STRING
  END RECORD

TYPE
  t_campaignlistqbeinput RECORD
    sortby STRING,
    orderby STRING
  END RECORD

TYPE
  t_campaignlist RECORD
    campaign RECORD LIKE campaigns.*,
    pic_value LIKE pics.pic_value,
    brnd_name LIKE brands.brnd_name,
    campaignstatus_name LIKE campaignstatus.cmpst_name
  END RECORD
TYPE
  t_campaigngrid RECORD
    campaign RECORD LIKE campaigns.*,
    pic_value LIKE pics.pic_value,
    campaign_genders STRING,
    campaign_categories STRING,
    campaign_posttypes STRING,
    pic_id1 LIKE pics.pic_id,
    pic_value1 LIKE pics.pic_value,
    pic_id2 LIKE pics.pic_id,
    pic_value2 LIKE pics.pic_value,
    pic_id3 LIKE pics.pic_id,
    pic_value3 LIKE pics.pic_value,
    instagram_usertag STRING,
    instagram_hashtag STRING,
    crr_symbol LIKE currencies.crr_name, --currency symbol next to campaign budget
    crr_symbol1 LIKE currencies.crr_name, --currency symbol next to product
    campaign_countries STRING,
    campaign_states STRING,
    campaign_cities STRING
  END RECORD

TYPE
  t_campaignpricegrid RECORD
    campaign RECORD LIKE campaigns.*,
    influencersestimatedcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    brandestimatedcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    influencerscost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    brandcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    alreadypaidtoinfluencers LIKE campaignuserlist.cmpusrl_salfatixtotalprice
  END RECORD

DEFINE
  m_dialogtouched SMALLINT
DEFINE --menu data
  marec_campaignmenu DYNAMIC ARRAY OF t_campaignmenu_list
DEFINE --list qbe data
  mrec_campaignlistqbeinput t_campaignlistqbeinput

DEFINE --list data
  marec_campaignlist DYNAMIC ARRAY OF t_campaignlist
DEFINE --grid data
  mint_campaign_id LIKE campaigns.cmp_id,
  mrec_campaigngrid t_campaigngrid,
  marec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
  marec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
  mrec_copy_campaigngrid t_campaigngrid,
  mrec_db_campaign RECORD LIKE campaigns.*,
  mint_workinggroup_id SMALLINT

DEFINE
  mstr_campaignlist_default_title STRING

#+ Fetch and display the list campaigns
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignlist_open_form(pstr_where, pstr_orderby, pstr_title)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_campaign_id LIKE campaigns.cmp_id,
    i INTEGER,
    frontcall_return STRING,
    lint_action SMALLINT

  LET mstr_campaignlist_default_title = IIF(setup.g_app_brand,NULL,%"Campaigns")
  LET lint_action = C_APPACTION_UNDEFINED
  CALL campaignlist_get_data(NULL, pstr_where, pstr_orderby, marec_campaignlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    IF marec_campaignlist.getLength() == 0 THEN
      OPEN WINDOW w_campaign_empty WITH FORM "campaign_empty"
      CALL campaignlist_empty()
        RETURNING lint_ret, lint_action
      CLOSE WINDOW w_campaign_empty
    ELSE
      OPEN WINDOW w_campaign_list WITH FORM "campaign_list"
      CALL campaignlist_display(pstr_title)
        RETURNING lint_ret, lint_action
      CLOSE WINDOW w_campaign_list
    END IF
  END IF
  IF lint_action == C_APPACTION_ADDCAMPAIGN THEN
    CALL campaigngrid_open_form_by_key(0, C_APPSTATE_ADD, C_CAMPAIGNMENU_ALLGROUPS)
    --CALL campaignmenu_open_form_by_key(0, C_APPSTATE_ADD)
      RETURNING lint_ret, lint_action, lint_campaign_id
    CALL core_automaton.update_webmenu(setup.g_frontcall_module,"campaignlist_page", setup.g_loggedin_name) RETURNING frontcall_return
    IF lint_ret == 0 THEN
      IF lint_action == C_APPACTION_ACCEPT OR lint_action == C_APPACTION_CANCEL THEN
        LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      END IF
    END IF
  END IF

  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog an empty campaign list
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignlist_empty()
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT,
    ff_formtitle STRING,
    frontcall_return STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = IIF(setup.g_app_brand,NULL,%"Campaigns")
  CALL FGL_SETTITLE(ff_formtitle)
  MENU ""
    ON ACTION addcampaign
      LET lint_ret = 0
      LET lint_action = C_APPACTION_ADDCAMPAIGN
      EXIT MENU
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT MENU
    BEFORE MENU
      CALL DIALOG.setActionHidden("customaction", TRUE)
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"campaignlist_page", setup.g_loggedin_name) RETURNING frontcall_return
  END MENU
  RETURN lint_ret, lint_action
END FUNCTION

#+ Display the list of campaigns
#+
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignlist_display(pstr_title)
  DEFINE
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    lint_campaign_id LIKE campaigns.cmp_id,
    i INTEGER,
    frontcall_return STRING,
    lstr_sql_from_clause STRING,
    lstr_sql_where_clause STRING,
    lstr_sql_orderby_clause STRING,
    lstr_sql_where STRING,
    lint_campaigngridstate SMALLINT

  LET lint_action = C_APPACTION_UNDEFINED
  IF pstr_title IS NULL THEN
    LET pstr_title = mstr_campaignlist_default_title
  END IF
  LET ff_formtitle = pstr_title
  CALL FGL_SETTITLE(ff_formtitle)

  LET mrec_campaignlistqbeinput.sortby = campaignlist_get_default_sortby()
  LET mrec_campaignlistqbeinput.orderby = campaignlist_get_default_orderby()

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaignlistqbeinput.* FROM scr_qbeinput.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    CONSTRUCT lstr_sql_where
      ON
        brands.brnd_name,
        campaigns.cmp_title,
        campaignstatus.cmpst_name
      FROM scr_qbeconstruct.*
      BEFORE CONSTRUCT
    END CONSTRUCT
    DISPLAY ARRAY marec_campaignlist TO scr_campaign_list.*
    END DISPLAY
    ON ACTION filter
      --DISPLAY CURRENT, " qbe=", lstr_sql_where
      --DISPLAY "mrec_campaignlistqbeinput.sortby = ",mrec_userlistqbeinput.sortby
      --DISPLAY "mrec_campaignlistqbeinput.orderby = ",mrec_userlistqbeinput.orderby
      IF lstr_sql_where.getLength() == 0 THEN
       LET lstr_sql_where = " 1=1"
      END IF
      LET lstr_sql_from_clause = " campaigns"
      LET lstr_sql_where_clause = lstr_sql_where
      IF lstr_sql_where.getIndexOf("brands.brnd_name", 1) > 0
        OR mrec_campaignlistqbeinput.sortby == "brands.brnd_name"
      THEN
        LET lstr_sql_from_clause = SFMT("%1, brands", lstr_sql_from_clause)
        LET lstr_sql_where_clause = lstr_sql_where_clause
          ," AND campaigns.cmp_brand_id = brands.brnd_id"
      END IF
      IF lstr_sql_where.getIndexOf("campaignstatus.cmpst_name", 1) > 0
        OR mrec_campaignlistqbeinput.sortby == "campaignstatus.cmpst_name"
      THEN
        LET lstr_sql_from_clause = SFMT("%1, campaignstatus", lstr_sql_from_clause)
        LET lstr_sql_where_clause = lstr_sql_where_clause
          ," AND campaigns.cmp_campaignstatus_id = campaignstatus.cmpst_id"
      END IF
      LET lstr_sql_orderby_clause = SFMT("%1 %2",mrec_campaignlistqbeinput.sortby, mrec_campaignlistqbeinput.orderby)

      CALL campaignlist_get_data(lstr_sql_from_clause, lstr_sql_where_clause,lstr_sql_orderby_clause, marec_campaignlist)
        RETURNING lint_ret, lstr_msg
      CALL display_campaignlist_default_title()
    ON ACTION display_campaign
      LET i = DIALOG.getCurrentRow("scr_campaign_list")
      IF i > 0 THEN
        --brand or salfatix edition
        LET lint_campaigngridstate = C_APPSTATE_UPDATE
        IF NOT campaign_allow_edition(marec_campaignlist[i].campaign.cmp_campaignstatus_id) THEN
          LET lint_campaigngridstate = C_APPSTATE_DISPLAY
        END IF
        CALL campaigngrid_open_form_by_key(marec_campaignlist[i].campaign.cmp_id, lint_campaigngridstate, C_CAMPAIGNMENU_ALLGROUPS)
          RETURNING lint_ret, lint_action, lint_campaign_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"campaignlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action <> C_APPACTION_VIEWCAMPAIGNS AND lint_action <> C_APPACTION_CANCEL THEN
            EXIT DIALOG
          END IF
          CALL campaignlist_get_data_by_key(lint_campaign_id, marec_campaignlist, i)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
          END IF
          CALL campaignlist_ui_set_action_state(DIALOG)
          CALL display_campaignlist_default_title()
        END IF
      END IF
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DIALOG
    BEFORE DIALOG
      CALL campaignlist_ui_set_action_state(DIALOG)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"campaignlist_page", setup.g_loggedin_name) RETURNING frontcall_return
  END DIALOG
  RETURN lint_ret, lint_action
END FUNCTION

#+ Get the campaign list data
#+
#+ @param pstr_from SQL FROM clause to select data
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of campaigns t_campaignlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_campaignlist,
    lstr_sql STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_campaign_id LIKE campaigns.cmp_id

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM campaigns"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT campaigns.cmp_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_campaignlist_get_data CURSOR FROM lstr_sql
    FOREACH c_campaignlist_get_data
      INTO lint_campaign_id
      CALL campaignlist_get_data_by_key(lint_campaign_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END FOREACH
    FREE c_campaignlist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the campaign list data for a given row
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_list list of campaigns t_campaignlist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_data_by_key(pint_campaign_id, parec_list, pint_index)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_list DYNAMIC ARRAY OF t_campaignlist,
    pint_index INTEGER,
    lstr_sql STRING,
    lrec_data t_campaignlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_pic RECORD LIKE pics.*

  --get campaign data
  LET lstr_sql = "SELECT campaigns.*, brands.brnd_name, campaignstatus.cmpst_name"
    ," FROM campaigns, brands, campaignstatus"
    ," WHERE campaigns.cmp_brand_id = brands.brnd_id"
    ," AND campaigns.cmp_campaignstatus_id = campaignstatus.cmpst_id"
    ,SFMT(" AND campaigns.cmp_id = %1", pint_campaign_id)
  TRY
    PREPARE p_campaignlist_get_data_by_key FROM lstr_sql
    EXECUTE p_campaignlist_get_data_by_key
      INTO lrec_data.campaign.*, lrec_data.brnd_name, lrec_data.campaignstatus_name
    CALL core_db.pics_select_row(lrec_data.campaign.cmp_pic_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_pic.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET parec_list[pint_index].campaign.* = lrec_data.campaign.*
    LET parec_list[pint_index].brnd_name = lrec_data.brnd_name
    LET parec_list[pint_index].campaignstatus_name = lrec_data.campaignstatus_name
    LET parec_list[pint_index].pic_value = lrec_pic.pic_value
    FREE p_campaignlist_get_data_by_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignlist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.Dialog
  CALL p_dialog.setActionActive("display_campaign", (marec_campaignlist.getLength()>0))
  CALL p_dialog.setActionHidden("customaction", TRUE)
  IF setup.g_app_brand THEN
    CALL core_ui.ui_set_node_attribute("Group","name","filtergroup","hidden", "1")
  END IF
END FUNCTION

#+ Fetch and display campaigns
#+
#+ @param pint_campaign_id current campaign
#+ @param pint_state current state invoked
#+ @param pint_displaygroup_id indicates which group to display in the grid
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaigngrid_open_form_by_key(pint_campaign_id, pint_state, pint_displaygroup_id)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_state SMALLINT,
    pint_displaygroup_id SMALLINT,
    lint_ret INTEGER,
    lint_action INTEGER

  LET mint_workinggroup_id = pint_displaygroup_id
  LET mint_campaign_id = pint_campaign_id
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_campaign_grid WITH FORM "campaign_grid"
  CASE pint_state
    WHEN C_APPSTATE_DISPLAY
      CALL campaigngrid_display() RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_ADD
      CALL campaigngrid_create() RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL campaigngrid_update() RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_campaign_grid
  RETURN lint_ret, lint_action, mint_campaign_id
END FUNCTION

#+ Dialog of the campaign display
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaigngrid_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    frontcall_return STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Campaign"
  CALL FGL_SETTITLE(ff_formtitle)
  LET m_dialogtouched = FALSE
  CALL campaigngrid_initialize_data(mint_campaign_id, C_DIALOGSTATE_DISPLAY)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  MENU ""
    BEFORE MENU
      LET m_dialogtouched = FALSE
      CALL campaigngrid_ui_set_action_state(DIALOG, C_DIALOGSTATE_DISPLAY, m_dialogtouched)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"campaignmenu_page", setup.g_loggedin_name) RETURNING frontcall_return
      CALL campaignstatus_combobox_initializer()
      CALL formatdecimal(mrec_campaigngrid.campaign.cmp_totalbudget,"campaigns.cmp_totalbudget","######&.&&","######&")
      DISPLAY mrec_campaigngrid.* TO scr_campaign_grid.*
    ON ACTION deletecampaign
      CALL campaigngrid_process_data(DIALOG, C_DIALOGSTATE_DISPLAY, m_dialogtouched, C_APPACTION_CAMPAIGN_DELETE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE MENU
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT MENU
    ON ACTION editpublication
      CALL campaignpublications.campaignpublication_open_form_by_key(mrec_campaigngrid.campaign.cmp_id)
        RETURNING lint_ret, lstr_msg, lint_action
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE MENU
      END IF
      CASE lint_action
        WHEN C_APPACTION_ACCEPT
          CALL campaigngrid_initialize_data(mrec_campaigngrid.campaign.cmp_id, C_DIALOGSTATE_DISPLAY)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            RETURN lint_ret, lstr_msg
          END IF
          --reset UI
          LET m_dialogtouched = FALSE
          CALL campaigngrid_ui_set_action_state(DIALOG, C_DIALOGSTATE_DISPLAY, m_dialogtouched)
        WHEN C_APPACTION_CANCEL --stay in dialog
        OTHERWISE --custom action
          EXIT MENU
      END CASE
    ON ACTION customaction
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT MENU
    ON ACTION cancel
      LET lint_action = C_APPACTION_CANCEL
      EXIT MENU
  END MENU
  RETURN lint_ret, lint_action
END FUNCTION

#+ Create a campaign
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaigngrid_create()
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL campaigngrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a campaign
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaigngrid_update()
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL campaigngrid_input(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lint_action
    --we want to stay in the influencer edition
    IF lint_ret == 0 AND lint_action == C_APPACTION_ACCEPT THEN
      LET lbool_exit = FALSE
    END IF
  END WHILE
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the campaign input
#+
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaigngrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    larec_genders DYNAMIC ARRAY OF RECORD LIKE genders.*,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    ff_formtitle STRING,
    frontcall_return STRING,
    lint_action_tmp SMALLINT

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = IIF(pint_dialog_state==C_DIALOGSTATE_ADD, %"Create Campaign",%"Edit Campaign")
  IF mint_workinggroup_id IS NOT NULL AND mint_workinggroup_id <> C_CAMPAIGNMENU_ALLGROUPS THEN
    LET ff_formtitle = SFMT("%1 - %2", ff_formtitle, marec_campaignmenu[mint_workinggroup_id].firstlinedefaulttitle)
  END IF
  CALL FGL_SETTITLE(ff_formtitle)

  LET m_dialogtouched = FALSE
  CALL campaigngrid_initialize_data(mint_campaign_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaigngrid.* FROM scr_campaign_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL campaignstatus_combobox_initializer()

      ON CHANGE cmp_issharedonfacebook
        IF mrec_campaigngrid.campaign.cmp_issharedonfacebook == 0 THEN
          INITIALIZE mrec_campaigngrid.campaign.cmp_sharedfacebooklink TO NULL
        END IF
        CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      ON CHANGE cmp_prd_value
        IF mrec_campaigngrid.campaign.cmp_prd_value IS NOT NULL THEN
          CALL formatdecimal(mrec_campaigngrid.campaign.cmp_prd_value,"campaigns.cmp_prd_value","######&.&&","######&")
        END IF

      ON CHANGE cmp_totalbudget
        IF mrec_campaigngrid.campaign.cmp_totalbudget IS NOT NULL THEN
          CALL formatdecimal(mrec_campaigngrid.campaign.cmp_totalbudget,"campaigns.cmp_totalbudget","######&.&&","######&")
        END IF

      AFTER INPUT
      ON CHANGE cmp_brand_id
        IF mrec_campaigngrid.campaign.cmp_brand_id IS NOT NULL AND mrec_campaigngrid.campaign.cmp_brand_id > 0 THEN
          LET mrec_campaigngrid.campaign.cmp_currency_id = get_brand_currency(mrec_campaigngrid.campaign.cmp_brand_id)
          LET mrec_campaigngrid.crr_symbol = core_db.currency_get_symbol(mrec_campaigngrid.campaign.cmp_currency_id)
          LET mrec_campaigngrid.crr_symbol1 = mrec_campaigngrid.crr_symbol
        END IF
      ON ACTION zoom_posttype
        CALL campaignposttypes.open_posttypes(mrec_campaigngrid.campaign.cmp_id, marec_campaignposttypes)
          RETURNING lint_ret, lstr_msg, lint_action_tmp
        IF lint_ret == 0 THEN
          IF lint_action_tmp == C_APPACTION_ACCEPT THEN
            LET mrec_campaigngrid.campaign_posttypes = campaignposttypes.serialize_campaignposttypes(marec_campaignposttypes)
            LET m_dialogtouched = TRUE
            CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
          END IF
        END IF
      ON ACTION zoom
        IF INFIELD(campaign_genders) THEN
          CALL string.deserialize_genders(mrec_campaigngrid.campaign_genders, larec_genders)
            RETURNING lint_ret, lstr_msg
          IF lint_ret == 0 THEN
            CALL zoom_gender.display(larec_genders)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              LET mrec_campaigngrid.campaign_genders = string.serialize_genders(larec_genders)
              LET m_dialogtouched = TRUE
              CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF
        IF INFIELD(campaign_categories) THEN
          CALL string.deserialize_categories(mrec_campaigngrid.campaign_categories, larec_categories)
            RETURNING lint_ret, lstr_msg
          IF lint_ret == 0 THEN
            CALL zoom_category.display(larec_categories, setup.g_app_backoffice, NULL, TRUE)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              LET mrec_campaigngrid.campaign_categories = string.serialize_categories(larec_categories)
              LET m_dialogtouched = TRUE
              CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF
        IF INFIELD(campaign_countries) THEN
          CALL campaignlocations.display_countries(mrec_campaigngrid.campaign.cmp_id, marec_campaignlocations)
            RETURNING lint_ret, lstr_msg, lint_action_tmp
          IF lint_ret == 0 THEN
            IF lint_action_tmp == C_APPACTION_ACCEPT THEN
              CALL campaignlocations.serialize(marec_campaignlocations)
                RETURNING mrec_campaigngrid.campaign_countries, mrec_campaigngrid.campaign_states, mrec_campaigngrid.campaign_cities
              LET m_dialogtouched = TRUE
              CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF
        IF INFIELD(campaign_states) THEN
          CALL campaignlocations.display_states(marec_campaignlocations)
            RETURNING lint_ret, lstr_msg, lint_action_tmp
          IF lint_ret == 0 THEN
            IF lint_action_tmp == C_APPACTION_ACCEPT THEN
              CALL campaignlocations.serialize(marec_campaignlocations)
                RETURNING mrec_campaigngrid.campaign_countries, mrec_campaigngrid.campaign_states, mrec_campaigngrid.campaign_cities
              LET m_dialogtouched = TRUE
              CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF
        IF INFIELD(campaign_cities) THEN
          CALL campaignlocations.display_cities(marec_campaignlocations)
            RETURNING lint_ret, lstr_msg, lint_action_tmp
          IF lint_ret == 0 THEN
            IF lint_action_tmp == C_APPACTION_ACCEPT THEN
              CALL campaignlocations.serialize(marec_campaignlocations)
                RETURNING mrec_campaigngrid.campaign_countries, mrec_campaigngrid.campaign_states, mrec_campaigngrid.campaign_cities
              LET m_dialogtouched = TRUE
              CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF
    END INPUT
    ON ACTION upload_photo
      LET lint_ret = core_ui.ui_upload_image(mrec_campaigngrid.pic_value)
      IF lint_ret == 0 THEN
        LET mrec_campaigngrid.campaign.cmp_pic_id = 0 --trick for mark the picture as touched
        LET m_dialogtouched = TRUE
        CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF
    ON ACTION upload_photo1
      LET lint_ret = core_ui.ui_upload_image(mrec_campaigngrid.pic_value1)
      IF lint_ret == 0 THEN
        LET mrec_campaigngrid.pic_id1 = 0 --trick for mark the picture as touched
        LET m_dialogtouched = TRUE
        CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF
    ON ACTION upload_photo2
      LET lint_ret = core_ui.ui_upload_image(mrec_campaigngrid.pic_value2)
      IF lint_ret == 0 THEN
        LET mrec_campaigngrid.pic_id2 = 0 --trick for mark the picture as touched
        LET m_dialogtouched = TRUE
        CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF
    ON ACTION upload_photo3
      LET lint_ret = core_ui.ui_upload_image(mrec_campaigngrid.pic_value3)
      IF lint_ret == 0 THEN
        LET mrec_campaigngrid.pic_id3 = 0 --trick for mark the picture as touched
        LET m_dialogtouched = TRUE
        CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF
    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    ON ACTION save
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION cancel
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    ON ACTION submitcampaign
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CAMPAIGN_SUBMIT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT DIALOG
    ON ACTION deletecampaign
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CAMPAIGN_DELETE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT DIALOG
    ON ACTION reviewcampaign
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CAMPAIGN_REVIEW)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT DIALOG
    ON ACTION validatecampaign
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CAMPAIGN_VALIDATE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      ELSE
        CALL notifications.sendmail_brand_campaign_validated(mrec_campaigngrid.campaign.cmp_id)
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT DIALOG
    ON ACTION editprice
      --save first before publication
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      CALL campaignprices.campaignpricegrid_open_form_by_key(mrec_campaigngrid.campaign.cmp_id, C_APPSTATE_UPDATE)
        RETURNING lint_ret, lint_action
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      CASE lint_action
        WHEN C_APPACTION_ACCEPT
          CALL campaigngrid_initialize_data(mrec_campaigngrid.campaign.cmp_id, pint_dialog_state)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            RETURN lint_ret, lstr_msg
          END IF
          --reset UI
          LET m_dialogtouched = FALSE
          CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
          CALL DIALOG.setFieldTouched("scr_campaign_grid.*", FALSE) --reset the 'touched' flag
        WHEN C_APPACTION_CANCEL --stay in dialog
        OTHERWISE --custom action
          EXIT DIALOG
      END CASE
    ON ACTION editpublication
      --save first before publication
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      CALL campaignpublications.campaignpublication_open_form_by_key(mrec_campaigngrid.campaign.cmp_id)
        RETURNING lint_ret, lstr_msg, lint_action
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      CASE lint_action
        WHEN C_APPACTION_ACCEPT
          CALL campaigngrid_initialize_data(mrec_campaigngrid.campaign.cmp_id, pint_dialog_state)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            RETURN lint_ret, lstr_msg
          END IF
          --reset UI
          LET m_dialogtouched = FALSE
          CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
          CALL DIALOG.setFieldTouched("scr_campaign_grid.*", FALSE) --reset the 'touched' flag
        WHEN C_APPACTION_CANCEL --stay in dialog
        OTHERWISE --custom action
          EXIT DIALOG
      END CASE
    ON ACTION askinfluencersstat
      CALL campaigngrid_askinfluencersstatistics(mrec_campaigngrid.campaign.cmp_id)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT DIALOG
    ON ACTION closecampaign
      IF core_ui.ui_message(%"Question",%"Close the campaign?","no","yes|no","fa-question") == "yes" THEN
        CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CAMPAIGN_CLOSED)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE DIALOG
        END IF
        LET mint_campaign_id = mrec_campaigngrid.campaign.cmp_id
        LET lint_action = C_APPACTION_VIEWCAMPAIGNS
        EXIT DIALOG
      END IF
    ON ACTION customaction
      CALL campaigngrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DIALOG
    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL campaigngrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"campaignmenu_page", setup.g_loggedin_name) RETURNING frontcall_return
      IF mrec_campaigngrid.campaign.cmp_totalbudget IS NOT NULL THEN
        CALL formatdecimal(mrec_campaigngrid.campaign.cmp_totalbudget,"campaigns.cmp_totalbudget","######&.&&","######&")
      END IF
      IF mrec_campaigngrid.campaign.cmp_prd_value IS NOT NULL THEN
        CALL formatdecimal(mrec_campaigngrid.campaign.cmp_prd_value,"campaigns.cmp_prd_value","######&.&&","######&")
      END IF
  END DIALOG
  RETURN lint_ret, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION campaigngrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT,
    ffimage_value STRING,
    lbool_allow_submitcampaign BOOLEAN,
    lbool_allow_deletecampaign BOOLEAN,
    lbool_allow_reviewcampaign BOOLEAN,
    lbool_allow_publication BOOLEAN,
    lbool_allow_validatecampaign BOOLEAN,
    lbool_allow_editprice BOOLEAN,
    lbool_allow_askinfluencersstat BOOLEAN,
    lbool_allow_closecampaign BOOLEAN

  LET lbool_allow_submitcampaign = FALSE
  LET lbool_allow_deletecampaign = FALSE
  LET lbool_allow_reviewcampaign = FALSE
  LET lbool_allow_publication = FALSE
  LET lbool_allow_validatecampaign = FALSE
  LET lbool_allow_editprice = FALSE
  LET lbool_allow_askinfluencersstat = FALSE
  LET lbool_allow_closecampaign = FALSE

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched)
      --CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","campaigns_cmp_brand_id","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_brand_id","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_brand_id","noEntry","0")
      CALL p_dialog.setActionHidden("customaction", TRUE)

      CALL core_ui.ui_set_node_attribute("Label","name","campaign_actions_label","hidden", "1")
      CALL p_dialog.setActionActive("submitcampaign", lbool_allow_submitcampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","submitcampaign","hidden", NOT lbool_allow_submitcampaign)
      CALL p_dialog.setActionActive("deletecampaign", lbool_allow_deletecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","deletecampaign","hidden", NOT lbool_allow_deletecampaign)
      CALL p_dialog.setActionActive("reviewcampaign", lbool_allow_reviewcampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","reviewcampaign","hidden", NOT lbool_allow_reviewcampaign)
      CALL p_dialog.setActionActive("validatecampaign", lbool_allow_validatecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","validatecampaign","hidden", NOT lbool_allow_validatecampaign)
      CALL p_dialog.setActionActive("editprice", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","editprice","hidden", TRUE)
      CALL p_dialog.setActionActive("editpublication", lbool_allow_publication)
      CALL core_ui.ui_set_node_attribute("Button","name","editpublication","hidden", NOT lbool_allow_publication)
      CALL p_dialog.setActionActive("askinfluencersstat", lbool_allow_askinfluencersstat)
      CALL core_ui.ui_set_node_attribute("Button","name","askinfluencersstat","hidden", NOT lbool_allow_askinfluencersstat)
      CALL p_dialog.setActionActive("closecampaign", lbool_allow_closecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","closecampaign","hidden", NOT lbool_allow_closecampaign)

      IF NOT setup.g_app_backoffice THEN
        CALL core_ui.ui_set_node_attribute("Label","name","campaigns_cmp_campaignstatus_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_campaignstatus_id","hidden", "1")
      END IF

      LET ffimage_value = IIF(pbool_dialog_touched, "fa-check-circle-green", "fa-check-circle-gray")
      DISPLAY BY NAME ffimage_value

      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_sharedfacebooklink","noEntry",(mrec_campaigngrid.campaign.cmp_issharedonfacebook==0))
      
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_detail","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_DETAILS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_influencers","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_INFLUENCERS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_promote","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_PRODUCT))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_content","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_CONTENT))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_tags","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_TAGS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_schedule","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_SCHEDULE))

    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched)
      --CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","campaigns_cmp_brand_id","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_brand_id","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_brand_id","noEntry","1")
      CALL p_dialog.setActionHidden("customaction", TRUE)

      LET lbool_allow_submitcampaign = campaign_allow_submit(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_deletecampaign = campaign_allow_delete(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_reviewcampaign = campaign_allow_review(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_publication = campaign_allow_publication(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_validatecampaign = campaign_allow_validate(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_editprice = campaign_allow_editprice(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_askinfluencersstat = campaign_allow_requestinfluencerstat(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_closecampaign = campaign_allow_closecampaign(mrec_campaigngrid.campaign.cmp_campaignstatus_id)

      CALL core_ui.ui_set_node_attribute("Label","name","campaign_actions_label","hidden", NOT (lbool_allow_submitcampaign
        OR lbool_allow_deletecampaign OR lbool_allow_reviewcampaign OR lbool_allow_publication
        OR lbool_allow_validatecampaign OR lbool_allow_editprice
        OR lbool_allow_askinfluencersstat OR lbool_allow_closecampaign))

      CALL p_dialog.setActionActive("submitcampaign", lbool_allow_submitcampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","submitcampaign","hidden", NOT lbool_allow_submitcampaign)
      CALL p_dialog.setActionActive("deletecampaign", lbool_allow_deletecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","deletecampaign","hidden", NOT lbool_allow_deletecampaign)
      CALL p_dialog.setActionActive("reviewcampaign", lbool_allow_reviewcampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","reviewcampaign","hidden", NOT lbool_allow_reviewcampaign)
      CALL p_dialog.setActionActive("validatecampaign", lbool_allow_validatecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","validatecampaign","hidden", NOT lbool_allow_validatecampaign)
      CALL p_dialog.setActionActive("editprice", lbool_allow_editprice)
      CALL core_ui.ui_set_node_attribute("Button","name","editprice","hidden", NOT lbool_allow_editprice)
      CALL p_dialog.setActionActive("editpublication", lbool_allow_publication)
      CALL core_ui.ui_set_node_attribute("Button","name","editpublication","hidden", NOT lbool_allow_publication)
      CALL p_dialog.setActionActive("askinfluencersstat", lbool_allow_askinfluencersstat)
      CALL core_ui.ui_set_node_attribute("Button","name","askinfluencersstat","hidden", NOT lbool_allow_askinfluencersstat)
      CALL p_dialog.setActionActive("closecampaign", lbool_allow_closecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","closecampaign","hidden", NOT lbool_allow_closecampaign)

      IF NOT setup.g_app_backoffice THEN
        CALL core_ui.ui_set_node_attribute("Label","name","campaigns_cmp_campaignstatus_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_campaignstatus_id","hidden", "1")
      END IF

      LET ffimage_value = IIF(pbool_dialog_touched, "fa-check-circle-green", "fa-check-circle-gray")
      DISPLAY BY NAME ffimage_value

      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_sharedfacebooklink","noEntry",(mrec_campaigngrid.campaign.cmp_issharedonfacebook==0))

      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_detail","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_DETAILS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_influencers","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_INFLUENCERS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_promote","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_PRODUCT))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_content","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_CONTENT))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_tags","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_TAGS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_schedule","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_SCHEDULE))

    WHEN C_DIALOGSTATE_DISPLAY
      CALL core_ui.ui_set_node_attribute("Label","name","campaigns_cmp_brand_id","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_brand_id","hidden",(NOT setup.g_app_backoffice))
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_brand_id","noEntry","1")
      CALL p_dialog.setActionHidden("customaction", TRUE)

      LET lbool_allow_deletecampaign = campaign_allow_delete(mrec_campaigngrid.campaign.cmp_campaignstatus_id)
      LET lbool_allow_publication = campaign_allow_publication(mrec_campaigngrid.campaign.cmp_campaignstatus_id)

      CALL core_ui.ui_set_node_attribute("Label","name","campaign_actions_label","hidden", NOT (lbool_allow_deletecampaign))

      CALL core_ui.ui_set_node_attribute("Button","name","submitcampaign","hidden", NOT lbool_allow_submitcampaign)
      CALL p_dialog.setActionActive("deletecampaign", lbool_allow_deletecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","deletecampaign","hidden", NOT lbool_allow_deletecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","reviewcampaign","hidden", NOT lbool_allow_reviewcampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","validatecampaign","hidden", NOT lbool_allow_validatecampaign)
      CALL core_ui.ui_set_node_attribute("Button","name","editprice","hidden", NOT lbool_allow_editprice)
      CALL core_ui.ui_set_node_attribute("Button","name","editpublication","hidden", NOT lbool_allow_publication)
      CALL core_ui.ui_set_node_attribute("Button","name","askinfluencersstat","hidden", NOT lbool_allow_askinfluencersstat)
      CALL core_ui.ui_set_node_attribute("Button","name","closecampaign","hidden", NOT lbool_allow_closecampaign)

      CALL core_ui.ui_set_node_attribute("Label","name","campaigns_cmp_campaignstatus_label","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","campaigns.cmp_campaignstatus_id","hidden", "1")

      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_detail","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_DETAILS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_influencers","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_INFLUENCERS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_promote","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_PRODUCT))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_content","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_CONTENT))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_tags","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_TAGS))
      CALL core_ui.ui_set_node_attribute("Group","name","group_campaign_schedule","hidden", (mint_workinggroup_id<>C_CAMPAIGNMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_CAMPAIGNMENU_SCHEDULE))
  END CASE

END FUNCTION

#+ Initializes the campaign business record
#+
#+ @param pint_campaign_id current campaign
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigngrid_initialize_data(pint_campaign_id, pint_dialog_state)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING

  INITIALIZE mrec_campaigngrid.* TO NULL
  INITIALIZE mrec_copy_campaigngrid.* TO NULL
  INITIALIZE mrec_db_campaign.* TO NULL
  CALL marec_campaignlocations.clear()
  CALL marec_campaignposttypes.clear()

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_campaigngrid.campaign.cmp_id = 0
      CALL _get_default_add_banner_photo()
        RETURNING lint_ret, lstr_msg, mrec_campaigngrid.campaign.cmp_pic_id, mrec_campaigngrid.pic_value
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_campaigngrid.campaign.cmp_issharedonfacebook = 0
      CALL _get_default_add_photo()
        RETURNING lint_ret, lstr_msg, mrec_campaigngrid.pic_id1, mrec_campaigngrid.pic_value1
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      CALL _get_default_add_photo()
        RETURNING lint_ret, lstr_msg, mrec_campaigngrid.pic_id2, mrec_campaigngrid.pic_value2
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      CALL _get_default_add_photo()
        RETURNING lint_ret, lstr_msg, mrec_campaigngrid.pic_id3, mrec_campaigngrid.pic_value3
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      IF setup.g_app_brand THEN
        LET mrec_campaigngrid.campaign.cmp_brand_id = setup.g_loggedin_id
      END IF
      LET mrec_campaigngrid.campaign.cmp_isproductneeded = 1
      LET mrec_campaigngrid.campaign.cmp_post_time_starttime = C_POSTTIME_ANYTIME
      LET mrec_campaigngrid.campaign.cmp_post_time_endtime = C_POSTTIME_ANYTIME
      LET mrec_campaigngrid.campaign.cmp_postduration_id = C_POSTDURATION_PERMANENT
      IF mrec_campaigngrid.campaign.cmp_brand_id IS NOT NULL AND mrec_campaigngrid.campaign.cmp_brand_id > 0 THEN
        LET mrec_campaigngrid.campaign.cmp_currency_id = get_brand_currency(mrec_campaigngrid.campaign.cmp_brand_id)
        LET mrec_campaigngrid.crr_symbol = core_db.currency_get_symbol(mrec_campaigngrid.campaign.cmp_currency_id)
        LET mrec_campaigngrid.crr_symbol1 = mrec_campaigngrid.crr_symbol
      END IF
      LET mrec_campaigngrid.campaign.cmp_campaignstatus_id = campaign_get_default_add_status()
      LET mrec_campaigngrid.campaign.cmp_createdby_id = IIF(setup.g_app_brand, C_CREATEDBY_BRAND, C_CREATEDBY_SALFATIX)

      LET mrec_campaigngrid.campaign_posttypes = campaignposttypes.serialize_campaignposttypes(marec_campaignposttypes)

      CALL campaignlocations.serialize(marec_campaignlocations)
        RETURNING mrec_campaigngrid.campaign_countries, mrec_campaigngrid.campaign_states, mrec_campaigngrid.campaign_cities

    WHEN C_DIALOGSTATE_UPDATE
      CALL campaigngrid_get_data_by_key(pint_campaign_id, marec_campaignlocations, marec_campaignposttypes)
        RETURNING lint_ret, lstr_msg, mrec_campaigngrid.*, mrec_db_campaign.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      IF mrec_campaigngrid.pic_id1 IS NULL THEN
        CALL _get_default_add_photo()
          RETURNING lint_ret, lstr_msg, mrec_campaigngrid.pic_id1, mrec_campaigngrid.pic_value1
        IF lint_ret <> 0 THEN
          RETURN lint_ret, lstr_msg
        END IF
      END IF
      IF mrec_campaigngrid.pic_id2 IS NULL THEN
        CALL _get_default_add_photo()
          RETURNING lint_ret, lstr_msg, mrec_campaigngrid.pic_id2, mrec_campaigngrid.pic_value2
        IF lint_ret <> 0 THEN
          RETURN lint_ret, lstr_msg
        END IF
      END IF
      IF mrec_campaigngrid.pic_id3 IS NULL THEN
        CALL _get_default_add_photo()
          RETURNING lint_ret, lstr_msg, mrec_campaigngrid.pic_id3, mrec_campaigngrid.pic_value3
        IF lint_ret <> 0 THEN
          RETURN lint_ret, lstr_msg
        END IF
      END IF
      LET mrec_copy_campaigngrid.* = mrec_campaigngrid.*
    WHEN C_DIALOGSTATE_DISPLAY
      CALL campaigngrid_get_data_by_key(pint_campaign_id, marec_campaignlocations, marec_campaignposttypes)
        RETURNING lint_ret, lstr_msg, mrec_campaigngrid.*, mrec_db_campaign.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_copy_campaigngrid.* = mrec_campaigngrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_campaigngrid
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_campaignlocations list of campaign locations
#+ @param parec_campaignposttypes list of campaign post types
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_campaigngrid business record, campaign database record
FUNCTION campaigngrid_get_data_by_key(pint_campaign_id, parec_campaignlocations, parec_campaignposttypes)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    parec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    larec_genders DYNAMIC ARRAY OF RECORD LIKE genders.*,
    larec_photos DYNAMIC ARRAY OF RECORD LIKE campaignphotos.*,
    larec_posttypes DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    larec_hashtags DYNAMIC ARRAY OF RECORD LIKE tags.*,
    larec_usertags DYNAMIC ARRAY OF RECORD LIKE tags.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_ui_campaign t_campaigngrid,
    lrec_db_campaign RECORD LIKE campaigns.*,
    lrec_pic RECORD LIKE pics.*,
    lrec_pic_tmp RECORD LIKE pics.*,
    lint_id1 LIKE pics.pic_id,
    l_pic1 LIKE pics.pic_value,
    lint_id2 LIKE pics.pic_id,
    l_pic2 LIKE pics.pic_value,
    lint_id3 LIKE pics.pic_id,
    l_pic3 LIKE pics.pic_value,
    i INTEGER

  INITIALIZE lrec_ui_campaign.* TO NULL
  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF
  CALL core_db.pics_select_row(lrec_campaign.cmp_pic_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF
  CALL core_db.get_campaign_genders(pint_campaign_id, larec_genders)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF
  CALL core_db.get_campaign_categories(pint_campaign_id, larec_categories)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF

  CALL core_db.get_campaign_campaignposttypes_and_posttypes(pint_campaign_id, parec_campaignposttypes, larec_posttypes)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF

  --get campaign photo examples
  CALL core_db.campaignphotos_fetch_all_rows(SFMT("WHERE campaignphotos.cmpph_campaign_id = %1", pint_campaign_id), " ORDER BY campaignphotos.cmpph_uiorder", larec_photos)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF
  INITIALIZE lint_id1 TO NULL
  INITIALIZE l_pic1 TO NULL
  INITIALIZE lint_id2 TO NULL
  INITIALIZE l_pic2 TO NULL
  INITIALIZE lint_id3 TO NULL
  INITIALIZE l_pic3 TO NULL
  FOR i = 1 TO larec_photos.getLength()
    CALL core_db.pics_select_row(larec_photos[i].cmpph_pic_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_pic_tmp.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
    END IF
    CASE
      WHEN l_pic1 IS NULL
        LET lint_id1 = lrec_pic_tmp.pic_id
        LET l_pic1 = lrec_pic_tmp.pic_value
      WHEN l_pic2 IS NULL
        LET lint_id2 = lrec_pic_tmp.pic_id
        LET l_pic2 = lrec_pic_tmp.pic_value
      WHEN l_pic3 IS NULL
        LET lint_id3 = lrec_pic_tmp.pic_id
        LET l_pic3 = lrec_pic_tmp.pic_value
    END CASE
  END FOR

  --get campaign tags
  CALL core_db.get_campaign_tags(pint_campaign_id, C_TAGTYPE_HASHTAG, larec_hashtags)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF
  CALL core_db.get_campaign_tags(pint_campaign_id, C_TAGTYPE_USERTAG, larec_usertags)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF

  --get campaign locations
  CALL campaignlocations.fetch_all_rows(pint_campaign_id, parec_campaignlocations)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END IF

  LET lrec_ui_campaign.campaign.* = lrec_campaign.*
  LET lrec_ui_campaign.pic_value = lrec_pic.pic_value
  LET lrec_ui_campaign.campaign_genders = string.serialize_genders(larec_genders)
  LET lrec_ui_campaign.campaign_categories = string.serialize_categories(larec_categories)
  LET lrec_ui_campaign.campaign_posttypes = campaignposttypes.serialize_campaignposttypes(parec_campaignposttypes)
  LET lrec_ui_campaign.pic_id1 = lint_id1
  LET lrec_ui_campaign.pic_value1 = l_pic1
  LET lrec_ui_campaign.pic_id2 = lint_id2
  LET lrec_ui_campaign.pic_value2 = l_pic2
  LET lrec_ui_campaign.pic_id3 = lint_id3
  LET lrec_ui_campaign.pic_value3 = l_pic3
  --TODO : refactorize  string.serialize_tags()
  LET lrec_ui_campaign.instagram_hashtag = string.serialize_tags(larec_hashtags, C_TAGTYPE_HASHTAG)
  LET lrec_ui_campaign.instagram_usertag = string.serialize_tags(larec_usertags, C_TAGTYPE_USERTAG)
  LET lrec_ui_campaign.crr_symbol = core_db.currency_get_symbol(lrec_campaign.cmp_currency_id)
  LET lrec_ui_campaign.crr_symbol1 = lrec_ui_campaign.crr_symbol
  CALL campaignlocations.serialize(parec_campaignlocations)
    RETURNING lrec_ui_campaign.campaign_countries, lrec_ui_campaign.campaign_states, lrec_ui_campaign.campaign_cities
  LET lrec_db_campaign.* = lrec_campaign.*
  RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
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
FUNCTION campaigngrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_campaign_id LIKE campaigns.cmp_id,
    lint_campaignstatus_id LIKE campaigns.cmp_campaignstatus_id

  DISPLAY SFMT("campaign_process_data = pint_dialog_state=%1 pbool_dialog_touched=%2 pint_dialog_action=%3",pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
      LET lint_campaignstatus_id = 0
      CASE pint_dialog_action
        WHEN C_APPACTION_ACCEPT
          IF pbool_dialog_touched THEN
            LET lbool_update_data = TRUE
          END IF
        WHEN C_APPACTION_CANCEL
          IF pbool_dialog_touched THEN
            IF core_ui.ui_message(%"Question ?",%"Abort campaign edition?","no","yes|no","fa-question") == "yes" THEN
              LET lbool_restore_data = TRUE
            END IF
          END IF
        WHEN C_APPACTION_CAMPAIGN_SUBMIT
          LET lbool_update_data = TRUE
          LET lint_campaignstatus_id = C_CAMPAIGNSTATUS_SUBMITTED
        WHEN C_APPACTION_CAMPAIGN_DELETE
          LET lbool_update_data = TRUE
          LET lint_campaignstatus_id = C_CAMPAIGNSTATUS_DELETED
        WHEN C_APPACTION_CAMPAIGN_REVIEW
          LET lbool_update_data = TRUE
          LET lint_campaignstatus_id = C_CAMPAIGNSTATUS_PENDING
        WHEN C_APPACTION_CAMPAIGN_VALIDATE
          LET lbool_update_data = TRUE
          LET lint_campaignstatus_id = C_CAMPAIGNSTATUS_VALIDATED
        WHEN C_APPACTION_CAMPAIGN_CLOSED
          LET lbool_update_data = TRUE
          LET lint_campaignstatus_id = C_CAMPAIGNSTATUS_CLOSED
      END CASE
    WHEN C_DIALOGSTATE_DISPLAY
      LET lbool_update_data = TRUE
      LET lint_campaignstatus_id = 0
      CASE pint_dialog_action
        WHEN C_APPACTION_CAMPAIGN_DELETE
          LET lint_campaignstatus_id = C_CAMPAIGNSTATUS_DELETED
      END CASE
    OTHERWISE --do nothing
      RETURN 0, NULL
  END CASE
  LET mrec_campaigngrid.campaign.cmp_sharedfacebooklink = string.trim(mrec_campaigngrid.campaign.cmp_sharedfacebooklink)
  IF lbool_insert_data THEN
    CALL campaign_validate_data(C_DIALOGSTATE_ADD, mint_workinggroup_id)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL campaign_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_campaign_id
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Campaign registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_campaigngrid.campaign.cmp_id = lint_campaign_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_update_data THEN
    CALL campaign_validate_data(C_DIALOGSTATE_UPDATE, mint_workinggroup_id)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL campaign_update_into_dabatase(lint_campaignstatus_id)
      RETURNING lint_ret, lstr_msg
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Campaign updated","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
    IF pint_dialog_action == C_APPACTION_CAMPAIGN_REVIEW THEN
      CALL notifications.sendmail_brand_campaign_to_review(mrec_campaigngrid.campaign.cmp_id)
    END IF
  END IF

  IF lbool_restore_data THEN
    CALL campaigngrid_initialize_data(mrec_campaigngrid.campaign.cmp_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL campaigngrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    IF pint_dialog_state <> C_DIALOGSTATE_DISPLAY THEN
      CALL p_dialog.setFieldTouched("scr_campaign_grid.*", FALSE) --reset the 'touched' flag
    END IF
  END IF

  IF lbool_refresh_data THEN
    CALL campaigngrid_initialize_data(mrec_campaigngrid.campaign.cmp_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL campaigngrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    IF pint_dialog_state <> C_DIALOGSTATE_DISPLAY THEN
      CALL p_dialog.setFieldTouched("scr_campaign_grid.*", FALSE) --reset the 'touched' flag
    END IF
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the genders into database
#+
#+ @param pint_campaign_id current campaign
#+ @param pstr_genders campaign genders string
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_genders(pint_campaign_id, pstr_genders)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pstr_genders STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_genders DYNAMIC ARRAY OF RECORD LIKE genders.*,
    i INTEGER,
    lrec_campaigngender RECORD LIKE campaigngenders.*

  --delete and insert genders
  CALL core_db.campaigngenders_delete_all_rows(pint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL string.deserialize_genders(pstr_genders, larec_genders)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      FOR i = 1 TO larec_genders.getLength()
        INITIALIZE lrec_campaigngender.* TO NULL
        LET lrec_campaigngender.cmpgen_campaign_id = pint_campaign_id
        LET lrec_campaigngender.cmpgen_gender_id = larec_genders[i].gnd_id
        CALL core_db.campaigngenders_insert_row(lrec_campaigngender.*)
          RETURNING lint_ret, lstr_msg, lrec_campaigngender.cmpgen_campaign_id, lrec_campaigngender.cmpgen_gender_id
        IF lint_ret <> 0 THEN
          EXIT FOR
        END IF
      END FOR
    END IF
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the categories into database
#+
#+ @param pint_campaign_id current campaign
#+ @param pstr_categories campaign categories string
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_categories(pint_campaign_id, pstr_categories)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pstr_categories STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    i INTEGER,
    lrec_campaigncategory RECORD LIKE campaigncategories.*

  --delete and insert categories
  CALL core_db.campaigncategories_delete_all_rows(pint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL string.deserialize_categories(pstr_categories, larec_categories)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      FOR i = 1 TO larec_categories.getLength()
        INITIALIZE lrec_campaigncategory.* TO NULL
        LET lrec_campaigncategory.cmpcat_campaign_id = pint_campaign_id
        LET lrec_campaigncategory.cmpcat_category_id = larec_categories[i].ctgr_id
        CALL core_db.campaigncategories_insert_row(lrec_campaigncategory.*)
          RETURNING lint_ret, lstr_msg, lrec_campaigncategory.cmpcat_campaign_id, lrec_campaigncategory.cmpcat_category_id
        IF lint_ret <> 0 THEN
          EXIT FOR
        END IF
      END FOR
    END IF
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the posttypes into database
#+
#+ @param pint_campaign_id current campaign
#+ @param pstr_posttypes campaign posttypes string
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_posttypes(pint_campaign_id, parec_campaignposttypes)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER,
    lrec_campaignposttype RECORD LIKE campaignposttypes.*

  --delete and insert posttypes
  CALL core_db.campaignposttypes_delete_all_rows(pint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO parec_campaignposttypes.getLength()
      INITIALIZE lrec_campaignposttype.* TO NULL
      LET lrec_campaignposttype.cmppst_campaign_id = pint_campaign_id
      LET lrec_campaignposttype.cmppst_posttype_id = parec_campaignposttypes[i].cmppst_posttype_id
      LET lrec_campaignposttype.cmppst_quantity = parec_campaignposttypes[i].cmppst_quantity
      LET lrec_campaignposttype.cmppst_tovalidate = parec_campaignposttypes[i].cmppst_tovalidate
      CALL core_db.campaignposttypes_insert_row(lrec_campaignposttype.*)
        RETURNING lint_ret, lstr_msg, lrec_campaignposttype.cmppst_campaign_id, lrec_campaignposttype.cmppst_posttype_id
      IF lint_ret <> 0 THEN
        EXIT FOR
      END IF
    END FOR
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the posttypes into database
#+
#+ @param pint_campaign_id current campaign
#+ @param pint_pic_id1 first photo id
#+ @param pint_pic_value1 first photo picture (BYTE)
#+ @param pint_pic_id2 second photo id
#+ @param pint_pic_value2 second photo picture (BYTE)
#+ @param pint_pic_id3 third photo id
#+ @param pint_pic_value3 third photo picture (BYTE)
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_photos(pint_campaign_id, pint_pic_id1, pint_pic_value1, pint_pic_id2, pint_pic_value2, pint_pic_id3, pint_pic_value3)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_pic_id1 LIKE pics.pic_id,
    pint_pic_value1 LIKE pics.pic_value,
    pint_pic_id2 LIKE pics.pic_id,
    pint_pic_value2 LIKE pics.pic_value,
    pint_pic_id3 LIKE pics.pic_id,
    pint_pic_value3 LIKE pics.pic_value,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  --delete and insert campaign photos
  CALL core_db.campaignphotos_delete_all_rows(pint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    IF pint_pic_id1 <> C_PIC_DEFAULTADDPHOTO THEN
      CALL _process_photo(pint_campaign_id, pint_pic_value1, (i:=i+1))
        RETURNING lint_ret, lstr_msg
    END IF
  END IF
  IF lint_ret == 0 THEN
    IF pint_pic_id2 <> C_PIC_DEFAULTADDPHOTO THEN
      CALL _process_photo(pint_campaign_id, pint_pic_value2, (i:=i+1))
        RETURNING lint_ret, lstr_msg
    END IF
  END IF
  IF lint_ret == 0 THEN
    IF pint_pic_id3 <> C_PIC_DEFAULTADDPHOTO THEN
      CALL _process_photo(pint_campaign_id, pint_pic_value3, (i:=i+1))
        RETURNING lint_ret, lstr_msg
    END IF
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process a campaign photo into database
#+
#+ @param pint_campaign_id current campaign
#+ @param pint_pic_value picture file (BYTE)
#+ @param pint_uiorder campaign photo order number
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_photo(pint_campaign_id, pint_pic_value, pint_uiorder)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_pic_value LIKE pics.pic_value,
    pint_uiorder LIKE campaignphotos.cmpph_uiorder,
    lrec_pic RECORD LIKE pics.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignphoto RECORD LIKE campaignphotos.*

  INITIALIZE lrec_pic.* TO NULL
  LET lrec_pic.pic_id = 0
  LET lrec_pic.pic_value = pint_pic_value
  CALL core_db.pics_insert_row(lrec_pic.*)
    RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  IF lint_ret == 0 THEN
    INITIALIZE lrec_campaignphoto.* TO NULL
    LET lrec_campaignphoto.cmpph_campaign_id = pint_campaign_id
    LET lrec_campaignphoto.cmpph_pic_id = lrec_pic.pic_id
    LET lrec_campaignphoto.cmpph_uiorder = pint_uiorder
    CALL core_db.campaignphotos_insert_row(lrec_campaignphoto.*)
      RETURNING lint_ret, lstr_msg, lrec_campaignphoto.cmpph_campaign_id, lrec_campaignphoto.cmpph_pic_id
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the tags into database
#+
#+ @param pint_campaign_id current campaign
#+ @param pstr_tags campaign tags string
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_tags(pint_campaign_id, pstr_tags)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pstr_tags STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_tags DYNAMIC ARRAY OF RECORD LIKE tags.*,
    i,j INTEGER,
    lrec_campaigntag RECORD LIKE campaigntags.*,
    lint_tag_id LIKE tags.tag_id

  --delete and insert tags
  CALL core_db.campaigntags_delete_all_rows(pint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL string.deserialize_tags(pstr_tags, larec_tags)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      FOR i = 1 TO larec_tags.getLength()
        LET lint_tag_id = larec_tags[i].tag_id
        IF lint_tag_id == 0 THEN
          CALL core_db.tags_insert_row(larec_tags[i].*)
            RETURNING lint_ret, lstr_msg, lint_tag_id
          CASE lint_ret
            WHEN 0
            WHEN -268 --Unique constraint violated
              --this happens when we input a non-existing tag twice or more.
              CONTINUE FOR
            OTHERWISE
              EXIT FOR
          END CASE
        END IF
        INITIALIZE lrec_campaigntag.* TO NULL
        LET lrec_campaigntag.cmptg_campaign_id = pint_campaign_id
        LET lrec_campaigntag.cmptg_tag_id = lint_tag_id
        LET lrec_campaigntag.cmptg_uiorder = (j:=j+1)
        CALL core_db.campaigntags_insert_row(lrec_campaigntag.*)
          RETURNING lint_ret, lstr_msg, lrec_campaigntag.cmptg_campaign_id, lrec_campaigntag.cmptg_tag_id
        IF lint_ret <> 0 THEN
          EXIT FOR
        END IF
      END FOR
    END IF
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the campaign locations into database
#+
#+ @param pint_campaign_id current campaign
#+ @param parec_campaignlocations campaign locations array
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_locations(pint_campaign_id, parec_campaignlocations)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lint_ret INTEGER,
    lstr_msg STRING

  --delete and insert campaign
  CALL campaignlocations.delete_all_rows(pint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL campaignlocations.insert_all_rows(pint_campaign_id, parec_campaignlocations)
      RETURNING lint_ret, lstr_msg
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Returns the default add banner photo picture in case the given parameter is NULL
#+
#+ @returnType INTEGER, STRING, INTEGER, BYTE
#+ @return     0|error, error message, picture id, picture value
PRIVATE FUNCTION _get_default_add_banner_photo()
  DEFINE
    lrec_pic RECORD LIKE pics.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.pics_select_row(C_PIC_DEFAULTADDBANNER, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  RETURN lint_ret, lstr_msg, lrec_pic.pic_id, lrec_pic.pic_value
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
  RETURN lint_ret, lstr_msg, lrec_pic.pic_id, lrec_pic.pic_value
END FUNCTION

#+ Insert a campaign into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, campaign id
FUNCTION campaign_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_pic RECORD LIKE pics.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_campaign.cmp_id
  END IF
  IF mrec_campaigngrid.campaign.cmp_pic_id == 0 THEN --means there is a photo which is not the default avatar
    INITIALIZE lrec_pic.* TO NULL
    LET lrec_pic.pic_id = 0
    LET lrec_pic.pic_value = mrec_campaigngrid.pic_value
    CALL core_db.pics_insert_row(lrec_pic.*)
      RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  END IF
  IF lint_ret == 0 THEN
    INITIALIZE lrec_campaign.* TO NULL
    LET lrec_campaign.* = mrec_campaigngrid.campaign.*
    LET lrec_campaign.cmp_id = 0
    IF lrec_campaign.cmp_pic_id == 0 THEN
      LET lrec_campaign.cmp_pic_id = lrec_pic.pic_id
    END IF
    LET lrec_campaign.cmp_creationdate = CURRENT
    CALL core_db.campaigns_insert_row(lrec_campaign.*)
      RETURNING lint_ret, lstr_msg, lrec_campaign.cmp_id
  END IF
  --insert genders
  IF lint_ret == 0 THEN
    CALL _process_genders(lrec_campaign.cmp_id, mrec_campaigngrid.campaign_genders)
      RETURNING lint_ret, lstr_msg
  END IF
  --insert categories
  IF lint_ret == 0 THEN
    CALL _process_categories(lrec_campaign.cmp_id, mrec_campaigngrid.campaign_categories)
      RETURNING lint_ret, lstr_msg
  END IF
  --insert post types
  IF lint_ret == 0 THEN
    CALL _process_posttypes(lrec_campaign.cmp_id, marec_campaignposttypes)
      RETURNING lint_ret, lstr_msg
  END IF
  --insert photo examples
  IF lint_ret == 0 THEN
    CALL _process_photos(lrec_campaign.cmp_id
      ,mrec_campaigngrid.pic_id1, mrec_campaigngrid.pic_value1
      ,mrec_campaigngrid.pic_id2, mrec_campaigngrid.pic_value2
      ,mrec_campaigngrid.pic_id3, mrec_campaigngrid.pic_value3)
    RETURNING lint_ret, lstr_msg
  END IF
  --insert tags
  IF lint_ret == 0 THEN
    CALL _process_tags(lrec_campaign.cmp_id, SFMT("%1 %2",mrec_campaigngrid.instagram_hashtag,mrec_campaigngrid.instagram_usertag))
      RETURNING lint_ret, lstr_msg
  END IF
  --insert locations
  IF lint_ret == 0 THEN
    CALL _process_locations(lrec_campaign.cmp_id, marec_campaignlocations)
      RETURNING lint_ret, lstr_msg
  END IF
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_campaign.cmp_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_campaign.cmp_id
END FUNCTION

#+ Update a campaign into database
#+
#+ @param pint_status_id new campaign status
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaign_update_into_dabatase(pint_status_id)
  DEFINE
    pint_status_id LIKE campaigns.cmp_campaignstatus_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_pic RECORD LIKE pics.*,
    lint_status INTEGER,
    lbool_delete_old_photo BOOLEAN,
    l_timestamp DATETIME YEAR TO SECOND

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET l_timestamp = CURRENT
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET lbool_delete_old_photo = (mrec_campaigngrid.campaign.cmp_pic_id == 0)
  IF mrec_campaigngrid.campaign.cmp_pic_id == 0 THEN --means there is a photo which is not the default avatar
    INITIALIZE lrec_pic.* TO NULL
    LET lrec_pic.pic_id = 0
    LET lrec_pic.pic_value = mrec_campaigngrid.pic_value
    CALL pics_insert_row(lrec_pic.*)
      RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  END IF
  IF lint_ret == 0 THEN
    INITIALIZE lrec_campaign.* TO NULL
    LET lrec_campaign.* = mrec_campaigngrid.campaign.*
    IF lrec_campaign.cmp_pic_id == 0 THEN
      LET lrec_campaign.cmp_pic_id = lrec_pic.pic_id
    END IF
    IF pint_status_id IS NOT NULL AND pint_status_id > 0 THEN
      LET lrec_campaign.cmp_campaignstatus_id = pint_status_id
    END IF
    LET lrec_campaign.cmp_lastupdatedate = l_timestamp
    CALL core_db.campaigns_update_row(mrec_db_campaign.*, lrec_campaign.*, l_timestamp)
      RETURNING lint_ret, lstr_msg
  END IF
  IF (lint_ret == 0) AND lbool_delete_old_photo THEN
    CALL core_db.pics_delete_row(mrec_copy_campaigngrid.campaign.cmp_pic_id)
      RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert genders
  IF lint_ret == 0 THEN
    CALL _process_genders(lrec_campaign.cmp_id, mrec_campaigngrid.campaign_genders)
      RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert categories
  IF lint_ret == 0 THEN
    CALL _process_categories(lrec_campaign.cmp_id, mrec_campaigngrid.campaign_categories)
      RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert post types
  IF lint_ret == 0 THEN
    CALL _process_posttypes(lrec_campaign.cmp_id, marec_campaignposttypes)
      RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert photo examples
  IF lint_ret == 0 THEN
    CALL _process_photos(lrec_campaign.cmp_id
      ,mrec_campaigngrid.pic_id1, mrec_campaigngrid.pic_value1
      ,mrec_campaigngrid.pic_id2, mrec_campaigngrid.pic_value2
      ,mrec_campaigngrid.pic_id3, mrec_campaigngrid.pic_value3)
    RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert tags
  IF lint_ret == 0 THEN
    CALL _process_tags(lrec_campaign.cmp_id, SFMT("%1 %2",mrec_campaigngrid.instagram_hashtag,mrec_campaigngrid.instagram_usertag))
      RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert locations
  IF lint_ret == 0 THEN
    CALL _process_locations(lrec_campaign.cmp_id, marec_campaignlocations)
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

#+ Check business rules of a campaign
#+
#+ @param pint_dialog_state current DIALOG state
#+ @param pint_group_id group to validate
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaign_validate_data(pint_dialog_state, pint_group_id)
  DEFINE
    pint_dialog_state SMALLINT,
    pint_group_id SMALLINT

  --TODO : do validation of record

  --always test first NOT NULL database fields
  IF pint_dialog_state <> C_DIALOGSTATE_ADD THEN
    IF mrec_campaigngrid.campaign.cmp_id IS NULL OR mrec_campaigngrid.campaign.cmp_id==0 THEN
      RETURN -1, %"Campaign missing"
    END IF
  END IF
  IF mrec_campaigngrid.campaign.cmp_brand_id IS NULL OR mrec_campaigngrid.campaign.cmp_brand_id==0 THEN
    RETURN -1, %"Brand missing"
  END IF
  IF mrec_campaigngrid.campaign.cmp_pic_id IS NULL OR mrec_campaigngrid.pic_value IS NULL THEN
    RETURN -1, %"Photo missing"
  END IF
  IF mrec_campaigngrid.campaign.cmp_campaignstatus_id IS NULL THEN
    RETURN -1, %"Status missing"
  END IF
  IF mrec_campaigngrid.campaign.cmp_issharedonfacebook IS NULL THEN
    RETURN -1, %"Shared on facebook missing"
  END IF
  IF mrec_campaigngrid.campaign.cmp_createdby_id IS NULL THEN
    RETURN -1, %"CreatedBy missing"
  END IF
  IF pint_group_id==C_CAMPAIGNMENU_ALLGROUPS OR pint_group_id==C_CAMPAIGNMENU_DETAILS THEN
    --IF mrec_campaigngrid.campaign.cmp_title IS NULL THEN
      --RETURN -1, %"Title missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_overview IS NULL THEN
      --RETURN -1, %"Overview missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_url IS NULL THEN
      --RETURN -1, %"Website missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_totalbudget IS NULL THEN
      --RETURN -1, %"Campaign budget missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_currency_id IS NULL THEN
      --RETURN -1, %"Campaign currency missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_wantedusers IS NULL OR mrec_campaigngrid.campaign.cmp_wantedusers <= 0 THEN
      --RETURN -1, %"Wanted influencers missing"
    --END IF
  END IF
  IF pint_group_id==C_CAMPAIGNMENU_ALLGROUPS OR pint_group_id==C_CAMPAIGNMENU_INFLUENCERS THEN
    --IF mrec_campaigngrid.campaign_countries IS NULL THEN
      --RETURN -1, %"Country missing"
    --END IF
    --IF mrec_campaigngrid.campaign_states IS NULL THEN
      --RETURN -1, %"State missing"
    --END IF
    --IF mrec_campaigngrid.campaign_cities IS NULL THEN
      --RETURN -1, %"City missing"
    --END IF
    --IF mrec_campaigngrid.campaign_categories IS NULL THEN
      --RETURN -1, %"Categories missing"
    --END IF
  END IF
  IF pint_group_id==C_CAMPAIGNMENU_ALLGROUPS OR pint_group_id==C_CAMPAIGNMENU_PRODUCT THEN
    --IF mrec_campaigngrid.campaign.cmp_prd_description IS NULL THEN
      --RETURN -1, %"Product description missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_prd_value IS NULL THEN
      --RETURN -1, %"Product value missing"
    --END IF
  END IF
  IF pint_group_id==C_CAMPAIGNMENU_ALLGROUPS OR pint_group_id==C_CAMPAIGNMENU_CONTENT THEN
    --IF mrec_campaigngrid.campaign_posttypes IS NULL THEN
      --RETURN -1, %"Post types missing"
    --END IF
    IF mrec_campaigngrid.campaign.cmp_issharedonfacebook == 1 THEN
      IF LENGTH(mrec_campaigngrid.campaign.cmp_sharedfacebooklink) == 0 THEN
        RETURN -1, %"Facebook link page missing"
      END IF
    ELSE
      IF LENGTH(mrec_campaigngrid.campaign.cmp_sharedfacebooklink) > 0 THEN
        RETURN -1, %"Facebook link page should be empty when sharing is not set"
      END IF
    END IF

    --IF mrec_campaigngrid.campaign.cmp_post_guidelines IS NULL THEN
      --RETURN -1, %"Content guidelines missing"
    --END IF
    --IF mrec_campaigngrid.pic_id1 IS NULL OR mrec_campaigngrid.pic_value1 IS NULL THEN
      --RETURN -1, %"Photo examples missing"
    --END IF
    --IF mrec_campaigngrid.pic_id2 IS NULL OR mrec_campaigngrid.pic_value2 IS NULL THEN
      --RETURN -1, %"Photo examples missing"
    --END IF
    --IF mrec_campaigngrid.pic_id3 IS NULL OR mrec_campaigngrid.pic_value3 IS NULL THEN
      --RETURN -1, %"Photo examples missing"
    --END IF
  END IF
  IF pint_group_id==C_CAMPAIGNMENU_ALLGROUPS OR pint_group_id==C_CAMPAIGNMENU_TAGS THEN
    --IF mrec_campaigngrid.instagram_usertag IS NULL THEN
      --RETURN -1, %"Usertag missing"
    --END IF
    --CALL string.validate_tags_format(mrec_campaigngrid.instagram_usertag, C_TAGTYPE_USERTAG)
      --RETURNING lint_ret, lstr_msg
    --IF lint_ret <> 0 THEN
      --RETURN lint_ret, lstr_msg
    --END IF
    --IF mrec_campaigngrid.instagram_hashtag IS NULL THEN
      --RETURN -1, %"Hashtag missing"
    --END IF
    --CALL string.validate_tags_format(mrec_campaigngrid.instagram_hashtag, C_TAGTYPE_HASHTAG)
      --RETURNING lint_ret, lstr_msg
    --IF lint_ret <> 0 THEN
      --RETURN lint_ret, lstr_msg
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_captionrequirements IS NULL THEN
      --RETURN -1, %"Caption requirements missing"
    --END IF
  END IF
  IF pint_group_id==C_CAMPAIGNMENU_ALLGROUPS OR pint_group_id==C_CAMPAIGNMENU_SCHEDULE THEN
    --IF mrec_campaigngrid.campaign.cmp_post_startdate IS NULL THEN
      --RETURN -1, %"Start date missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_post_enddate IS NULL THEN
      --RETURN -1, %"End date missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_post_time_starttime IS NULL THEN
      --RETURN -1, %"Post start time missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_post_time_endtime IS NULL THEN
      --RETURN -1, %"Post end time missing"
    --END IF
    --IF mrec_campaigngrid.campaign.cmp_postduration_id IS NULL THEN
      --RETURN -1, %"Post duration missing"
    --END IF
  END IF

  RETURN 0, NULL
END FUNCTION

#+ Checks if a campaign can be edited
#+
#+ @param pint_campaignstatus_id current campaign status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_edition(pint_campaignstatus_id LIKE campaignstatus.cmpst_id)
  IF setup.g_app_brand THEN
    IF pint_campaignstatus_id <> C_CAMPAIGNSTATUS_CREATED
      AND pint_campaignstatus_id <> C_CAMPAIGNSTATUS_SUBMITTED
      AND pint_campaignstatus_id <> C_CAMPAIGNSTATUS_PENDING
    THEN --campaign is published-closed-deleted
      RETURN FALSE
    END IF
  END IF
  RETURN TRUE
END FUNCTION

#+ Checks if a campaign can be submited
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_submit(pint_campaignstatus_id)
  DEFINE
    pint_campaignstatus_id LIKE campaignstatus.cmpst_id

  IF setup.g_app_backoffice OR setup.g_app_brand THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_CREATED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_PENDING
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a campaign can be deleted
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_delete(pint_campaignstatus_id)
  DEFINE
    pint_campaignstatus_id LIKE campaignstatus.cmpst_id

  IF setup.g_app_brand THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_CREATED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_SUBMITTED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_PENDING
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED
    THEN
      RETURN TRUE
    END IF
  END IF
  IF setup.g_app_backoffice THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_CREATED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_SUBMITTED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_PENDING
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a campaign can be sent back to the brand
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_review(pint_campaignstatus_id)
  DEFINE
    pint_campaignstatus_id LIKE campaignstatus.cmpst_id

  IF setup.g_app_backoffice THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_SUBMITTED THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a campaign can be validated
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_validate(pint_campaignstatus_id)
  DEFINE
    pint_campaignstatus_id LIKE campaignstatus.cmpst_id

  IF setup.g_app_backoffice THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_SUBMITTED
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a campaign can be set to "deposit paid"
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_editprice(pint_campaignstatus_id)
  DEFINE
    pint_campaignstatus_id LIKE campaignstatus.cmpst_id

  IF setup.g_app_backoffice THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_VALIDATED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED
      OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_CLOSED
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if brand/salfatix can open the publication list of the campaign
#+
#+ @param prec_campaign modified campaign
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_publication(pint_campaignstatus_id)
  DEFINE
    pint_campaignstatus_id LIKE campaignstatus.cmpst_id

  IF setup.g_app_backoffice OR setup.g_app_brand THEN
    IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED
     OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_CLOSED
    THEN
      RETURN TRUE
    END IF
    IF setup.g_app_backoffice
      AND pint_campaignstatus_id == C_CAMPAIGNSTATUS_VALIDATED 
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can request the post statistics of the influencers
#+
#+ @param pint_campaignstatus_id campaign status id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_requestinfluencerstat(pint_campaignstatus_id LIKE campaignstatus.cmpst_id)
  IF NOT setup.g_app_backoffice THEN
    RETURN FALSE
  END IF
  IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can close the campaign
#+
#+ @param pint_campaignstatus_id campaign status id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_closecampaign(pint_campaignstatus_id LIKE campaignstatus.cmpst_id)
  IF NOT setup.g_app_backoffice THEN
    RETURN FALSE
  END IF
  --TODO : review condition of close campaign
  IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
    RETURN TRUE
  END IF

  RETURN FALSE
END FUNCTION

#+ Get default status when creating a campaign
#+
#+ @returnType INTEGER
#+ @return     campaign status
FUNCTION campaign_get_default_add_status()

  IF setup.g_app_backoffice THEN
    RETURN C_CAMPAIGNSTATUS_SUBMITTED
  END IF
  RETURN C_CAMPAIGNSTATUS_CREATED
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION campaignlist_get_default_sortby()
  RETURN "campaigns.cmp_title"
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION campaignlist_get_default_orderby()
  RETURN "asc"
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION campaignlist_get_default_sqlorderby()
  RETURN SFMT("%1 %2", campaignlist_get_default_sortby(), campaignlist_get_default_orderby())
END FUNCTION

#+ Get a currency for a brand
#+
#+ @param pint_brand_id brand id
#+
#+ @returnType STRING
#+ @return     brand currency
FUNCTION get_brand_currency(pint_brand_id)
  DEFINE
    pint_brand_id LIKE brands.brnd_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    l_data LIKE brands.brnd_currency_id

  INITIALIZE l_data TO NULL
  TRY
    SELECT brands.brnd_currency_id
      INTO l_data
    FROM brands
    WHERE brands.brnd_id = pint_brand_id
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN l_data
END FUNCTION

#+ Initializer of the starttime combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION starttime_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox

  CALL combobox.time_initializer(p_combo, C_POSTTIME_ANYTIME, 23)
END FUNCTION

#+ Initializer of the endtime combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION endtime_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox

  CALL combobox.time_initializer(p_combo, C_POSTTIME_ANYTIME, 23)
END FUNCTION

#+ Initializer of the day combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION duration_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox

  CALL combobox.duration_initializer(p_combo)
END FUNCTION

#+ Initializer of the campaign status combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION campaign_status_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox
  CALL combobox.campaignstatus_initializer(p_combo)
END FUNCTION

#+ Initializer of the campaign brand combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION campaign_brand_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox
  CALL combobox.brand_initializer(p_combo)
END FUNCTION

#+ Initializer of the campaign brand combobox
#+
FUNCTION campaignstatus_combobox_initializer()
  CALL combobox.campaignstatus_initializer(ui.ComboBox.forName("campaigns.cmp_campaignstatus_id"))
END FUNCTION

#+ Display the default title for the list of influencers
#+
FUNCTION display_campaignlist_default_title()
  DEFINE
    ff_formtitle STRING
  LET ff_formtitle = mstr_campaignlist_default_title
  CALL FGL_SETTITLE(ff_formtitle)
  DISPLAY BY NAME ff_formtitle
END FUNCTION

#+ Update the campaign and its posts to status "statistics requested"
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaigngrid_askinfluencersstatistics(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    larec_campaignusers DYNAMIC ARRAY OF RECORD LIKE campaignuserlist.*,
    larec_ids DYNAMIC ARRAY OF INTEGER,
    i INTEGER

  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  IF mrec_campaigngrid.campaign.cmp_campaignstatus_id <> C_CAMPAIGNSTATUS_PUBLISHED THEN
    RETURN -1, %"Operation not allowed"
  END IF
  CALL core_db.campaignuserlist_fetch_all_rows(SFMT("WHERE cmpusrl_campaign_id = %1 AND cmpusrl_isacceptedbybrand=1",pint_campaign_id), NULL, larec_campaignusers)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  IF larec_campaignusers.getLength() == 0 THEN
    IF core_ui.ui_message(%"Campaigns","There is no influencers to ask statistics for.","ok","ok","fa-check") THEN END IF
    RETURN 0, NULL
  END IF
  FOR i = 1 TO larec_campaignusers.getLength()
    LET larec_ids[i] = larec_campaignusers[i].cmpusrl_user_id
  END FOR
  CALL notifications.notif_influencers_to_get_post_statistics(larec_ids, lrec_campaign.cmp_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    IF core_ui.ui_message(%"Campaigns","Campaign statistics requested","ok","ok","fa-check") THEN END IF
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION
