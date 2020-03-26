IMPORT FGL core_cst
IMPORT FGL core_db

SCHEMA salfatixmedia

#+ Fills a combobox according to an sql string that is construct by using the parameters
#+
#+ @param pstr_field_name name of the combobox
#+ @param pstr_table_name sql table names
#+ @param pstr_table_field_name sql fields name that will be selected for filling up the combobox
#+ @param pstr_where_clause sql where clause
#+ @param pstr_order_by sql order by clause
#+
FUNCTION fill_combo(pstr_field_name, pstr_table_name, pstr_table_field_name, pstr_where_clause, pstr_order_by)
  DEFINE
    pstr_field_name STRING,
    pstr_table_name STRING,
    pstr_table_field_name STRING,
    pstr_where_clause STRING,
    pstr_order_by STRING,
    lstr_sql STRING,
    l_combo ui.ComboBox,
    l_combo_id VARCHAR(255),
    l_combo_value VARCHAR(255)

  LET l_combo = ui.ComboBox.forName(pstr_field_name)
  CALL l_combo.clear()
  -- Fetch the values from database which are used to fill the combo box
  LET lstr_sql = SFMT("SELECT %1 FROM %2 %3 %4",pstr_table_field_name,pstr_table_name,pstr_where_clause,pstr_order_by)
  TRY
    DECLARE c_ui_fill_combo CURSOR FROM lstr_sql
    FOREACH c_ui_fill_combo
      INTO l_combo_id, l_combo_value
      CALL l_combo.addItem(l_combo_id CLIPPED, LSTR(l_combo_value CLIPPED))
    END FOREACH
    FREE c_ui_fill_combo
  CATCH
    CALL l_combo.clear()
  END TRY
END FUNCTION

#+ Initializer of the country combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION country_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE countries.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.country_fetch_all_rows(NULL, "ORDER BY countries.cntr_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].cntr_id, LSTR(larec_data[i].cntr_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the state combobox
#+
#+ @param p_combo combobox identifer
#+ @param pint_country_id country id
#+
FUNCTION state_initializer(p_combo, pint_country_id)
  DEFINE
    p_combo ui.ComboBox,
    pint_country_id INTEGER,
    larec_data DYNAMIC ARRAY OF RECORD LIKE states.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.state_fetch_all_rows(SFMT("WHERE states.stt_country_id = %1",pint_country_id), "ORDER BY states.stt_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].stt_id, LSTR(larec_data[i].stt_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the city combobox
#+
#+ @param p_combo combobox identifer
#+ @param pint_state_id state id
#+
FUNCTION city_initializer(p_combo, pint_state_id)
  DEFINE
    p_combo ui.ComboBox,
    pint_state_id INTEGER,
    larec_data DYNAMIC ARRAY OF RECORD LIKE cities.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.city_fetch_all_rows(SFMT("WHERE cities.cts_state_id = %1",pint_state_id), "ORDER BY cities.cts_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].cts_id, LSTR(larec_data[i].cts_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the currency combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION currency_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE currencies.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.currency_fetch_all_rows(NULL, "ORDER BY currencies.crr_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].crr_id, LSTR(larec_data[i].crr_symbol))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the day combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION day_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox

  CALL p_combo.clear()
  CALL p_combo.addItem(C_POSTDAY_ANYDAY, %"Any day")
  CALL p_combo.addItem(1, %"Monday")
  CALL p_combo.addItem(2, %"Tuesday")
  CALL p_combo.addItem(3, %"Wednesday")
  CALL p_combo.addItem(4, %"Thursday")
  CALL p_combo.addItem(5, %"Friday")
  CALL p_combo.addItem(6, %"Saturday")
  CALL p_combo.addItem(7, %"Sunday")
END FUNCTION

#+ Initializer of the time combobox
#+
#+ @param p_combo combobox identifer
#+ @param pint_begin start time
#+ @param pint_end end time
#+
FUNCTION time_initializer(p_combo, pint_begin, pint_end)
  DEFINE
    p_combo ui.ComboBox,
    pint_begin INTEGER,
    pint_end INTEGER,
    i INTEGER

  CALL p_combo.clear()
  IF pint_begin == C_POSTTIME_ANYTIME THEN
    CALL p_combo.addItem(C_POSTTIME_ANYTIME, %"Any time")
    LET pint_begin = 0
  END IF
  FOR i = pint_begin TO pint_end
    CALL p_combo.addItem(i, SFMT("%1h", i))
  END FOR
END FUNCTION

#+ Initializer of the duration combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION duration_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE postdurations.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.postduration_fetch_all_rows(NULL, "ORDER BY postdurations.pstdr_id", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].pstdr_id, LSTR(larec_data[i].pstdr_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the campaign status combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION campaignstatus_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE campaignstatus.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.campaignstatus_fetch_all_rows(NULL, "ORDER BY campaignstatus.cmpst_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].cmpst_id, LSTR(larec_data[i].cmpst_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the brand combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION brand_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE brands.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.brands_fetch_all_rows(NULL, "ORDER BY brands.brnd_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].brnd_id, LSTR(larec_data[i].brnd_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the accountstatus combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION accountstatus_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE accountstatus.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.accountstatus_fetch_all_rows(NULL, "ORDER BY accountstatus.accst_name", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].accst_id, LSTR(larec_data[i].accst_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the post type combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION posttype_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE posttypes.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.posttype_fetch_all_rows(NULL, "ORDER BY posttypes.pstt_uiorder", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].pstt_id, LSTR(larec_data[i].pstt_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the post type combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION socialnetwork_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE socialnetworks.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.socialnetwork_fetch_all_rows(NULL, "ORDER BY socialnetworks.scl_uiorder", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].scl_id, LSTR(larec_data[i].scl_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the gender combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION gender_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE genders.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.gender_fetch_all_rows(NULL, "ORDER BY genders.gnd_uiorder", larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].gnd_id, LSTR(larec_data[i].gnd_name))
    END FOR
  END IF
END FUNCTION

#+ Initializer of the campaign post status combobox
#+
#+ @param p_combo combobox identifer
#+
FUNCTION campaignpoststatus_initializer(p_combo)
  DEFINE
    p_combo ui.ComboBox,
    larec_data DYNAMIC ARRAY OF RECORD LIKE campaignpoststatus.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER

  CALL p_combo.clear()
  CALL core_db.campaignpoststatus_fetch_all_rows(NULL, NULL, larec_data)
    RETURNING lint_ret, lstr_msg
  IF lint_ret == 0 THEN
    FOR i = 1 TO larec_data.getLength()
      CALL p_combo.addItem(larec_data[i].cmppstst_id, LSTR(larec_data[i].cmppstst_name))
    END FOR
  END IF
END FUNCTION