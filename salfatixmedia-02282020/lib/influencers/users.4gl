IMPORT util
IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL hash
IMPORT FGL emails
IMPORT FGL notifications
IMPORT FGL layout
IMPORT FGL userpostprices
IMPORT FGL usersocialnetworks
IMPORT FGL instagram
Import FGL notifications_clients
Import FGL zoom_countrystatecitylist
IMPORT FGL campaigns_mobile

SCHEMA salfatixmedia

CONSTANT
  C_INFLUENCERMENU_ALLGROUPS SMALLINT = 0,
  C_INFLUENCERMENU_DETAILS SMALLINT = 1,
  C_INFLUENCERMENU_INSTAGRAM SMALLINT = 3,
  C_INFLUENCERMENU_NOTIFICATION SMALLINT = 4,
  C_INFLUENCERMENU_RATES SMALLINT = 5,
  C_INFLUENCERMENU_BANK SMALLINT = 6
 
TYPE
  t_userlistqbeinput RECORD
    sortby STRING,
    orderby STRING
  END RECORD

TYPE
  t_userlist RECORD
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    user_phonenumber STRING,
    nb_followers STRING,
    usrmtc_reach STRING,
    accst_name LIKE accountstatus.accst_name
  END RECORD
TYPE
  t_usergrid RECORD
    user RECORD LIKE users.*,
    usermetric RECORD LIKE usermetrics.*,
    password2 LIKE users.usr_password,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture
  END RECORD
Type
  t_userloc   Record
    cntr_name   String,
    stt_name    String,
    cts_name    String
              End Record

DEFINE
  m_dialogtouched SMALLINT
DEFINE --list qbe data
  mrec_userlistqbeinput t_userlistqbeinput

DEFINE --list data
  marec_userlist DYNAMIC ARRAY OF t_userlist
DEFINE --grid data
  mint_user_id LIKE users.usr_id,
  mrec_usergrid t_usergrid,
  mrec_location t_userloc,
  mrec_copy_usergrid t_usergrid,
  mrec_db_user RECORD LIKE users.*,
  mrec_db_usermetric RECORD LIKE usermetrics.*,
  mint_workinggroup_id SMALLINT

DEFINE
  mstr_influencerlist_default_title STRING

#+ Fetch and display the list of influencers
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION userlist_open_form(pstr_where, pstr_orderby, pstr_title)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT

  LET mstr_influencerlist_default_title = %"Influencers"
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_user_list WITH FORM "user_list"
  CALL userlist_get_data(NULL, pstr_where, pstr_orderby, marec_userlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL userlist_display(pstr_title)
      RETURNING lint_ret, lint_action
  END IF
  CLOSE WINDOW w_user_list
  RETURN lint_ret, lint_action
END FUNCTION

#+ Display the influencers
#+
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION userlist_display(pstr_title)
  DEFINE
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_user_id LIKE users.usr_id,
    i INTEGER,
    ff_formtitle STRING,
    frontcall_return STRING,
    lstr_sql_from_clause STRING,
    lstr_sql_where_clause STRING,
    lstr_sql_orderby_clause STRING,
    lstr_sql_where STRING

  LET lint_action = C_APPACTION_UNDEFINED
  IF pstr_title IS NULL THEN
    LET pstr_title = mstr_influencerlist_default_title
  END IF
  LET ff_formtitle = pstr_title
  CALL FGL_SETTITLE(ff_formtitle)

  LET mrec_userlistqbeinput.sortby = userlist_get_default_sortby()
  LET mrec_userlistqbeinput.orderby = userlist_get_default_orderby()

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_userlistqbeinput.* FROM scr_qbeinput.*
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
    DISPLAY ARRAY marec_userlist TO scr_influencer_list.*
    END DISPLAY
    ON ACTION filter
      --DISPLAY CURRENT, " qbe=", lstr_sql_where
      --DISPLAY "mrec_userlistqbeinput.sortby = ",mrec_userlistqbeinput.sortby
      --DISPLAY "mrec_userlistqbeinput.orderby = ",mrec_userlistqbeinput.orderby
      IF lstr_sql_where.getLength() == 0 THEN
       LET lstr_sql_where = " 1=1"
      END IF
      LET lstr_sql_from_clause = " users"
      LET lstr_sql_where_clause = lstr_sql_where
      IF lstr_sql_where.getIndexOf("usermetrics.", 1) > 0
        OR mrec_userlistqbeinput.sortby == "usermetrics.usrmtc_followers_count"
        OR mrec_userlistqbeinput.sortby == "usermetrics.usrmtc_reach"
      THEN
        LET lstr_sql_from_clause = SFMT("%1, usermetrics", lstr_sql_from_clause)
        LET lstr_sql_where_clause = lstr_sql_where_clause
          ," AND users.usr_id = usermetrics.usrmtc_usr_id"
          ," AND CURRENT BETWEEN usermetrics.usrmtc_bdate AND usermetrics.usrmtc_edate"
      END IF
      LET lstr_sql_orderby_clause = SFMT("%1 %2",mrec_userlistqbeinput.sortby, mrec_userlistqbeinput.orderby)

      CALL userlist_get_data(lstr_sql_from_clause, lstr_sql_where_clause,lstr_sql_orderby_clause, marec_userlist)
        RETURNING lint_ret, lstr_msg
      CALL display_userlist_default_title()

    ON ACTION display_influencer
      LET i = DIALOG.getCurrentRow("scr_influencer_list")
      IF i > 0 THEN
        --CALL usermenu_open_form_by_key(marec_userlist[i].user.usr_id)
          --RETURNING lint_ret, lint_action, lint_user_id
        CALL usergrid_open_form_by_key(marec_userlist[i].user.usr_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_ALLGROUPS)
          RETURNING lint_ret, lint_action, lint_user_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"influencerlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action <> C_APPACTION_VIEWINFLUENCERS THEN
            EXIT DIALOG
          END IF
          CALL userlist_get_data_by_key(lint_user_id, marec_userlist, i)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
          END IF
          CALL userlist_ui_set_action_state(DIALOG)
          CALL display_userlist_default_title()
        END IF
      END IF
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      IF lint_action == C_APPACTION_ADDINFLUENCER THEN
        CALL usergrid_open_form_by_key(0, C_APPSTATE_ADD, C_INFLUENCERMENU_ALLGROUPS)
          RETURNING lint_ret, lint_action, lint_user_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"influencerlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_ACCEPT THEN
            LET lint_action = C_APPACTION_VIEWINFLUENCERS
          END IF
          IF lint_action <> C_APPACTION_VIEWINFLUENCERS THEN
            EXIT DIALOG
          END IF
          IF lint_user_id > 0 THEN
            LET i = marec_userlist.getLength() + 1
            CALL userlist_get_data_by_key(lint_user_id, marec_userlist, i)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
            END IF
            CALL userlist_ui_set_action_state(DIALOG)
            CALL display_userlist_default_title()
          END IF
        END IF
      END IF
      EXIT DIALOG
    BEFORE DIALOG
      CALL userlist_ui_set_action_state(DIALOG)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"influencerlist_page", setup.g_loggedin_name) RETURNING frontcall_return
  END DIALOG
   RETURN lint_ret, lint_action
END FUNCTION

#+ Get the influencer list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of brands t_brandlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userlist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_userlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_usr_id LIKE users.usr_id

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM users"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT users.usr_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_userlist_get_data CURSOR FROM lstr_sql
    FOREACH c_userlist_get_data
      INTO lint_usr_id
      CALL userlist_get_data_by_key(lint_usr_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END FOREACH
    FREE c_userlist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the influencer list data for a given row
#+
#+ @param pint_user_id influencer id
#+ @param parec_list list of influencers t_userlist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userlist_get_data_by_key(pint_user_id, parec_list, pint_index)
  DEFINE
    pint_user_id LIKE users.usr_id,
    parec_list DYNAMIC ARRAY OF t_userlist,
    pint_index INTEGER,
    lrec_user RECORD LIKE users.*,
    lrec_usermetric RECORD LIKE usermetrics.*,
    lrec_accountstatus RECORD LIKE accountstatus.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.users_select_row(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.accountstatus_select_row(lrec_user.usr_accountstatus_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_accountstatus.*
  IF lint_ret == 0 THEN
    LET parec_list[pint_index].accst_name = lrec_accountstatus.accst_name
  END IF
  CALL core_db.usermetrics_select_current_row_by_userid(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_usermetric.*
  IF lint_ret == 0 THEN
    LET parec_list[pint_index].nb_followers = lrec_usermetric.usrmtc_followers_count
    LET parec_list[pint_index].usrmtc_reach = lrec_usermetric.usrmtc_reach
  END IF
  LET parec_list[pint_index].user.* = lrec_user.*
  LET parec_list[pint_index].usr_instagram_profilepicture = _get_default_photo(parec_list[pint_index].user.usr_instagram_profilepicture)
  LET parec_list[pint_index].user_phonenumber = string.build_phonenumber(parec_list[pint_index].user.usr_country_id, parec_list[pint_index].user.usr_mobile_phone)
  RETURN 0, NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION userlist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.Dialog
  CALL p_dialog.setActionActive("display_influencer", (marec_userlist.getLength()>0))
  CALL p_dialog.setActionHidden("customaction", TRUE)
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_user_id current user id
#+
FUNCTION usermenu_ui_set_action_state(p_dialog ui.Dialog, pint_user_id  LIKE users.usr_id)
  CALL p_dialog.setActionActive("infl_notifications", FALSE)
  CALL p_dialog.setActionHidden("infl_notifications", TRUE)
  --only validated influencers can view the campaigns
  IF user_is_valid(pint_user_id) THEN
    CALL p_dialog.setActionActive("infl_campaigns", TRUE)
    CALL p_dialog.setActionHidden("infl_campaigns", FALSE)
  ELSE
    CALL p_dialog.setActionActive("infl_campaigns", FALSE)
    CALL p_dialog.setActionHidden("infl_campaigns", TRUE)
  END IF
END FUNCTION

Function setMenuOptions(pint_user_id,level,amenu)
  Define
    i             Smallint,
    pint_user_id  LIKE users.usr_id,
    level         String,
    amenu         Dynamic Array Of Record
      menuname      String,
      menuimg       String,
      menuact       String
                  End Record

  Call amenu.clear()
  Case level
    When "main"
      Let amenu[1].menuname = %"Campaigns"
      Let amenu[1].menuimg  = "fa-list-green"
      Let amenu[1].menuact  = "infl_campaigns"
      Let amenu[2].menuname = %"Profile"
      Let amenu[2].menuimg  = "fa-info"
      Let amenu[2].menuact  = "infl_yourdetail"
      Let amenu[3].menuname = %"Remuneration"
      Let amenu[3].menuimg  = "fa-money"
      Let amenu[3].menuact  = "infl_financialdata"
      Let amenu[4].menuname = %"Notifications"
      Let amenu[4].menuimg  = "letter"
      Let amenu[4].menuact  = "infl_notifications"
      Let amenu[5].menuname = %"Social networks"
      Let amenu[5].menuimg  = "fa-users"
      Let amenu[5].menuact  = "infl_socialnetworks"
      Let amenu[6].menuname = %"Sign out"
      Let amenu[6].menuimg  = "fa-sign-out-red"
      Let amenu[6].menuact  = "signout"

      Let i = amenu.search("menuact","infl_notifications")
      If i > 0 Then
        Call amenu.deleteElement(i)
      End If

      Let i = amenu.search("menuact","infl_campaigns")
      IF Not user_is_valid(pint_user_id) THEN
        Call amenu.deleteElement(i)
      END IF
    When "infl_financialdata"
      Let amenu[1].menuname = %"Currency"
      Let amenu[1].menuimg  = "fa-euro"
      Let amenu[1].menuact  = "infl_rates"
      Let amenu[2].menuname = %"Bank information"
      Let amenu[2].menuimg  = "fa-bank"
      Let amenu[2].menuact  = "infl_bankdata"
      Let amenu[3].menuname = %"Price per post"
      Let amenu[3].menuimg  = "fa-calculator"
      Let amenu[3].menuact  = "infl_postprices"
      Let amenu[4].menuname = %"Euro symbols meaning"
      Let amenu[4].menuimg  = "fa-calculator"
      Let amenu[4].menuact  = "infl_postpriceshelp"

      Let i = amenu.search("menuact","infl_rates")
      If i > 0 Then
        Call amenu.deleteElement(i)
      End If

      Let i = amenu.search("menuact","infl_postprices")
      If i > 0 Then
        Call amenu.deleteElement(i)
      End If
  End Case

End Function

#+ Fetch and display user menu
#+
#+ @param pint_user_id user id
#+
#+ @returnType INTEGER, SMALLINT, INTEGER
#+ @return     0|error, next performed action id, user id
FUNCTION usermenu_open_form_by_key(pint_user_id)
  DEFINE
    pint_user_id LIKE users.usr_id,
    lbool_isbackground Boolean,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lrec_user RECORD LIKE users.*,
    lint_user_id LIKE users.usr_id

  CALL menuthroughtables(pint_user_id,"main")
    RETURNING lint_ret, lint_action, pint_user_id

  --IF setup.g_app_backoffice THEN
    --OPEN WINDOW w_user_menu WITH FORM "user_menu"
  --END IF

  --MENU %"Menu"
    --BEFORE MENU
      --CALL core_db.users_select_row(pint_user_id, FALSE)
        --RETURNING lint_ret, lstr_msg, lrec_user.*
      --CALL usermenu_ui_set_action_state(DIALOG,pint_user_id)
--
    --ON ACTION infl_campaigns ATTRIBUTES(DISCLOSUREINDICATOR)
      --CALL campaigns_mobile.campaignlist_open_form_mobile()
          --RETURNING lint_ret, lint_action
      --CALL usermenu_ui_set_action_state(DIALOG,pint_user_id)
    --ON ACTION infl_yourdetail ATTRIBUTES(DISCLOSUREINDICATOR)
      --CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_DETAILS)
        --RETURNING lint_ret, lint_action, lint_user_id
      --CALL usermenu_ui_set_action_state(DIALOG,pint_user_id)
    --ON ACTION infl_financialdata ATTRIBUTES(DISCLOSUREINDICATOR)
      --MENU %"Remuneration"
        --BEFORE MENU
          --CALL DIALOG.setActionActive("infl_postprices", FALSE)
          --CALL DIALOG.setActionHidden("infl_postprices", TRUE)
        --ON ACTION infl_rates ATTRIBUTES(DISCLOSUREINDICATOR)
          --CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_RATES)
            --RETURNING lint_ret, lint_action, lint_user_id
        --ON ACTION infl_bankdata ATTRIBUTES(DISCLOSUREINDICATOR)
          --CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_BANK)
            --RETURNING lint_ret, lint_action, lint_user_id
        --ON ACTION infl_postprices ATTRIBUTES(DISCLOSUREINDICATOR)
          --CALL userpostprices.userpostpricelist_open_form_by_key(pint_user_id)
            --RETURNING lint_ret, lint_action
        --ON ACTION infl_postpriceshelp ATTRIBUTES(DISCLOSUREINDICATOR)
          --CALL userpostprices.userpostprice_eurosymbolshelp()
            --RETURNING lint_ret, lint_action
        --ON ACTION close
          --EXIT MENU
      --END MENU
      --CALL usermenu_ui_set_action_state(DIALOG,pint_user_id)
    --ON ACTION infl_notifications ATTRIBUTES(DISCLOSUREINDICATOR)
      --CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_NOTIFICATION)
        --RETURNING lint_ret, lint_action, lint_user_id
      --CALL usermenu_ui_set_action_state(DIALOG,pint_user_id)
    --ON ACTION infl_socialnetworks ATTRIBUTES(DISCLOSUREINDICATOR)
      --CALL usersocialnetworks.usersocialnetworklist_open_form_by_key(pint_user_id)
        --RETURNING lint_ret, lint_action
      --CALL usermenu_ui_set_action_state(DIALOG,pint_user_id)
    --ON ACTION signout
      --LET lint_action = C_APPACTION_LOGOUT
      --EXIT MENU
  --END MENU
  --IF setup.g_app_backoffice THEN
    --CLOSE WINDOW w_user_menu
  --END IF
  RETURN lint_ret, lint_action, pint_user_id
END FUNCTION

Function doMenuAction(pint_user_id,menuact,amenu)
  Define
    menuact String,
    pint_user_id LIKE users.usr_id,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lint_user_id LIKE users.usr_id,
    level      String,
    amenu      Dynamic Array Of Record
      menuname   String,
      menuimg    String,
      menuact    String
               End Record

  Case menuact
    When "infl_campaigns"
      CALL campaigns_mobile.campaignlist_open_form_mobile() RETURNING lint_ret, lint_action
    When "infl_yourdetail"
      CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_DETAILS) RETURNING lint_ret, lint_action, lint_user_id
    When "infl_financialdata"
      CALL menuthroughtables(pint_user_id,"infl_financialdata") RETURNING lint_ret, lint_action, pint_user_id
    When "infl_notifications"
      CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_NOTIFICATION) RETURNING lint_ret, lint_action, lint_user_id
    When "infl_socialnetworks"
      CALL usersocialnetworks.usersocialnetworklist_open_form_by_key(pint_user_id) RETURNING lint_ret, lint_action
    When "signout"
      LET lint_action = C_APPACTION_LOGOUT

    When "infl_rates"
      CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_RATES) RETURNING lint_ret, lint_action, lint_user_id
    When "infl_bankdata"
      CALL usergrid_open_form_by_key(pint_user_id, C_APPSTATE_UPDATE, C_INFLUENCERMENU_BANK) RETURNING lint_ret, lint_action, lint_user_id
    When "infl_postprices"
      CALL userpostprices.userpostpricelist_open_form_by_key(pint_user_id) RETURNING lint_ret, lint_action
    When "infl_postpriceshelp"
      CALL userpostprices.userpostprice_eurosymbolshelp() RETURNING lint_ret, lint_action

  End Case
  RETURN lint_ret, lint_action, lint_user_id
End Function

Function menuthroughtables(pint_user_id,level)
  Define
    pint_user_id LIKE users.usr_id,
    lbool_isbackground Boolean,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lrec_user RECORD LIKE users.*,
    lint_user_id LIKE users.usr_id,
    level       String,
    buttonLabel String,
    amenu      Dynamic Array Of Record
      menuname   String,
      menuimg    String,
      menuact    String
               End Record

  LET lint_action = C_APPACTION_UNDEFINED
  LET lbool_isbackground = FALSE

  Case level
    When "main"
      Open Window wUserMenuMain With Form "user_menu"
      Display "footer-menu-1.jpg" To foot
    When "infl_financialdata"
      Open Window wUserMenuFinancialdata With Form "user_menu"
      Display "footer-financials-2.jpg" To foot
  End Case

  If ui_get_front_end_type() = C_FE_GMA Then
    Display Array amenu To srMenu.* ATTRIBUTES (Accept=False)
      Before Display
        CALL core_db.users_select_row(pint_user_id, FALSE) RETURNING lint_ret, lstr_msg, lrec_user.*
        CALL setMenuOptions(pint_user_id,level,amenu)

      On Action doMenu
        Call doMenuAction(pint_user_id,amenu[dialog.getCurrentRow("srmenu")].menuact,amenu) RETURNING lint_ret, lint_action, lint_user_id
        CALL setMenuOptions(pint_user_id,level,amenu)
        If lint_action = C_APPACTION_LOGOUT Then
          Exit Display
        End If

      On Action cancel Attributes (ContextMenu=No,DefaultView=No)
        If level = "main" Then
          LET lint_action = C_APPACTION_UNDEFINED
        End If
        Exit Display
    End Display
  Else
    If level = "main" Then
      Let buttonLabel = LSTR("Back")
    Else
      Let buttonLabel = LSTR("Menu")
    End If
    Display Array amenu To srMenu.* ATTRIBUTES (Accept=False)
      Before Display
        CALL core_db.users_select_row(pint_user_id, FALSE) RETURNING lint_ret, lstr_msg, lrec_user.*
        CALL setMenuOptions(pint_user_id,level,amenu)

      On Action doMenu
        Call doMenuAction(pint_user_id,amenu[dialog.getCurrentRow("srmenu")].menuact,amenu) RETURNING lint_ret, lint_action, lint_user_id
        If lint_action = C_APPACTION_LOGOUT Then
          Exit Display
        End If

      On Action cancel Attributes (ContextMenu=No,Text=buttonLabel)
        If level = "main" Then
          LET lint_action = C_APPACTION_UNDEFINED
        End If
        Exit Display
    End Display
  End If

  Case level
    When "main"
      Close Window wUserMenuMain
    When "infl_financialdata"
      Close Window wUserMenuFinancialdata
  End Case

  RETURN lint_ret, lint_action, pint_user_id
END FUNCTION

#+ Fetch and display users
#+
#+ @param pint_user_id current user
#+ @param pint_state current state invoked
#+ @param pint_displaygroup_id indicates which group to display in the grid
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION usergrid_open_form_by_key(pint_user_id, pint_state, pint_displaygroup_id)
  DEFINE
    pint_user_id LIKE users.usr_id,
    pint_state SMALLINT,
    pint_displaygroup_id SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  LET mint_workinggroup_id = pint_displaygroup_id
  IF mint_workinggroup_id IS NULL OR mint_workinggroup_id==0 THEN
    LET mint_workinggroup_id = C_INFLUENCERMENU_ALLGROUPS
  END IF
  LET mint_user_id = pint_user_id
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_user_grid WITH FORM "user_grid" ATTRIBUTES(STYLE=IIF(setup.g_app_backoffice AND pint_state==C_APPSTATE_DISPLAY, "centerwindowpopup","centerwindow"))
  CASE pint_state
    WHEN C_APPSTATE_DISPLAY
      CALL usergrid_display() RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_ADD
      CALL usergrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL usergrid_update(pint_state) RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_user_grid
  RETURN lint_ret, lint_action, mint_user_id
END FUNCTION

#+ Dialog of the user display
#+
#+ @param pint_prev_state state from which the function was invoked
#+ @param pint_prev_action action from which the function was invoked
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION usergrid_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Profile"
  CALL FGL_SETTITLE(ff_formtitle)
  CALL usergrid_initialize_data(mint_user_id, C_DIALOGSTATE_DISPLAY)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  MENU ""
    BEFORE MENU
      CALL accountstatus_combobox_initializer()
      CALL gender_combobox_initializer()
      CALL usergrid_ui_set_action_state(DIALOG, C_DIALOGSTATE_DISPLAY, FALSE)
      DISPLAY BY NAME ff_formtitle
      DISPLAY mrec_usergrid.* TO scr_user_grid.*
      Display mrec_location.* To scr_loc.*
    ON ACTION viewsocialnetwork
      CALL layout.open_socialnetwork_account(C_SOCIALNETWORK_INSTAGRAM, mrec_usergrid.user.usr_instagram_username)
    ON ACTION cancel
      LET mint_user_id = mrec_usergrid.user.usr_id
      LET lint_action = C_APPACTION_CLOSE
      EXIT MENU
  END MENU
  RETURN lint_ret, lint_action
END FUNCTION

#+ Create a profile for a user
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION usergrid_create(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL usergrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a profile for a user
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION usergrid_update(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL usergrid_input(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lint_action
    --we want to stay in the influencer edition
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
#+ @return     0|error, next performed action id
FUNCTION usergrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    frontcall_return STRING,
    lstr_tmp STRING
  Define
    la_val        Dynamic Array Of String,
    oldCountry    String,
    oldState      String,
    oldCity       String,
    qry           String,
    countryList   Dynamic Array Of String,
    stateList     Dynamic Array Of String,
    cityList      Dynamic Array Of String,
    countryIdList Dynamic Array Of Integer,
    stateIdList   Dynamic Array Of Integer,
    cityIdList    Dynamic Array Of Integer,
    zoomKeyReturn Integer

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = IIF(pint_dialog_state==C_DIALOGSTATE_ADD, %"Create Profile",%"Edit Profile")
  IF mint_workinggroup_id IS NOT NULL AND mint_workinggroup_id <> C_INFLUENCERMENU_ALLGROUPS THEN
    --TODO:  get title according to displayed group
    --LET ff_formtitle =....
  END IF
  CALL FGL_SETTITLE(ff_formtitle)

  LET m_dialogtouched = FALSE
  CALL usergrid_initialize_data(mint_user_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_usergrid.*,mrec_location.* FROM scr_user_grid.*,scr_loc.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL accountstatus_combobox_initializer()
        CALL gender_combobox_initializer()

      AFTER INPUT
        If mrec_usergrid.user.usr_city_id Is Null Then
          Error %"City required"
          Next Field city
        End If
        If mrec_usergrid.user.usr_state_id Is Null Then
          Error %"State required"
          Next Field state
        End If
        If mrec_usergrid.user.usr_country_id Is Null Then
          Error %"Country required"
          Next Field country
        End If

      ON CHANGE usr_instagram_username
        IF instagram.instagramUserNameExist(DIALOG.getFieldBuffer("usr_instagram_username")) THEN
          ERROR %"Account not allowed"
          NEXT FIELD CURRENT
        END IF

      ON CHANGE usr_mobile_notifications
        Call notifications_clients.allowNotification(mrec_usergrid.user.usr_mobile_notifications,mrec_usergrid.user.usr_id,setup.g_device_id)

      Before Field cntr_name
        Let oldCountry = mrec_location.cntr_name

      ON CHANGE cntr_name
        Let qry = "select cntr_id,cntr_name from countries"
                  || IIF(fgl_dialog_getbuffer() Is Not Null,
                         " Where UPPER(cntr_name) Like UPPER('"
                           || fgl_dialog_getbuffer()
                           || "%')"
                        ," ")
                  ||" Order By cntr_sortname"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),countryList,countryIdList)
        Case countryList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_usergrid.user.usr_country_id = Null
          Otherwise
            Call Dialog.setCompleterItems(countryList)
        End Case
        LET m_dialogtouched = TRUE
        CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field cntr_name
        If Not oldCountry.equals(mrec_location.cntr_name) Then
          If countryList.getLength() > 0 And mrec_location.cntr_name Is Not Null Then
            Let mrec_usergrid.user.usr_country_id = IIF(countryList.search("",mrec_location.cntr_name)=0,-1,countryIdList[countryList.search("",mrec_location.cntr_name)])
            If mrec_usergrid.user.usr_country_id = -1 Then
              Let mrec_location.cntr_name = Null
              Let mrec_usergrid.user.usr_country_id = Null
            End If
            Let mrec_location.stt_name = Null
            Let mrec_usergrid.user.usr_state_id = Null
            Let mrec_location.cts_name = Null
            Let mrec_usergrid.user.usr_city_id = Null
          Else
            If mrec_location.cntr_name Is Not Null And mrec_usergrid.user.usr_country_id Is Not Null Then
            Else
              Let mrec_location.cntr_name = Null
              Let mrec_usergrid.user.usr_country_id = Null
            End If
            Let mrec_location.stt_name = Null
            Let mrec_usergrid.user.usr_state_id = Null
            Let mrec_location.cts_name = Null
            Let mrec_usergrid.user.usr_city_id = Null
          End If
          LET m_dialogtouched = TRUE
          CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call countryList.clear()
        Call countryIdList.clear()

      On Action zoomcountry
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"Country List","Select countries.cntr_id,countries.cntr_name From countries",Null,"countries.cntr_name",fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call core_db.sqlQuery("Select countries.cntr_id,countries.cntr_name From countries Where countries.cntr_id = "||zoomKeyReturn,la_val)
          If la_val.getLength()>0 Then
            Let mrec_usergrid.user.usr_country_id = la_val[1]
            Let mrec_location.cntr_name = la_val[2]
          Else
            Let mrec_usergrid.user.usr_country_id = Null
            Let mrec_location.cntr_name = Null
          End If
          Let mrec_location.stt_name = Null
          Let mrec_usergrid.user.usr_state_id = Null
          Let mrec_location.cts_name = Null
          Let mrec_usergrid.user.usr_city_id = Null
          LET m_dialogtouched = TRUE
          CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      Before Field stt_name
        Let oldState = mrec_location.stt_name

      ON CHANGE stt_name
        Let qry =
             "Select stt_id,stt_name From states"
             || IIF(mrec_location.cntr_name Is Not Null," Where stt_country_id = "||mrec_usergrid.user.usr_country_id," ")
             || IIF(fgl_dialog_getbuffer() Is Not Null,
                    IIF(mrec_location.cntr_name Is Not Null," And "," Where ") || "UPPER(stt_name) Like UPPER('"||fgl_dialog_getbuffer()||"%')"," ")
             || " Order By stt_name"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),stateList,stateIdList)
        Case stateList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_usergrid.user.usr_state_id = Null
          Otherwise
            Call Dialog.setCompleterItems(stateList)
        End Case
        LET m_dialogtouched = TRUE
        CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field stt_name
        If Not oldState.equals(mrec_location.stt_name) Then
          If stateList.getLength() > 0 And mrec_location.stt_name Is Not Null Then
            Let mrec_usergrid.user.usr_state_id = IIF(stateList.search("",mrec_location.stt_name)=0,-1,stateIdList[stateList.search("",mrec_location.stt_name)])
            If mrec_usergrid.user.usr_state_id = -1 Then
              Let mrec_location.stt_name = Null
              Let mrec_usergrid.user.usr_state_id = Null
            Else
              If mrec_usergrid.user.usr_country_id Is Null Then
                Call la_val.clear()
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_usergrid.user.usr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_usergrid.user.usr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            End If
            Let mrec_location.cts_name = Null
            Let mrec_usergrid.user.usr_city_id = Null
          Else
            If mrec_location.stt_name Is Not Null And mrec_usergrid.user.usr_state_id Is Not Null Then
              If mrec_usergrid.user.usr_country_id Is Null Then
                Call la_val.clear()
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_usergrid.user.usr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_usergrid.user.usr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            Else
              Let mrec_location.stt_name = Null
              Let mrec_usergrid.user.usr_state_id = Null
            End If
            Let mrec_location.cts_name = Null
            Let mrec_usergrid.user.usr_city_id = Null
          End If
          LET m_dialogtouched = TRUE
          CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call stateList.clear()
        Call stateIdList.clear()

      On Action zoomstate
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"State List","Select states.stt_id,states.stt_name||' ( '||countries.cntr_name||' ) ' From states,countries",
                    "states.stt_country_id = countries.cntr_id"||
                    IIF(mrec_usergrid.user.usr_country_id Is Not Null," And states.stt_country_id = "||mrec_usergrid.user.usr_country_id," "),
                    "states.stt_name",
                    fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call la_val.clear()
          Call core_db.sqlQuery("Select states.stt_id,states.stt_name From states Where states.stt_id = "||zoomKeyReturn,la_val)
          If la_val.getLength() > 0 Then
            Let mrec_usergrid.user.usr_state_id = la_val[1]
            Let mrec_location.stt_name = la_val[2]
          Else
            Let mrec_usergrid.user.usr_state_id = Null
            Let mrec_location.stt_name = Null
          End If
          If mrec_usergrid.user.usr_country_id Is Null Then
            Call la_val.clear()
            Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_usergrid.user.usr_country_id = la_val[1]
              Let mrec_location.cntr_name = la_val[2]
            Else
              Let mrec_usergrid.user.usr_country_id = Null
              Let mrec_location.cntr_name = Null
            End If
          End If
          Let mrec_location.cts_name = Null
          Let mrec_usergrid.user.usr_city_id = Null
          LET m_dialogtouched = TRUE
          CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      Before Field cts_name
        Let oldCity = mrec_location.cts_name

      On Change cts_name
        Let qry =
             "Select cts_id,cts_name From cities"
             || IIF(mrec_usergrid.user.usr_country_id Is Not Null And mrec_usergrid.user.usr_state_id Is Null,
                    " Where cities.cts_state_id in (select stt_id From states Where stt_country_id = "||mrec_usergrid.user.usr_country_id||")",
                    " ")
             || IIF(mrec_usergrid.user.usr_state_id Is Not Null,
                    " Where cts_state_id = "||mrec_usergrid.user.usr_state_id,
                    " ")
             || IIF(fgl_dialog_getbuffer() Is Not Null,
                    IIF(mrec_usergrid.user.usr_state_id Is Not Null Or mrec_usergrid.user.usr_country_id Is Not Null,
                        " And ",
                        " Where ")|| "Upper(cts_name) Like Upper('"||fgl_dialog_getbuffer()||"%')",
                    " ")
             || " Order by cts_name"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),cityList,cityIdList)
        Case cityList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_usergrid.user.usr_city_id = Null
          Otherwise
            Call Dialog.setCompleterItems(cityList)
        End Case
        LET m_dialogtouched = TRUE
        CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field cts_name
        If Not oldCity.equals(mrec_location.cts_name) Then
          If cityList.getLength() > 0 And mrec_location.cts_name Is Not Null Then
            Let mrec_usergrid.user.usr_city_id = IIF(cityList.search("",mrec_location.cts_name)=0,-1,cityIdList[cityList.search("",mrec_location.cts_name)])
            If mrec_usergrid.user.usr_city_id = -1 Then
              Let mrec_location.cts_name = Null
              Let mrec_usergrid.user.usr_city_id = Null
            Else
              If mrec_usergrid.user.usr_state_id Is Null Then
                Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||mrec_usergrid.user.usr_city_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_usergrid.user.usr_state_id = la_val[1]
                  Let mrec_location.stt_name = la_val[2]
                Else
                  Let mrec_usergrid.user.usr_state_id = Null
                  Let mrec_location.stt_name = Null
                End If
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_usergrid.user.usr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_usergrid.user.usr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            End If
          Else
            If mrec_location.cts_name Is Not Null And mrec_usergrid.user.usr_city_id Is Not Null Then
              If mrec_usergrid.user.usr_state_id Is Null Then
                Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||mrec_usergrid.user.usr_city_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_usergrid.user.usr_state_id = la_val[1]
                  Let mrec_location.stt_name = la_val[2]
                Else
                  Let mrec_usergrid.user.usr_state_id = Null
                  Let mrec_location.stt_name = Null
                End If
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_usergrid.user.usr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_usergrid.user.usr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            Else
              Let mrec_location.cts_name = Null
              Let mrec_usergrid.user.usr_city_id = Null
            End If
          End If
          LET m_dialogtouched = TRUE
          CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call cityList.clear()
        Call cityIdList.clear()

      On Action zoomcity
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"City List","Select cities.cts_id,cities.cts_name||' ( '||states.stt_name||' - '||countries.cntr_name||' )' From cities,states,countries",
                    "cities.cts_state_id = states.stt_id And states.stt_country_id = countries.cntr_id"||
                    IIF(mrec_usergrid.user.usr_state_id Is Not Null," And cities.cts_state_id = "||mrec_usergrid.user.usr_state_id," ")||
                    IIF(mrec_usergrid.user.usr_country_id Is Not Null," And states.stt_country_id = "||mrec_usergrid.user.usr_country_id," "),
                    "cities.cts_name",
                    fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call core_db.sqlQuery("Select cities.cts_id,cities.cts_name From cities Where cities.cts_id = "||zoomKeyReturn,la_val)
              If la_val.getLength() > 0 Then
                Let mrec_usergrid.user.usr_city_id = la_val[1]
                Let mrec_location.cts_name = la_val[2]
              Else
                Let mrec_usergrid.user.usr_city_id = Null
                Let mrec_location.cts_name = Null
              End If
          If mrec_usergrid.user.usr_state_id Is Null Then
            Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||zoomKeyReturn,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_usergrid.user.usr_state_id = la_val[1]
              Let mrec_location.stt_name = la_val[2]
            Else
              Let mrec_usergrid.user.usr_state_id = Null
              Let mrec_location.stt_name = Null
            End If
            Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_usergrid.user.usr_country_id = la_val[1]
              Let mrec_location.cntr_name = la_val[2]
            Else
              Let mrec_usergrid.user.usr_country_id = Null
              Let mrec_location.cntr_name = Null
            End If
          End If
          LET m_dialogtouched = TRUE
          CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      ON CHANGE usr_gender_id
        LET m_dialogtouched = TRUE
        CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    END INPUT
    ON ACTION infl_postprices --we must be in backoffice app in update mode for having this action active
      IF m_dialogtouched THEN
        IF core_ui.ui_message(%"Question ?",%"Save the edition and continue?","yes","yes|cancel","fa-question") == "yes" THEN
          CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
            CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
            CONTINUE DIALOG
          END IF
          LET mint_user_id = mrec_usergrid.user.usr_id
        ELSE
          CONTINUE DIALOG
        END IF
      END IF
      CALL userpostprices.userpostpricelist_open_form_by_key(mrec_usergrid.user.usr_id)
        RETURNING lint_ret, lint_action
      IF lint_ret == 0 THEN
        IF lint_action <> C_APPACTION_CANCEL THEN
          EXIT DIALOG
        END IF
      END IF
    ON ACTION infl_socialnetworks --we must be in backoffice app in update mode for having this action active
      IF m_dialogtouched THEN
        IF core_ui.ui_message(%"Question ?",%"Save the edition and continue?","yes","yes|cancel","fa-question") == "yes" THEN
          CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
            CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
            CONTINUE DIALOG
          END IF
          LET mint_user_id = mrec_usergrid.user.usr_id
        ELSE
          CONTINUE DIALOG
        END IF
      END IF
      CALL usersocialnetworks.usersocialnetworklist_open_form_by_key(mrec_usergrid.user.usr_id)
        RETURNING lint_ret, lint_action
      IF lint_ret == 0 THEN
        IF lint_action <> C_APPACTION_CANCEL THEN
          EXIT DIALOG
        END IF
      END IF
    ON ACTION viewsocialnetwork
      CALL layout.open_socialnetwork_account(C_SOCIALNETWORK_INSTAGRAM, mrec_usergrid.user.usr_instagram_username)
    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    ON ACTION validate_influencer
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_INFLUENCER_VALIDATE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION cancel_influencer
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_INFLUENCER_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION reject_influencer
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_INFLUENCER_REJECT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION suspend_influencer
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_INFLUENCER_SUSPEND)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION delete_influencer
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_INFLUENCER_DELETE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION save_mobile ATTRIBUTE(TEXT=%"Done") --gmi action panel
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_user_id = mrec_usergrid.user.usr_id
      LET lint_action = C_APPACTION_ACCEPT
      IF setup.g_app_influencer THEN
        LET setup.g_loggedin_id = mint_user_id
      END IF
      EXIT DIALOG
    ON ACTION save
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_user_id = mrec_usergrid.user.usr_id
      LET lint_action = C_APPACTION_ACCEPT
      IF setup.g_app_influencer THEN
        LET setup.g_loggedin_id = mint_user_id
      END IF
      EXIT DIALOG
    ON ACTION cancel ATTRIBUTE(TEXT=%"Cancel")
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_user_id = mrec_usergrid.user.usr_id
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    ON ACTION customaction
      CALL usergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      LET mint_user_id = mrec_usergrid.user.usr_id
      EXIT DIALOG
    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL usergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      IF setup.g_app_backoffice THEN
        DISPLAY BY NAME ff_formtitle
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,IIF(pint_dialog_state==C_DIALOGSTATE_ADD, "addinfluencer_page", "updateinfluencer_page"), setup.g_loggedin_name) RETURNING frontcall_return
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
FUNCTION usergrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT,
    lbool_allow_validate BOOLEAN,
    lbool_allow_cancel BOOLEAN,
    lbool_allow_reject BOOLEAN,
    lbool_allow_suspend BOOLEAN,
    lbool_allow_delete BOOLEAN

  LET lbool_allow_validate = FALSE
  LET lbool_allow_cancel = FALSE
  LET lbool_allow_reject = FALSE
  LET lbool_allow_suspend = FALSE
  LET lbool_allow_delete = FALSE

  IF core_ui.ui_action_exist("infl_postprices") THEN
    CALL core_ui.ui_set_node_attribute("Button","name","infl_postprices","hidden", TRUE)
    CALL p_dialog.setActionActive("infl_postprices", FALSE)
  END IF

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionHidden("dialogtouched", TRUE)
      CALL p_dialog.setActionHidden("close", TRUE)
      CALL p_dialog.setActionActive("save_mobile", pbool_dialog_touched AND setup.g_app_is_mobile)
      CALL p_dialog.setActionHidden("save_mobile", NOT setup.g_app_is_mobile)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("save", NOT setup.g_app_backoffice)
      --CALL core_ui.ui_set_node_attribute("Button","name","infl_postprices","hidden", TRUE)
      --CALL p_dialog.setActionActive("infl_postprices", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","infl_socialnetworks","hidden", TRUE)
      CALL p_dialog.setActionActive("infl_socialnetworks", FALSE)
      CALL p_dialog.setActionActive("viewsocialnetwork", FALSE)

      IF NOT setup.g_app_backoffice THEN
        CALL core_ui.ui_set_node_attribute("Label","name","users_emailvalidationdate_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_emailvalidationdate","hidden", "1")
        CALL core_ui.ui_set_node_attribute("Label","name","user_accountstatus_id_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_accountstatus_id","hidden", "1")
      END IF
      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", "1")
      CALL core_ui.ui_set_node_attribute("Button","name","validate_influencer","hidden","1")
      CALL p_dialog.setActionActive("validate_influencer", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","cancel_influencer","hidden","1")
      CALL p_dialog.setActionActive("cancel_influencer", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","reject_influencer","hidden","1")
      CALL p_dialog.setActionActive("reject_influencer", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","suspend_influencer","hidden","1")
      CALL p_dialog.setActionActive("suspend_influencer", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","delete_influencer","hidden","1")
      CALL p_dialog.setActionActive("delete_influencer", FALSE)

      IF setup.g_app_backoffice THEN
        CALL layout.display_savebutton(pbool_dialog_touched)
        CALL usergrid_viewinstagramaccount(mrec_usergrid.user.usr_instagram_username)
      END IF
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.usr_instagram_profilepicture","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ffimage_value","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)

      --display password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_birthday_label","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_birthday","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_password","hidden",setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM))
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_password","hidden",setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM))
      CALL core_ui.ui_set_node_attribute("Label","name","users1_usr_password","hidden",setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM))
      CALL core_ui.ui_set_node_attribute("FormField","name","users1.usr_password","hidden",setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM))
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_address_number_label","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_address_number","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_address_street_label","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_address_street","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_address_zipcode_label","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_address_zipcode","hidden",setup.g_app_influencer)
      --CALL core_ui.ui_set_node_attribute("Label","name","users_usr_address_town_label","hidden",setup.g_app_influencer)
      --CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_address_town","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_address_more_label","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_address_more","hidden",setup.g_app_influencer)

      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_instagram_username","noEntry",setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM))
      
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
      --CALL core_ui.ui_set_node_attribute("Button","name","infl_postprices","hidden", NOT setup.g_app_backoffice)
      --CALL p_dialog.setActionActive("infl_postprices", setup.g_app_backoffice)
      CALL core_ui.ui_set_node_attribute("Button","name","infl_socialnetworks","hidden", NOT setup.g_app_backoffice)
      CALL p_dialog.setActionActive("infl_socialnetworks", setup.g_app_backoffice)
      CALL p_dialog.setActionActive("viewsocialnetwork", setup.g_app_backoffice)

      IF NOT setup.g_app_backoffice THEN
        CALL core_ui.ui_set_node_attribute("Label","name","users_emailvalidationdate_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_emailvalidationdate","hidden", "1")
        CALL core_ui.ui_set_node_attribute("Label","name","user_accountstatus_id_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_accountstatus_id","hidden", "1")
      END IF
      LET lbool_allow_validate = user_allow_validate(mrec_usergrid.user.usr_accountstatus_id)
      LET lbool_allow_cancel = user_allow_cancel(mrec_usergrid.user.usr_accountstatus_id)
      LET lbool_allow_reject = user_allow_reject(mrec_usergrid.user.usr_accountstatus_id)
      LET lbool_allow_suspend = user_allow_suspend(mrec_usergrid.user.usr_accountstatus_id)
      LET lbool_allow_delete = user_allow_delete(mrec_usergrid.user.usr_accountstatus_id)
      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", (NOT setup.g_app_backoffice)
        OR NOT (lbool_allow_validate OR lbool_allow_cancel OR lbool_allow_reject OR lbool_allow_suspend OR lbool_allow_delete))
      CALL core_ui.ui_set_node_attribute("Button","name","validate_influencer","hidden",(NOT setup.g_app_backoffice) OR (NOT lbool_allow_validate))
      CALL p_dialog.setActionActive("validate_influencer", setup.g_app_backoffice AND lbool_allow_validate)
      CALL core_ui.ui_set_node_attribute("Button","name","cancel_influencer","hidden",(NOT setup.g_app_backoffice) OR (NOT lbool_allow_cancel))
      CALL p_dialog.setActionActive("cancel_influencer", setup.g_app_backoffice AND lbool_allow_cancel)
      CALL core_ui.ui_set_node_attribute("Button","name","reject_influencer","hidden",(NOT setup.g_app_backoffice) OR (NOT lbool_allow_reject))
      CALL p_dialog.setActionActive("reject_influencer", setup.g_app_backoffice AND lbool_allow_reject)
      CALL core_ui.ui_set_node_attribute("Button","name","suspend_influencer","hidden",(NOT setup.g_app_backoffice) OR (NOT lbool_allow_suspend))
      CALL p_dialog.setActionActive("suspend_influencer", setup.g_app_backoffice AND lbool_allow_suspend)
      CALL core_ui.ui_set_node_attribute("Button","name","delete_influencer","hidden",(NOT setup.g_app_backoffice) OR (NOT lbool_allow_delete))
      CALL p_dialog.setActionActive("delete_influencer", setup.g_app_backoffice AND lbool_allow_delete)

      IF setup.g_app_backoffice THEN
        CALL layout.display_savebutton(pbool_dialog_touched)
        CALL usergrid_viewinstagramaccount(mrec_usergrid.user.usr_instagram_username)
      END IF
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.usr_instagram_profilepicture","hidden","0")
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ffimage_value","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)

      --hide password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","users1_usr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","users1.usr_password","hidden","1")

      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_instagram_username","noEntry",setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM))

      CALL p_dialog.setActionActive("customaction", setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("customaction", NOT setup.g_app_backoffice)

    WHEN C_DIALOGSTATE_DISPLAY
      --CALL core_ui.ui_set_node_attribute("Button","name","infl_postprices","hidden", "1")
      CALL core_ui.ui_set_node_attribute("Button","name","infl_socialnetworks","hidden", "1")
      IF setup.g_app_backoffice THEN
        CALL usergrid_viewinstagramaccount(mrec_usergrid.user.usr_instagram_username)
      END IF

      IF NOT setup.g_app_backoffice THEN
        CALL core_ui.ui_set_node_attribute("Label","name","users_emailvalidationdate_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_emailvalidationdate","hidden", "1")
        CALL core_ui.ui_set_node_attribute("Label","name","user_accountstatus_id_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_accountstatus_id","hidden", "1")
      END IF
      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", "1")
      CALL core_ui.ui_set_node_attribute("Button","name","validate_influencer","hidden","1")
      CALL core_ui.ui_set_node_attribute("Button","name","cancel_influencer","hidden","1")
      CALL core_ui.ui_set_node_attribute("Button","name","reject_influencer","hidden","1")
      CALL core_ui.ui_set_node_attribute("Button","name","suspend_influencer","hidden","1")
      CALL core_ui.ui_set_node_attribute("Button","name","delete_influencer","hidden","1")

      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.usr_instagram_profilepicture","hidden","0")
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ffimage_value","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)

      --hide password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","users_usr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","users.usr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","users1_usr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","users1.usr_password","hidden","1")

  END CASE
  CALL layout.display_phonenumberprefix(mrec_usergrid.user.usr_country_id)

  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_detail","hidden", (mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_INFLUENCERMENU_DETAILS))
  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_address","hidden", (mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_INFLUENCERMENU_DETAILS))
  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_instagram","hidden", (mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS))
  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_notifications","hidden", (mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_INFLUENCERMENU_NOTIFICATION))
  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_rates","hidden", (pint_dialog_state==C_DIALOGSTATE_ADD AND setup.g_app_influencer) OR ((mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_INFLUENCERMENU_RATES)))
  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_bank","hidden", (pint_dialog_state==C_DIALOGSTATE_ADD AND setup.g_app_influencer) OR (pint_dialog_state==C_DIALOGSTATE_DISPLAY AND setup.g_app_backoffice) OR ((mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS) AND (mint_workinggroup_id<>C_INFLUENCERMENU_BANK)))

  CALL core_ui.ui_set_node_attribute("Group","name","group_influencer_metrics","hidden", (pint_dialog_state==C_DIALOGSTATE_ADD AND setup.g_app_influencer) OR (mint_workinggroup_id<>C_INFLUENCERMENU_ALLGROUPS))
END FUNCTION

#+ Initializes the user business record
#+
#+ @param pint_user_id current user
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER
#+ @return     0|error
FUNCTION usergrid_initialize_data(pint_user_id, pint_dialog_state)
  DEFINE
    pint_user_id LIKE users.usr_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    instagramUser t_instagramUser,
    la_val   Dynamic Array Of String

  INITIALIZE mrec_usergrid.* TO NULL
  INITIALIZE mrec_copy_usergrid.* TO NULL
  INITIALIZE mrec_db_user.* TO NULL
  INITIALIZE mrec_db_usermetric.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_usergrid.user.usr_id = 0
      LET mrec_usergrid.user.usr_email_style = C_EMAILSTYLE_HTML
      LET mrec_usergrid.user.usr_notif_style = C_NOTIFSTYLE_TEXT
      LET mrec_usergrid.user.usr_gender_id = C_GENDER_OTHER
      LET mrec_usergrid.user.usr_country_id = C_COUNTRY_FRANCE
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_usergrid.user.usr_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      LET mrec_usergrid.user.usr_state_id   = C_STATE_IDF
      Call core_db.sqlQuery("Select stt_name From states Where stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.stt_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_state_id = Null
        Let mrec_location.stt_name = Null
      End If
      LET mrec_usergrid.user.usr_city_id    = C_CITY_PARIS1
      Call core_db.sqlQuery("Select cts_name From cities Where cts_id = "||mrec_usergrid.user.usr_city_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cts_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_city_id = Null
        Let mrec_location.cts_name = Null
      End If
      LET mrec_usergrid.user.usr_mobile_notifications = 1
      LET mrec_usergrid.user.usr_email_notifications = 0
      LET mrec_usergrid.user.usr_currency_id = C_CURRENCY_EURO
      LET mrec_usergrid.user.usr_accountstatus_id = C_ACCOUNTSTATUS_INCOMPLETE
      LET mrec_usergrid.user.usr_createdby_id = IIF(setup.g_app_influencer, C_CREATEDBY_INFLUENCER, C_CREATEDBY_SALFATIX)

      --initialize Instagram fields in case the influncer is created his account
      IF setup.g_app_influencer AND (setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM) THEN
        --set default fake password because user connects only via instagram (so we don't have any password)
        LET mrec_usergrid.user.usr_password = "x"
        LET mrec_usergrid.password2 = mrec_usergrid.user.usr_password
        
        CALL util.JSON.parse(setup.g_signin_socialnetwork_answer, instagramUser)
        LET mrec_usergrid.user.usr_instagram_userid = instagramUser.user.id
        LET mrec_usergrid.user.usr_instagram_username = instagramUser.user.username
        LET mrec_usergrid.user.usr_instagram_fullname = instagramUser.user.full_name
        LET mrec_usergrid.user.usr_instagram_profilepicture = instagramUser.user.profile_picture
        LET mrec_usergrid.user.usr_instagram_biography = instagramUser.user.bio
        LET mrec_usergrid.user.usr_instagram_website = instagramUser.user.website
        LET mrec_usergrid.user.usr_instagram_is_business = instagramUser.user.is_business
        LET mrec_usergrid.user.usr_instagram_token = instagramUser.access_token
      END IF

      LET mrec_usergrid.usr_instagram_profilepicture = NVL(mrec_usergrid.usr_instagram_profilepicture,_get_default_photo(mrec_usergrid.user.usr_instagram_profilepicture))

    WHEN C_DIALOGSTATE_UPDATE
      CALL usergrid_get_data_by_key(pint_user_id)
        RETURNING lint_ret, lstr_msg, mrec_usergrid.*, mrec_db_user.*, mrec_db_usermetric.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_usergrid.user.usr_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      Call core_db.sqlQuery("Select stt_name From states Where stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.stt_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_state_id = Null
        Let mrec_location.stt_name = Null
      End If
      Call core_db.sqlQuery("Select cts_name From cities Where cts_id = "||mrec_usergrid.user.usr_city_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cts_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_city_id = Null
        Let mrec_location.cts_name = Null
      End If
      LET mrec_copy_usergrid.* = mrec_usergrid.*
    WHEN C_DIALOGSTATE_DISPLAY
      CALL usergrid_get_data_by_key(pint_user_id)
        RETURNING lint_ret, lstr_msg, mrec_usergrid.*, mrec_db_user.*, mrec_db_usermetric.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_usergrid.user.usr_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      Call core_db.sqlQuery("Select stt_name From states Where stt_id = "||mrec_usergrid.user.usr_state_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.stt_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_state_id = Null
        Let mrec_location.stt_name = Null
      End If
      Call core_db.sqlQuery("Select cts_name From cities Where cts_id = "||mrec_usergrid.user.usr_city_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cts_name = la_val[1]
      Else
        Let mrec_usergrid.user.usr_city_id = Null
        Let mrec_location.cts_name = Null
      End If
      LET mrec_copy_usergrid.* = mrec_usergrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_usergrid
#+
#+ @param pint_user_id user id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_usergrid business record, user database record
FUNCTION usergrid_get_data_by_key(pint_user_id)
  DEFINE
    pint_user_id LIKE users.usr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*,
    lrec_ui_user t_usergrid,
    lrec_db_user RECORD LIKE users.*,
    lrec_db_usermetric RECORD LIKE usermetrics.*,
    lrec_usermetric RECORD LIKE usermetrics.*

  INITIALIZE lrec_ui_user.* TO NULL
  CALL core_db.users_select_row(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_user.*, lrec_db_user.*, lrec_db_usermetric.*
  END IF

  LET lrec_ui_user.user.* = lrec_user.*
  CALL core_db.usermetrics_select_current_row_by_userid(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_usermetric.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_user.*, lrec_db_user.*, lrec_db_usermetric.*
  END IF
  IF lint_ret == NOTFOUND THEN
    LET lint_ret = 0
    INITIALIZE lrec_usermetric.* TO NULL
  END IF
  LET lrec_ui_user.usermetric.* = lrec_usermetric.*
  LET lrec_ui_user.password2 = lrec_user.usr_password
  LET lrec_ui_user.usr_instagram_profilepicture = _get_default_photo(lrec_ui_user.user.usr_instagram_profilepicture)
  LET lrec_db_user.* = lrec_user.*
  LET lrec_db_usermetric.* = lrec_usermetric.*
  RETURN lint_ret, lstr_msg, lrec_ui_user.*, lrec_db_user.*, lrec_db_usermetric.*
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
FUNCTION usergrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_user_id LIKE users.usr_id,
    lint_accountstatus_id LIKE users.usr_accountstatus_id

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
            IF core_ui.ui_message(%"Question ?",%"Abort profile edition?","no","yes|no","fa-question") == "yes" THEN
              LET lbool_restore_data = TRUE
            END IF
          END IF
        WHEN C_APPACTION_INFLUENCER_VALIDATE
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_VALIDATED
        WHEN C_APPACTION_INFLUENCER_CANCEL
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_CANCELLED
        WHEN C_APPACTION_INFLUENCER_REJECT
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_STOPPED
        WHEN C_APPACTION_INFLUENCER_SUSPEND
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_SUSPENDED
        WHEN C_APPACTION_INFLUENCER_DELETE
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_DELETED
    END CASE
    OTHERWISE --do nothing
      RETURN 0, NULL
  END CASE
  IF lbool_insert_data THEN
    CALL user_validate_data(C_DIALOGSTATE_ADD, mint_workinggroup_id)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL user_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_user_id
    --IF lint_ret == 0 THEN
    --  IF core_ui.ui_message(%"Information",%"Profile registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_usergrid.user.usr_id = lint_user_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
    CALL notifications.sendmail_influencer_creation(mrec_usergrid.user.usr_id)
  END IF

  IF lbool_update_data THEN
    CALL user_validate_data(C_DIALOGSTATE_UPDATE, mint_workinggroup_id)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --we need to reset emailvalidationdate field in case the email has changed
    IF mrec_db_user.usr_email <> mrec_usergrid.user.usr_email THEN
      INITIALIZE mrec_usergrid.user.usr_emailvalidationdate TO NULL
    END IF
    CALL user_update_into_dabatase(lint_accountstatus_id)
      RETURNING lint_ret, lstr_msg
    --IF lint_ret == 0 THEN
    --  IF core_ui.ui_message(%"Information",%"Profile updated","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
    IF mrec_db_user.usr_email <> mrec_usergrid.user.usr_email THEN 
      CALL notifications.sendmail_influencer_emailupdate(mrec_usergrid.user.usr_id)
    END IF
    IF pint_dialog_action == C_APPACTION_INFLUENCER_VALIDATE THEN
      CALL notifications.sendmail_influencer_validated(mrec_usergrid.user.usr_id)
    END IF
    IF pint_dialog_action == C_APPACTION_INFLUENCER_REJECT THEN
      CALL notifications.sendmail_influencer_rejected(mrec_usergrid.user.usr_id, mrec_db_user.usr_accountstatus_id)
    END IF
  END IF

  IF lbool_restore_data THEN
    CALL usergrid_initialize_data(mrec_usergrid.user.usr_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL usergrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_user_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL usergrid_initialize_data(mrec_usergrid.user.usr_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL usergrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_user_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a user into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, user id
FUNCTION user_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*,
    lrec_usermetric RECORD LIKE usermetrics.*,
    lint_status INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_user.usr_id
  END IF
  LET l_timestamp = CURRENT
  INITIALIZE lrec_user.* TO NULL
  LET lrec_user.* = mrec_usergrid.user.*
  LET lrec_user.usr_id = 0
  LET lrec_user.usr_password = hash.compute_hash(lrec_user.usr_password, "BCRYPT", FALSE)
  LET lrec_user.usr_creationdate = l_timestamp
  CALL core_db.users_insert_row(lrec_user.*)
    RETURNING lint_ret, lstr_msg, lrec_user.usr_id
  IF lint_ret == 0 THEN
    INITIALIZE lrec_usermetric.* TO NULL
    LET lrec_usermetric.* = mrec_usergrid.usermetric.*
    LET lrec_usermetric.usrmtc_id = 0
    LET lrec_usermetric.usrmtc_usr_id = lrec_user.usr_id
    LET lrec_usermetric.usrmtc_bdate = l_timestamp
    LET lrec_usermetric.usrmtc_edate = "9999-12-31 23:59:59"
    CALL core_db.usermetrics_insert_row(lrec_usermetric.*)
      RETURNING lint_ret, lstr_msg, lrec_usermetric.usrmtc_id
  END IF
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_user.usr_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_user.usr_id
END FUNCTION

#+ Update a user into database
#+
#+ @param pint_status_id user account status
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION user_update_into_dabatase(pint_status_id)
  DEFINE
    pint_status_id LIKE users.usr_accountstatus_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*,
    lrec_usermetric RECORD LIKE usermetrics.*,
    lrec_tmp RECORD LIKE usermetrics.*,
    lint_status INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET l_timestamp = CURRENT
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  INITIALIZE lrec_user.* TO NULL
  LET lrec_user.* = mrec_usergrid.user.*
  IF pint_status_id IS NOT NULL AND pint_status_id > 0 THEN
    CASE pint_status_id
      WHEN C_ACCOUNTSTATUS_VALIDATED
        LET lrec_user.usr_validationdate = l_timestamp
      WHEN C_ACCOUNTSTATUS_CANCELLED
        LET lrec_user.usr_canceldate = l_timestamp
      WHEN C_ACCOUNTSTATUS_STOPPED
        LET lrec_user.usr_stopdate = l_timestamp
      WHEN C_ACCOUNTSTATUS_SUSPENDED
        LET lrec_user.usr_suspendeddate = l_timestamp
      WHEN C_ACCOUNTSTATUS_DELETED
        LET lrec_user.usr_deletiondate = l_timestamp
    END CASE
    LET lrec_user.usr_accountstatus_id = pint_status_id
  END IF
  LET lrec_user.usr_lastupdatedate = l_timestamp
  CALL core_db.users_update_row(mrec_db_user.*, lrec_user.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL usermetrics_select_row(mrec_usergrid.usermetric.usrmtc_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_tmp.*
    CASE lint_ret
      WHEN 0
        LET lrec_usermetric.* = mrec_usergrid.usermetric.*
        CALL core_db.usermetrics_update_row(mrec_db_usermetric.*, lrec_usermetric.*)
          RETURNING lint_ret, lstr_msg
      WHEN NOTFOUND
        INITIALIZE lrec_usermetric.* TO NULL
        LET lrec_usermetric.* = mrec_usergrid.usermetric.*
        LET lrec_usermetric.usrmtc_id = 0
        LET lrec_usermetric.usrmtc_usr_id = lrec_user.usr_id
        LET lrec_usermetric.usrmtc_bdate = l_timestamp
        LET lrec_usermetric.usrmtc_edate = "9999-12-31 23:59:59"
        CALL core_db.usermetrics_insert_row(lrec_usermetric.*)
          RETURNING lint_ret, lstr_msg, lrec_usermetric.usrmtc_id
      OTHERWISE
    END CASE
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

#+ Check business rules of a influencer
#+
#+ @param pint_dialog_state current DIALOG state
#+ @param pint_group_id group to validate
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION user_validate_data(pint_dialog_state, pint_group_id)
  DEFINE
    pint_dialog_state SMALLINT,
    pint_group_id SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_id BIGINT,
    lint_usertype SMALLINT

  --TODO : do validation of record

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_usergrid.user.usr_id IS NULL OR mrec_usergrid.user.usr_id==0 THEN
      RETURN -1, %"User missing"
    END IF
  END IF
  IF mrec_usergrid.user.usr_country_id IS NULL THEN
    RETURN -1, %"Country missing"
  END IF
  IF mrec_usergrid.user.usr_firstname IS NULL THEN
    RETURN -1, %"Firstname missing"
  END IF
  IF mrec_usergrid.user.usr_lastname IS NULL THEN
    RETURN -1, %"Lastname missing"
  END IF
  LET mrec_usergrid.user.usr_email = string.trim(mrec_usergrid.user.usr_email)
  IF mrec_usergrid.user.usr_email IS NULL THEN
    RETURN -1, %"Email missing"
  END IF
  IF NOT emails.check_format(mrec_usergrid.user.usr_email) THEN
    RETURN -1, %"Email Format Invalid"
  END IF
  CALL emails.get_usertype_and_id(mrec_usergrid.user.usr_email,C_USERTYPE_INFLUENCER)
    RETURNING lint_ret, lint_id, lint_usertype
  CASE lint_ret
    WHEN 0
      IF pint_dialog_state == C_DIALOGSTATE_ADD THEN
        RETURN -1, %"Email already used"
      ELSE --update
        IF (lint_usertype <> C_USERTYPE_INFLUENCER)
          OR (mrec_usergrid.user.usr_id <> lint_id)
        THEN
          RETURN -1, %"Email already used"
        END IF
      END IF
    WHEN NOTFOUND
    OTHERWISE --error case
      RETURN -1, %"Email already used"
  END CASE

  LET mrec_usergrid.user.usr_password = string.trim(mrec_usergrid.user.usr_password)
  IF mrec_usergrid.user.usr_password IS NULL THEN
    RETURN -1, %"Password missing"
  END IF
  IF pint_dialog_state==C_DIALOGSTATE_ADD THEN
    LET mrec_usergrid.password2 = string.trim(mrec_usergrid.password2)
    IF mrec_usergrid.password2 IS NULL THEN
      RETURN -1, %"Confirm Password missing"
    END IF
    IF mrec_usergrid.user.usr_password <> mrec_usergrid.password2 THEN
      RETURN -1, %"Passwords don't match"
    END IF
  END IF
  IF mrec_usergrid.user.usr_instagram_username IS NULL THEN
    RETURN -1, %"Instagram username missing"
  END IF
  IF mrec_usergrid.user.usr_accountstatus_id IS NULL THEN
    RETURN -1, %"Status missing"
  END IF
  IF mrec_usergrid.user.usr_createdby_id IS NULL THEN
    RETURN -1, %"CreatedBy missing"
  END IF
  IF pint_group_id==C_INFLUENCERMENU_ALLGROUPS OR pint_group_id==C_INFLUENCERMENU_DETAILS THEN
  END IF
  IF pint_group_id==C_INFLUENCERMENU_ALLGROUPS OR pint_group_id==C_INFLUENCERMENU_INSTAGRAM THEN
  END IF
  IF pint_group_id==C_INFLUENCERMENU_ALLGROUPS OR pint_group_id==C_INFLUENCERMENU_NOTIFICATION THEN
  END IF
  IF pint_group_id==C_INFLUENCERMENU_ALLGROUPS OR pint_group_id==C_INFLUENCERMENU_RATES THEN
  END IF
  IF pint_group_id==C_INFLUENCERMENU_ALLGROUPS OR pint_group_id==C_INFLUENCERMENU_BANK THEN
  END IF

  RETURN 0, NULL
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

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION userlist_get_default_sortby()
  RETURN "users.usr_instagram_username"
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION userlist_get_default_orderby()
  RETURN "asc"
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION userlist_get_default_sqlorderby()
  RETURN SFMT("%1 %2", userlist_get_default_sortby(), userlist_get_default_orderby())
END FUNCTION

#+ Initializer of the country combobox
#+
--FUNCTION country_combobox_initializer()
  --CALL combobox.country_initializer(ui.ComboBox.forName("users.usr_country_id"))
--END FUNCTION

#+ Initializer of the city combobox
#+
#+ @param pint_state_id state id
#+
--FUNCTION city_combobox_initializer(pint_state_id)
  --DEFINE
    --pint_state_id INTEGER
  --CALL combobox.city_initializer(ui.ComboBox.forName("users.usr_city_id"), pint_state_id)
--END FUNCTION

#+ Initializer of the state combobox
#+
#+ @param pint_country_id country id
#+
--FUNCTION state_combobox_initializer(pint_country_id)
  --DEFINE
    --pint_country_id INTEGER
  --CALL combobox.state_initializer(ui.ComboBox.forName("users.usr_state_id"), pint_country_id)
--END FUNCTION

#+ Initializer of the currency combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION user_currency_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox

  --DVM can't load directly the initializer in the combobox library so we set a local function loaded by the DVM instead
  --View doc :
  --https://intranet.4js.com/distrib/manuals/FOURJS/HTML/3.10/fjs-fgl-latest-manual-html/index.html#fgl-topics/c_fgl_FSFAttributes_INITIALIZER.html
  CALL combobox.currency_initializer(p_combo)
END FUNCTION

#+ Initializer of the currency combobox
#+
FUNCTION accountstatus_combobox_initializer()
  CALL combobox.accountstatus_initializer(ui.ComboBox.forName("users.usr_accountstatus_id"))
END FUNCTION

#+ Initializer of the gender combobox
#+
FUNCTION gender_combobox_initializer()
  CALL combobox.gender_initializer(ui.ComboBox.forName("users.usr_gender_id"))
END FUNCTION

#+ Display the default title for the list of influencers
#+
FUNCTION display_userlist_default_title()
  DEFINE
    ff_formtitle STRING
  LET ff_formtitle = mstr_influencerlist_default_title
  CALL FGL_SETTITLE(ff_formtitle)
  DISPLAY BY NAME ff_formtitle
END FUNCTION

#+ Checks if an influencer has been validated
#+
#+ @param pint_user_id user id
#+
#+ @returnType INTEGER, SMALLINT, INTEGER
#+ @return     0|error, next performed action id, user id
FUNCTION user_is_valid(pint_user_id)
  DEFINE
    pint_user_id LIKE users.usr_id,
    lint_ret INTEGER,
    lbool_ret BOOLEAN,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*

  CALL core_db.users_select_row(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  IF lint_ret ==0 THEN
    IF lrec_user.usr_accountstatus_id == C_ACCOUNTSTATUS_VALIDATED THEN
      LET lbool_ret = TRUE
    ELSE
      LET lbool_ret = FALSE
    END IF
  ELSE
    LET lbool_ret = FALSE
  END IF

  RETURN lbool_ret
END FUNCTION

#+ Checks if a influencer can be validated
#+
#+ @param pint_status_id current influencer status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION user_allow_validate(pint_status_id)
  DEFINE
    pint_status_id LIKE users.usr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_INCOMPLETE 
    OR pint_status_id == C_ACCOUNTSTATUS_SUSPENDED
  THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a influencer can be cancelled
#+
#+ @param pint_status_id current influencer status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION user_allow_cancel(pint_status_id)
  DEFINE
    pint_status_id LIKE users.usr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_INCOMPLETE THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a influencer can be rejected
#+
#+ @param pint_status_id current influencer status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION user_allow_reject(pint_status_id)
  DEFINE
    pint_status_id LIKE users.usr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_INCOMPLETE
    OR pint_status_id == C_ACCOUNTSTATUS_VALIDATED
    OR pint_status_id == C_ACCOUNTSTATUS_SUSPENDED
  THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a influencer can be validated
#+
#+ @param pint_status_id current influencer status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION user_allow_suspend(pint_status_id)
  DEFINE
    pint_status_id LIKE users.usr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_VALIDATED THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a influencer can be validated
#+
#+ @param pint_status_id current influencer status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION user_allow_delete(pint_status_id)
  DEFINE
    pint_status_id LIKE users.usr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_STOPPED THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Display the image to open an instagram account
#+
#+ @param pstr_account instagram account
#+
FUNCTION usergrid_viewinstagramaccount(pstr_account STRING)
  LET pstr_account = pstr_account.trim()
  IF pstr_account.getLength() > 0 THEN
    DISPLAY "fa-eye" TO viewimage
  END IF
END FUNCTION