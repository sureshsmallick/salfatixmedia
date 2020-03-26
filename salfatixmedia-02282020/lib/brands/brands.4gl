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
IMPORT FGL emails
IMPORT FGL notifications
IMPORT FGL layout
IMPORT FGL brandsocialnetworks
IMPORT FGL campaignlocations
Import FGL zoom_countrystatecitylist
IMPORT os
IMPORT xml

SCHEMA salfatixmedia

TYPE
  t_brandlistqbeinput RECORD
    sortby STRING,
    orderby STRING
  END RECORD
TYPE
  t_brandlist RECORD
    brand RECORD LIKE brands.*,
    pic_value LIKE pics.pic_value,
    brands_primarycategory STRING,
    brands_othercategories STRING
  END RECORD
TYPE
  t_brandgrid RECORD
    brand RECORD LIKE brands.*,
    pic_value LIKE pics.pic_value,
    password2 LIKE brands.brnd_password,
    brand_primarycategory STRING,
    brand_othercategories STRING
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
  mrec_brandlistqbeinput t_brandlistqbeinput

DEFINE --list data
  marec_brandlist DYNAMIC ARRAY OF t_brandlist

DEFINE --grid data
  mint_brand_id LIKE brands.brnd_id,
  mrec_brandgrid t_brandgrid,
  mrec_location   t_csc,
  mrec_copy_brandgrid t_brandgrid,
  mrec_db_brand RECORD LIKE brands.*

DEFINE
  mstr_brandlist_default_title STRING,
  mstr_brandformname STRING

FUNCTION setBrandFormStyle( formStyle String )
  CASE formStyle.toLowerCase()
    WHEN "list"
      LET mstr_brandformname = "brand_list"
    WHEN "tile"
      LET mstr_brandformname = "brand_scrollgrid"
    OTHERWISE
      LET mstr_brandformname = "brand_list"
  END CASE
END FUNCTION

#+ Fetch and display the list of brands
#+
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandlist_open_form(pstr_where, pstr_orderby, pstr_title)
  DEFINE
    pstr_where STRING,
    pstr_orderby STRING,
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT

  LET mstr_brandlist_default_title = %"Brands"
  LET lint_action = C_APPACTION_UNDEFINED
  IF mstr_brandformname IS NULL THEN
    LET mstr_brandformname = "brand_scrollgrid"
  END IF
  OPEN WINDOW w_brand_list WITH FORM mstr_brandformname
  CALL brandlist_get_data(NULL, pstr_where, pstr_orderby, marec_brandlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL brandlist_display(pstr_title)
      RETURNING lint_ret, lint_action
  END IF
  CLOSE WINDOW w_brand_list
  RETURN lint_ret, lint_action
END FUNCTION

#+ Display the brands
#+
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandlist_display(pstr_title)
  DEFINE
    pstr_title STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_brand_id LIKE brands.brnd_id,
    i,j,k INTEGER,
    ff_formtitle STRING,
    frontcall_return STRING,
    lstr_sql_from_clause STRING,
    lstr_sql_where_clause STRING,
    lstr_sql_orderby_clause STRING,
    lstr_sql_where STRING,
    lstr_where STRING,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*

  LET lint_action = C_APPACTION_UNDEFINED
  IF pstr_title IS NULL THEN
    LET pstr_title = mstr_brandlist_default_title
  END IF
  LET ff_formtitle = pstr_title
  CALL FGL_SETTITLE(ff_formtitle)

  LET mrec_brandlistqbeinput.sortby = brandlist_get_default_sortby()
  LET mrec_brandlistqbeinput.orderby = brandlist_get_default_orderby()
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_brandlistqbeinput.* FROM scr_qbeinput.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    CONSTRUCT lstr_sql_where
      ON
        brands.brnd_name,
        brands.brnd_email,
        accountstatus.accst_name,
        brands_primarycategory,
        brands_othercategories
      FROM scr_qbeconstruct.*
      BEFORE CONSTRUCT
    END CONSTRUCT
    DISPLAY ARRAY marec_brandlist TO scr_brand_list.*
    END DISPLAY

    ON ACTION zoom
      IF INFIELD(brands_othercategories_filter) THEN
        CALL larec_categories.clear()
        CALL zoom_category.display(larec_categories, setup.g_app_backoffice, NULL, TRUE)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          DISPLAY string.serialize_categories(larec_categories) TO brands_othercategories_filter
        END IF
      END IF
      IF INFIELD(brands_primarycategory_filter) THEN
        CALL larec_categories.clear()
        CALL zoom_category.display(larec_categories, setup.g_app_backoffice, NULL, FALSE)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          DISPLAY string.serialize_categories(larec_categories) TO brands_primarycategory_filter
        END IF
      END IF

    ON ACTION filter
      --DISPLAY CURRENT, " qbe=", lstr_sql_where
      --DISPLAY "mrec_brandlistqbeinput.sortby = ",mrec_brandlistqbeinput.sortby
      --DISPLAY "mrec_brandlistqbeinput.orderby = ",mrec_brandlistqbeinput.orderby
      IF lstr_sql_where.getLength() == 0 THEN
       LET lstr_sql_where = " 1=1"
      END IF
      LET lstr_sql_from_clause = " brands"
      IF lstr_sql_where.getIndexOf("brands_primarycategory",1) > 0 THEN
        LET i = lstr_sql_where.getIndexOf("brands_primarycategory",1)
        LET j = lstr_sql_where.getIndexOf("'",i)+1
        LET k = lstr_sql_where.getIndexOf("'",j)
        LET lstr_where = lstr_sql_where.subString(j,k-1)
        CALL string.deserialize_categories(lstr_where, larec_categories)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          LET lstr_sql_where = IIF(i=1,"",lstr_sql_where.subString(1,i-1)),
                               " brands.brnd_id IN (SELECT brandcategories.brndcat_brand_id FROM brandcategories WHERE brandcategories.brndcat_isprimary = 1 AND brandcategories.brndcat_category_id = ",
                               string.get_ids_from_categories(lstr_where),") ",
                               lstr_sql_where.subString(k+1,lstr_sql_where.getLength())
        END IF
      END IF
      IF lstr_sql_where.getIndexOf("brands_othercategories",1) > 0 THEN
        LET i = lstr_sql_where.getIndexOf("brands_othercategories",1)
        LET j = lstr_sql_where.getIndexOf("'",i)+1
        LET k = lstr_sql_where.getIndexOf("'",j)
        LET lstr_where = lstr_sql_where.subString(j,k-1)
        CALL string.deserialize_categories(lstr_where, larec_categories)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          LET j = string.countTokens(string.get_ids_from_categories(lstr_where),",")-1
          LET lstr_sql_where = IIF(i=1,"",lstr_sql_where.subString(1,i-1)),
                               " brands.brnd_id IN (SELECT brandcategories.brndcat_brand_id FROM brandcategories WHERE brandcategories.brndcat_isprimary = 0 AND brandcategories.brndcat_category_id IN ",
                               string.get_ids_from_categories(lstr_where),
                               " GROUP BY brandcategories.brndcat_brand_id",
                               IIF(j>0,SFMT(" HAVING count(brandcategories.brndcat_brand_id)>%1",j),""),
                               ") ",
                               lstr_sql_where.subString(k+1,lstr_sql_where.getLength())
        END IF
      END IF
      LET lstr_sql_where_clause = lstr_sql_where
      IF lstr_sql_where.getIndexOf("accountstatus.accst_name", 1) > 0
        OR mrec_brandlistqbeinput.sortby == "accountstatus.accst_name"
      THEN
        LET lstr_sql_from_clause = SFMT("%1, accountstatus", lstr_sql_from_clause)
        LET lstr_sql_where_clause = lstr_sql_where_clause
          ," AND brands.brnd_accountstatus_id = accountstatus.accst_id"
      END IF
      LET lstr_sql_orderby_clause = SFMT("%1 %2",mrec_brandlistqbeinput.sortby, mrec_brandlistqbeinput.orderby)

      CALL brandlist_get_data(lstr_sql_from_clause, lstr_sql_where_clause,lstr_sql_orderby_clause, marec_brandlist)
        RETURNING lint_ret, lstr_msg
      CALL display_brandlist_default_title()

    ON ACTION display_brand
      LET i = DIALOG.getCurrentRow("scr_brand_list")
      IF i > 0 THEN
        CALL brandgrid_open_form_by_key(marec_brandlist[i].brand.brnd_id, C_APPSTATE_UPDATE)
          RETURNING lint_ret, lint_action, lint_brand_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"brandlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action <> C_APPACTION_VIEWBRANDS THEN
            EXIT DIALOG
          END IF
          CALL brandlist_get_data_by_key(lint_brand_id, marec_brandlist, i)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
          END IF
          CALL brandlist_ui_set_action_state(DIALOG)
          CALL display_brandlist_default_title()
        END IF
      END IF
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      IF lint_action == C_APPACTION_ADDBRAND THEN
        CALL brandgrid_open_form_by_key(0, C_APPSTATE_ADD)
          RETURNING lint_ret, lint_action, lint_brand_id
        CALL core_automaton.update_webmenu(setup.g_frontcall_module,"brandlist_page", setup.g_loggedin_name) RETURNING frontcall_return
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_ACCEPT THEN
            LET lint_action = C_APPACTION_VIEWBRANDS
          END IF
          IF lint_action <> C_APPACTION_VIEWBRANDS THEN
            EXIT DIALOG
          END IF
          IF lint_brand_id > 0 THEN
            LET i = marec_brandlist.getLength() + 1
            CALL brandlist_get_data_by_key(lint_brand_id, marec_brandlist, i)
              RETURNING lint_ret, lstr_msg
            IF lint_ret <> 0 THEN
              ERROR lstr_msg
            END IF
            CALL brandlist_ui_set_action_state(DIALOG)
            CALL display_brandlist_default_title()
          END IF
        END IF
      END IF
      EXIT DIALOG
    BEFORE DIALOG
      CALL brandlist_ui_set_action_state(DIALOG)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"brandlist_page", setup.g_loggedin_name) RETURNING frontcall_return
  END DIALOG
   RETURN lint_ret, lint_action
END FUNCTION

#+ Get the brand list data
#+
#+ @param pstr_from SQL FROM clause to select data
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of brands t_brandlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandlist_get_data(pstr_from, pstr_where, pstr_orderby, parec_list)
  DEFINE
    pstr_from STRING,
    pstr_where STRING,
    pstr_orderby STRING,
    parec_list DYNAMIC ARRAY OF t_brandlist,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_sql STRING,
    lint_brand_id LIKE brands.brnd_id,
    lrec_primarycategory RECORD LIKE categories.*,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*

  CALL parec_list.clear()
  LET pstr_from = pstr_from.trim()
  IF pstr_from.getLength() > 0 THEN
    LET pstr_from = SFMT("FROM %1", pstr_from)
  ELSE
    LET pstr_from = "FROM brands"
  END IF
  LET pstr_where = pstr_where.trim()
  IF pstr_where.getLength() > 0 THEN
    LET pstr_where = SFMT("WHERE %1", pstr_where)
  END IF
  LET pstr_orderby = pstr_orderby.trim()
  IF pstr_orderby.getLength() > 0 THEN
    LET pstr_orderby = SFMT("ORDER BY %1", pstr_orderby)
  END IF
  LET lstr_sql = "SELECT brands.brnd_id ", pstr_from, " ", pstr_where, " ", pstr_orderby
  TRY
    DECLARE c_brandlist_get_data CURSOR FROM lstr_sql
    FOREACH c_brandlist_get_data
      INTO lint_brand_id
      CALL brandlist_get_data_by_key(lint_brand_id, parec_list, parec_list.getLength()+1)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      -- Get categories
      CALL larec_categories.clear()
      CALL core_db.get_brand_primary_category(lint_brand_id)
        RETURNING lint_ret, lstr_msg, lrec_primarycategory.*
      CASE lint_ret
        WHEN 0
          LET larec_categories[1].* = lrec_primarycategory.*
        WHEN NOTFOUND
          LET lint_ret = 0
          INITIALIZE lstr_msg TO NULL
        OTHERWISE
          RETURN lint_ret, lstr_msg
      END CASE
      LET parec_list[parec_list.getLength()].brands_primarycategory = string.serialize_categories(larec_categories)
      CALL core_db.get_brand_primary_other_categories(lint_brand_id, larec_categories)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET parec_list[parec_list.getLength()].brands_othercategories = string.serialize_categories(larec_categories)
    END FOREACH
    FREE c_brandlist_get_data
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the brand list data for a given row
#+
#+ @param pint_brand_id brand id
#+ @param parec_list list of brands t_brandlist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandlist_get_data_by_key(pint_brand_id, parec_list, pint_index)
  DEFINE
    pint_brand_id LIKE brands.brnd_id,
    parec_list DYNAMIC ARRAY OF t_brandlist,
    pint_index INTEGER,
    lrec_brand RECORD LIKE brands.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_pic RECORD LIKE pics.*

  CALL core_db.brands_select_row(pint_brand_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_brand.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET parec_list[pint_index].brand.* = lrec_brand.*
  CALL core_db.pics_select_row(lrec_brand.brnd_pic_id, FALSE)
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
FUNCTION brandlist_ui_set_action_state(p_dialog)
  DEFINE
    p_dialog ui.Dialog
  CALL p_dialog.setActionActive("display_brand", (marec_brandlist.getLength()>0))
  CALL p_dialog.setActionHidden("customaction", TRUE)
END FUNCTION

#+ Fetch and display brands
#+
#+ @param pint_brand_id current brand
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandgrid_open_form_by_key(pint_brand_id, pint_state)
  DEFINE
    pint_brand_id LIKE brands.brnd_id,
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action INTEGER

  LET mint_brand_id = pint_brand_id
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_brand_grid WITH FORM "brand_grid"
  CASE pint_state
    --WHEN C_APPSTATE_DISPLAY
      --CALL brandgrid_display(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_ADD
      CALL brandgrid_create(pint_state) RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL brandgrid_update(pint_state) RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_brand_grid
  RETURN lint_ret, lint_action, mint_brand_id
END FUNCTION

#+ Dialog of the brand display
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
--FUNCTION brandgrid_display(pint_state)
  --DEFINE
    --pint_state SMALLINT,
    --lint_ret INTEGER,
    --lstr_msg STRING,
    --lint_action SMALLINT
--
  --LET lint_action = C_APPACTION_UNDEFINED
  --CALL FGL_SETTITLE(%"Profile")
  --CALL brandgrid_get_data_by_key(mint_brand_id)
    --RETURNING lint_ret, lstr_msg, mrec_brandgrid.*, mrec_db_brand.*
  --IF lint_ret <> 0 THEN
    --RETURN lint_ret, lint_action
  --END IF
  --MENU ""
    --BEFORE MENU
      --CALL brandgrid_ui_set_action_state(DIALOG, C_DIALOGSTATE_DISPLAY, FALSE)
      --DISPLAY mrec_brandgrid.* TO scr_brand_grid.*
    --ON ACTION update_profile
      --LET lint_action = C_APPACTION_UPDATE
      --EXIT MENU
    --ON ACTION update_password
      --CALL passwords.update_password(mint_brand_id, C_USERTYPE_BRAND, FALSE, setup.g_app_is_mobile)
        --RETURNING lint_ret, lstr_msg
      --IF lint_ret <> 0 THEN
        --ERROR lstr_msg
      --END IF
    --ON ACTION close
      --LET lint_action = C_APPACTION_CLOSE
      --EXIT MENU
    --ON ACTION logout
      --LET lint_action = C_APPACTION_EXIT
      --EXIT MENU
  --END MENU
  --RETURN lint_ret, lint_action
--END FUNCTION

#+ Create a profile for a brand
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandgrid_create(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT

  LET pint_state = pint_state
  CALL brandgrid_input(C_DIALOGSTATE_ADD)
    RETURNING lint_ret, lint_action
  RETURN lint_ret, lint_action
END FUNCTION

#+ Update a profile for a brand
#+
#+ @param pint_state current state from which the function was invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION brandgrid_update(pint_state)
  DEFINE
    pint_state SMALLINT,
    lint_ret INTEGER,
    lint_action SMALLINT,
    lbool_exit BOOLEAN

  LET pint_state = pint_state
  LET lbool_exit = FALSE
  WHILE NOT lbool_exit
    LET lbool_exit = TRUE
    CALL brandgrid_input(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lint_action
    --we want to stay in the brand edition
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
#+ @return     0|error, next performed action id
FUNCTION brandgrid_input(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    ff_formtitle STRING,
    frontcall_return STRING,
    lstr_where STRING,
    larec_campaigns DYNAMIC ARRAY OF RECORD LIKE campaigns.*

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
  CALL brandgrid_initialize_data(mint_brand_id, pint_dialog_state)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_brandgrid.*,mrec_location.* FROM scr_brand_grid.*,scr_loc.*
      ATTRIBUTE (WITHOUT DEFAULTS)
      BEFORE INPUT
        CALL currency_combobox_initializer()
        CALL accountstatus_combobox_initializer()
        CALL gender_combobox_initializer()

      AFTER INPUT
        If mrec_brandgrid.brand.brnd_city_id Is Null Then
          Error %"City required"
          Next Field cts_name
        End If
        If mrec_brandgrid.brand.brnd_state_id Is Null Then
          Error %"State required"
          Next Field sttt_name
        End If
        If mrec_brandgrid.brand.brnd_country_id Is Null Then
          Error %"Country required"
          Next Field cntr_name
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
            Let mrec_brandgrid.brand.brnd_country_id = Null
          Otherwise
            Call Dialog.setCompleterItems(countryList)
        End Case
        LET m_dialogtouched = TRUE
        CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field cntr_name
        If Not oldCountry.equals(mrec_location.cntr_name) Then
          If countryList.getLength() > 0 And mrec_location.cntr_name Is Not Null Then
            Let mrec_brandgrid.brand.brnd_country_id = IIF(countryList.search("",mrec_location.cntr_name)=0,-1,countryIdList[countryList.search("",mrec_location.cntr_name)])
            If mrec_brandgrid.brand.brnd_country_id = -1 Then
              Let mrec_location.cntr_name = Null
              Let mrec_brandgrid.brand.brnd_country_id = Null
            End If
            Let mrec_location.stt_name = Null
            Let mrec_brandgrid.brand.brnd_state_id = Null
            Let mrec_location.cts_name = Null
            Let mrec_brandgrid.brand.brnd_city_id = Null
          Else
            If mrec_location.cntr_name Is Not Null And mrec_brandgrid.brand.brnd_country_id Is Not Null Then
            Else
              Let mrec_location.cntr_name = Null
              Let mrec_brandgrid.brand.brnd_country_id = Null
            End If
            Let mrec_location.stt_name = Null
            Let mrec_brandgrid.brand.brnd_state_id = Null
            Let mrec_location.cts_name = Null
            Let mrec_brandgrid.brand.brnd_city_id = Null
          End If
          LET m_dialogtouched = TRUE
          CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
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
            Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
            Let mrec_location.cntr_name = la_val[2]
          Else
            Let mrec_brandgrid.brand.brnd_country_id = Null
            Let mrec_location.cntr_name = Null
          End If
          Let mrec_location.stt_name = Null
          Let mrec_brandgrid.brand.brnd_state_id = Null
          Let mrec_location.cts_name = Null
          Let mrec_brandgrid.brand.brnd_city_id = Null
          LET m_dialogtouched = TRUE
          CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      Before Field stt_name
        Let oldState = mrec_location.stt_name

      ON CHANGE stt_name
        LET m_dialogtouched = TRUE
        CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

        Let qry =
             "Select stt_id,stt_name From states"
             || IIF(mrec_location.cntr_name Is Not Null," Where stt_country_id = "||mrec_brandgrid.brand.brnd_country_id," ")
             || IIF(fgl_dialog_getbuffer() Is Not Null,
                    IIF(mrec_location.cntr_name Is Not Null," And "," Where ") || "UPPER(stt_name) Like UPPER('"||fgl_dialog_getbuffer()||"%')"," ")
             || " Order By stt_name"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),stateList,stateIdList)
        Case stateList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_brandgrid.brand.brnd_state_id = Null
          Otherwise
            Call Dialog.setCompleterItems(stateList)
        End Case
        LET m_dialogtouched = TRUE
        CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field stt_name
        If Not oldState.equals(mrec_location.stt_name) Then
          If stateList.getLength() > 0 And mrec_location.stt_name Is Not Null Then
            Let mrec_brandgrid.brand.brnd_state_id = IIF(stateList.search("",mrec_location.stt_name)=0,-1,stateIdList[stateList.search("",mrec_location.stt_name)])
            If mrec_brandgrid.brand.brnd_state_id = -1 Then
              Let mrec_location.stt_name = Null
              Let mrec_brandgrid.brand.brnd_state_id = Null
            Else
              If mrec_brandgrid.brand.brnd_country_id Is Null Then
                Call la_val.clear()
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_brandgrid.brand.brnd_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            End If
            Let mrec_location.cts_name = Null
            Let mrec_brandgrid.brand.brnd_city_id = Null
          Else
            If mrec_location.stt_name Is Not Null And mrec_brandgrid.brand.brnd_state_id Is Not Null Then
              If mrec_brandgrid.brand.brnd_country_id Is Null Then
                Call la_val.clear()
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_brandgrid.brand.brnd_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            Else
              Let mrec_location.stt_name = Null
              Let mrec_brandgrid.brand.brnd_state_id = Null
            End If
            Let mrec_location.cts_name = Null
            Let mrec_brandgrid.brand.brnd_city_id = Null
          End If
          LET m_dialogtouched = TRUE
          CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call stateList.clear()
        Call stateIdList.clear()

      On Action zoomstate
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"State List","Select states.stt_id,states.stt_name||' ( '||countries.cntr_name||' ) ' From states,countries",
                    "states.stt_country_id = countries.cntr_id"||
                    IIF(mrec_brandgrid.brand.brnd_country_id Is Not Null," And states.stt_country_id = "||mrec_brandgrid.brand.brnd_country_id," "),
                    "states.stt_name",
                    fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call la_val.clear()
          Call core_db.sqlQuery("Select states.stt_id,states.stt_name From states Where states.stt_id = "||zoomKeyReturn,la_val)
          If la_val.getLength() > 0 Then
            Let mrec_brandgrid.brand.brnd_state_id = la_val[1]
            Let mrec_location.stt_name = la_val[2]
          Else
            Let mrec_brandgrid.brand.brnd_state_id = Null
            Let mrec_location.stt_name = Null
          End If
          If mrec_brandgrid.brand.brnd_country_id Is Null Then
            Call la_val.clear()
            Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
              Let mrec_location.cntr_name = la_val[2]
            Else
              Let mrec_brandgrid.brand.brnd_country_id = Null
              Let mrec_location.cntr_name = Null
            End If
          End If
          Let mrec_location.cts_name = Null
          Let mrec_brandgrid.brand.brnd_city_id = Null
          LET m_dialogtouched = TRUE
          CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      Before Field cts_name
        Let oldCity = mrec_location.cts_name

      On Change cts_name
        Let qry =
             "Select cts_id,cts_name From cities"
             || IIF(mrec_brandgrid.brand.brnd_country_id Is Not Null And mrec_brandgrid.brand.brnd_state_id Is Null,
                    " Where cities.cts_state_id in (select stt_id From states Where stt_country_id = "||mrec_brandgrid.brand.brnd_country_id||")",
                    " ")
             || IIF(mrec_brandgrid.brand.brnd_state_id Is Not Null,
                    " Where cts_state_id = "||mrec_brandgrid.brand.brnd_state_id,
                    " ")
             || IIF(fgl_dialog_getbuffer() Is Not Null,
                    IIF(mrec_brandgrid.brand.brnd_state_id Is Not Null Or mrec_brandgrid.brand.brnd_country_id Is Not Null,
                        " And ",
                        " Where ")|| "Upper(cts_name) Like Upper('"||fgl_dialog_getbuffer()||"%')",
                    " ")
             || " Order by cts_name"
        Call core_db.getListForCompleter(qry,fgl_dialog_getbuffer(),cityList,cityIdList)
        Case cityList.getLength()
          When 0
            Call Dialog.setCompleterItems(Null)
            Let mrec_brandgrid.brand.brnd_city_id = Null
          Otherwise
            Call Dialog.setCompleterItems(cityList)
        End Case
        LET m_dialogtouched = TRUE
        CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      After Field cts_name
        If Not oldCity.equals(mrec_location.cts_name) Then
          If cityList.getLength() > 0 And mrec_location.cts_name Is Not Null Then
            Let mrec_brandgrid.brand.brnd_city_id = IIF(cityList.search("",mrec_location.cts_name)=0,-1,cityIdList[cityList.search("",mrec_location.cts_name)])
            If mrec_brandgrid.brand.brnd_city_id = -1 Then
              Let mrec_location.cts_name = Null
              Let mrec_brandgrid.brand.brnd_city_id = Null
            Else
              If mrec_brandgrid.brand.brnd_state_id Is Null Then
                Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||mrec_brandgrid.brand.brnd_city_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_brandgrid.brand.brnd_state_id = la_val[1]
                  Let mrec_location.stt_name = la_val[2]
                Else
                  Let mrec_brandgrid.brand.brnd_state_id = Null
                  Let mrec_location.stt_name = Null
                End If
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_brandgrid.brand.brnd_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            End If
          Else
            If mrec_location.cts_name Is Not Null And mrec_brandgrid.brand.brnd_city_id Is Not Null Then
              If mrec_brandgrid.brand.brnd_state_id Is Null Then
                Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||mrec_brandgrid.brand.brnd_city_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_brandgrid.brand.brnd_state_id = la_val[1]
                  Let mrec_location.stt_name = la_val[2]
                Else
                  Let mrec_brandgrid.brand.brnd_state_id = Null
                  Let mrec_location.stt_name = Null
                End If
                Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
                If la_val.getLength() > 0 Then
                  Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
                  Let mrec_location.cntr_name = la_val[2]
                Else
                  Let mrec_brandgrid.brand.brnd_country_id = Null
                  Let mrec_location.cntr_name = Null
                End If
              End If
            Else
              Let mrec_location.cts_name = Null
              Let mrec_brandgrid.brand.brnd_city_id = Null
            End If
          End If
          LET m_dialogtouched = TRUE
          CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If
        Call cityList.clear()
        Call cityIdList.clear()

      On Action zoomcity
        Call zoom_countrystatecitylist.zoomCountryStateCity(%"City List","Select cities.cts_id,cities.cts_name||' ( '||states.stt_name||' - '||countries.cntr_name||' )' From cities,states,countries",
                    "cities.cts_state_id = states.stt_id And states.stt_country_id = countries.cntr_id"||
                    IIF(mrec_brandgrid.brand.brnd_state_id Is Not Null," And cities.cts_state_id = "||mrec_brandgrid.brand.brnd_state_id," ")||
                    IIF(mrec_brandgrid.brand.brnd_country_id Is Not Null," And states.stt_country_id = "||mrec_brandgrid.brand.brnd_country_id," "),
                    "cities.cts_name",
                    fgl_dialog_getbuffer())
          Returning zoomKeyReturn
        If zoomKeyReturn Is Not Null Then
          Call core_db.sqlQuery("Select cities.cts_id,cities.cts_name From cities Where cities.cts_id = "||zoomKeyReturn,la_val)
          If la_val.getLength() > 0 Then
            Let mrec_brandgrid.brand.brnd_city_id = la_val[1]
            Let mrec_location.cts_name = la_val[2]
          Else
            Let mrec_brandgrid.brand.brnd_city_id = Null
            Let mrec_location.cts_name = Null
          End If
          If mrec_brandgrid.brand.brnd_state_id Is Null Then
            Call core_db.sqlQuery("Select cities.cts_state_id,states.stt_name From cities,states Where cities.cts_state_id = states.stt_id And cities.cts_id = "||zoomKeyReturn,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_brandgrid.brand.brnd_state_id = la_val[1]
              Let mrec_location.stt_name = la_val[2]
            Else
              Let mrec_brandgrid.brand.brnd_state_id = Null
              Let mrec_location.stt_name = Null
            End If
            Call core_db.sqlQuery("Select states.stt_country_id,countries.cntr_name From states,countries Where states.stt_country_id = countries.cntr_id And states.stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
            If la_val.getLength() > 0 Then
              Let mrec_brandgrid.brand.brnd_country_id = la_val[1]
              Let mrec_location.cntr_name = la_val[2]
            Else
              Let mrec_brandgrid.brand.brnd_country_id = Null
              Let mrec_location.cntr_name = Null
            End If
          End If
          LET m_dialogtouched = TRUE
          CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
        End If

      ON CHANGE brnd_gender_id
        LET m_dialogtouched = TRUE
        CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

      ON ACTION zoom
        IF INFIELD(brands_othercategories) THEN
          CALL string.deserialize_categories(mrec_brandgrid.brand_othercategories, larec_categories)
            RETURNING lint_ret, lstr_msg
          IF lint_ret == 0 THEN
            LET lstr_where = string.get_ids_from_categories(mrec_brandgrid.brand_primarycategory)
            IF lstr_where.getLength() > 0 THEN
              LET lstr_where = SFMT("categories.ctgr_id NOT IN %1",lstr_where)
            END IF
            CALL zoom_category.display(larec_categories, setup.g_app_backoffice, lstr_where, TRUE)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              LET mrec_brandgrid.brand_othercategories = string.serialize_categories(larec_categories)
              LET m_dialogtouched = TRUE
              CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF
        IF INFIELD(brands_primarycategory) THEN
          CALL string.deserialize_categories(mrec_brandgrid.brand_primarycategory, larec_categories)
            RETURNING lint_ret, lstr_msg
          IF lint_ret == 0 THEN
            LET lstr_where = string.get_ids_from_categories(mrec_brandgrid.brand_othercategories)
            IF lstr_where.getLength() > 0 THEN
              LET lstr_where = SFMT("categories.ctgr_id NOT IN %1",lstr_where)
            END IF
            CALL zoom_category.display(larec_categories, setup.g_app_backoffice, lstr_where, FALSE)
              RETURNING lint_ret, lstr_msg
            IF lint_ret == 0 THEN
              LET mrec_brandgrid.brand_primarycategory = string.serialize_categories(larec_categories)
              LET m_dialogtouched = TRUE
              CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
            END IF
          END IF
        END IF

    END INPUT
    ON ACTION edit_brandsocialnetworks
      IF m_dialogtouched THEN
        IF core_ui.ui_message(%"Question ?",%"Save the edition and continue?","yes","yes|cancel","fa-question") == "yes" THEN
          CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
            CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
            CONTINUE DIALOG
          END IF
          LET mint_brand_id = mrec_brandgrid.brand.brnd_id
        ELSE
          CONTINUE DIALOG
        END IF
      END IF
      CALL brandsocialnetworks.brandsocialnetworklist_open_form_by_key(mrec_brandgrid.brand.brnd_id)
        RETURNING lint_ret, lint_action
      IF lint_ret == 0 THEN
        IF lint_action <> C_APPACTION_CANCEL THEN
          EXIT DIALOG
        END IF
      END IF

    ON ACTION upload_photo
      LET lint_ret = core_ui.ui_upload_image(mrec_brandgrid.pic_value)
      IF lint_ret == 0 THEN
        LET mrec_brandgrid.brand.brnd_pic_id = 0 --trick for mark the picture as touched
        LET m_dialogtouched = TRUE
        CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      END IF

    ON ACTION dialogtouched
      LET m_dialogtouched = TRUE
      CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)

    ON ACTION validate_brand
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_VALIDATE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF

    ON ACTION cancel_brand
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF

    ON ACTION reject_brand
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_REJECT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF

    ON ACTION suspend_brand
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_SUSPEND)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF

    ON ACTION delete_brand
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_DELETE)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF

    ON ACTION requestcancelaccount
      IF core_ui.ui_message(%"Question",%"Do you really want to cancel your account?","no","yes|no","fa-question") == "yes" THEN
        CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_WANTTOLEAVE)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE DIALOG
        END IF
        LET lint_action = C_APPACTION_LOGOUT
        LET mint_brand_id = mrec_brandgrid.brand.brnd_id
        EXIT DIALOG
      END IF

    ON ACTION acceptrequestcancelaccount
      --count number of campaigns that are not closed-deleted-removed
      CALL core_db.campaigns_fetch_all_rows(SFMT("WHERE campaigns.cmp_brand_id = %1 AND campaigns.cmp_campaignstatus_id NOT IN ('%2','%3','%4')",mrec_brandgrid.brand.brnd_id,C_CAMPAIGNSTATUS_DELETED,C_CAMPAIGNSTATUS_REMOVED,C_CAMPAIGNSTATUS_CLOSED),NULL, larec_campaigns)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF larec_campaigns.getLength() > 0 THEN
          ERROR SFMT("This brand has %1 campaigns which are neither closed nor deleted", larec_campaigns.getLength())
          CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE DIALOG
        END IF
        CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_REJECT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
          CONTINUE DIALOG
        END IF
        LET mint_brand_id = mrec_brandgrid.brand.brnd_id
        LET lint_action = C_APPACTION_ACCEPT
        EXIT DIALOG
      END IF

    ON ACTION rejectrequestcancelaccount
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_BRAND_REJECTREQUESTCANCELACCOUNT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_brand_id = mrec_brandgrid.brand.brnd_id
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG

    ON ACTION exportaccount
      CALL brandgrid_export_account()
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF

    ON ACTION save
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_ACCEPT)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET mint_brand_id = mrec_brandgrid.brand.brnd_id
      LET lint_action = C_APPACTION_ACCEPT
      IF setup.g_app_brand THEN
        LET setup.g_loggedin_id = mint_brand_id
        CALL setup.refresh_loggedin_name()
      END IF
      EXIT DIALOG

    ON ACTION customaction
      CALL brandgrid_process_data(DIALOG, pint_dialog_state, m_dialogtouched, C_APPACTION_CANCEL)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CALL DIALOG.nextField(FGL_DIALOG_GETFIELDNAME())
        CONTINUE DIALOG
      END IF
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      LET mint_brand_id = mrec_brandgrid.brand.brnd_id
      EXIT DIALOG

    BEFORE DIALOG
      LET m_dialogtouched = FALSE
      CALL brandgrid_ui_set_action_state(DIALOG, pint_dialog_state, m_dialogtouched)
      DISPLAY BY NAME ff_formtitle
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,IIF(pint_dialog_state==C_DIALOGSTATE_ADD, "addbrand_page", "updatebrand_page"), setup.g_loggedin_name) RETURNING frontcall_return

  END DIALOG
  RETURN lint_ret, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pint_dialog_state current DIALOG state
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+
FUNCTION brandgrid_ui_set_action_state(p_dialog, pint_dialog_state, pbool_dialog_touched)
  DEFINE
    p_dialog ui.Dialog,
    pint_dialog_state SMALLINT,
    pbool_dialog_touched SMALLINT,
    lbool_allow_validate BOOLEAN,
    lbool_allow_cancel BOOLEAN,
    lbool_allow_reject BOOLEAN,
    lbool_allow_suspend BOOLEAN,
    lbool_allow_delete BOOLEAN,
    lbool_allow_requestcancelaccount BOOLEAN,
    lbool_allow_acceptrequestcancelaccount BOOLEAN,
    lbool_allow_rejectrequestcancelaccount BOOLEAN,
    lbool_allow_exportaccount BOOLEAN

  LET lbool_allow_validate = FALSE
  LET lbool_allow_cancel = FALSE
  LET lbool_allow_reject = FALSE
  LET lbool_allow_suspend = FALSE
  LET lbool_allow_delete = FALSE
  LET lbool_allow_requestcancelaccount = FALSE
  LET lbool_allow_acceptrequestcancelaccount = FALSE
  LET lbool_allow_rejectrequestcancelaccount = FALSE
  LET lbool_allow_exportaccount = FALSE

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND NOT setup.g_app_is_mobile)
      CALL core_ui.ui_set_node_attribute("Button","name","upload_photo","hidden","0")
      --display password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","brands_brnd_password_label1","hidden",0)
      CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_password","hidden","0")
      CALL core_ui.ui_set_node_attribute("Label","name","brands1_brnd_password","hidden","0")
      CALL core_ui.ui_set_node_attribute("FormField","name","brands1.brnd_password","hidden","0")

      IF setup.g_app_brand THEN
        CALL core_ui.ui_set_node_attribute("Label","name","brnd_emailvalidationdate_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_emailvalidationdate","hidden", "1")
        CALL core_ui.ui_set_node_attribute("Label","name","brnd_accountstatus_id_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_accountstatus_id","hidden", "1")
      END IF
      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", "1")
      CALL core_ui.ui_set_node_attribute("Button","name","validate_brand","hidden","1")
      CALL p_dialog.setActionActive("validate_brand", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","cancel_brand","hidden","1")
      CALL p_dialog.setActionActive("cancel_brand", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","reject_brand","hidden","1")
      CALL p_dialog.setActionActive("reject_brand", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","suspend_brand","hidden","1")
      CALL p_dialog.setActionActive("suspend_brand", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","delete_brand","hidden","1")
      CALL p_dialog.setActionActive("delete_brand", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","requestcancelaccount","hidden","1")
      CALL p_dialog.setActionActive("requestcancelaccount", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptrequestcancelaccount","hidden","1")
      CALL p_dialog.setActionActive("acceptrequestcancelaccount", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","rejectrequestcancelaccount","hidden","1")
      CALL p_dialog.setActionActive("rejectrequestcancelaccount", FALSE)
      CALL core_ui.ui_set_node_attribute("Button","name","exportaccount","hidden","1")
      CALL p_dialog.setActionActive("exportaccount", FALSE)

      CALL core_ui.ui_set_node_attribute("Button","name","edit_brandsocialnetworks","hidden", TRUE)
      CALL p_dialog.setActionActive("edit_brandsocialnetworks", FALSE)

    WHEN C_DIALOGSTATE_UPDATE
      CALL p_dialog.setActionActive("dialogtouched", NOT pbool_dialog_touched)
      CALL p_dialog.setActionActive("save", pbool_dialog_touched AND NOT setup.g_app_is_mobile)
      CALL core_ui.ui_set_node_attribute("Button","name","upload_photo","hidden","0")
      --hide password fields and labels
      CALL core_ui.ui_set_node_attribute("Label","name","brands_brnd_password_label1","hidden",1)
      CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("Label","name","brands1_brnd_password","hidden","1")
      CALL core_ui.ui_set_node_attribute("FormField","name","brands1.brnd_password","hidden","1")

      IF setup.g_app_brand THEN
        CALL core_ui.ui_set_node_attribute("Label","name","brnd_emailvalidationdate_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_emailvalidationdate","hidden", "1")
        CALL core_ui.ui_set_node_attribute("Label","name","brnd_accountstatus_id_label","hidden", "1")
        CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_accountstatus_id","hidden", "1")
        CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", "1")
      END IF
      LET lbool_allow_validate = brand_allow_validate(mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_cancel = brand_allow_cancel(mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_reject = brand_allow_reject(mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_suspend = brand_allow_suspend(mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_delete = brand_allow_delete(mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_requestcancelaccount = brand_allow_requestcancelaccount(mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_acceptrequestcancelaccount = brand_allow_acceptrequestcancelaccount(mrec_brandgrid.brand.brnd_id, mrec_brandgrid.brand.brnd_accountstatus_id)
      LET lbool_allow_rejectrequestcancelaccount = lbool_allow_acceptrequestcancelaccount --same conditions
      LET lbool_allow_exportaccount = brand_allow_exportaccount()

      CALL core_ui.ui_set_node_attribute("Label","name","account_actions_label","hidden", setup.g_app_brand
        OR NOT (lbool_allow_validate OR lbool_allow_cancel OR lbool_allow_reject OR lbool_allow_suspend OR lbool_allow_delete
        OR lbool_allow_acceptrequestcancelaccount OR lbool_allow_rejectrequestcancelaccount OR lbool_allow_exportaccount))
      CALL core_ui.ui_set_node_attribute("Button","name","validate_brand","hidden",setup.g_app_brand OR (NOT lbool_allow_validate))
      CALL p_dialog.setActionActive("validate_brand", setup.g_app_backoffice AND lbool_allow_validate)
      CALL core_ui.ui_set_node_attribute("Button","name","cancel_brand","hidden",setup.g_app_brand OR (NOT lbool_allow_cancel))
      CALL p_dialog.setActionActive("cancel_brand", setup.g_app_backoffice AND lbool_allow_cancel)
      CALL core_ui.ui_set_node_attribute("Button","name","reject_brand","hidden",setup.g_app_brand OR (NOT lbool_allow_reject))
      CALL p_dialog.setActionActive("reject_brand", setup.g_app_backoffice AND lbool_allow_reject)
      CALL core_ui.ui_set_node_attribute("Button","name","suspend_brand","hidden",setup.g_app_brand OR (NOT lbool_allow_suspend))
      CALL p_dialog.setActionActive("suspend_brand", setup.g_app_backoffice AND lbool_allow_suspend)
      CALL core_ui.ui_set_node_attribute("Button","name","delete_brand","hidden",setup.g_app_brand OR (NOT lbool_allow_delete))
      CALL p_dialog.setActionActive("delete_brand", setup.g_app_backoffice AND lbool_allow_delete)

      CALL core_ui.ui_set_node_attribute("Button","name","requestcancelaccount","hidden",(NOT lbool_allow_requestcancelaccount))
      CALL p_dialog.setActionActive("requestcancelaccount", lbool_allow_requestcancelaccount)
      CALL core_ui.ui_set_node_attribute("Button","name","acceptrequestcancelaccount","hidden",(NOT lbool_allow_acceptrequestcancelaccount))
      CALL p_dialog.setActionActive("acceptrequestcancelaccount", lbool_allow_acceptrequestcancelaccount)
      CALL core_ui.ui_set_node_attribute("Button","name","rejectrequestcancelaccount","hidden",(NOT lbool_allow_rejectrequestcancelaccount))
      CALL p_dialog.setActionActive("rejectrequestcancelaccount", lbool_allow_rejectrequestcancelaccount)
      CALL core_ui.ui_set_node_attribute("Button","name","exportaccount","hidden",(NOT lbool_allow_exportaccount))
      CALL p_dialog.setActionActive("exportaccount", lbool_allow_exportaccount)

      CALL core_ui.ui_set_node_attribute("Button","name","edit_brandsocialnetworks","hidden", NOT (setup.g_app_backoffice OR setup.g_app_brand))
      CALL p_dialog.setActionActive("edit_brandsocialnetworks", setup.g_app_backoffice OR setup.g_app_brand)

    WHEN C_DIALOGSTATE_DISPLAY
      --CALL core_ui.ui_set_node_attribute("Button","name","update_profile","hidden","0")
      --CALL core_ui.ui_set_node_attribute("Button","name","update_password","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Button","name","upload_photo","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Button","name","save","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Label","name","brands_brnd_password_label1","hidden",1)
      --CALL core_ui.ui_set_node_attribute("FormField","name","brands.brnd_password","hidden","1")
      --CALL core_ui.ui_set_node_attribute("Label","name","brands1_brnd_password","hidden","1")
      --CALL core_ui.ui_set_node_attribute("FormField","name","brands1.brnd_password","hidden","1")
      --CALL p_dialog.setActionHidden("logout", TRUE)
  END CASE
  CALL p_dialog.setActionHidden("customaction", TRUE)
  CALL layout.display_savebutton(pbool_dialog_touched)
  CALL layout.display_phonenumberprefix(mrec_brandgrid.brand.brnd_country_id)

END FUNCTION

#+ Initializes the brand business record
#+
#+ @param pint_brand_id current brand
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandgrid_initialize_data(pint_brand_id, pint_dialog_state)
  DEFINE
    pint_brand_id LIKE brands.brnd_id,
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    la_val   Dynamic Array Of String

  INITIALIZE mrec_brandgrid.* TO NULL
  INITIALIZE mrec_copy_brandgrid.* TO NULL
  INITIALIZE mrec_db_brand.* TO NULL

  CASE pint_dialog_state
    WHEN C_DIALOGSTATE_ADD
      LET mrec_brandgrid.brand.brnd_id = 0
      LET mrec_brandgrid.brand.brnd_email_style = C_EMAILSTYLE_HTML
      CALL _get_default_add_photo()
        RETURNING lint_ret, lstr_msg, mrec_brandgrid.brand.brnd_pic_id, mrec_brandgrid.pic_value
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET mrec_brandgrid.brand.brnd_currency_id = C_CURRENCY_EURO
      LET mrec_brandgrid.brand.brnd_gender_id = C_GENDER_OTHER
      LET mrec_brandgrid.brand.brnd_country_id = C_COUNTRY_FRANCE
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_brandgrid.brand.brnd_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_brandgrid.brand.brnd_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      LET mrec_brandgrid.brand.brnd_accountstatus_id = C_ACCOUNTSTATUS_INCOMPLETE
      LET mrec_brandgrid.brand.brnd_createdby_id = IIF(setup.g_app_brand, C_CREATEDBY_BRAND, C_CREATEDBY_SALFATIX)
    WHEN C_DIALOGSTATE_UPDATE
      CALL brandgrid_get_data_by_key(pint_brand_id)
        RETURNING lint_ret, lstr_msg, mrec_brandgrid.*, mrec_db_brand.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      Call core_db.sqlQuery("Select cntr_name From countries Where cntr_id = "||mrec_brandgrid.brand.brnd_country_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cntr_name = la_val[1]
      Else
        Let mrec_brandgrid.brand.brnd_country_id = Null
        Let mrec_location.cntr_name = Null
      End If
      Call core_db.sqlQuery("Select stt_name From states Where stt_id = "||mrec_brandgrid.brand.brnd_state_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.stt_name = la_val[1]
      Else
        Let mrec_brandgrid.brand.brnd_state_id = Null
        Let mrec_location.stt_name = Null
      End If
      Call core_db.sqlQuery("Select cts_name From cities Where cts_id = "||mrec_brandgrid.brand.brnd_city_id,la_val)
      If la_val.getLength() > 0 Then
        Let mrec_location.cts_name = la_val[1]
      Else
        Let mrec_brandgrid.brand.brnd_city_id = Null
        Let mrec_location.cts_name = Null
      End If
      LET mrec_copy_brandgrid.* = mrec_brandgrid.*
    OTHERWISE
      RETURN -1, %"Unknown dialog state"
  END CASE
  RETURN 0, NULL
END FUNCTION

#+ Get the data for the record type t_brandgrid
#+
#+ @param pint_brand_id brand id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_brandgrid business record, brand database record
FUNCTION brandgrid_get_data_by_key(pint_brand_id)
  DEFINE
    pint_brand_id LIKE brands.brnd_id,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    larec_primarycategory DYNAMIC ARRAY OF RECORD LIKE categories.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_ui_brand t_brandgrid,
    lrec_db_brand RECORD LIKE brands.*,
    lrec_pic RECORD LIKE pics.*,
    lrec_primarycategory RECORD LIKE categories.*

  INITIALIZE lrec_ui_brand.* TO NULL
  CALL core_db.brands_select_row(pint_brand_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_brand.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN
    RETURN lint_ret, lstr_msg, lrec_ui_brand.*, lrec_db_brand.*
  END IF
  CALL core_db.pics_select_row(lrec_brand.brnd_pic_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_pic.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_brand.*, lrec_db_brand.*
  END IF
  --get brand primary category
  CALL core_db.get_brand_primary_category(pint_brand_id)
    RETURNING lint_ret, lstr_msg, lrec_primarycategory.*
  CASE lint_ret
    WHEN 0
      LET larec_primarycategory[1].* = lrec_primarycategory.*
    WHEN NOTFOUND
      LET lint_ret = 0
      INITIALIZE lstr_msg TO NULL
    OTHERWISE
      RETURN lint_ret, lstr_msg, lrec_ui_brand.*, lrec_db_brand.*
  END CASE
  --get brand other categories
  CALL core_db.get_brand_primary_other_categories(pint_brand_id, larec_categories)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_ui_brand.*, lrec_db_brand.*
  END IF

  LET lrec_ui_brand.brand.* = lrec_brand.*
  LET lrec_ui_brand.password2 = lrec_brand.brnd_password
  LET lrec_ui_brand.pic_value = lrec_pic.pic_value
  LET lrec_ui_brand.brand_primarycategory = string.serialize_categories(larec_primarycategory)
  LET lrec_ui_brand.brand_othercategories = string.serialize_categories(larec_categories)
  LET lrec_db_brand.* = lrec_brand.*
  RETURN lint_ret, lstr_msg, lrec_ui_brand.*, lrec_db_brand.*
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
FUNCTION brandgrid_process_data(p_dialog, pint_dialog_state, pbool_dialog_touched, pint_dialog_action)
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
    lint_brand_id LIKE brands.brnd_id,
    lint_accountstatus_id LIKE brands.brnd_accountstatus_id,
    lint_action INTEGER

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
            IF core_ui.ui_message(%"Question ?",%"Abort profile edition?","no","yes|no","fa-question") == "yes" THEN
              LET lbool_restore_data = TRUE
            END IF
          END IF
        WHEN C_APPACTION_BRAND_VALIDATE
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_VALIDATED
        WHEN C_APPACTION_BRAND_CANCEL
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_CANCELLED
        WHEN C_APPACTION_BRAND_REJECT
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_STOPPED
        WHEN C_APPACTION_BRAND_SUSPEND
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_SUSPENDED
        WHEN C_APPACTION_BRAND_DELETE
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_DELETED
        WHEN C_APPACTION_BRAND_WANTTOLEAVE
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_WANTTOLEAVE
        WHEN C_APPACTION_BRAND_REJECTREQUESTCANCELACCOUNT
          LET lbool_update_data = TRUE
          LET lint_accountstatus_id = C_ACCOUNTSTATUS_VALIDATED  --restore previous brand status
    END CASE
    OTHERWISE --do nothing
      RETURN 0, NULL
  END CASE
  IF lbool_insert_data THEN
    CALL brand_validate_data(C_DIALOGSTATE_ADD)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    CALL brand_insert_into_dabatase()
      RETURNING lint_ret, lstr_msg, lint_brand_id
    --IF lint_ret == 0 THEN
    --  IF core_ui.ui_message(%"Information",%"Profile registered","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET mrec_brandgrid.brand.brnd_id = lint_brand_id

    CALL brandsocialnetworks.brandsocialnetworklist_open_form_by_key(mrec_brandgrid.brand.brnd_id)
      RETURNING lint_ret, lint_action
    IF lint_ret <> 0 THEN
      LET lint_ret = 0
    END IF

    LET pint_dialog_state = C_DIALOGSTATE_UPDATE
    LET lbool_refresh_data = TRUE
    CALL notifications.sendmail_brand_creation(mrec_brandgrid.brand.brnd_id)
  END IF

  IF lbool_update_data THEN
    CALL brand_validate_data(C_DIALOGSTATE_UPDATE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --we need to reset emailvalidationdate field in case the email has changed
    IF mrec_db_brand.brnd_email <> mrec_brandgrid.brand.brnd_email THEN
      INITIALIZE mrec_brandgrid.brand.brnd_emailvalidationdate TO NULL
    END IF
    CALL brand_update_into_dabatase(lint_accountstatus_id)
      RETURNING lint_ret, lstr_msg
    --IF lint_ret == 0 THEN
    --  IF core_ui.ui_message(%"Information",%"Profile updated","ok","ok","fa-check") THEN END IF
    --END IF
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lbool_refresh_data = TRUE
    IF mrec_db_brand.brnd_email <> mrec_brandgrid.brand.brnd_email THEN
      CALL notifications.sendmail_brand_emailupdate(mrec_brandgrid.brand.brnd_id)
    END IF
    IF pint_dialog_action == C_APPACTION_BRAND_VALIDATE THEN
      CALL notifications.sendmail_brand_validated(mrec_brandgrid.brand.brnd_id)
    END IF
    IF pint_dialog_action == C_APPACTION_BRAND_REJECT THEN
      CALL notifications.sendmail_brand_rejected(mrec_brandgrid.brand.brnd_id, mrec_db_brand.brnd_accountstatus_id)
    END IF
  END IF

  IF lbool_restore_data THEN
    CALL brandgrid_initialize_data(mrec_brandgrid.brand.brnd_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL brandgrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_brand_grid.*", FALSE) --reset the 'touched' flag
  END IF

  IF lbool_refresh_data THEN
    CALL brandgrid_initialize_data(mrec_brandgrid.brand.brnd_id, pint_dialog_state)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    --reset UI
    LET m_dialogtouched = FALSE
    CALL brandgrid_ui_set_action_state(p_dialog, pint_dialog_state, m_dialogtouched)
    CALL p_dialog.setFieldTouched("scr_brand_grid.*", FALSE) --reset the 'touched' flag
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Process the categories into database
#+
#+ @param pint_brand_id current brand
#+ @param pstr_primarycategory brand primary category string
#+ @param pstr_othercategories brand other categories string
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _process_categories(pint_brand_id, pstr_primarycategory, pstr_othercategories)
  DEFINE
    pint_brand_id LIKE brands.brnd_id,
    pstr_primarycategory STRING,
    pstr_othercategories STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    i INTEGER,
    lrec_brandcategory RECORD LIKE brandcategories.*

  --delete and insert categories
  CALL core_db.brandcategories_delete_all_rows(pint_brand_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    CALL string.deserialize_categories(pstr_primarycategory, larec_categories)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      FOR i = 1 TO larec_categories.getLength()
        INITIALIZE lrec_brandcategory.* TO NULL
        LET lrec_brandcategory.brndcat_brand_id = pint_brand_id
        LET lrec_brandcategory.brndcat_category_id = larec_categories[i].ctgr_id
        LET lrec_brandcategory.brndcat_isprimary = 1
        CALL core_db.brandcategories_insert_row(lrec_brandcategory.*)
          RETURNING lint_ret, lstr_msg, lrec_brandcategory.brndcat_brand_id, lrec_brandcategory.brndcat_category_id
        IF lint_ret <> 0 THEN
          EXIT FOR
        END IF
      END FOR
    END IF
  END IF
  IF lint_ret == 0 THEN
    CALL string.deserialize_categories(pstr_othercategories, larec_categories)
      RETURNING lint_ret, lstr_msg
    IF lint_ret == 0 THEN
      FOR i = 1 TO larec_categories.getLength()
        INITIALIZE lrec_brandcategory.* TO NULL
        LET lrec_brandcategory.brndcat_brand_id = pint_brand_id
        LET lrec_brandcategory.brndcat_category_id = larec_categories[i].ctgr_id
        LET lrec_brandcategory.brndcat_isprimary = 0
        CALL core_db.brandcategories_insert_row(lrec_brandcategory.*)
          RETURNING lint_ret, lstr_msg, lrec_brandcategory.brndcat_brand_id, lrec_brandcategory.brndcat_category_id
        IF lint_ret <> 0 THEN
          EXIT FOR
        END IF
      END FOR
    END IF
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

#+ Insert a brand into database
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, brand id
FUNCTION brand_insert_into_dabatase()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_pic RECORD LIKE pics.*,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lrec_brand.brnd_id
  END IF
  IF mrec_brandgrid.brand.brnd_pic_id == 0 THEN --means there is a photo which is not the default avatar
    INITIALIZE lrec_pic.* TO NULL
    LET lrec_pic.pic_id = 0
    LET lrec_pic.pic_value = mrec_brandgrid.pic_value
    CALL core_db.pics_insert_row(lrec_pic.*)
      RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  END IF
  IF lint_ret == 0 THEN
    INITIALIZE lrec_brand.* TO NULL
    LET lrec_brand.* = mrec_brandgrid.brand.*
    LET lrec_brand.brnd_id = 0
    IF lrec_brand.brnd_pic_id == 0 THEN
      LET lrec_brand.brnd_pic_id = lrec_pic.pic_id
    END IF
    LET lrec_brand.brnd_password = hash.compute_hash(lrec_brand.brnd_password, "BCRYPT", FALSE)
    LET lrec_brand.brnd_creationdate = CURRENT
    CALL core_db.brands_insert_row(lrec_brand.*)
      RETURNING lint_ret, lstr_msg, lrec_brand.brnd_id
  END IF
  --insert categories
  IF lint_ret == 0 THEN
    CALL _process_categories(lrec_brand.brnd_id, mrec_brandgrid.brand_primarycategory, mrec_brandgrid.brand_othercategories)
      RETURNING lint_ret, lstr_msg
  END IF
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_brand.brnd_id
  END IF

  RETURN lint_ret, lstr_msg, lrec_brand.brnd_id
END FUNCTION

#+ Update a brand into database
#+
#+ @param pint_status_id brand account status
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brand_update_into_dabatase(pint_status_id)
  DEFINE
    pint_status_id LIKE brands.brnd_accountstatus_id,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brand RECORD LIKE brands.*,
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
  LET lbool_delete_old_photo = (mrec_brandgrid.brand.brnd_pic_id == 0)
  IF mrec_brandgrid.brand.brnd_pic_id == 0 THEN --means there is a photo which is not the default avatar
    INITIALIZE lrec_pic.* TO NULL
    LET lrec_pic.pic_id = 0
    LET lrec_pic.pic_value = mrec_brandgrid.pic_value
    CALL pics_insert_row(lrec_pic.*)
      RETURNING lint_ret, lstr_msg, lrec_pic.pic_id
  END IF
  IF lint_ret == 0 THEN
    INITIALIZE lrec_brand.* TO NULL
    LET lrec_brand.* = mrec_brandgrid.brand.*
    IF lrec_brand.brnd_pic_id == 0 THEN
      LET lrec_brand.brnd_pic_id = lrec_pic.pic_id
    END IF
    IF pint_status_id IS NOT NULL AND pint_status_id > 0 THEN
      CASE pint_status_id
        WHEN C_ACCOUNTSTATUS_VALIDATED
          LET lrec_brand.brnd_validationdate = l_timestamp
        WHEN C_ACCOUNTSTATUS_CANCELLED
          LET lrec_brand.brnd_canceldate = l_timestamp
        WHEN C_ACCOUNTSTATUS_STOPPED
          LET lrec_brand.brnd_stopdate = l_timestamp
        WHEN C_ACCOUNTSTATUS_SUSPENDED
          LET lrec_brand.brnd_suspendeddate = l_timestamp
        WHEN C_ACCOUNTSTATUS_DELETED
          LET lrec_brand.brnd_deletiondate = l_timestamp
      END CASE
      LET lrec_brand.brnd_accountstatus_id = pint_status_id
    END IF
    LET lrec_brand.brnd_lastupdatedate = l_timestamp
    CALL core_db.brands_update_row(mrec_db_brand.*, lrec_brand.*)
      RETURNING lint_ret, lstr_msg
  END IF
  IF (lint_ret == 0) AND lbool_delete_old_photo THEN
    CALL core_db.pics_delete_row(mrec_copy_brandgrid.brand.brnd_pic_id)
      RETURNING lint_ret, lstr_msg
  END IF
  --delete and insert categories
  IF lint_ret == 0 THEN
    CALL _process_categories(lrec_brand.brnd_id, mrec_brandgrid.brand_primarycategory, mrec_brandgrid.brand_othercategories)
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

#+ Check business rules of a brand
#+
#+ @param pint_dialog_state current DIALOG state
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION brand_validate_data(pint_dialog_state)
  DEFINE
    pint_dialog_state SMALLINT,
    lint_ret INTEGER,
    lint_id BIGINT,
    lint_usertype SMALLINT

  --always test first NOT NULL database fields
  IF pint_dialog_state<>C_DIALOGSTATE_ADD THEN
    IF mrec_brandgrid.brand.brnd_id IS NULL OR mrec_brandgrid.brand.brnd_id==0 THEN
      RETURN -1, %"Brand missing"
    END IF
  END IF
  IF mrec_brandgrid.brand.brnd_pic_id IS NULL OR mrec_brandgrid.pic_value IS NULL THEN
    RETURN -1, %"Photo missing"
  END IF
  IF mrec_brandgrid.brand.brnd_name IS NULL THEN
    RETURN -1, %"Brand name missing"
  END IF
  IF mrec_brandgrid.brand.brnd_website IS NULL THEN
    RETURN -1, %"Website missing"
  END IF
  IF mrec_brandgrid.brand.brnd_country_id IS NULL THEN
    RETURN -1, %"Country missing"
  END IF
  IF mrec_brandgrid.brand_primarycategory IS NULL THEN
    RETURN -1, %"Main categories missing"
  END IF
  IF mrec_brandgrid.brand.brnd_currency_id IS NULL THEN
    RETURN -1, %"Currency missing"
  END IF
  IF mrec_brandgrid.brand.brnd_gender_id IS NULL THEN
    RETURN -1, %"Gender missing"
  END IF
  IF mrec_brandgrid.brand.brnd_firstname IS NULL THEN
    RETURN -1, %"Firstname missing"
  END IF
  IF mrec_brandgrid.brand.brnd_lastname IS NULL THEN
    RETURN -1, %"Lastname missing"
  END IF
  LET mrec_brandgrid.brand.brnd_email = string.trim(mrec_brandgrid.brand.brnd_email)
  IF mrec_brandgrid.brand.brnd_email IS NULL THEN
    RETURN -1, %"Email missing"
  END IF
  IF NOT emails.check_format(mrec_brandgrid.brand.brnd_email) THEN
    RETURN -1, %"Email Format Invalid"
  END IF
  CALL emails.get_usertype_and_id(mrec_brandgrid.brand.brnd_email,C_USERTYPE_BRAND)
    RETURNING lint_ret, lint_id, lint_usertype
  CASE lint_ret
    WHEN 0
      IF pint_dialog_state == C_DIALOGSTATE_ADD THEN
        RETURN -1, %"Email already used"
      ELSE --update
        IF (lint_usertype <> C_USERTYPE_BRAND)
          OR (mrec_brandgrid.brand.brnd_id <> lint_id)
        THEN
          RETURN -1, %"Email already used"
        END IF
      END IF
    WHEN NOTFOUND
    OTHERWISE --error case
      RETURN -1, %"Email already used"
  END CASE
  LET mrec_brandgrid.brand.brnd_password = string.trim(mrec_brandgrid.brand.brnd_password)
  IF mrec_brandgrid.brand.brnd_password IS NULL THEN
    RETURN -1, %"Password missing"
  END IF
  IF pint_dialog_state==C_DIALOGSTATE_ADD THEN
    LET mrec_brandgrid.password2 = string.trim(mrec_brandgrid.password2)
    IF mrec_brandgrid.password2 IS NULL THEN
      RETURN -1, %"Confirm Password missing"
    END IF
    IF mrec_brandgrid.brand.brnd_password <> mrec_brandgrid.password2 THEN
      RETURN -1, %"Passwords don't match"
    END IF
  END IF
  IF mrec_brandgrid.brand.brnd_mobile_phonenumber IS NULL THEN
    RETURN -1, %"Phone number missing"
  END IF
  IF mrec_brandgrid.brand.brnd_accountstatus_id IS NULL THEN
    RETURN -1, %"Status missing"
  END IF
  IF mrec_brandgrid.brand.brnd_createdby_id IS NULL THEN
    RETURN -1, %"CreatedBy missing"
  END IF

  RETURN 0, NULL
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION brandlist_get_default_sortby()
  RETURN "brands.brnd_name"
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION brandlist_get_default_orderby()
  RETURN "asc"
END FUNCTION

#+ Returns the default database sortby string for list
#+
#+ @returnType STRING
#+ @return     sortby string
PUBLIC FUNCTION brandlist_get_default_sqlorderby()
  RETURN SFMT("%1 %2", brandlist_get_default_sortby(), brandlist_get_default_orderby())
END FUNCTION

#+ Initializer of the country combobox
#+
FUNCTION country_combobox_initializer(fldId ui.ComboBox)
  CALL combobox.country_initializer(fldId)
END FUNCTION

#+ Initializer of the city combobox
#+
#+ @param pint_state_id state id
#+
--FUNCTION city_combobox_initializer(pint_state_id)
  --DEFINE
    --pint_state_id INTEGER
  --CALL combobox.city_initializer(ui.ComboBox.forName("brands.brnd_city_id"), pint_state_id)
--END FUNCTION

#+ Initializer of the state combobox
#+
#+ @param pint_country_id country id
#+
--FUNCTION state_combobox_initializer(pint_country_id)
  --DEFINE
    --pint_country_id INTEGER
  --CALL combobox.state_initializer(ui.ComboBox.forName("brands.brnd_state_id"), pint_country_id)
--END FUNCTION

#+ Initializer of the brand combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION brand_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox
  CALL combobox.brand_initializer(p_combo)
END FUNCTION

#+ Initializer of the brand status combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION brand_status_combobox_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox
  CALL combobox.accountstatus_initializer(p_combo)
END FUNCTION

#+ Initializer of the currency combobox
#+
FUNCTION currency_combobox_initializer()
  CALL combobox.currency_initializer(ui.ComboBox.forName("brands.brnd_currency_id"))
END FUNCTION

#+ Initializer of the status combobox
#+
FUNCTION accountstatus_combobox_initializer()
  CALL combobox.accountstatus_initializer(ui.ComboBox.forName("brands.brnd_accountstatus_id"))
END FUNCTION

#+ Initializer of the gender combobox
#+
FUNCTION gender_combobox_initializer()
  CALL combobox.gender_initializer(ui.ComboBox.forName("brands.brnd_gender_id"))
END FUNCTION

#+ Display the default title for the list of brands
#+
FUNCTION display_brandlist_default_title()
  DEFINE
    ff_formtitle STRING
  LET ff_formtitle = mstr_brandlist_default_title
  CALL FGL_SETTITLE(ff_formtitle)
  DISPLAY BY NAME ff_formtitle
END FUNCTION

#+ Checks if a brand can be validated
#+
#+ @param pint_status_id current brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_validate(pint_status_id)
  DEFINE
    pint_status_id LIKE brands.brnd_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_INCOMPLETE
    OR pint_status_id == C_ACCOUNTSTATUS_SUSPENDED
  THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can be cancelled
#+
#+ @param pint_status_id current brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_cancel(pint_status_id)
  DEFINE
    pint_status_id LIKE brands.brnd_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_INCOMPLETE THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can be rejected
#+
#+ @param pint_status_id current brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_reject(pint_status_id)
  DEFINE
    pint_status_id LIKE brands.brnd_accountstatus_id

    IF pint_status_id == C_ACCOUNTSTATUS_INCOMPLETE
    OR pint_status_id == C_ACCOUNTSTATUS_VALIDATED
    OR pint_status_id == C_ACCOUNTSTATUS_SUSPENDED
  THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can be validated
#+
#+ @param pint_status_id current brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_suspend(pint_status_id)
  DEFINE
    pint_status_id LIKE brands.brnd_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_VALIDATED THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can be validated
#+
#+ @param pint_status_id current brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_delete(pint_status_id)
  DEFINE
    pint_status_id LIKE brands.brnd_accountstatus_id

  IF pint_status_id == C_ACCOUNTSTATUS_STOPPED THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can ask to cancel his account
#+
#+ @param pint_status_id current brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_requestcancelaccount(pint_status_id LIKE brands.brnd_accountstatus_id)
  IF pint_status_id == C_ACCOUNTSTATUS_VALIDATED THEN
    IF setup.g_app_brand THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a salfatix user can accept the cancel request made by a brand
#+
#+ @param pint_id brand id
#+ @param pint_status_id brand status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_acceptrequestcancelaccount(pint_id LIKE brands.brnd_id, pint_status_id LIKE brands.brnd_accountstatus_id)
  LET pint_id = pint_id
  IF setup.g_app_backoffice THEN
    IF pint_status_id == C_ACCOUNTSTATUS_WANTTOLEAVE THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a user can export the brand account data
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION brand_allow_exportaccount()
  IF setup.g_app_backoffice THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Export the brand and his deals
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION brandgrid_export_account()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i,j INTEGER,
    lstr_sql STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_country RECORD LIKE countries.*,
    lrec_state RECORD LIKE states.*,
    lrec_city RECORD LIKE cities.*,
    lrec_category RECORD LIKE categories.*,
    lrec_currency RECORD LIKE currencies.*,
    lrec_gender RECORD LIKE genders.*,
    lrec_accountstatus RECORD LIKE accountstatus.*,
    lrec_socialnetwork RECORD LIKE socialnetworks.*,
    lrec_brandsocialnetwork RECORD LIKE brandsocialnetworks.*,
    larec_categories DYNAMIC ARRAY OF RECORD LIKE categories.*,
    larec_campaigns DYNAMIC ARRAY OF RECORD LIKE campaigns.*,
    larec_genders DYNAMIC ARRAY OF RECORD LIKE genders.*,
    larec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    larec_posttypes DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    larec_hashtags DYNAMIC ARRAY OF RECORD LIKE tags.*,
    larec_usertags DYNAMIC ARRAY OF RECORD LIKE tags.*,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_campaignstatus RECORD LIKE campaignstatus.*,
    lrec_postduration RECORD LIKE postdurations.*,
    larec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lrec_data RECORD ATTRIBUTE(XMLName="Brand")
      brnd_name LIKE brands.brnd_name ATTRIBUTE(XMLNillable, XMLName="Name"),
      brnd_website LIKE brands.brnd_website ATTRIBUTE(XMLNillable, XMLName="Website"),
      cntr_name LIKE countries.cntr_name ATTRIBUTE(XMLName="Country"),
      stt_name LIKE states.stt_name ATTRIBUTE(XMLNillable, XMLName="State"),
      cts_name LIKE cities.cts_name ATTRIBUTE(XMLNillable, XMLName="City"),
      brnd_address_number LIKE cities.cts_name ATTRIBUTE(XMLNillable, XMLName="Number"),
      brnd_address_street LIKE cities.cts_name ATTRIBUTE(XMLNillable, XMLName="Street"),
      brnd_address_zipcode LIKE cities.cts_name ATTRIBUTE(XMLNillable, XMLName="Zipcode"),
      brnd_address_more LIKE cities.cts_name ATTRIBUTE(XMLNillable, XMLName="More"),
      main_category LIKE categories.ctgr_name ATTRIBUTE(XMLNillable, XMLName="MainCategory"),
      other_categories DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="OtherCategories") OF VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="Category"),
      crr_name LIKE currencies.crr_name ATTRIBUTE(XMLNillable, XMLName="Currency"),
      gnd_name LIKE genders.gnd_name ATTRIBUTE(XMLNillable, XMLName="Gender"),
      brnd_firstname LIKE brands.brnd_firstname ATTRIBUTE(XMLNillable, XMLName="FirstName"),
      brnd_lastname LIKE brands.brnd_lastname ATTRIBUTE(XMLNillable, XMLName="LastName"),
      brnd_email LIKE brands.brnd_email ATTRIBUTE(XMLNillable, XMLName="Email"),
      brnd_emailvalidationdate LIKE brands.brnd_emailvalidationdate ATTRIBUTE(XMLNillable, XMLName="EmailValidation"),
      brnd_mobile_phonenumber VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="MobilePhoneNumber"),
      accst_name LIKE accountstatus.accst_name ATTRIBUTE(XMLName="Status"),
      socialnetworks DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="SocialNetworks") OF RECORD ATTRIBUTE(XMLName="SocialNetwork")
        scl_name LIKE socialnetworks.scl_name ATTRIBUTE(XMLNillable, XMLName="Name"),
        brndscl_accountname VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="Account")
      END RECORD,
      campaigns DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="Campaigns") OF RECORD ATTRIBUTE(XMLName="Campaign")
        cmp_title LIKE campaigns.cmp_title ATTRIBUTE(XMLNillable, XMLName="Title"),
        cmp_overview LIKE campaigns.cmp_overview ATTRIBUTE(XMLNillable, XMLName="Overview"),
        cmp_url LIKE campaigns.cmp_url ATTRIBUTE(XMLNillable, XMLName="Website"),
        cmp_totalbudget LIKE campaigns.cmp_totalbudget ATTRIBUTE(XMLNillable, XMLName="CampaignBudget"),
        crr_name LIKE currencies.crr_name ATTRIBUTE(XMLNillable, XMLName="Currency"),
        cmp_wantedusers LIKE campaigns.cmp_wantedusers ATTRIBUTE(XMLNillable, XMLName="PreferedNumberOfInfluencers"),
        cmpst_name LIKE campaignstatus.cmpst_name ATTRIBUTE(XMLNillable, XMLName="Status"),
        genders DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="Genders") OF VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="Gender"),
        countries VARCHAR(255) ATTRIBUTE (XMLNillable, XMLName="Countries"),
        states VARCHAR(255) ATTRIBUTE (XMLNillable, XMLName="States"),
        cities VARCHAR(255) ATTRIBUTE (XMLNillable, XMLName="Cities"),
        categories DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="Categories") OF VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="Category"),
        cmp_isproductneeded LIKE campaigns.cmp_isproductneeded ATTRIBUTE(XMLNillable, XMLName="IsProductNeeded"),
        cmp_prd_description LIKE campaigns.cmp_prd_description ATTRIBUTE(XMLNillable, XMLName="ProductDescription"),
        cmp_prd_value LIKE campaigns.cmp_prd_value ATTRIBUTE(XMLNillable, XMLName="ProductValue"),
        posttypes DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="PostTypes") OF RECORD ATTRIBUTE(XMLName="PostType")
          pstt_name LIKE posttypes.pstt_name ATTRIBUTE(XMLNillable, XMLName="Name"),
          cmppst_quantity LIKE campaignposttypes.cmppst_quantity ATTRIBUTE(XMLNillable, XMLName="Quantity")
        END RECORD,
        cmp_issharedonfacebook LIKE campaigns.cmp_issharedonfacebook ATTRIBUTE(XMLNillable, XMLName="IsSharedOnFacebook"),
        cmp_sharedfacebooklink LIKE campaigns.cmp_sharedfacebooklink ATTRIBUTE(XMLNillable, XMLName="FacebookLinkPage"),
        cmp_post_guidelines LIKE campaigns.cmp_post_guidelines ATTRIBUTE(XMLNillable, XMLName="ContentGuidelines"),
        hashtags DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="Hashtags") OF VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="Hashtag"),
        usertags DYNAMIC ARRAY ATTRIBUTE(XMLNillable, XMLName="Usertags") OF VARCHAR(255) ATTRIBUTE(XMLNillable, XMLName="Usertag"),
        cmp_captionrequirements LIKE campaigns.cmp_captionrequirements ATTRIBUTE(XMLNillable, XMLName="CaptionRequirements"),
        cmp_post_startdate LIKE campaigns.cmp_post_startdate ATTRIBUTE(XMLNillable, XMLName="PostStartDate"),
        cmp_post_enddate LIKE campaigns.cmp_post_enddate ATTRIBUTE(XMLNillable, XMLName="PostEndDate"),
        cmp_post_time_starttime LIKE campaigns.cmp_post_time_starttime ATTRIBUTE(XMLNillable, XMLName="PostStartTime"),
        cmp_post_time_endtime LIKE campaigns.cmp_post_time_endtime ATTRIBUTE(XMLNillable, XMLName="PostEndTime"),
        pstdr_name LIKE postdurations.pstdr_name ATTRIBUTE(XMLNillable, XMLName="PostDuration"),
        cmp_publisheddate LIKE campaigns.cmp_publisheddate ATTRIBUTE(XMLNillable, XMLName="PublicationDate"),
        cmp_selectionstartdate LIKE campaigns.cmp_selectionstartdate ATTRIBUTE(XMLNillable, XMLName="SubscriptionStartDate"),
        cmp_selectionenddate LIKE campaigns.cmp_selectionenddate ATTRIBUTE(XMLNillable, XMLName="SubscriptionEndDate"),
        cmp_selectioncomment LIKE campaigns.cmp_selectioncomment ATTRIBUTE(XMLNillable, XMLName="SubscriptionInternalComment")
      END RECORD
    END RECORD,
    lstr_server_filename STRING,
    lstr_client_filename STRING,
    doc xml.DomDocument,
    node xml.DomNode

  INITIALIZE lrec_data.* TO NULL

  --get brand main data
  CALL core_db.brands_select_row(mrec_brandgrid.brand.brnd_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_brand.*
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF

  CALL core_db.country_select_row(lrec_brand.brnd_country_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_country.*
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF

  CALL core_db.currency_select_row(lrec_brand.brnd_currency_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_currency.*
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF

  CALL core_db.accountstatus_select_row(lrec_brand.brnd_accountstatus_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_accountstatus.*
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF

  CALL core_db.state_select_row(lrec_brand.brnd_state_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_state.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN RETURN lint_ret, lstr_msg END IF

  CALL core_db.city_select_row(lrec_brand.brnd_city_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_city.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN RETURN lint_ret, lstr_msg END IF

  CALL core_db.gender_select_row(lrec_brand.brnd_gender_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_gender.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN RETURN lint_ret, lstr_msg END IF

  LET lrec_data.brnd_name = lrec_brand.brnd_name
  LET lrec_data.brnd_website = lrec_brand.brnd_website
  LET lrec_data.cntr_name = lrec_country.cntr_name
  LET lrec_data.stt_name = lrec_state.stt_name
  LET lrec_data.cts_name = lrec_city.cts_name
  LET lrec_data.brnd_address_number = lrec_brand.brnd_address_number
  LET lrec_data.brnd_address_street = lrec_brand.brnd_address_street
  LET lrec_data.brnd_address_zipcode = lrec_brand.brnd_address_zipcode
  LET lrec_data.brnd_address_more = lrec_brand.brnd_address_more
  LET lrec_data.crr_name = lrec_currency.crr_name
  LET lrec_data.gnd_name = lrec_gender.gnd_name
  LET lrec_data.brnd_firstname = lrec_brand.brnd_firstname
  LET lrec_data.brnd_lastname = lrec_brand.brnd_lastname
  LET lrec_data.brnd_email = lrec_brand.brnd_email
  LET lrec_data.brnd_emailvalidationdate = lrec_brand.brnd_emailvalidationdate
  LET lrec_data.brnd_mobile_phonenumber = SFMT("%1%2",string.get_phonenumberprefix(lrec_country.cntr_id), lrec_brand.brnd_mobile_phonenumber)
  LET lrec_data.accst_name = lrec_accountstatus.accst_name

  --get brand primary category
  CALL core_db.get_brand_primary_category(mrec_brandgrid.brand.brnd_id)
    RETURNING lint_ret, lstr_msg, lrec_category.*
  IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN RETURN lint_ret, lstr_msg END IF
  IF lint_ret == 0 THEN
    LET lrec_data.main_category = lrec_category.ctgr_name
  END IF

  --get brand other categories
  CALL core_db.get_brand_primary_other_categories(mrec_brandgrid.brand.brnd_id, larec_categories)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO larec_categories.getLength()
    LET lrec_data.other_categories[i] = larec_categories[i].ctgr_name
  END FOR

  --get social networks
  LET lstr_sql = "SELECT socialnetworks.scl_name, brandsocialnetworks.brndscl_accountname"
    ," FROM brandsocialnetworks, socialnetworks"
    ,SFMT(" WHERE brandsocialnetworks.brndscl_brand_id = %1", mrec_brandgrid.brand.brnd_id)
    ," AND brandsocialnetworks.brndscl_socialnetwork_id = socialnetworks.scl_id"
    ," ORDER BY socialnetworks.scl_uiorder"
  LET i = 0
  TRY
    DECLARE c_get_socialnetwork_data_for_export CURSOR FROM lstr_sql
    FOREACH c_get_socialnetwork_data_for_export
      INTO lrec_socialnetwork.scl_name, lrec_brandsocialnetwork.brndscl_accountname
      LET i = i + 1
      LET lrec_data.socialnetworks[i].scl_name = lrec_socialnetwork.scl_name
      LET lrec_data.socialnetworks[i].brndscl_accountname = lrec_brandsocialnetwork.brndscl_accountname
    END FOREACH
    FREE c_get_socialnetwork_data_for_export
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY

  --get brand's campaigns
  CALL core_db.campaigns_fetch_all_rows(SFMT("WHERE campaigns.cmp_brand_id = %1", mrec_brandgrid.brand.brnd_id), NULL, larec_campaigns)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
  FOR i = 1 TO larec_campaigns.getLength()
    CALL core_db.campaignstatus_select_row(larec_campaigns[i].cmp_campaignstatus_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_campaignstatus.*
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    CALL core_db.currency_select_row(larec_campaigns[i].cmp_currency_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_currency.*
    IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN RETURN lint_ret, lstr_msg END IF
    CALL core_db.postduration_select_row(larec_campaigns[i].cmp_postduration_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_postduration.*
    IF lint_ret <> 0 AND lint_ret <> NOTFOUND THEN RETURN lint_ret, lstr_msg END IF

    LET lrec_data.campaigns[i].cmp_title = lrec_campaign.cmp_title
    LET lrec_data.campaigns[i].cmp_overview = lrec_campaign.cmp_overview
    LET lrec_data.campaigns[i].cmp_url = lrec_campaign.cmp_url
    LET lrec_data.campaigns[i].cmp_totalbudget = lrec_campaign.cmp_totalbudget
    LET lrec_data.campaigns[i].crr_name = lrec_currency.crr_name
    LET lrec_data.campaigns[i].cmp_wantedusers = lrec_campaign.cmp_wantedusers
    LET lrec_data.campaigns[i].cmp_isproductneeded = lrec_campaign.cmp_isproductneeded
    LET lrec_data.campaigns[i].cmpst_name = lrec_campaignstatus.cmpst_name
    LET lrec_data.campaigns[i].cmp_prd_description = lrec_campaign.cmp_prd_description
    LET lrec_data.campaigns[i].cmp_prd_value = lrec_campaign.cmp_prd_value
    LET lrec_data.campaigns[i].cmp_issharedonfacebook = lrec_campaign.cmp_issharedonfacebook
    LET lrec_data.campaigns[i].cmp_sharedfacebooklink = lrec_campaign.cmp_sharedfacebooklink
    LET lrec_data.campaigns[i].cmp_post_guidelines = lrec_campaign.cmp_post_guidelines
    LET lrec_data.campaigns[i].cmp_captionrequirements = lrec_campaign.cmp_captionrequirements
    LET lrec_data.campaigns[i].cmp_post_startdate = lrec_campaign.cmp_post_startdate
    LET lrec_data.campaigns[i].cmp_post_enddate = lrec_campaign.cmp_post_enddate
    LET lrec_data.campaigns[i].cmp_post_time_starttime = IIF(lrec_campaign.cmp_post_time_starttime==C_POSTTIME_ANYTIME, %"Any Time", lrec_campaign.cmp_post_time_starttime||"h")
    LET lrec_data.campaigns[i].cmp_post_time_endtime = IIF(lrec_campaign.cmp_post_time_endtime==C_POSTTIME_ANYTIME, %"Any Time", lrec_campaign.cmp_post_time_endtime||"h")
    LET lrec_data.campaigns[i].pstdr_name = lrec_postduration.pstdr_name
    LET lrec_data.campaigns[i].cmp_publisheddate = lrec_campaign.cmp_publisheddate
    LET lrec_data.campaigns[i].cmp_selectionstartdate = lrec_campaign.cmp_selectionstartdate
    LET lrec_data.campaigns[i].cmp_selectionenddate = lrec_campaign.cmp_selectionenddate
    LET lrec_data.campaigns[i].cmp_selectioncomment = lrec_campaign.cmp_selectioncomment

    CALL core_db.get_campaign_genders(larec_campaigns[i].cmp_id, larec_genders)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    FOR j = 1 TO larec_genders.getLength()
      LET lrec_data.campaigns[i].genders[j] = larec_genders[j].gnd_name
    END FOR

    CALL core_db.get_campaign_categories(larec_campaigns[i].cmp_id, larec_categories)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    FOR j = 1 TO larec_categories.getLength()
      LET lrec_data.campaigns[i].categories[j] = larec_categories[j].ctgr_name
    END FOR

    CALL core_db.get_campaign_campaignposttypes_and_posttypes(larec_campaigns[i].cmp_id, larec_campaignposttypes, larec_posttypes)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    FOR j = 1 TO larec_campaignposttypes.getLength()
      LET lrec_data.campaigns[i].posttypes[j].pstt_name = larec_posttypes[j].pstt_name
      LET lrec_data.campaigns[i].posttypes[j].cmppst_quantity = larec_campaignposttypes[j].cmppst_quantity
    END FOR

    CALL core_db.get_campaign_tags(larec_campaigns[i].cmp_id, C_TAGTYPE_HASHTAG, larec_hashtags)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    FOR j = 1 TO larec_hashtags.getLength()
      LET lrec_data.campaigns[i].hashtags[j] = larec_hashtags[j].tag_name
    END FOR

    CALL core_db.get_campaign_tags(larec_campaigns[i].cmp_id, C_TAGTYPE_USERTAG, larec_usertags)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    FOR j = 1 TO larec_usertags.getLength()
      LET lrec_data.campaigns[i].usertags[j] = larec_usertags[j].tag_name
    END FOR

    --get campaign locations
    CALL campaignlocations.fetch_all_rows(larec_campaigns[i].cmp_id, larec_campaignlocations)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    CALL campaignlocations.serialize(larec_campaignlocations)
      RETURNING lrec_data.campaigns[i].countries, lrec_data.campaigns[i].states, lrec_data.campaigns[i].cities
  END FOR

  --create and upload XML file
  LET lstr_server_filename = os.Path.join(base.Application.getResourceEntry("salfatixmedia.export.tmpdir"), string.get_report_name("brand",".xml"))
  LET doc = xml.DomDocument.Create()
  CALL doc.setFeature("format-pretty-print",TRUE)
  LET node = doc.createElement("Root")
  CALL xml.Serializer.VariableToDom(lrec_data, node)
  CALL doc.appendDocumentNode(node)
  CALL doc.save(lstr_server_filename)
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
