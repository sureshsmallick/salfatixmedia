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
  t_userpostpricelist RECORD
    userpostprice RECORD LIKE userpostprices.*,
    pstt_name LIKE posttypes.pstt_name,
    crr_symbol LIKE currencies.crr_name,
    delimage STRING,
    editimage STRING,
    freeofcharge STRING,
    salfatixlabel STRING,
    salfatixcrr_symbol LIKE currencies.crr_name,
    salfatixfreeofcharge STRING
  END RECORD
TYPE
  t_userpostpricegrid RECORD
    userpostprice RECORD LIKE userpostprices.*,
    crr_symbol LIKE currencies.crr_name,
    salfatixlabel STRING,
    salfatixcrr_symbol LIKE currencies.crr_name
  END RECORD

DEFINE
  m_dialogtouched SMALLINT

DEFINE --list data
  marec_userpostpricelist DYNAMIC ARRAY OF t_userpostpricelist
DEFINE --grid data
  mint_userpostprice_usr_id LIKE userpostprices.usrpp_usr_id,
  mint_userpostprice_posttype_id LIKE userpostprices.usrpp_posttype_id,
  mrec_userpostpricegrid t_userpostpricegrid,
  mrec_copy_userpostpricegrid t_userpostpricegrid,
  mrec_db_userpostprice RECORD LIKE userpostprices.*


#+ Explain the meaning of the Euro pictures shown in the campaign list
#+
Function userpostprice_eurosymbolshelp()
  Define
    lint_ret    Integer,
    lint_action Smallint

  Define
    ldar_euroSymbols Dynamic Array Of Record
      par_des          Like params.par_des,
      def              String
                     End Record,
    lParams          Record Like params.*

  Let lint_action = C_APPACTION_UNDEFINED
  Open Window w_userpostprice_eurosymbolshelp With Form "userpostprice_eurosymbolshelp"

    Call ldar_euroSymbols.clear()
    Declare cEuroSymbols Cursor For Select * From params Where par_typ = 1
    Foreach cEuroSymbols Into lParams.*
      Call ldar_euroSymbols.appendElement()
      Let ldar_euroSymbols[ldar_euroSymbols.getLength()].par_des = lParams.par_des
      Case
        When lParams.par_min = 0 And lParams.par_max = 1
          Let ldar_euroSymbols[ldar_euroSymbols.getLength()].def = %"Process Exchange"
        When lParams.par_max >= 99999999.00
          Let ldar_euroSymbols[ldar_euroSymbols.getLength()].def = %"Exciting Great Deal"
        Otherwise
          Let ldar_euroSymbols[ldar_euroSymbols.getLength()].def = LSTR("Up to "),lParams.par_max+1 Using "<<<<<<<<<<&",LSTR(" €")
      End Case
    End Foreach
    Free cEuroSymbols

    Let int_flag = False
    Display "footer-remuneration-1.jpg" To foot
    Display Array ldar_euroSymbols To srMeaning.*
      Attributes (Count=ldar_euroSymbols.getLength(), Cancel=False)

  Close Window w_userpostprice_eurosymbolshelp
  Return lint_ret, lint_action
End Function

#+ Fetch and display the list of prices per post
#+
#+ @param pint_user_id user id we're managing prices
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
#+ output FROM EMPTY : CANCEL|VIEWLIST|CUSTOMACTION
#+ output FROM LIST : CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION userpostpricelist_open_form_by_key(pint_user_id)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lint_action = C_APPACTION_UNDEFINED
  LET mint_userpostprice_usr_id = pint_user_id

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL userpostpricelist_get_data("userpostprices, posttypes", SFMT("userpostprices.usrpp_usr_id=%1 AND userpostprices.usrpp_posttype_id = posttypes.pstt_id", pint_user_id), "posttypes.pstt_uiorder", marec_userpostpricelist)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      IF marec_userpostpricelist.getLength() == 0 AND setup.g_app_backoffice THEN
        OPEN WINDOW w_userpostprice_empty WITH FORM "userpostprice_empty"
        CALL userpostpricelist_empty()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_userpostprice_empty
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_VIEWLIST THEN
            LET lbool_exit = FALSE
          END IF
        END IF
      ELSE
        OPEN WINDOW w_userpostprice_list WITH FORM "userpostprice_list"
        CALL userpostpricelist_display()
          RETURNING lint_ret, lint_action
        CLOSE WINDOW w_userpostprice_list
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

#+ Dialog an empty list of prices per post
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (CANCEL|VIEWLIST|CUSTOMACTION)
FUNCTION userpostpricelist_empty()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    lint_user_id LIKE userpostprices.usrpp_usr_id,
    lint_posttype_id LIKE userpostprices.usrpp_posttype_id

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Price per post"
  CALL FGL_SETTITLE(ff_formtitle)
  MENU ""
    ON ACTION addprice
      CALL userpostpricegrid_open_form_by_key(mint_userpostprice_usr_id, 0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_user_id, lint_posttype_id
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

#+ Display the prices per post list
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (CANCEL|VIEWEMPTY|CUSTOMACTION
FUNCTION userpostpricelist_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_user_id LIKE userpostprices.usrpp_usr_id,
    lint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    i INTEGER,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = %"Price per post"
  CALL FGL_SETTITLE(ff_formtitle)

  DISPLAY ARRAY marec_userpostpricelist TO scr_userpostprice_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY
      CALL userpostpricelist_ui_set_action_state(DIALOG)
      IF setup.g_app_backoffice THEN
        DISPLAY BY NAME ff_formtitle
      END IF
    ON ACTION delete ATTRIBUTES (ROWBOUND)
      LET i = DIALOG.getCurrentRow("scr_userpostprice_list")
      IF i > 0 THEN
        CALL userpostprice_can_delete_price(mint_userpostprice_usr_id, marec_userpostpricelist[i].userpostprice.usrpp_posttype_id)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
        CALL userpostprice_delete_into_dabatase(mint_userpostprice_usr_id, marec_userpostpricelist[i].userpostprice.usrpp_posttype_id)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          CALL DIALOG.deleteRow("scr_userpostprice_list", i)
          CALL userpostpricelist_ui_set_action_state(DIALOG)
          IF marec_userpostpricelist.getLength() == 0 AND setup.g_app_backoffice THEN
            LET lint_action = C_APPACTION_VIEWEMPTY
            EXIT DISPLAY
          END IF
        END IF
      END IF
    ON ACTION addprice
      CALL userpostpricegrid_open_form_by_key(mint_userpostprice_usr_id, 0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_user_id, lint_posttype_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            CALL userpostpricelist_get_data_by_key(lint_user_id, lint_posttype_id, marec_userpostpricelist, marec_userpostpricelist.getLength()+1)
              RETURNING lint_ret, lstr_msg
            CALL userpostpricelist_ui_set_action_state(DIALOG)
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION addpricemobile
      CALL userpostpricegrid_open_form_by_key(mint_userpostprice_usr_id, 0, C_APPSTATE_ADD)
        RETURNING lint_ret, lint_action, lint_user_id, lint_posttype_id
      IF lint_ret == 0 THEN
        CASE lint_action
          WHEN C_APPACTION_ACCEPT
            CALL userpostpricelist_get_data_by_key(lint_user_id, lint_posttype_id, marec_userpostpricelist, marec_userpostpricelist.getLength()+1)
              RETURNING lint_ret, lstr_msg
            CALL userpostpricelist_ui_set_action_state(DIALOG)
          WHEN C_APPACTION_CANCEL
          OTHERWISE --custom action
            EXIT DISPLAY
        END CASE
      END IF
    ON ACTION editprice
      LET i = DIALOG.getCurrentRow("scr_userpostprice_list")
      IF i > 0 THEN
        CALL userpostpricegrid_open_form_by_key(mint_userpostprice_usr_id, marec_userpostpricelist[i].userpostprice.usrpp_posttype_id, C_APPSTATE_UPDATE)
          RETURNING lint_ret, lint_action, lint_user_id, lint_posttype_id
        IF lint_ret == 0 THEN
          CASE lint_action
            WHEN C_APPACTION_ACCEPT
            WHEN C_APPACTION_CANCEL
            OTHERWISE --custom action
              EXIT DISPLAY
          END CASE
          CALL userpostpricelist_get_data_by_key(lint_user_id, lint_posttype_id, marec_userpostpricelist, i)
            RETURNING lint_ret, lstr_msg
          CALL userpostpricelist_ui_set_action_state(DIALOG)
        END IF
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

#+ Get the prices per post list data
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of t_userpostpricelist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userpostpricelist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_userpostpricelist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_usr_id LIKE userpostprices.usrpp_usr_id,
    lint_posttype_id LIKE userpostprices.usrpp_posttype_id

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM userpostprices"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT userpostprices.usrpp_usr_id, userpostprices.usrpp_posttype_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_userpostpricelist_get_data CURSOR FROM lstr_sql
    FOREACH c_userpostpricelist_get_data
      INTO lint_usr_id, lint_posttype_id
      CALL userpostpricelist_get_data_by_key(lint_usr_id, lint_posttype_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END FOREACH
    FREE c_userpostpricelist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the prices per post list data for a given row
#+
#+ @param pint_user_id influencer id
#+ @param pint_posttype_id post type id
#+ @param parec_list list of influencers t_userpostpricelist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userpostpricelist_get_data_by_key(pint_user_id, pint_posttype_id, parec_list, pint_index)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    pint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    parec_list DYNAMIC ARRAY OF t_userpostpricelist,
    pint_index INTEGER,
    lrec_user RECORD LIKE users.*,
    lrec_userpostprice RECORD LIKE userpostprices.*,
    lrec_posttype RECORD LIKE posttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING

  CALL core_db.users_select_row(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.userpostprices_select_row(pint_user_id, pint_posttype_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_userpostprice.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.posttype_select_row(pint_posttype_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_posttype.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET parec_list[pint_index].userpostprice.* = lrec_userpostprice.*
  LET parec_list[pint_index].pstt_name = lrec_posttype.pstt_name
  LET parec_list[pint_index].crr_symbol = core_db.currency_get_symbol(lrec_user.usr_currency_id)
  LET parec_list[pint_index].delimage = "delete"
  LET parec_list[pint_index].editimage = "fa-pencil"
  LET parec_list[pint_index].freeofcharge = IIF(lrec_userpostprice.usrpp_freeofcharge, %"Accept free of charge", NULL)
  LET parec_list[pint_index].salfatixlabel = _getsalfatixlabel(lrec_userpostprice.usrpp_isvalidatedbysalfatix)
  LET parec_list[pint_index].salfatixcrr_symbol = parec_list[pint_index].crr_symbol
  LET parec_list[pint_index].salfatixfreeofcharge = IIF(lrec_userpostprice.usrpp_salfatixfreeofcharge, %"Free when influencer's service has no price", NULL)
  RETURN 0, NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION userpostpricelist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.DIALOG,
    lbool_add_allowed BOOLEAN
  CALL core_ui.ui_set_node_attribute("ScrollGrid","name","salfatixmedia1","style",IIF(setup.g_app_influencer,"priceperpostmobile","priceperpost"))
  CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden",setup.g_app_influencer)
  CALL p_dialog.setActionHidden("cancel", TRUE)
  CALL p_dialog.setActionHidden("customaction", TRUE)
  CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)
  CALL p_dialog.setActionActive("delete", (marec_userpostpricelist.getLength()>0))
  CALL core_ui.ui_set_node_attribute("Matrix","name","formonly.delimage","hidden",setup.g_app_influencer)
  CALL p_dialog.setActionActive("editprice", (marec_userpostpricelist.getLength()>0))
  CALL core_ui.ui_set_node_attribute("Matrix","name","formonly.editimage","hidden",setup.g_app_influencer)
  LET lbool_add_allowed = can_add_price(mint_userpostprice_usr_id)
  CALL p_dialog.setActionActive("addprice", lbool_add_allowed AND setup.g_app_backoffice)
  CALL core_ui.ui_set_node_attribute("Image","name","addprice","hidden", (NOT lbool_add_allowed) OR setup.g_app_influencer)
  CALL p_dialog.setActionActive("addpricemobile", lbool_add_allowed AND setup.g_app_influencer)
  CALL p_dialog.setActionHidden("addpricemobile", (NOT lbool_add_allowed) OR setup.g_app_backoffice)
  IF setup.g_app_influencer THEN
    CALL core_ui.ui_set_node_attribute("Matrix","name","formonly.salfatixlbl","hidden","1")
    CALL core_ui.ui_set_node_attribute("Label","name","userpostprices_usrpp_salfatixminprice_label","hidden","1")
    CALL core_ui.ui_set_node_attribute("Matrix","name","userpostprices.usrpp_salfatixminprice","hidden","1")
    CALL core_ui.ui_set_node_attribute("Label","name","userpostprices_usrpp_salfatixmaxprice_label","hidden","1")
    CALL core_ui.ui_set_node_attribute("Matrix","name","userpostprices.usrpp_salfatixmaxprice","hidden","1")
    CALL core_ui.ui_set_node_attribute("Matrix","name","formonly.sur","hidden","1")
    CALL core_ui.ui_set_node_attribute("Matrix","name","formonly.sreeofcharge","hidden","1")
  END IF
END FUNCTION

#+ Fetch and display post types
#+
#+ @param pint_user_id current user
#+ @param pint_posttype_id current post type
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION)
FUNCTION userpostpricegrid_open_form_by_key(pint_user_id, pint_posttype_id, pint_state)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    pint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  LET mint_userpostprice_usr_id = pint_user_id
  LET mint_userpostprice_posttype_id = pint_posttype_id
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_userpostprice_grid WITH FORM "userpostprice_grid"
  CASE pint_state
    WHEN C_APPSTATE_ADD
      CALL userpostpricegrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL userpostpricegrid_update(pint_state) RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_userpostprice_grid
  RETURN lint_ret, lint_action, mint_userpostprice_usr_id, mint_userpostprice_posttype_id
END FUNCTION

#+ Create a price per post
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION userpostpricegrid_create(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL userpostpricegrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a price per post
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION userpostpricegrid_update(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL userpostpricegrid_input(C_DIALOGSTATE_UPDATE)
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
FUNCTION userpostpricegrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_UNDEFINED
  LET ff_formtitle = IIF(pint_dialog_state==C_DIALOGSTATE_ADD, %"Create Price",%"Edit Price")
  CALL FGL_SETTITLE(ff_formtitle)

  LET m_dialogtouched = FALSE
  CALL userpostpricegrid_initialize_data(mint_userpostprice_usr_id, mint_userpostprice_posttype_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_userpostpricegrid.* FROM scr_userpostprice_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL posttypes_combobox_initializer()
      AFTER INPUT
      ON CHANGE usrpp_posttype_id
        LET m_dialogtouched = TRUE
        CALL userpostpricegrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    END INPUT
    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL userpostpricegrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    ON ACTION save_mobile ATTRIBUTE(TEXT=%"Done") --gmi action panel
      CALL userpostpricegrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_userpostprice_usr_id = mrec_userpostpricegrid.userpostprice.usrpp_usr_id
      LET mint_userpostprice_posttype_id = mrec_userpostpricegrid.userpostprice.usrpp_posttype_id
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION save
      CALL userpostpricegrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_userpostprice_usr_id = mrec_userpostpricegrid.userpostprice.usrpp_usr_id
      LET mint_userpostprice_posttype_id = mrec_userpostpricegrid.userpostprice.usrpp_posttype_id
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION cancel ATTRIBUTE(TEXT=%"Cancel")
      CALL userpostpricegrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_userpostprice_usr_id = mrec_userpostpricegrid.userpostprice.usrpp_usr_id
      LET mint_userpostprice_posttype_id = mrec_userpostpricegrid.userpostprice.usrpp_posttype_id
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    ON ACTION customaction
      CALL userpostpricegrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      LET mint_userpostprice_usr_id = mrec_userpostpricegrid.userpostprice.usrpp_usr_id
      LET mint_userpostprice_posttype_id = mrec_userpostpricegrid.userpostprice.usrpp_posttype_id
      EXIT DIALOG
    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL userpostpricegrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      IF setup.g_app_backoffice THEN
        DISPLAY BY NAME ff_formtitle
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
FUNCTION userpostpricegrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
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
      CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ffimage_value","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)

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
      CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ffimage_value","hidden",setup.g_app_influencer)
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ff_formtitle","hidden",setup.g_app_influencer)

      CALL p_dialog.setActionActive("customaction", setup.g_app_backoffice)
      CALL p_dialog.setActionHidden("customaction", NOT setup.g_app_backoffice)
  END CASE

  IF setup.g_app_influencer THEN
    CALL core_ui.ui_set_node_attribute("FormField","name","formonly.salfatixlbl","hidden","1")
    CALL core_ui.ui_set_node_attribute("Label","name","userpostprices_usrpp_salfatixminprice_label","hidden","1")
    CALL core_ui.ui_set_node_attribute("FormField","name","userpostprices.usrpp_salfatixminprice","hidden","1")
    CALL core_ui.ui_set_node_attribute("Label","name","userpostprices_usrpp_salfatixmaxprice_label","hidden","1")
    CALL core_ui.ui_set_node_attribute("FormField","name","userpostprices.usrpp_salfatixmaxprice","hidden","1")
    CALL core_ui.ui_set_node_attribute("FormField","name","formonly.sur","hidden","1")
    CALL core_ui.ui_set_node_attribute("Label","name","userpostprices_usrpp_salfatixfreeofcharge_label","hidden","1")
    CALL core_ui.ui_set_node_attribute("FormField","name","userpostprices.usrpp_salfatixfreeofcharge","hidden","1")
  END IF
END FUNCTION

#+ Initializes the price per post business record
#+
#+ @param pint_user_id current user
#+ @param pint_posttype_id current post type
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER
#+ @return     0|error
FUNCTION userpostpricegrid_initialize_data(pint_user_id, pint_posttype_id, pint_dialog_state)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    pint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*

  INITIALIZE mrec_userpostpricegrid.* TO NULL
  INITIALIZE mrec_copy_userpostpricegrid.* TO NULL
  INITIALIZE mrec_db_userpostprice.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL core_db.users_select_row(pint_user_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_user.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_userpostpricegrid.userpostprice.usrpp_usr_id = pint_user_id
      LET mrec_userpostpricegrid.userpostprice.usrpp_posttype_id = get_first_posttype_to_price(pint_user_id)
      LET mrec_userpostpricegrid.userpostprice.usrpp_freeofcharge = 0
      LET mrec_userpostpricegrid.userpostprice.usrpp_salfatixfreeofcharge = 0
      LET mrec_userpostpricegrid.userpostprice.usrpp_isvalidatedbysalfatix = 0
      LET mrec_userpostpricegrid.crr_symbol = core_db.currency_get_symbol(lrec_user.usr_currency_id)
      LET mrec_userpostpricegrid.salfatixlabel = _getsalfatixlabel(mrec_userpostpricegrid.userpostprice.usrpp_isvalidatedbysalfatix)
      LET mrec_userpostpricegrid.salfatixcrr_symbol = mrec_userpostpricegrid.crr_symbol
    WHEN C_DIALOGSTATE_UPDATE
      CALL userpostpricegrid_get_data_by_key(pint_user_id, pint_posttype_id)
        RETURNING lint_ret, lstr_msg, mrec_userpostpricegrid.*, mrec_db_userpostprice.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_copy_userpostpricegrid.* = mrec_userpostpricegrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_userpostpricegrid
#+
#+ @param pint_user_id current user
#+ @param pint_posttype_id current post type
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_userpostpricegrid business record, userpostprice database record
FUNCTION userpostpricegrid_get_data_by_key(pint_user_id, pint_posttype_id)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    pint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data RECORD LIKE userpostprices.*,
    lrec_ui_userpostprice t_userpostpricegrid,
    lrec_db_data RECORD LIKE userpostprices.*,
    lrec_user RECORD LIKE users.*

  INITIALIZE lrec_ui_userpostprice.* TO NULL
  CALL core_db.users_select_row(pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_userpostprice.*, lrec_db_data.*
  END IF

  CALL core_db.userpostprices_select_row(pint_user_id, pint_posttype_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_data.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_userpostprice.*, lrec_db_data.*
  END IF
  LET lrec_ui_userpostprice.userpostprice.* = lrec_data.*
  LET lrec_ui_userpostprice.crr_symbol = core_db.currency_get_symbol(lrec_user.usr_currency_id)
  LET lrec_ui_userpostprice.salfatixlabel = _getsalfatixlabel(lrec_ui_userpostprice.userpostprice.usrpp_isvalidatedbysalfatix)
  LET lrec_ui_userpostprice.salfatixcrr_symbol = lrec_ui_userpostprice.crr_symbol
  LET lrec_db_data.* = lrec_data.*
  RETURN lint_ret, lstr_msg, lrec_ui_userpostprice.*, lrec_db_data.*
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
FUNCTION userpostpricegrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_user_id LIKE userpostprices.usrpp_usr_id,
    lint_posttype_id LIKE userpostprices.usrpp_posttype_id

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
            IF core_ui.ui_message(%"Question ?",%"Abort price edition?","no","yes|no","fa-question") == "yes" THEN
              LET lbool_restore_data = TRUE
            END IF
          END IF
    END CASE
    OTHERWISE --do nothing
      RETURN 0, NULL
  END CASE
  IF lbool_insert_data THEN
    CALL userpostprice_validate_data(C_DIALOGSTATE_ADD)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_userpostpricegrid.userpostprice.usrpp_isvalidatedbysalfatix = (setup.g_app_backoffice)
    CALL userpostprice_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_user_id, lint_posttype_id
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Price registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_userpostpricegrid.userpostprice.usrpp_usr_id = lint_user_id
    LET mrec_userpostpricegrid.userpostprice.usrpp_posttype_id = lint_posttype_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_update_data THEN
    CALL userpostprice_validate_data(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_userpostpricegrid.userpostprice.usrpp_isvalidatedbysalfatix = (setup.g_app_backoffice)
    CALL userpostprice_update_into_dabatase()
      RETURNING lint_ret, lstr_msg
    --IF lint_ret == 0 THEN
      --IF core_ui.ui_message(%"Information",%"Price updated","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
  END IF

  IF lbool_restore_data THEN
    CALL userpostpricegrid_initialize_data(mrec_userpostpricegrid.userpostprice.usrpp_usr_id, mrec_userpostpricegrid.userpostprice.usrpp_posttype_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL userpostpricegrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_userpostprice_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL userpostpricegrid_initialize_data(mrec_userpostpricegrid.userpostprice.usrpp_usr_id, mrec_userpostpricegrid.userpostprice.usrpp_posttype_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL userpostpricegrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_userpostprice_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert a user post price into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, user id, posttype id
FUNCTION userpostprice_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_userpostprice RECORD LIKE userpostprices.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_userpostprice.usrpp_usr_id, lrec_userpostprice.usrpp_posttype_id
  END IF
  INITIALIZE lrec_userpostprice.* TO NULL
  LET lrec_userpostprice.* = mrec_userpostpricegrid.userpostprice.*
  CALL core_db.userpostprices_insert_row(lrec_userpostprice.*)
    RETURNING lint_ret, lstr_msg, lrec_userpostprice.usrpp_usr_id, lrec_userpostprice.usrpp_posttype_id
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_userpostprice.usrpp_usr_id, lrec_userpostprice.usrpp_posttype_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_userpostprice.usrpp_usr_id, lrec_userpostprice.usrpp_posttype_id
END FUNCTION

#+ Update a user post price into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userpostprice_update_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_userpostprice RECORD LIKE userpostprices.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  INITIALIZE lrec_userpostprice.* TO NULL
  LET lrec_userpostprice.* = mrec_userpostpricegrid.userpostprice.*
  CALL core_db.userpostprices_update_row(mrec_db_userpostprice.*, lrec_userpostprice.*)
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

#+ Delete a user post price from database
#+
#+ @param pint_user_id user id
#+ @param pint_posttype_id post type id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userpostprice_delete_into_dabatase(pint_user_id, pint_posttype_id)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    pint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    i INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  IF lint_ret == 0 THEN
    CALL userpostprice_can_delete_price(pint_user_id, pint_posttype_id)
      RETURNING lint_ret, lstr_msg
  END IF
  IF lint_ret == 0 THEN
    CALL core_db.userpostprices_delete_row(pint_user_id, pint_posttype_id)
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

#+ Check business rules of a user post price
#+
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION userpostprice_validate_data(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_userpostprice RECORD LIKE userpostprices.*

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_userpostpricegrid.userpostprice.usrpp_usr_id IS NULL OR mrec_userpostpricegrid.userpostprice.usrpp_usr_id==0 THEN
      RETURN -1, %"User missing"
    END IF
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_posttype_id IS NULL OR mrec_userpostpricegrid.userpostprice.usrpp_posttype_id==0 THEN
    RETURN -1, %"Post type missing"
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_freeofcharge IS NULL THEN
    RETURN -1, %"Free of charge value missing"
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_minprice IS NULL THEN
    RETURN -1, %"Price missing"
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_maxprice IS NULL THEN
    RETURN -1, %"Price missing"
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_minprice <= 0 THEN
    RETURN -1, %"Invalid price"
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_maxprice <= 0 THEN
    RETURN -1, %"Invalid price"
  END IF
  IF mrec_userpostpricegrid.userpostprice.usrpp_minprice > mrec_userpostpricegrid.userpostprice.usrpp_maxprice THEN
    RETURN -1, %"Inconsistent prices"
  END IF
  IF setup.g_app_backoffice THEN
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixfreeofcharge IS NULL THEN
      RETURN -1, %"SalfatixMedia free of charge missing"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixminprice IS NULL THEN
      RETURN -1, %"SalfatixMedia price missing"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixmaxprice IS NULL THEN
      RETURN -1, %"SalfatixMedia price missing"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixminprice <= 0 THEN
      RETURN -1, %"Invalid SalfatixMedia price"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixmaxprice <= 0 THEN
      RETURN -1, %"Invalid SalfatixMedia price"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixminprice < mrec_userpostpricegrid.userpostprice.usrpp_minprice THEN
      RETURN -1, %"SalfatixMedia minimum price is lesser than influencer minimum price"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixmaxprice < mrec_userpostpricegrid.userpostprice.usrpp_maxprice THEN
      RETURN -1, %"SalfatixMedia maximum price is lesser than influencer maximum price"
    END IF
    IF mrec_userpostpricegrid.userpostprice.usrpp_salfatixminprice > mrec_userpostpricegrid.userpostprice.usrpp_salfatixmaxprice THEN
      RETURN -1, %"Inconsistent SalfatixMedia prices"
    END IF
  END IF
  CALL core_db.userpostprices_select_row(mrec_userpostpricegrid.userpostprice.usrpp_usr_id, mrec_userpostpricegrid.userpostprice.usrpp_posttype_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_userpostprice.*
  CASE lint_ret
    WHEN 0
      IF pint_dialog_state == C_DIALOGSTATE_ADD THEN
        RETURN -1, %"Price type already priced"
      ELSE --update
        IF mrec_db_userpostprice.usrpp_posttype_id <> mrec_userpostpricegrid.userpostprice.usrpp_posttype_id THEN
          --if the post type has changed AND the new record exists then forbid the update
          RETURN -1, %"Price type already priced"
        END IF
      END IF
    WHEN NOTFOUND
    OTHERWISE --error case
      RETURN -1, %"Price type already priced"
  END CASE

  RETURN 0, NULL
END FUNCTION

#+ Get the first post type that is not priced for a user
#+
#+ @param pint_user_id user id
#+
#+ @returnType INTEGER
#+ @return     post type id
FUNCTION get_first_posttype_to_price(pint_user_id)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_posttype_id LIKE posttypes.pstt_id

  LET lstr_sql = "SELECT posttypes.pstt_id"
    ," FROM posttypes"
    ," WHERE posttypes.pstt_id NOT IN "
    ,SFMT("(SELECT userpostprices.usrpp_posttype_id FROM userpostprices WHERE userpostprices.usrpp_usr_id=%1)", pint_user_id)
    ," ORDER BY posttypes.pstt_uiorder"
  LET lint_posttype_id = 0
  TRY
    DECLARE c_get_first_posttype_to_price CURSOR FROM lstr_sql
    FOREACH c_get_first_posttype_to_price
      INTO lint_posttype_id
      EXIT FOREACH
    END FOREACH
    FREE c_get_first_posttype_to_price
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  RETURN lint_posttype_id
END FUNCTION

#+ check if we can add a post price for a user
#+
#+ @param pint_user_id user id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE|FALSE
FUNCTION can_add_price(pint_user_id)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    lint_posttype_id LIKE posttypes.pstt_id

  LET lint_posttype_id = get_first_posttype_to_price(pint_user_id)
  RETURN (lint_posttype_id > 0)
END FUNCTION

#+ Test if we are allowed to delete a user post price from database
#+
#+ @param pint_user_id user id
#+ @param pint_posttype_id post type id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION userpostprice_can_delete_price(pint_user_id, pint_posttype_id)
  DEFINE
    pint_user_id LIKE userpostprices.usrpp_usr_id,
    pint_posttype_id LIKE userpostprices.usrpp_posttype_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  LET i = 0
  TRY
    SELECT COUNT(*)
      INTO i
    FROM campaignuserprices
    WHERE cmpusrp_usr_id = pint_user_id
      AND cmpusrp_posttype_id = pint_posttype_id
    IF i > 0 THEN
      LET lint_ret = -1
    END IF
  CATCH
    LET lint_ret = SQLCA.sqlcode
    LET lstr_msg = SQLERRMESSAGE
  END TRY
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  IF i > 0 THEN
    RETURN -1, %"Deletion forbidden"
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Initializer of the country combobox
#+
FUNCTION posttypes_combobox_initializer()
  CALL combobox.posttype_initializer(ui.ComboBox.forName("userpostprices.usrpp_posttype_id"))
END FUNCTION

#+ Get SalfatixMedia label on price
#+
#+ @param pint_isvalidated 1 if price is already validated by salfatix, 0 otherwise
#+
#+ @returnType STRING
#+ @return     label
PRIVATE FUNCTION _getsalfatixlabel(pint_isvalidated)
  DEFINE
    pint_isvalidated LIKE userpostprices.usrpp_isvalidatedbysalfatix
  RETURN IIF(pint_isvalidated, %"SalfatixMedia price", %"SalfatixMedia price (to validate)")
END FUNCTION