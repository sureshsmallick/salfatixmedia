IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL string

SCHEMA salfatixmedia

#+ Display a save button image
#+
#+ @param pint_country_id country id
#+
FUNCTION display_savebutton(p_dialogtouched)
  DEFINE
    p_dialogtouched BOOLEAN,
    ffimage_value STRING

  LET ffimage_value = IIF(p_dialogtouched, "fa-check-circle-green", "fa-check-circle-gray")
  DISPLAY BY NAME ffimage_value
END FUNCTION

#+ Display a country phone prefix
#+
#+ @param pint_country_id country id
#+
FUNCTION display_phonenumberprefix(pint_country_id)
  DEFINE
    pint_country_id LIKE countries.cntr_id,
    lstr_phonenumberprefix STRING

  LET lstr_phonenumberprefix = string.get_phonenumberprefix(pint_country_id)
  DISPLAY lstr_phonenumberprefix TO phonenumberprefix_label
END FUNCTION

#+ Display a currency symbol
#+
#+ @param pint_currency_id currency id
#+ @param pstr_formfields list of formfields separated by comma
#+
FUNCTION display_currencysymbol(pint_currency_id LIKE currencies.crr_id, pstr_formfields STRING)
  DEFINE
    s STRING,
    lstr_tok base.StringTokenizer,
    lstr_tmp STRING
  LET s = core_db.currency_get_symbol(pint_currency_id)
  LET lstr_tok = base.StringTokenizer.create(pstr_formfields, ",")
  WHILE lstr_tok.hasMoreTokens()
    LET lstr_tmp = lstr_tok.nextToken()
    LET lstr_tmp = lstr_tmp.trim()
    CALL core_ui.ui_set_node_attribute("FormField","name",SFMT("formonly.%1",lstr_tmp),"value",s)
  END WHILE

END FUNCTION

#+ Open a social network account on the front-end side
#+
#+ @param pint_socialnetwork_id social network id
#+ @param pstr_target string to add to the social network url
#+
FUNCTION open_socialnetwork_account(pint_socialnetwork_id LIKE socialnetworks.scl_id, pstr_account STRING)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_socialnetwork RECORD LIKE socialnetworks.*,
    url STRING

  LET pstr_account = pstr_account.trim()
  IF pstr_account.getLength()==0 THEN RETURN END IF
  CALL core_db.socialnetwork_select_row(pint_socialnetwork_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_socialnetwork.*
  IF lint_ret == 0 THEN
    IF lrec_socialnetwork.scl_id <> C_SOCIALNETWORK_SNAPCHAT THEN
      LET url = SFMT("%1%2", lrec_socialnetwork.scl_url, pstr_account)
      CALL core_ui.ui_launch_url(url)
    END IF
  END IF
END FUNCTION
