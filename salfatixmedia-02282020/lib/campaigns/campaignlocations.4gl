IMPORT FGL fgldbutl
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL string

SCHEMA salfatixmedia

CONSTANT
  C_ICON_CHECKED STRING = "fa-check-square",
  C_ICON_UNCHECKED STRING = "fa-square-o"

PUBLIC TYPE
  t_campaigncity RECORD
    city RECORD LIKE campaigncities.*
  END RECORD
PUBLIC TYPE
  t_campaignstate RECORD
    state RECORD LIKE campaignstates.*,
    cities DYNAMIC ARRAY OF t_campaigncity
  END RECORD
PUBLIC TYPE
  t_campaigncountry RECORD
    country RECORD LIKE campaigncountries.*,
    states DYNAMIC ARRAY OF t_campaignstate
  END RECORD

TYPE
  t_displayed_countries RECORD
    country RECORD LIKE countries.*,
    country_id LIKE countries.cntr_id,
    myimage STRING
  END RECORD,
  t_displayed_states RECORD
    state RECORD LIKE states.*,
    country_id LIKE countries.cntr_id,
    country_name LIKE countries.cntr_name,
    state_id LIKE states.stt_id,
    myimage STRING
  END RECORD,
  t_displayed_cities RECORD
    city RECORD LIKE cities.*,
    country_id LIKE countries.cntr_id,
    country_name LIKE countries.cntr_name,
    state_id LIKE states.stt_id,
    state_name LIKE states.stt_name,
    city_id LIKE cities.cts_id,
    myimage STRING
  END RECORD
  
#+ Select all rows in the "campaigncountries" table according to a SQL where part and order by part
#+
#+ @param pstr_where SQL WHERE part
#+ @param pstr_where SQL ORDER BY part
#+ @param p_ret output list of t_campaigncountry
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION fetch_all_rows(pint_campaign_id, p_ret)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    p_ret DYNAMIC ARRAY OF t_campaigncountry,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_data0 RECORD LIKE campaigncountries.*,
    lrec_data1 RECORD LIKE campaignstates.*,
    lrec_data2 RECORD LIKE campaigncities.*,
    lstr_sql0 STRING,
    lstr_sql1 STRING,
    lstr_sql2 STRING,
    i,j,k INTEGER

  CALL p_ret.clear()
  LET lstr_sql0 = "SELECT campaigncountries.*"
  ," FROM campaigncountries, countries"
  ," WHERE campaigncountries.cmpcntr_country_id = countries.cntr_id"
  ,SFMT(" AND campaigncountries.cmpcntr_campaign_id = %1", pint_campaign_id)
  ," ORDER BY countries.cntr_name ASC"
  LET lstr_sql1 = "SELECT campaignstates.*"
  ," FROM campaignstates, states"
  ," WHERE campaignstates.cmpstt_state_id = states.stt_id"
  ," AND campaignstates.cmpstt_campaigncountry_id = ?"
  ," ORDER BY states.stt_name ASC"
  LET lstr_sql2 = "SELECT campaigncities.*"
  ," FROM campaigncities, cities"
  ," WHERE campaigncities.cmpcts_city_id = cities.cts_id"
  ," AND campaigncities.cmpcts_campaignstate_id = ?"
  ," ORDER BY cities.cts_name ASC"

  TRY
    DECLARE c_campaignlocation_countries CURSOR FROM lstr_sql0
    DECLARE c_campaignlocation_states CURSOR FROM lstr_sql1
    DECLARE c_campaignlocation_cities CURSOR FROM lstr_sql2
    LET i = 0
    FOREACH c_campaignlocation_countries
      INTO lrec_data0.*
      LET i = i + 1
      LET p_ret[i].country.* = lrec_data0.*
      LET j = 0
      FOREACH c_campaignlocation_states
        USING p_ret[i].country.cmpcntr_id
        INTO lrec_data1.*
        LET j = j + 1
        LET p_ret[i].states[j].state.* = lrec_data1.*
        LET k = 0
        FOREACH c_campaignlocation_cities
          USING p_ret[i].states[j].state.cmpstt_id
          INTO lrec_data2.*
          LET k = k + 1
          LET p_ret[i].states[j].cities[k].city.* = lrec_data2.*
        END FOREACH
      END FOREACH
    END FOREACH
    FREE c_campaignlocation_countries
    FREE c_campaignlocation_states
    FREE c_campaignlocation_cities
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL p_ret.clear()
  END TRY
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Delete all rows related to campaign locations for a given campaign
#+
#+ @param pint_campaign_id campaign id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION delete_all_rows(pint_campaign_id)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    larec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    i,j,k INTEGER

  CALL fetch_all_rows(pint_campaign_id, larec_campaignlocations)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO larec_campaignlocations.getLength()
    FOR j = 1 TO larec_campaignlocations[i].states.getLength()
      FOR k = 1 TO larec_campaignlocations[i].states[j].cities.getLength()
        CALL core_db.campaigncities_delete_row(larec_campaignlocations[i].states[j].cities[k].city.cmpcts_id)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN EXIT FOR END IF
      END FOR
      IF lint_ret <> 0 THEN EXIT FOR END IF
      CALL core_db.campaignstates_delete_row(larec_campaignlocations[i].states[j].state.cmpstt_id)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN EXIT FOR END IF
    END FOR
    IF lint_ret <> 0 THEN EXIT FOR END IF
    CALL core_db.campaigncountries_delete_row(larec_campaignlocations[i].country.cmpcntr_id)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN EXIT FOR END IF
  END FOR
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Insert all rows related to campaign locations
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_campaignlocations list of campaign locations
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION insert_all_rows(pint_campaign_id, parec_campaignlocations)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    i,j,k INTEGER

  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO parec_campaignlocations.getLength()
    LET parec_campaignlocations[i].country.cmpcntr_campaign_id = pint_campaign_id
    CALL core_db.campaigncountries_insert_row(parec_campaignlocations[i].country.*)
      RETURNING lint_ret, lstr_msg, parec_campaignlocations[i].country.cmpcntr_id
    IF lint_ret <> 0 THEN EXIT FOR END IF
    FOR j = 1 TO parec_campaignlocations[i].states.getLength()
      LET parec_campaignlocations[i].states[j].state.cmpstt_campaigncountry_id = parec_campaignlocations[i].country.cmpcntr_id
      CALL core_db.campaignstates_insert_row(parec_campaignlocations[i].states[j].state.*)
        RETURNING lint_ret, lstr_msg, parec_campaignlocations[i].states[j].state.cmpstt_id
      IF lint_ret <> 0 THEN EXIT FOR END IF
      FOR k = 1 TO parec_campaignlocations[i].states[j].cities.getLength()
        LET parec_campaignlocations[i].states[j].cities[k].city.cmpcts_campaignstate_id = parec_campaignlocations[i].states[j].state.cmpstt_id
        CALL core_db.campaigncities_insert_row(parec_campaignlocations[i].states[j].cities[k].city.*)
          RETURNING lint_ret, lstr_msg, parec_campaignlocations[i].states[j].cities[k].city.cmpcts_id
        IF lint_ret <> 0 THEN EXIT FOR END IF
      END FOR
      IF lint_ret <> 0 THEN EXIT FOR END IF
    END FOR
    IF lint_ret <> 0 THEN EXIT FOR END IF
  END FOR
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret==0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
  END IF

  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Display campaign locations as a country list
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_campaignlocations list of already selected locations
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION display_countries(pint_campaign_id, parec_campaignlocations)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    larec_countries DYNAMIC ARRAY OF RECORD LIKE countries.*,
    larec_displayedlist DYNAMIC ARRAY OF t_displayed_countries,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i,j,idx_country INTEGER,
    lbool_is_mobile BOOLEAN,
    lbool_found BOOLEAN

  LET lint_action = C_APPACTION_CLOSE

  --list all countries
  CALL core_db.country_fetch_all_rows(NULL, "ORDER BY countries.cntr_name ASC", larec_countries)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  --add 'All' fictive country
  CALL larec_countries.insertElement(1)
  INITIALIZE larec_countries[1].* TO NULL
  LET larec_countries[1].cntr_name = "All"

  --initialize the array that will be displayed
  FOR i = 1 TO larec_countries.getLength()
    LET larec_displayedlist[i].country.* = larec_countries[i].*
    --trick to use 4gl array built-in search
    LET larec_displayedlist[i].country_id = NVL(larec_countries[i].cntr_id, -1)
    LET larec_displayedlist[i].myimage = C_ICON_UNCHECKED
  END FOR
  CALL larec_countries.clear()

  --check the countries that are already present in the list of locations
  IF parec_campaignlocations.getLength()==0 THEN
    LET larec_displayedlist[1].myimage = C_ICON_CHECKED
  END IF
  FOR i = 1 TO parec_campaignlocations.getLength()
    LET j = larec_displayedlist.search("country_id", parec_campaignlocations[i].country.cmpcntr_country_id)
    LET larec_displayedlist[j].myimage = C_ICON_CHECKED
  END FOR

  LET lbool_is_mobile = core_ui.ui_is_mobile()
  OPEN WINDOW w_zoom_country WITH FORM "campaignlocations_country"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY larec_displayedlist TO scrlist_country.*
      ON ACTION selectrow
        --we check "All" country -> other countries are set to uncheck
        --we check a country -> "All" country is unchecked
        --we cannot uncheck "All"
        --we can uncheck a country. If no countries remains checked then check 'All' country
        LET i = arr_curr()
        IF larec_displayedlist[i].myimage==C_ICON_UNCHECKED THEN
          --line is checked
          LET larec_displayedlist[i].myimage = C_ICON_CHECKED
          IF larec_displayedlist[i].country_id < 0 THEN --"All" country has been checked
            FOR j = i+1 TO larec_displayedlist.getLength()
              LET larec_displayedlist[j].myimage = C_ICON_UNCHECKED
            END FOR
          ELSE --an other country has been checked
            --uncheck "All" country
            LET larec_displayedlist[1].myimage = C_ICON_UNCHECKED
          END IF
        ELSE
          --line is unchecked
          LET larec_displayedlist[i].myimage = C_ICON_UNCHECKED
          IF larec_displayedlist[i].country_id < 0 THEN
            --forbid to uncheck manually "All"
            LET larec_displayedlist[i].myimage = C_ICON_CHECKED
          ELSE
            --we need to check "All" country is there is no more other coutries checked
            LET lbool_found = FALSE
            FOR j = 2 TO larec_displayedlist.getLength()
              IF larec_displayedlist[j].myimage = C_ICON_CHECKED THEN
                LET lbool_found = TRUE
                EXIT FOR
              END IF
            END FOR
            IF NOT lbool_found THEN
              LET larec_displayedlist[1].myimage = C_ICON_CHECKED
            END IF
          END IF
        END IF
        CALL _display_selected_countries(larec_displayedlist)
    END DISPLAY
    ON ACTION accept
      FOR i = 1 TO larec_displayedlist.getLength()
        IF larec_displayedlist[i].country_id < 0 THEN --ignore selection of 'all' country
          CONTINUE FOR
        END IF
        LET idx_country = _search_country(parec_campaignlocations, larec_displayedlist[i].country_id)
        IF larec_displayedlist[i].myimage == C_ICON_UNCHECKED THEN
          IF idx_country > 0 THEN
            CALL parec_campaignlocations.deleteElement(idx_country)
          END IF
        ELSE --element checked
          IF idx_country == 0 THEN
            LET j = parec_campaignlocations.getLength() + 1
            INITIALIZE parec_campaignlocations[j].* TO NULL
            LET parec_campaignlocations[j].country.cmpcntr_campaign_id = pint_campaign_id
            LET parec_campaignlocations[j].country.cmpcntr_country_id = larec_displayedlist[i].country_id
          END IF
        END IF
      END FOR
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionActive("close",NOT lbool_is_mobile)
      CALL DIALOG.setActionHidden("close",lbool_is_mobile)
      CALL _display_selected_countries(larec_displayedlist)
  END DIALOG
  CLOSE WINDOW w_zoom_country
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Display campaign locations as a states list
#+
#+ @param parec_campaignlocations list of already selected locations
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION display_states(parec_campaignlocations)
  DEFINE
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lrec_country RECORD LIKE countries.*,
    larec_states DYNAMIC ARRAY OF RECORD LIKE states.*,
    larec_displayedlist DYNAMIC ARRAY OF t_displayed_states,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i,j,k,idx_country, idx_state INTEGER,
    lbool_is_mobile BOOLEAN,
    lbool_found BOOLEAN

  LET lint_action = C_APPACTION_CLOSE

  IF parec_campaignlocations.getLength()==0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  FOR i = 1 TO parec_campaignlocations.getLength()
    CALL core_db.country_select_row(parec_campaignlocations[i].country.cmpcntr_country_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_country.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg, lint_action
    END IF
    --list all states
    CALL core_db.state_fetch_all_rows(SFMT("WHERE states.stt_country_id = %1", lrec_country.cntr_id), "ORDER BY states.stt_name ASC", larec_states)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg, lint_action
    END IF
    --add 'All' fictive state
    CALL larec_states.insertElement(1)
    INITIALIZE larec_states[1].* TO NULL
    LET larec_states[1].stt_country_id = lrec_country.cntr_id
    LET larec_states[1].stt_name = "All"
    --initialize the array that will be displayed
    LET k = larec_displayedlist.getLength()
    FOR j = 1 TO larec_states.getLength()
      LET k = k + 1
      LET larec_displayedlist[k].state.* = larec_states[j].*
      LET larec_displayedlist[k].country_id = lrec_country.cntr_id
      LET larec_displayedlist[k].country_name = lrec_country.cntr_name
      LET larec_displayedlist[k].state_id = NVL(larec_states[j].stt_id, -lrec_country.cntr_id)
      LET larec_displayedlist[k].myimage = C_ICON_UNCHECKED
    END FOR
    CALL larec_states.clear()
  END FOR

  --check the states that are already present in the list of locations
  FOR i = 1 TO parec_campaignlocations.getLength()
    IF parec_campaignlocations[i].states.getLength()==0 THEN
      LET j = larec_displayedlist.search("state_id", -parec_campaignlocations[i].country.cmpcntr_country_id)
      LET larec_displayedlist[j].myimage = C_ICON_CHECKED
    END IF
    FOR j = 1 TO parec_campaignlocations[i].states.getLength()
      LET k = larec_displayedlist.search("state_id", parec_campaignlocations[i].states[j].state.cmpstt_state_id)
      LET larec_displayedlist[k].myimage = C_ICON_CHECKED
    END FOR
  END FOR

  LET lbool_is_mobile = core_ui.ui_is_mobile()
  OPEN WINDOW w_zoom_state WITH FORM "campaignlocations_state"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY larec_displayedlist TO scrlist_country.*
      ON ACTION selectrow
        LET i = arr_curr()
        IF larec_displayedlist[i].myimage==C_ICON_UNCHECKED THEN
          --line is checked
          LET larec_displayedlist[i].myimage = C_ICON_CHECKED
          IF larec_displayedlist[i].state_id < 0 THEN --"All" state for the current country has been checked
            FOR j = i+1 TO larec_displayedlist.getLength()
              IF larec_displayedlist[j].country_id <> larec_displayedlist[i].country_id THEN
                EXIT FOR
              END IF
              LET larec_displayedlist[j].myimage = C_ICON_UNCHECKED
            END FOR
          ELSE --an other state has been checked
            --uncheck "All" state for the current country
            LET j = larec_displayedlist.search("state_id", -larec_displayedlist[i].country_id)
            LET larec_displayedlist[j].myimage = C_ICON_UNCHECKED
          END IF
        ELSE
          --line is unchecked
          LET larec_displayedlist[i].myimage = C_ICON_UNCHECKED
          IF larec_displayedlist[i].state_id < 0 THEN
            --forbid to uncheck manually "All" state for the current country
            LET larec_displayedlist[i].myimage = C_ICON_CHECKED
          ELSE
            --we need to check "All" state for the current country is there is no more other states checked
            LET j = larec_displayedlist.search("state_id", -larec_displayedlist[i].country_id)
            LET lbool_found = FALSE
            FOR k = j+1 TO larec_displayedlist.getLength()
              IF larec_displayedlist[k].country_id <> larec_displayedlist[i].country_id THEN
                EXIT FOR
              END IF
              IF larec_displayedlist[k].myimage = C_ICON_CHECKED THEN
                LET lbool_found = TRUE
                EXIT FOR
              END IF
            END FOR
            IF NOT lbool_found THEN
              LET larec_displayedlist[j].myimage = C_ICON_CHECKED
            END IF
          END IF
        END IF
        CALL _display_selected_states(larec_displayedlist)
    END DISPLAY
    ON ACTION accept
      FOR i = 1 TO larec_displayedlist.getLength()
        IF larec_displayedlist[i].state_id < 0 THEN --ignore selection of 'all' states
          CONTINUE FOR
        END IF
        CALL _search_state(parec_campaignlocations, larec_displayedlist[i].state_id)
          RETURNING idx_country, idx_state
        IF idx_state == 0 THEN
          LET idx_country = _search_country(parec_campaignlocations, larec_displayedlist[i].country_id)
        END IF
        IF larec_displayedlist[i].myimage == C_ICON_UNCHECKED THEN
          IF idx_country > 0 AND idx_state > 0 THEN
            CALL parec_campaignlocations[idx_country].states.deleteElement(idx_state)
          END IF
        ELSE --element checked
          IF idx_state == 0 THEN
            LET j = parec_campaignlocations[idx_country].states.getLength() + 1
            INITIALIZE parec_campaignlocations[idx_country].states[j].state.* TO NULL
            LET parec_campaignlocations[idx_country].states[j].state.cmpstt_state_id = larec_displayedlist[i].state_id
          END IF
        END IF
      END FOR
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionActive("close",NOT lbool_is_mobile)
      CALL DIALOG.setActionHidden("close",lbool_is_mobile)
      CALL _display_selected_states(larec_displayedlist)
  END DIALOG
  CLOSE WINDOW w_zoom_state
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Display campaign locations as a cities list
#+
#+ @param parec_campaignlocations list of already selected locations
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION display_cities(parec_campaignlocations)
  DEFINE
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lrec_country RECORD LIKE countries.*,
    lrec_state RECORD LIKE states.*,
    larec_cities DYNAMIC ARRAY OF RECORD LIKE cities.*,
    larec_displayedlist DYNAMIC ARRAY OF t_displayed_cities,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i,j,k,l,idx_country, idx_state, idx_city INTEGER,
    lbool_is_mobile BOOLEAN,
    lbool_found BOOLEAN,
    lbool_hasstates BOOLEAN,
    lstr_tmp_cities_list STRING

  LET lint_action = C_APPACTION_CLOSE

  LET lbool_hasstates = FALSE
  FOR i = 1 TO parec_campaignlocations.getLength()
    IF parec_campaignlocations[i].states.getLength() > 0 THEN
      LET lbool_hasstates = TRUE
      EXIT FOR
    END IF
  END FOR
  IF NOT lbool_hasstates THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  FOR i = 1 TO parec_campaignlocations.getLength()
    CALL core_db.country_select_row(parec_campaignlocations[i].country.cmpcntr_country_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_country.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg, lint_action
    END IF
    IF parec_campaignlocations[i].states.getLength() == 0 THEN
      LET lstr_tmp_cities_list = IIF(lstr_tmp_cities_list.getLength()>0, SFMT("%1, %2",lstr_tmp_cities_list, SFMT("All (%1)",lrec_country.cntr_name)), SFMT("All (%1)",lrec_country.cntr_name))
    END IF
    FOR j = 1 TO parec_campaignlocations[i].states.getLength()
      CALL core_db.state_select_row(parec_campaignlocations[i].states[j].state.cmpstt_state_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_state.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg, lint_action
      END IF
      --list all cities
      CALL core_db.city_fetch_all_rows(SFMT("WHERE cities.cts_state_id = %1", lrec_state.stt_id), "ORDER BY cities.cts_name ASC", larec_cities)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg, lint_action
      END IF
      --add 'All' fictive city
      CALL larec_cities.insertElement(1)
      INITIALIZE larec_cities[1].* TO NULL
      LET larec_cities[1].cts_state_id = lrec_state.stt_id
      LET larec_cities[1].cts_name = "All"
      --initialize the array that will be displayed
      LET k = larec_displayedlist.getLength()
      FOR l = 1 TO larec_cities.getLength()
        LET k = k + 1
        LET larec_displayedlist[k].city.* = larec_cities[l].*
        LET larec_displayedlist[k].country_id = lrec_country.cntr_id
        LET larec_displayedlist[k].country_name = lrec_country.cntr_name
        LET larec_displayedlist[k].state_id = lrec_state.stt_id
        LET larec_displayedlist[k].state_name = lrec_state.stt_name
        LET larec_displayedlist[k].city_id = NVL(larec_cities[l].cts_id, -lrec_state.stt_id)
        LET larec_displayedlist[k].myimage = C_ICON_UNCHECKED
      END FOR
      CALL larec_cities.clear()
    END FOR
  END FOR

  --check the cities that are already present in the list of locations
  FOR i = 1 TO parec_campaignlocations.getLength()
    FOR j = 1 TO parec_campaignlocations[i].states.getLength()
      IF parec_campaignlocations[i].states[j].cities.getLength()==0 THEN
        LET k = larec_displayedlist.search("city_id", -parec_campaignlocations[i].states[j].state.cmpstt_state_id)
        LET larec_displayedlist[k].myimage = C_ICON_CHECKED
      END IF
      FOR k = 1 TO parec_campaignlocations[i].states[j].cities.getLength()
        LET l = larec_displayedlist.search("city_id", parec_campaignlocations[i].states[j].cities[k].city.cmpcts_city_id)
        LET larec_displayedlist[l].myimage = C_ICON_CHECKED
      END FOR
    END FOR
  END FOR

  LET lbool_is_mobile = core_ui.ui_is_mobile()
  OPEN WINDOW w_zoom_city WITH FORM "campaignlocations_city"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY larec_displayedlist TO scrlist_country.*
      ON ACTION selectrow
        LET i = arr_curr()
        IF larec_displayedlist[i].myimage==C_ICON_UNCHECKED THEN
          --line is checked
          LET larec_displayedlist[i].myimage = C_ICON_CHECKED
          IF larec_displayedlist[i].city_id < 0 THEN --"All" city for the current state has been checked
            FOR j = i+1 TO larec_displayedlist.getLength()
              IF (larec_displayedlist[j].country_id <> larec_displayedlist[i].country_id)
                OR (larec_displayedlist[j].state_id <> larec_displayedlist[i].state_id)
              THEN
                EXIT FOR
              END IF
              LET larec_displayedlist[j].myimage = C_ICON_UNCHECKED
            END FOR
          ELSE --an other city has been checked
            --uncheck "All" city for the current state
            LET j = larec_displayedlist.search("city_id", -larec_displayedlist[i].state_id)
            LET larec_displayedlist[j].myimage = C_ICON_UNCHECKED
          END IF
        ELSE
          --line is unchecked
          LET larec_displayedlist[i].myimage = C_ICON_UNCHECKED
          IF larec_displayedlist[i].city_id < 0 THEN
            --forbid to uncheck manually "All" city for the current state
            LET larec_displayedlist[i].myimage = C_ICON_CHECKED
          ELSE
            --we need to check "All" city for the current state is there is no more other cities checked
            LET j = larec_displayedlist.search("city_id", -larec_displayedlist[i].state_id)
            LET lbool_found = FALSE
            FOR k = j+1 TO larec_displayedlist.getLength()
              IF (larec_displayedlist[k].country_id <> larec_displayedlist[i].country_id)
                OR (larec_displayedlist[k].state_id <> larec_displayedlist[i].state_id)
              THEN
                EXIT FOR
              END IF
              IF larec_displayedlist[k].myimage = C_ICON_CHECKED THEN
                LET lbool_found = TRUE
                EXIT FOR
              END IF
            END FOR
            IF NOT lbool_found THEN
              LET larec_displayedlist[j].myimage = C_ICON_CHECKED
            END IF
          END IF
        END IF
        CALL _display_selected_cities(larec_displayedlist, lstr_tmp_cities_list)
    END DISPLAY
    ON ACTION accept
      FOR i = 1 TO larec_displayedlist.getLength()
        IF larec_displayedlist[i].city_id < 0 THEN --ignore selection of 'all' cities
          CONTINUE FOR
        END IF
        CALL _search_city(parec_campaignlocations, larec_displayedlist[i].city_id)
          RETURNING idx_country, idx_state, idx_city
        IF idx_city == 0 THEN
          CALL _search_state(parec_campaignlocations, larec_displayedlist[i].state_id)
            RETURNING idx_country, idx_state
        END IF
        IF larec_displayedlist[i].myimage == C_ICON_UNCHECKED THEN
          IF idx_country > 0 AND idx_state > 0 AND idx_city > 0 THEN
            CALL parec_campaignlocations[idx_country].states[idx_state].cities.deleteElement(idx_city)
          END IF
        ELSE --element checked
          IF idx_city == 0 THEN
            LET j = parec_campaignlocations[idx_country].states[idx_state].cities.getLength() + 1
            INITIALIZE parec_campaignlocations[idx_country].states[idx_state].cities[j].city.* TO NULL
            LET parec_campaignlocations[idx_country].states[idx_state].cities[j].city.cmpcts_city_id = larec_displayedlist[i].city_id
          END IF
        END IF
      END FOR
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionActive("close",NOT lbool_is_mobile)
      CALL DIALOG.setActionHidden("close",lbool_is_mobile)
      CALL _display_selected_cities(larec_displayedlist, lstr_tmp_cities_list)
  END DIALOG
  CLOSE WINDOW w_zoom_city
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Get country, state and city strings from a list of campaignlocations.
#+ This string is used to be displayed inside buttonedit fields
#+
#+ @param parec_campaignlocations list of campaign locations
#+
#+ @returnType STRING, STRING, STRING
#+ @return     country, state, city
FUNCTION serialize(parec_campaignlocations)
  DEFINE
    parec_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    larec_copy_campaignlocations DYNAMIC ARRAY OF t_campaigncountry,
    lstr_country STRING,
    lstr_state STRING,
    lstr_city STRING,
    i,j,k INTEGER,
    lbool_hasstates BOOLEAN,
    lbool_hascities BOOLEAN

  CALL parec_campaignlocations.copyTo(larec_copy_campaignlocations)

  --When we select for example 3 countries, to avoid issue like State="'All','All','All'" we need to check
  --if there is at least one state. If that's the case, the other 'All' should be pre/suffixed with the country name.
  --Same principle applies to cities.
  LET lbool_hasstates = FALSE
  LET lbool_hascities = FALSE
  FOR i = 1 TO larec_copy_campaignlocations.getLength()
    IF lbool_hasstates AND lbool_hascities THEN
      EXIT FOR
    END IF
    FOR j = 1 TO larec_copy_campaignlocations[i].states.getLength()
      LET lbool_hasstates = TRUE
      IF lbool_hascities THEN
        EXIT FOR
      END IF
      FOR k = 1 TO larec_copy_campaignlocations[i].states[j].cities.getLength()
        LET lbool_hascities = TRUE
        EXIT FOR
      END FOR
    END FOR
  END FOR

  IF larec_copy_campaignlocations.getLength()==0 THEN
    LET lstr_country = _get_country_name(NULL)
  END IF
  IF NOT lbool_hasstates THEN --there is no states amongst all countries
    LET lstr_state = _get_state_name(NULL, NULL)
  END IF
  IF NOT lbool_hascities THEN --there is no cities amongst all states amongst all countries
    LET lstr_city = _get_state_name(NULL, NULL)
  END IF
  FOR i = 1 TO larec_copy_campaignlocations.getLength()
    LET lstr_country = string.concat(lstr_country, _get_country_name(larec_copy_campaignlocations[i].country.cmpcntr_country_id))
    IF larec_copy_campaignlocations[i].states.getLength()==0 THEN
      IF lbool_hasstates THEN
        LET lstr_state = string.concat(lstr_state, _get_state_name(NULL, larec_copy_campaignlocations[i].country.cmpcntr_country_id))
      END IF
      IF lbool_hascities THEN
        LET lstr_city = string.concat(lstr_city, _get_city_name(NULL, NULL, larec_copy_campaignlocations[i].country.cmpcntr_country_id))
      END IF
    ELSE
      FOR j = 1 TO larec_copy_campaignlocations[i].states.getLength()
        LET lstr_state = string.concat(lstr_state, _get_state_name(larec_copy_campaignlocations[i].states[j].state.cmpstt_state_id, larec_copy_campaignlocations[i].country.cmpcntr_country_id))
        IF larec_copy_campaignlocations[i].states[j].cities.getLength()==0 THEN
          IF lbool_hascities THEN
            LET lstr_city = string.concat(lstr_city, _get_city_name(NULL, larec_copy_campaignlocations[i].states[j].state.cmpstt_state_id, NULL))
          END IF
        ELSE
          FOR k = 1 TO larec_copy_campaignlocations[i].states[j].cities.getLength()
            LET lstr_city = string.concat(lstr_city, _get_city_name(larec_copy_campaignlocations[i].states[j].cities[k].city.cmpcts_city_id, NULL, NULL))
          END FOR
        END IF
      END FOR
    END IF
  END FOR
  RETURN lstr_country, lstr_state, lstr_city
END FUNCTION

#+ Get the name of a country
#+
#+ @param p_key country id
#+
#+ @returnType STRING
#+ @return     country string
PRIVATE FUNCTION _get_country_name(p_key)
  DEFINE
    p_key LIKE countries.cntr_id,
    lstr_ret STRING,
    lstr_cntr_name LIKE countries.cntr_name

  IF p_key IS NULL THEN
    LET lstr_ret = "All"
  ELSE
    TRY
      SELECT countries.cntr_name
        INTO lstr_cntr_name
      FROM countries
      WHERE countries.cntr_id = p_key
      LET lstr_ret = lstr_cntr_name
    CATCH
    END TRY
  END IF
  RETURN lstr_ret
END FUNCTION

#+ Get the name of a state
#+
#+ @param p_key state id
#+ @param pint_country_id country id
#+
#+ @returnType STRING
#+ @return     state string
PRIVATE FUNCTION _get_state_name(p_key, pint_country_id)
  DEFINE
    p_key LIKE states.stt_id,
    pint_country_id LIKE countries.cntr_id,
    lstr_ret STRING,
    lstr_stt_name LIKE states.stt_name

  IF p_key IS NULL THEN
    IF pint_country_id IS NOT NULL THEN
      LET lstr_ret = _get_country_name(pint_country_id)
    END IF
    LET lstr_ret = IIF(lstr_ret.getLength()>0, SFMT("All (%1)",lstr_ret), "All")
  ELSE
    TRY
      SELECT states.stt_name
        INTO lstr_stt_name
      FROM states
      WHERE states.stt_id = p_key
    CATCH
    END TRY
    LET lstr_ret = lstr_stt_name
  END IF
  RETURN lstr_ret
END FUNCTION

#+ Get the name of a city
#+
#+ @param p_key city id
#+ @param pint_state_id state id
#+ @param pint_country_id country id
#+
#+ @returnType STRING
#+ @return     city string
PRIVATE FUNCTION _get_city_name(p_key, pint_state_id, pint_country_id)
  DEFINE
    p_key LIKE cities.cts_id,
    pint_state_id LIKE states.stt_id,
    pint_country_id LIKE countries.cntr_id,
    lstr_ret STRING,
    lstr_cts_name LIKE cities.cts_name

  IF p_key IS NULL THEN
    IF pint_state_id IS NOT NULL THEN
      LET lstr_ret = _get_state_name(pint_state_id, NULL)
    END IF
    IF pint_country_id IS NOT NULL THEN
      LET lstr_ret = _get_country_name(pint_country_id)
    END IF
    LET lstr_ret = IIF(lstr_ret.getLength()>0, SFMT("All (%1)",lstr_ret), "All")
  ELSE
    TRY
      SELECT cities.cts_name
        INTO lstr_cts_name
      FROM cities
      WHERE cities.cts_id = p_key
    CATCH
    END TRY
    LET lstr_ret = lstr_cts_name
  END IF
  RETURN lstr_ret
END FUNCTION

#+ Get the index of the given country in the list of campaign location datastructure
#+
#+ @param parec_campaignlocations campaign locations
#+ @param pint_country_id country id
#+
#+ @returnType INTEGER
#+ @return     0 (not found), > 0 otherwise
PRIVATE FUNCTION _search_country(parec_campaignlocation, pint_country_id)
  DEFINE
    parec_campaignlocation DYNAMIC ARRAY OF t_campaigncountry,
    pint_country_id LIKE countries.cntr_id,
    i INTEGER
  FOR i = 1 TO parec_campaignlocation.getLength()
    IF parec_campaignlocation[i].country.cmpcntr_country_id == pint_country_id THEN
      RETURN i
    END IF
  END FOR
  RETURN 0
END FUNCTION

#+ Get the index of the given state in the list of campaign location datastructure
#+
#+ @param parec_campaignlocations campaign locations
#+ @param pint_state_id state id
#+
#+ @returnType INTEGER, INTEGER
#+ @return     country index, state index
PRIVATE FUNCTION _search_state(parec_campaignlocation, pint_state_id)
  DEFINE
    parec_campaignlocation DYNAMIC ARRAY OF t_campaigncountry,
    pint_state_id LIKE states.stt_id,
    i,j INTEGER

  FOR i = 1 TO parec_campaignlocation.getLength()
    IF parec_campaignlocation[i].states.getLength() > 0 THEN
      FOR j = 1 TO parec_campaignlocation[i].states.getLength()
        IF parec_campaignlocation[i].states[j].state.cmpstt_state_id == pint_state_id THEN
          RETURN i, j
        END IF
      END FOR
    END IF
  END FOR
  RETURN 0, 0
END FUNCTION

#+ Get the index of the given city in the list of campaign location datastructure
#+
#+ @param parec_campaignlocations campaign locations
#+ @param pint_city_id city id
#+
#+ @returnType INTEGER, INTEGER, INTEGER
#+ @return     country index, state index, city index
PRIVATE FUNCTION _search_city(parec_campaignlocation, pint_city_id)
  DEFINE
    parec_campaignlocation DYNAMIC ARRAY OF t_campaigncountry,
    pint_city_id LIKE cities.cts_id,
    i,j,k INTEGER

  FOR i = 1 TO parec_campaignlocation.getLength()
    FOR j = 1 TO parec_campaignlocation[i].states.getLength()
      IF parec_campaignlocation[i].states[j].cities.getLength() > 0 THEN
       FOR k = 1 TO parec_campaignlocation[i].states[j].cities.getLength()
          IF parec_campaignlocation[i].states[j].cities[k].city.cmpcts_city_id == pint_city_id THEN
            RETURN i, j, k
          END IF
        END FOR
      END IF
    END FOR
  END FOR
  RETURN 0, 0, 0
END FUNCTION

#+ Display selected countries in the zoom
#+
#+ @param parec_displayedlist displayed list of countries
#+
PRIVATE FUNCTION _display_selected_countries(parec_displayedlist DYNAMIC ARRAY OF t_displayed_countries)
  DEFINE
    i,s INTEGER,
    lstr_ret STRING

  LET s = parec_displayedlist.getLength()
  FOR i = 1 TO s
    IF parec_displayedlist[i].myimage == C_ICON_CHECKED THEN
      LET lstr_ret = IIF(lstr_ret.getLength()>0, SFMT("%1, %2",lstr_ret, parec_displayedlist[i].country.cntr_name), parec_displayedlist[i].country.cntr_name)
    END IF
  END FOR
  DISPLAY lstr_ret TO selection_lbl
END FUNCTION

#+ Display selected states in the zoom
#+
#+ @param parec_displayedlist displayed list of states
#+
PRIVATE FUNCTION _display_selected_states(parec_displayedlist DYNAMIC ARRAY OF t_displayed_states)
  DEFINE
    i,s INTEGER,
    lstr_ret STRING,
    lstr_tmp STRING,
    nb_checked INTEGER,
    nb_all_checked INTEGER

  LET s = parec_displayedlist.getLength()
  FOR i = 1 TO s
    IF parec_displayedlist[i].myimage == C_ICON_CHECKED THEN
      LET nb_checked = nb_checked + 1
      IF parec_displayedlist[i].state_id < 0 THEN
        LET nb_all_checked = nb_all_checked + 1
        LET lstr_tmp = SFMT("%1 (%2)", parec_displayedlist[i].state.stt_name, parec_displayedlist[i].country_name)
      ELSE
        LET lstr_tmp = parec_displayedlist[i].state.stt_name
      END IF
      LET lstr_ret = IIF(lstr_ret.getLength()>0, SFMT("%1, %2",lstr_ret, lstr_tmp), lstr_tmp)
    END IF
  END FOR
  IF nb_checked == nb_all_checked THEN
    LET lstr_ret = "All"
  END IF
  DISPLAY lstr_ret TO selection_lbl
END FUNCTION

#+ Display selected cities in the zoom
#+
#+ @param parec_displayedlist displayed list of cities
#+
PRIVATE FUNCTION _display_selected_cities(parec_displayedlist DYNAMIC ARRAY OF t_displayed_cities, pstr_all_cities STRING)
  DEFINE
    i,s INTEGER,
    lstr_ret STRING,
    lstr_tmp STRING,
    nb_checked INTEGER,
    nb_all_checked INTEGER

  LET s = parec_displayedlist.getLength()
  LET lstr_ret = pstr_all_cities
  FOR i = 1 TO s
    IF parec_displayedlist[i].myimage == C_ICON_CHECKED THEN
      LET nb_checked = nb_checked + 1
      IF parec_displayedlist[i].city_id < 0 THEN
        LET nb_all_checked = nb_all_checked + 1
        LET lstr_tmp = SFMT("%1 (%2)", parec_displayedlist[i].city.cts_name, parec_displayedlist[i].state_name)
      ELSE
        LET lstr_tmp = parec_displayedlist[i].city.cts_name
      END IF
      LET lstr_ret = IIF(lstr_ret.getLength()>0, SFMT("%1, %2",lstr_ret, lstr_tmp), lstr_tmp)
    END IF
  END FOR
  IF nb_checked == nb_all_checked THEN
    LET lstr_ret = "All"
  END IF
  DISPLAY lstr_ret TO selection_lbl
END FUNCTION