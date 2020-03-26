IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL hash
IMPORT FGL zoom_category
IMPORT FGL zoom_countrystatecitylist
IMPORT FGL emails
IMPORT FGL layout

SCHEMA salfatixmedia

TYPE
  t_bouserlistqbeinput RECORD
    sortby STRING,
    orderby STRING
  END RECORD
TYPE
  t_bouserlist RECORD
    bouser RECORD LIKE backofficeusers.*,
    pic_value LIKE pics.pic_value
  END RECORD
TYPE
  t_bousergrid RECORD
    bouser RECORD LIKE backofficeusers.*,
    pic_value LIKE pics.pic_value,
    password2 LIKE backofficeusers.bousr_password
  END RECORD

Type
  t_csc       Record
    cntr_name   String,
    stt_name    String,
    cts_name    String
              End Record

DEFINE
  m_dialogtouched SMALLINT

DEFINE --list qbe data
  mrec_bouserlistqbeinput t_bouserlistqbeinput

DEFINE --list data
  marec_bouserlist DYNAMIC ARRAY OF t_bouserlist

DEFINE --grid data
  mint_bousr_id LIKE backofficeusers.bousr_id,
  mrec_bousergrid t_bousergrid,
  mrec_location   t_csc,
  mrec_copy_bousergrid t_bousergrid,
  mrec_db_bouser RECORD LIKE backofficeusers.*

DEFINE
  mstr_bouserlist_default_title STRING

#+ Fetch and display the list of backoffice users
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION bouserlist_open_form(pstr_where, pstr_orderby, pstr_title)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT

  LET mstr_bouserlist_default_title = %"Backoffice Users"
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_bouser_list WITH FORM "backofficeuser_list"
  CALL bouserlist_get_data(NULL, pstr_where, pstr_orderby, marec_bouserlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL bouserlist_display(pstr_title)
      RETURNING lint_ret, lint_action
  END IF
  CLOSE WINDOW w_bouser_list
  RETURN lint_ret, lint_action
END FUNCTION

#+ Display the backoffice users
#+
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION bouserlist_display(pstr_title)
  DEFINE
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_id LIKE backofficeusers.bousr_id,
    i INTEGER,
    ff_formtitle STRING,
    frontcall_return STRING,
    lstr_sql_from_clause STRING,
    lstr_sql_where_clause STRING,
    lstr_sql_orderby_clause STRING,
    lstr_sql_where STRING

  LET lint_action = C_APPACTION_UNDEFINED
  IF pstr_title IS NULL THEN
    LET pstr_title = mstr_bouserlist_default_title
  END IF
  LET ff_formtitle = pstr_title
  CALL FGL_SETTITLE(ff_formtitle)

  LET mrec_bouserlistqbeinput.sortby = "backofficeusers.bousr_firstname"
  LET mrec_bouserlistqbeinput.orderby = "asc"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_bouserlistqbeinput.* FROM scr_qbeinput.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    CONSTRUCT lstr_sql_where
      ON
        backofficeusers.bousr_firstname,
        backofficeusers.bousr_lastname,
        backofficeusers.bousr_email,
        accountstatus.accst_name
      FROM scr_qbeconstruct.*
      BEFORE CONSTRUCT
    END CONSTRUCT
    DISPLAY ARRAY marec_bouserlist TO scr_backofficeuser_list.*
    END DISPLAY
    ON ACTION filter
      IF lstr_sql_where.getLength() == 0 THEN
       LET lstr_sql_where = " 1=1"
      END IF
      LET lstr_sql_from_clause = " backofficeusers"
      LET lstr_sql_where_clause = lstr_sql_where
      IF lstr_sql_where.getIndexOf("accountstatus.accst_name", 1) > 0
        OR mrec_bouserlistqbeinput.sortby == "accountstatus.accst_name"
      THEN
        LET lstr_sql_from_clause = SFMT("%1, accountstatus", lstr_sql_from_clause)
        LET lstr_sql_where_clause = lstr_sql_where_clause
          ," AND backofficeusers.bousr_accountstatus_id = accountstatus.accst_id"
      END IF
      LET lstr_sql_orderby_clause = SFMT("%1 %2",mrec_bouserlistqbeinput.sortby, mrec_bouserlistqbeinput.orderby)

      CALL bouserlist_get_data(lstr_sql_from_clause, lstr_sql_where_clause,lstr_sql_orderby_clause, marec_bouserlist)
        RETURNING lint_ret, lstr_msg
      CALL display_bouserlist_default_title()

    ON ACTION display_bouser
      LET i = DIALOG.getCurrentRow("scr_backofficeuser_list")
      IF i > 0 THEN
        CALL bousergrid_open_form_by_key(marec_bouserlist[i].bouser.bousr_id, C_APPSTATE_UPDATE)
          RETURNING lint_ret, lint_action, lint_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"bouserlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action <> C_APPACTION_VIEWBOUSERS THEN
            EXIT DIALOG
          END IF
          CALL bouserlist_get_data_by_key(lint_id, marec_bouserlist, i)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
          END IF
          CALL bouserlist_ui_set_action_state(DIALOG)
          CALL display_bouserlist_default_title()
        END IF
      END IF
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      IF lint_action == C_APPACTION_ADDBOUSER THEN
        CALL bousergrid_open_form_by_key(0, C_APPSTATE_ADD)
          RETURNING lint_ret, lint_action, lint_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"bouserlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_ACCEPT THEN
            LET lint_action = C_APPACTION_VIEWBOUSERS
          END IF
          IF lint_action <> C_APPACTION_VIEWBOUSERS THEN
            EXIT DIALOG
          END IF
          IF lint_id > 0 THEN
            LET i = marec_bouserlist.getLength() + 1
            CALL bouserlist_get_data_by_key(lint_id, marec_bouserlist, i)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
            END IF
            CALL bouserlist_ui_set_action_state(DIALOG)
            CALL display_bouserlist_default_title()
          END IF
        END IF
      END IF
      EXIT DIALOG
    BEFORE DIALOG
      CALL bouserlist_ui_set_action_state(DIALOG)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"bouserlist_page", setup.g_loggedin_name) RETURNING frontcall_return
  END DIALOG
   RETURN lint_ret, lint_action
END FUNCTION

#+ Get the backoffice user list data
#+
#+ @param pstr_from SQL FROM clause to select data
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of backoffice user t_bouserlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION bouserlist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_bouserlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_id LIKE backofficeusers.bousr_id

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM backofficeusers"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT backofficeusers.bousr_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_bouserlist_get_data CURSOR FROM lstr_sql
    FOREACH c_bouserlist_get_data
      INTO lint_id
      CALL bouserlist_get_data_by_key(lint_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
    END FOREACH
    FREE c_bouserlist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the backoffice user list data for a given row
#+
#+ @param pint_id user id
#+ @param parec_list list of backoffice user t_bouserlist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION bouserlist_get_data_by_key(pint_id, parec_list, pint_index)
  DEFINE
    pint_id LIKE backofficeusers.bousr_id,
    parec_list DYNAMIC ARRAY OF t_bouserlist,
    pint_index INTEGER,
    lrec_bouser RECORD LIKE backofficeusers.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_pic RECORD LIKE pics.*

  CALL core_db.backofficeusers_select_row(pint_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_bouser.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET parec_list[pint_index].bouser.* = lrec_bouser.*
  CALL core_db.pics_select_row(lrec_bouser.bousr_pic_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET parec_list[pint_index].pic_value = lrec_pic.pic_value
  RETURN 0, NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION bouserlist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.Dialog
  CALL p_dialog.setActionActive("display_bouser", (marec_bouserlist.getLength()>0))
  CALL p_dialog.setActionHidden("customaction", TRUE)
END FUNCTION

#+ Fetch and display bousers
#+
#+ @param pint_bousr_id current bouser
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION bousergrid_open_form_by_key(pint_bousr_id, pint_state)
  DEFINE
    pint_bousr_id LIKE backofficeusers.bousr_id,
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action INTEGER

  LET mint_bousr_id = pint_bousr_id
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_bouser_grid WITH FORM "backofficeuser_grid"
  CASE pint_state
    --WHEN C_APPSTATE_DISPLAY
      --CALL bousergrid_display(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_ADD
      CALL bousergrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL bousergrid_update(pint_state) RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_bouser_grid
  RETURN lint_ret, lint_action, mint_bousr_id
END FUNCTION

#+ Create a profile for a backoffice user
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION bousergrid_create(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  CALL bousergrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a profile for a bouser
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION bousergrid_update(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL bousergrid_input(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lint_action
    --we want to stay in the bouser edition
    IF lint_ret == 0 AND lint_action == C_APPACTION_ACCEPT THEN
      LET lbool_exit = FALSE
    END IF
  END WHILE
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the bouser input
#+
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION bousergrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    frontcall_return STRING

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
  CALL FGL_SETTITLE(ff_formtitle)

  LET m_dialogtouched = FALSE
  CALL bousergrid_initialize_data(mint_bousr_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_bousergrid.*,mrec_location.* FROM scr_bouser_grid.*,src_loc.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL accountstatus_combobox_initializer()
        CALL gender_combobox_initializer()

      AFTER INPUT
        If mrec_bousergrid.bouser.bousr_city_id Is Null Then
          Error %"City required"
          Next Field city
        End If
        If mrec_bousergrid.bouser.bousr_state_id Is Null Then
          Error %"State required"
          Next Field state
        End If
        If mrec_bousergrid.bouser.bousr_country_id Is Null Then
          Error %"Country required"
          Next Field country
        End If

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
            Let mrec_bousergrid.bouser.bousr_country_id = Null
          Otherwise
            Call Dialog.setCompleterItems(countryList)
        End Case
        LET m_dialogtouched = TRUE
        CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

    After Field cntr_name
      If Not oldCountry.equals(mrec_location.cntr_name) Then
        If countryList.getLength() > 0 And mrec_location.cntr_name Is Not Null Then
          Let mrec_bousergrid.bouser.bousr_country_id = IIF(countryList.search("",mrec_location.cntr_name)=0,-1,countryIdList[countryList.search("",mrec_location.cntr_name)])
          If mrec_bousergrid.bouser.bousr_country_id = -1 Then
            Let mrec_location.cntr_name = Null
            Let mrec_bousergrid.bouser.bousr_country_id = Null
          End If
          Let mrec_location.stt_name = Null
          Let mrec_bousergrid.bouser.bousr_state_id = Null
          Let mrec_location.cts_name = Null
          Let mrec_bousergrid.bouser.bousr_city_id = Null
        Else
          If mrec_location.cntr_name Is Not Null And mrec_bousergrid.bouser.bousr_country_id Is Not Null Then
          Else
            Let mrec_location.cntr_name = Null
            Let mrec_bousergrid.bouser.bousr_country_id = Null
          End If
          Let mrec_location.stt_name = Null
          Let mrec_bousergrid.bouser.bousr_state_id = Null
          Let mrec_location.cts_name = Null
          Let mrec_bousergrid.bouser.bousr_city_id = Null
        End If
        LET m_dialogtouched = TRUE
        CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      End If
      Call countryList.clear()
      Call countryIdList.clear()

    On Action zoomcountry
      Call zoom_countrystatecitylist.zoomCountryStateCity(%"Country List","Select countries.cntr_id,countries.cntr_name From countries",Null,"countries.cntr_name",fgl_dialog_getbuffer())
        Returning zoomKeyReturn
      If zoomKeyReturn Is Not Null Then
        Call la_val.clear()
        Call core_db.sqlQuery("Select countries.cntr_id,countries.cntr_name From countries Where countries.cntr_id = "||zoomKeyReturn,la_val)
        If la_val.getLength()>0 Then
          Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
          Let mrec_location.cntr_name = la_val[2]
        Else
          Let mrec_bousergrid.bouser.bousr_country_id = Null
          Let mrec_location.cntr_name = Null
        End If
        Let mrec_location.stt_name = Null
        Let mrec_bousergrid.bouser.bousr_state_id = Null
        Let mrec_location.cts_name = Null
        Let mrec_bousergrid.bouser.bousr_city_id = Null
        LET m_dialogtouched = TRUE
        CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      End If

      Before Field stt_name
        Let oldState = mrec_location.stt_name

      ON CHANGE stt_name
        Let qry =
             "Select stt_id,stt_name From states"
             || IIF(mrec_location.cntr_name Is Not Null," Where stt_country_id = "||mrec_bousergrid.bouser.bousr_country_id," ")
             || IIF(fgl_dialog_getbuffer() Is Not Null,
                    IIF(mrec_location.cntr_name Is Not Null," And "," Where ") || "UPPER(stt_name) Like UPPER('"||fgl_dialog_getbuffer()||"%')"," ")
             || " Order By stt_name"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),stateList,stateIdList)
        Case stateList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_bousergrid.bouser.bousr_state_id = Null
          Otherwise
            Call Dialog.setCompleterItems(stateList)
        End Case
        LET m_dialogtouched = TRUE
        CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field stt_name
        If Not oldState.equals(mrec_location.stt_name) Then
          If stateList.getLength() > 0 And mrec_location.stt_name Is Not Null Then
            Let mrec_bousergrid.bouser.bousr_state_id = IIF(stateList.search("",mrec_location.stt_name)=0,-1,stateIdList[stateList.search("",mrec_location.stt_name)])
            If mrec_bousergrid.bouser.bousr_state_id = -1 Then
              Let mrec_location.stt_name = Null
              Let mrec_bousergrid.bouser.bousr_state_id = Null
            Else
              If mrec_bousergrid.bouser.bousr_country_id Is Null Then
                Call la_val.clear()
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_bousergrid.bouser.bousr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            End If
            Let mrec_location.cts_name = Null
            Let mrec_bousergrid.bouser.bousr_city_id = Null
          Else
            If mrec_location.stt_name Is Not Null And mrec_bousergrid.bouser.bousr_state_id Is Not Null Then
              If mrec_bousergrid.bouser.bousr_country_id Is Null Then
                Call la_val.clear()
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_bousergrid.bouser.bousr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            Else
              Let mrec_location.stt_name = Null
              Let mrec_bousergrid.bouser.bousr_state_id = Null
            End If
            Let mrec_location.cts_name = Null
            Let mrec_bousergrid.bouser.bousr_city_id = Null
          End If
          LET m_dialogtouched = TRUE
          CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call stateList.clear()
        Call stateIdList.clear()

      On Action zoomstate
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"State List","Select states.stt_id,states.stt_name||' ( '||countries.cntr_name||' ) ' From states,countries",
                    "states.stt_country_id = countries.cntr_id"||
                    IIF(mrec_bousergrid.bouser.bousr_country_id Is Not Null," And states.stt_country_id = "||mrec_bousergrid.bouser.bousr_country_id," "),
                    "states.stt_name",
                    fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call la_val.clear()
          Call core_db.sqlQuery("Select states.stt_id,states.stt_name From states Where states.stt_id = "||zoomKeyReturn,la_val)
          If la_val.getLength() > 0 Then
            Let mrec_bousergrid.bouser.bousr_state_id = la_val[1]
            Let mrec_location.stt_name = la_val[2]
          Else
            Let mrec_bousergrid.bouser.bousr_state_id = Null
            Let mrec_location.stt_name = Null
          End If
          If mrec_bousergrid.bouser.bousr_country_id Is Null Then
            Call la_val.clear()
            Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
              Let mrec_location.cntr_name = la_val[2]
            Else
              Let mrec_bousergrid.bouser.bousr_country_id = Null
              Let mrec_location.cntr_name = Null
            End If
          End If
          Let mrec_location.cts_name = Null
          Let mrec_bousergrid.bouser.bousr_city_id = Null
          LET m_dialogtouched = TRUE
          CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      Before Field cts_name
        Let oldCity = mrec_location.cts_name

      On Change cts_name
        Let qry =
             "Select cts_id,cts_name From cities"
             || IIF(mrec_bousergrid.bouser.bousr_country_id Is Not Null And mrec_bousergrid.bouser.bousr_state_id Is Null,
                    " Where cities.cts_state_id in (select stt_id From states Where stt_country_id = "||mrec_bousergrid.bouser.bousr_country_id||")",
                    " ")
             || IIF(mrec_bousergrid.bouser.bousr_state_id Is Not Null,
                    " Where cts_state_id = "||mrec_bousergrid.bouser.bousr_state_id,
                    " ")
             || IIF(fgl_dialog_getbuffer() Is Not Null,
                    IIF(mrec_bousergrid.bouser.bousr_state_id Is Not Null Or mrec_bousergrid.bouser.bousr_country_id Is Not Null,
                        " And ",
                        " Where ")|| "Upper(cts_name) Like Upper('"||fgl_dialog_getbuffer()||"%')",
                    " ")
             || " Order by cts_name"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),cityList,cityIdList)
        Case cityList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_bousergrid.bouser.bousr_city_id = Null
          Otherwise
            Call Dialog.setCompleterItems(cityList)
        End Case

      After Field cts_name
        If Not oldCity.equals(mrec_location.cts_name) Then
          If cityList.getLength() > 0 And mrec_location.cts_name Is Not Null Then
            Let mrec_bousergrid.bouser.bousr_city_id = IIF(cityList.search("",mrec_location.cts_name)=0,-1,cityIdList[cityList.search("",mrec_location.cts_name)])
            If mrec_bousergrid.bouser.bousr_city_id = -1 Then
              Let mrec_location.cts_name = Null
              Let mrec_bousergrid.bouser.bousr_city_id = Null
            Else
              If mrec_bousergrid.bouser.bousr_state_id Is Null Then
                Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||mrec_bousergrid.bouser.bousr_city_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_bousergrid.bouser.bousr_state_id = la_val[1]
                  Let mrec_location.stt_name = la_val[2]
                Else
                  Let mrec_bousergrid.bouser.bousr_state_id = Null
                  Let mrec_location.stt_name = Null
                End If
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_bousergrid.bouser.bousr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            End If
          Else
            If mrec_location.cts_name Is Not Null And mrec_bousergrid.bouser.bousr_city_id Is Not Null Then
              If mrec_bousergrid.bouser.bousr_state_id Is Null Then
                Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||mrec_bousergrid.bouser.bousr_city_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_bousergrid.bouser.bousr_state_id = la_val[1]
                  Let mrec_location.stt_name = la_val[2]
                Else
                  Let mrec_bousergrid.bouser.bousr_state_id = Null
                  Let mrec_location.stt_name = Null
                End If
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_bousergrid.bouser.bousr_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            Else
              Let mrec_location.cts_name = Null
              Let mrec_bousergrid.bouser.bousr_city_id = Null
            End If
          End If
          LET m_dialogtouched = TRUE
          CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call cityList.clear()
        Call cityIdList.clear()

      On Action zoomcity
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"City List","Select cities.cts_id,cities.cts_name||' ( '||states.stt_name||' - '||countries.cntr_name||' )' From cities,states,countries",
                    "cities.cts_state_id = states.stt_id And states.stt_country_id = countries.cntr_id"||
                    IIF(mrec_bousergrid.bouser.bousr_state_id Is Not Null," And cities.cts_state_id = "||mrec_bousergrid.bouser.bousr_state_id," ")||
                    IIF(mrec_bousergrid.bouser.bousr_country_id Is Not Null," And states.stt_country_id = "||mrec_bousergrid.bouser.bousr_country_id," "),
                    "cities.cts_name",
                    fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call core_db.sqlQuery("Select cities.cts_id,cities.cts_name From cities Where cities.cts_id = "||zoomKeyReturn,la_val)
              If la_val.getLength() > 0 Then
                Let mrec_bousergrid.bouser.bousr_city_id = la_val[1]
                Let mrec_location.cts_name = la_val[2]
              Else
                Let mrec_bousergrid.bouser.bousr_city_id = Null
                Let mrec_location.cts_name = Null
              End If
          If mrec_bousergrid.bouser.bousr_state_id Is Null Then
            Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||zoomKeyReturn,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_bousergrid.bouser.bousr_state_id = la_val[1]
              Let mrec_location.stt_name = la_val[2]
            Else
              Let mrec_bousergrid.bouser.bousr_state_id = Null
              Let mrec_location.stt_name = Null
            End If
            Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_bousergrid.bouser.bousr_country_id = la_val[1]
              Let mrec_location.cntr_name = la_val[2]
            Else
              Let mrec_bousergrid.bouser.bousr_country_id = Null
              Let mrec_location.cntr_name = Null
            End If
          End If
          LET m_dialogtouched = TRUE
          CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      ON CHANGE bousr_gender_id
        LET m_dialogtouched = TRUE
        CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    END INPUT
    ON ACTION upload_photo
      LET lint_ret = core_ui.ui_upload_image(mrec_bousergrid.pic_value)
      IF lint_ret == 0 THEN
        LET mrec_bousergrid.bouser.bousr_pic_id = 0 --trick for mark the picture as touched
        LET m_dialogtouched = TRUE
        CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF
    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
    ON ACTION stop_bouser
      CALL bousergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BOUSER_STOP)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION delete_bouser
      CALL bousergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BOUSER_DELETE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
    ON ACTION save
      CALL bousergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_bousr_id = mrec_bousergrid.bouser.bousr_id
      LET lint_action = C_APPACTION_ACCEPT
      IF setup.g_app_backoffice THEN
        IF (pint_dialog_state == C_DIALOGSTATE_UPDATE) AND (setup.g_loggedin_id == mrec_bousergrid.bouser.bousr_id) THEN
          --self edition
          LET setup.g_loggedin_id = mint_bousr_id
          CALL setup.refresh_loggedin_name()
        END IF
      END IF
      EXIT DIALOG
    ON ACTION customaction
      CALL bousergrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      LET mint_bousr_id = mrec_bousergrid.bouser.bousr_id
      EXIT DIALOG
    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL bousergrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,IIF(pint_dialog_state==C_DIALOGSTATE_ADD, "addbouser_page", "updatebouser_page"), setup.g_loggedin_name) RETURNING frontcall_return
  END DIALOG
  RETURN lint_ret, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION bousergrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT,
    lbool_allow_stop BOOLEAN,
    lbool_allow_delete BOOLEAN

  LET lbool_allow_stop = FALSE
  LET lbool_allow_delete = FALSE

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND NOT setup.g_app_is_mobile)
      CALL core_ui.ui_set_node_attribute("Button","name","upload_photo","hidden","0")
      --display password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","bousers_bouser_password_label1","hidden",0)
      CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers.bousr_password","hidden","0")
      CALL core_ui.ui_set_node_attribute("Label","name","bousers_bouser_password","hidden","0")
      CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers1.bousr_password","hidden","0")

      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", "1")
      CALL core_ui.ui_set_node_attribute("Button","name","stop_bouser","hidden","1")
      CALL p_dialog.setActionActive("stop_bouser", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","delete_bouser","hidden","1")
      CALL p_dialog.setActionActive("delete_bouser", FALSE)

      CALL core_ui.ui_set_node_attribute("Label","name","backofficeusers_bousr_accountstatus_id_label1","hidden", "1")
      CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers.bousr_accountstatus_id","hidden","1")

    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND NOT setup.g_app_is_mobile)
      CALL core_ui.ui_set_node_attribute("Button","name","upload_photo","hidden","0")
      --hide password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","bousers_bouser_password_label1","hidden",1)
      CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers.bousr_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","bousers_bouser_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers1.bousr_password","hidden","1")

      IF mrec_bousergrid.bouser.bousr_id == C_SALFATIXSYSTEMADMINISTRATOR THEN
        CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers.bousr_email","noEntry","1")
        CALL core_ui.ui_set_node_attribute("FormField","name","backofficeusers.bousr_isadmin","noEntry","1")
      END IF
      LET lbool_allow_stop = bouser_allow_stop(mrec_bousergrid.bouser.bousr_id, mrec_bousergrid.bouser.bousr_accountstatus_id)
      LET lbool_allow_delete = bouser_allow_delete(mrec_bousergrid.bouser.bousr_id, mrec_bousergrid.bouser.bousr_accountstatus_id)
      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden",NOT (setup.g_app_backoffice AND (lbool_allow_stop OR lbool_allow_delete)))
      CALL core_ui.ui_set_node_attribute("Button","name","stop_bouser","hidden",NOT (setup.g_app_backoffice AND lbool_allow_stop))
      CALL p_dialog.setActionActive("stop_bouser", (setup.g_app_backoffice AND lbool_allow_stop))
      CALL core_ui.ui_set_node_attribute("Button","name","delete_bouser","hidden",NOT (setup.g_app_backoffice AND lbool_allow_delete))
      CALL p_dialog.setActionActive("delete_bouser", (setup.g_app_backoffice AND lbool_allow_delete))

    WHEN C_DIALOGSTATE_DISPLAY
      --CALL core_ui.ui_set_node_attribute("Button","name","update_profile","hidden","0")
      --CALL core_ui.ui_set_node_attribute("Button","name","update_password","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Button","name","upload_photo","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Button","name","save","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Label","name","bousers_brnd_password_label1","hidden",1)
      --CALL core_ui.ui_set_node_attribute("FormField","name","bousers.bousr_password","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Label","name","bousers1_brnd_password","hidden","1")
      --CALL core_ui.ui_set_node_attribute("FormField","name","bousers1.bousr_password","hidden","1")
      --CALL p_dialog.setActionHidden("logout", TRUE)
  END CASE
  CALL p_dialog.setActionHidden("customaction", TRUE)
  CALL layout.display_savebutton(pbool_dialog_touched)
  CALL layout.display_phonenumberprefix(mrec_bousergrid.bouser.bousr_country_id)

END FUNCTION

#+ Initializes the bouser business record
#+
#+ @param pint_bousr_id current bouser
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION bousergrid_initialize_data(pint_bousr_id, pint_dialog_state)
  DEFINE
    pint_bousr_id LIKE backofficeusers.bousr_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    la_val Dynamic Array Of String

  INITIALIZE mrec_bousergrid.* TO NULL
  Initialize mrec_location.* To Null
  INITIALIZE mrec_copy_bousergrid.* TO NULL
  INITIALIZE mrec_db_bouser.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_bousergrid.bouser.bousr_id = 0
      CALL _get_default_add_photo()
        RETURNING lint_ret, lstr_msg, mrec_bousergrid.bouser.bousr_pic_id, mrec_bousergrid.pic_value
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_bousergrid.bouser.bousr_email_style = C_EMAILSTYLE_HTML
      LET mrec_bousergrid.bouser.bousr_gender_id = C_GENDER_OTHER
      LET mrec_bousergrid.bouser.bousr_country_id = C_COUNTRY_FRANCE
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_bousergrid.bouser.bousr_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_bousergrid.bouser.bousr_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      LET mrec_bousergrid.bouser.bousr_isadmin = FALSE
      LET mrec_bousergrid.bouser.bousr_usrrole_id = C_ROLE_USER
      LET mrec_bousergrid.bouser.bousr_accountstatus_id = C_ACCOUNTSTATUS_COMPLETED
    WHEN C_DIALOGSTATE_UPDATE
      CALL bousergrid_get_data_by_key(pint_bousr_id)
        RETURNING lint_ret, lstr_msg, mrec_bousergrid.*, mrec_db_bouser.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_bousergrid.bouser.bousr_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_bousergrid.bouser.bousr_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      Call core_db.sqlQuery("Select stt_name From states Where stt_id = "||mrec_bousergrid.bouser.bousr_state_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.stt_name = la_val[1]
      Else
        Let mrec_bousergrid.bouser.bousr_state_id = Null
        Let mrec_location.stt_name = Null
      End If
      Call core_db.sqlQuery("Select cts_name From cities Where cts_id = "||mrec_bousergrid.bouser.bousr_city_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cts_name = la_val[1]
      Else
        Let mrec_bousergrid.bouser.bousr_city_id = Null
        Let mrec_location.cts_name = Null
      End If
      LET mrec_copy_bousergrid.* = mrec_bousergrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_bousergrid
#+
#+ @param pint_bousr_id bouser id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_bousergrid business record, bouser database record
FUNCTION bousergrid_get_data_by_key(pint_bousr_id)
  DEFINE
    pint_bousr_id LIKE backofficeusers.bousr_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_bouser RECORD LIKE backofficeusers.*,
    lrec_ui_bouser t_bousergrid,
    lrec_db_bouser RECORD LIKE backofficeusers.*,
    lrec_pic RECORD LIKE pics.*

  INITIALIZE lrec_ui_bouser.* TO NULL
  CALL core_db.backofficeusers_select_row(pint_bousr_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_bouser.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_bouser.*, lrec_db_bouser.* 
  END IF
  CALL core_db.pics_select_row(lrec_bouser.bousr_pic_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_bouser.*, lrec_db_bouser.* 
  END IF
  LET lrec_ui_bouser.bouser.* = lrec_bouser.*
  LET lrec_ui_bouser.password2 = lrec_bouser.bousr_password
  LET lrec_ui_bouser.pic_value = lrec_pic.pic_value
  LET lrec_db_bouser.* = lrec_bouser.*
  RETURN lint_ret, lstr_msg, lrec_ui_bouser.*, lrec_db_bouser.* 
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
FUNCTION bousergrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_bousr_id LIKE backofficeusers.bousr_id,
    lint_accountstatus_id LIKE backofficeusers.bousr_accountstatus_id

  --DISPLAY SFMT("bouser_process_data = pint_dialog_state=%1 pbool_dialog_touched=%2 pint_dialog_action=%3",pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
        WHEN C_APPACTION_BOUSER_STOP
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_STOPPED
        WHEN C_APPACTION_BOUSER_DELETE
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_DELETED
    END CASE
    OTHERWISE --do nothing
      RETURN 0, NULL
  END CASE
  IF lbool_insert_data THEN
    CALL bouser_validate_data(C_DIALOGSTATE_ADD)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL bouser_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_bousr_id
    --IF lint_ret == 0 THEN
    --  IF core_ui.ui_message(%"Information",%"Profile registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_bousergrid.bouser.bousr_id = lint_bousr_id
    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
    --TODO : call sendmail if email has changed
  END IF

  IF lbool_update_data THEN
    CALL bouser_validate_data(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL bouser_update_into_dabatase(lint_accountstatus_id)
      RETURNING lint_ret, lstr_msg
    --IF lint_ret == 0 THEN
    --  IF core_ui.ui_message(%"Information",%"Profile updated","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
    --TODO : call sendmail if mail has changed
  END IF

  IF lbool_restore_data THEN
    CALL bousergrid_initialize_data(mrec_bousergrid.bouser.bousr_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL bousergrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_bouser_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL bousergrid_initialize_data(mrec_bousergrid.bouser.bousr_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL bousergrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_bouser_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
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

  CALL core_db.pics_select_row(C_PIC_DEFAULTAVATAR, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  RETURN lint_ret, lstr_msg, lrec_pic.pic_id, lrec_pic.pic_value
END FUNCTION

#+ Insert a bouser into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, bouser id
FUNCTION bouser_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_bouser RECORD LIKE backofficeusers.*,
    lrec_pic RECORD LIKE pics.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_bouser.bousr_id
  END IF
  IF mrec_bousergrid.bouser.bousr_pic_id == 0 THEN --means there is a photo which is not the default avatar
    INITIALIZE lrec_pic.* TO NULL
    LET lrec_pic.pic_id = 0
    LET lrec_pic.pic_value = mrec_bousergrid.pic_value 
    CALL core_db.pics_insert_row(lrec_pic.*)
      RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  END IF
  IF lint_ret == 0 THEN
    INITIALIZE lrec_bouser.* TO NULL
    LET lrec_bouser.* = mrec_bousergrid.bouser.*
    LET lrec_bouser.bousr_id = 0
    IF lrec_bouser.bousr_pic_id == 0 THEN
      LET lrec_bouser.bousr_pic_id = lrec_pic.pic_id  
    END IF
    LET lrec_bouser.bousr_password = hash.compute_hash(lrec_bouser.bousr_password, "BCRYPT", FALSE)
    LET lrec_bouser.bousr_creationdate = CURRENT
    CALL core_db.backofficeusers_insert_row(lrec_bouser.*)
      RETURNING lint_ret, lstr_msg, lrec_bouser.bousr_id
  END IF
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_bouser.bousr_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_bouser.bousr_id
END FUNCTION

#+ Update a bouser into database
#+
#+ @param pint_status_id new account status
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION bouser_update_into_dabatase(pint_status_id)
  DEFINE
    pint_status_id LIKE backofficeusers.bousr_accountstatus_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_bouser RECORD LIKE backofficeusers.*,
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
  LET lbool_delete_old_photo = (mrec_bousergrid.bouser.bousr_pic_id == 0)
  IF mrec_bousergrid.bouser.bousr_pic_id == 0 THEN --means there is a photo which is not the default avatar
    INITIALIZE lrec_pic.* TO NULL
    LET lrec_pic.pic_id = 0
    LET lrec_pic.pic_value = mrec_bousergrid.pic_value
    CALL pics_insert_row(lrec_pic.*)
      RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  END IF
  IF lint_ret == 0 THEN
    INITIALIZE lrec_bouser.* TO NULL
    LET lrec_bouser.* = mrec_bousergrid.bouser.*
    IF lrec_bouser.bousr_pic_id == 0 THEN
      LET lrec_bouser.bousr_pic_id = lrec_pic.pic_id  
    END IF
    IF pint_status_id IS NOT NULL AND pint_status_id > 0 THEN
      CASE pint_status_id
        WHEN C_ACCOUNTSTATUS_STOPPED
          LET lrec_bouser.bousr_stopdate = l_timestamp
        WHEN C_ACCOUNTSTATUS_DELETED
          LET lrec_bouser.bousr_deletiondate = l_timestamp
      END CASE
      LET lrec_bouser.bousr_accountstatus_id = pint_status_id
    END IF
    LET lrec_bouser.bousr_lastupdatedate = l_timestamp
    CALL core_db.backofficeusers_update_row(mrec_db_bouser.*, lrec_bouser.*)
      RETURNING lint_ret, lstr_msg
  END IF
  IF (lint_ret == 0) AND lbool_delete_old_photo THEN
    CALL core_db.pics_delete_row(mrec_copy_bousergrid.bouser.bousr_pic_id)
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

#+ Check business rules of a backoffice user
#+
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION bouser_validate_data(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lint_id BIGINT,
    lint_usertype SMALLINT

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_bousergrid.bouser.bousr_id IS NULL OR mrec_bousergrid.bouser.bousr_id==0 THEN
      RETURN -1, %"User missing"
    END IF
  END IF
  IF mrec_bousergrid.bouser.bousr_pic_id IS NULL OR mrec_bousergrid.pic_value IS NULL THEN
    RETURN -1, %"Photo missing"
  END IF
  IF mrec_bousergrid.bouser.bousr_gender_id IS NULL THEN
    RETURN -1, %"Gender missing"
  END IF
  IF mrec_bousergrid.bouser.bousr_firstname IS NULL THEN
    RETURN -1, %"Firstname missing"
  END IF
  IF mrec_bousergrid.bouser.bousr_lastname IS NULL THEN
    RETURN -1, %"Lastname missing"
  END IF
  LET mrec_bousergrid.bouser.bousr_email = string.trim(mrec_bousergrid.bouser.bousr_email)
  IF mrec_bousergrid.bouser.bousr_email IS NULL THEN
    RETURN -1, %"Email missing"
  END IF
  IF NOT emails.check_format(mrec_bousergrid.bouser.bousr_email) THEN
    RETURN -1, %"Email Format Invalid"
  END IF
  CALL emails.get_usertype_and_id(mrec_bousergrid.bouser.bousr_email,C_USERTYPE_SALFATIX)
    RETURNING lint_ret, lint_id, lint_usertype
  CASE lint_ret
    WHEN 0
      IF pint_dialog_state == C_DIALOGSTATE_ADD THEN
        RETURN -1, %"Email already used"
      ELSE --update
        IF (lint_usertype <> C_USERTYPE_SALFATIX)
          OR (mrec_bousergrid.bouser.bousr_id <> lint_id)
        THEN
          RETURN -1, %"Email already used"
        END IF
      END IF
    WHEN NOTFOUND
    OTHERWISE --error case
      RETURN -1, %"Email already used"
  END CASE
  LET mrec_bousergrid.bouser.bousr_password = string.trim(mrec_bousergrid.bouser.bousr_password)
  IF mrec_bousergrid.bouser.bousr_password IS NULL THEN
    RETURN -1, %"Password missing"
  END IF
  IF pint_dialog_state==C_DIALOGSTATE_ADD THEN
    LET mrec_bousergrid.password2 = string.trim(mrec_bousergrid.password2)
    IF mrec_bousergrid.password2 IS NULL THEN
      RETURN -1, %"Confirm Password missing"
    END IF
    IF mrec_bousergrid.bouser.bousr_password <> mrec_bousergrid.password2 THEN
      RETURN -1, %"Passwords don't match"
    END IF
  END IF
  IF mrec_bousergrid.bouser.bousr_mobile_phone IS NULL THEN
    RETURN -1, %"Phone number missing"
  END IF
  IF mrec_bousergrid.bouser.bousr_accountstatus_id IS NULL THEN
    RETURN -1, %"Status missing"
  END IF
  IF mrec_bousergrid.bouser.bousr_country_id IS NULL THEN
    RETURN -1, %"Country missing"
  END IF
  IF mrec_bousergrid.bouser.bousr_isadmin IS NULL THEN
    RETURN -1, %"'Is Administrator' missing"
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Initializer of the country combobox
#+
--FUNCTION country_combobox_initializer()
  --CALL combobox.country_initializer(ui.ComboBox.forName("backofficeusers.bousr_country_id"))
--END FUNCTION

#+ Initializer of the city combobox
#+
#+ @param pint_state_id state id
#+
--FUNCTION city_combobox_initializer(pint_state_id)
  --DEFINE
    --pint_state_id INTEGER
  --CALL combobox.city_initializer(ui.ComboBox.forName("backofficeusers.bousr_city_id"), pint_state_id)
--END FUNCTION

#+ Initializer of the state combobox
#+
#+ @param pint_country_id country id
#+
--FUNCTION state_combobox_initializer(pint_country_id)
  --DEFINE
    --pint_country_id INTEGER
  --CALL combobox.state_initializer(ui.ComboBox.forName("backofficeusers.bousr_state_id"), pint_country_id)
--END FUNCTION

#+ Initializer of the bouser status combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION bouser_status_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox
  CALL combobox.accountstatus_initializer(p_combo)
END FUNCTION

#+ Initializer of the status combobox
#+
FUNCTION accountstatus_combobox_initializer()
  CALL combobox.accountstatus_initializer(ui.ComboBox.forName("backofficeusers.bousr_accountstatus_id"))
END FUNCTION

#+ Initializer of the gender combobox
#+
FUNCTION gender_combobox_initializer()
  CALL combobox.gender_initializer(ui.ComboBox.forName("backofficeusers.bousr_gender_id"))
END FUNCTION

#+ Display the default title for the list of backoffice users
#+
FUNCTION display_bouserlist_default_title()
  DEFINE
    ff_formtitle STRING
  LET ff_formtitle = mstr_bouserlist_default_title
  CALL FGL_SETTITLE(ff_formtitle)
  DISPLAY BY NAME ff_formtitle
END FUNCTION

#+ Checks if a backoffice user can be stopped
#+
#+ @param pint_id current backoffice user id
#+ @param pint_status_id current backoffice user status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION bouser_allow_stop(pint_id, pint_status_id)
  DEFINE
    pint_id LIKE backofficeusers.bousr_id,
    pint_status_id LIKE backofficeusers.bousr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_COMPLETED THEN
    IF (pint_id <> setup.g_loggedin_id) AND (pint_id <> C_SALFATIXSYSTEMADMINISTRATOR) THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a backoffice user can be deleted
#+
#+ @param pint_id current backoffice user id
#+ @param pint_status_id current backoffice user status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION bouser_allow_delete(pint_id, pint_status_id)
  DEFINE
    pint_id LIKE backofficeusers.bousr_id,
    pint_status_id LIKE backofficeusers.bousr_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_STOPPED THEN
    IF (pint_id <> setup.g_loggedin_id) AND (pint_id <> C_SALFATIXSYSTEMADMINISTRATOR) THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION