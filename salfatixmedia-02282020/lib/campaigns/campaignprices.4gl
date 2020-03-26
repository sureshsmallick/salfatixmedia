IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL layout

SCHEMA salfatixmedia

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
  mint_campaign_id LIKE campaigns.cmp_id,
  mrec_campaignpricegrid t_campaignpricegrid,
  mrec_db_campaign RECORD LIKE campaigns.*

#+ Add/Update the price already paid by brand to salfatix media
#+
#+ @param pint_campaign_id campaign id
#+ @param pint_state current state invoked
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpricegrid_open_form_by_key(pint_campaign_id LIKE campaigns.cmp_id, pint_state SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT

  LET lint_action = C_APPACTION_UNDEFINED
  LET mint_campaign_id = pint_campaign_id
  OPEN WINDOW w_campaignprice_grid WITH FORM "campaignprice_grid"
  CASE pint_state
    WHEN C_APPSTATE_DISPLAY
      CALL campaignpricegrid_display() RETURNING lint_ret, lint_action
    WHEN C_APPSTATE_UPDATE
      CALL campaignpricegrid_update() RETURNING lint_ret, lint_action
    OTHERWISE --error case
  END CASE
  CLOSE WINDOW w_campaignprice_grid
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the campaign price display
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpricegrid_display()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT

  LET lint_action = C_APPACTION_UNDEFINED
  CALL FGL_SETTITLE(%"Campaign price")
  CALL campaignprice_get_data_by_key(mint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  MENU ""
    BEFORE MENU
      CALL layout.display_currencysymbol(mrec_campaignpricegrid.campaign.cmp_currency_id,"cur,cur1,cur2,cur3,cur4,cur5,cur6")
      DISPLAY mrec_campaignpricegrid.* TO scr_campaignprice_grid.*
      CALL core_ui.ui_set_node_attribute("FormField","name","formonly.ffimage_value","hidden",1)
    ON ACTION cancel
      LET lint_action = C_APPACTION_CANCEL
      EXIT MENU
  END MENU
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog of the campaign price display
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpricegrid_update()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ffimage_value STRING

  LET lint_action = C_APPACTION_UNDEFINED
  CALL FGL_SETTITLE(%"Edit campaign price")
  CALL campaignprice_get_data_by_key(mint_campaign_id)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaignpricegrid.* FROM scr_campaignprice_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION dialogtouched
      CALL DIALOG.setActionActive("dialogtouched",FALSE)
      LET ffimage_value = "fa-check-circle-green"
      DISPLAY BY NAME ffimage_value
    ON ACTION save
      IF mrec_db_campaign.* <> mrec_campaignpricegrid.campaign.* THEN
        IF core_ui.ui_message(%"Question ?",%"Are you sure you want to change the value of 'Brand already paid' field?","no","yes|no","fa-question") == "yes" THEN
          CALL core_db.campaigns_update_row(mrec_db_campaign.*, mrec_campaignpricegrid.campaign.*, CURRENT)
            RETURNING lint_ret, lstr_msg
          IF lint_ret <> 0 THEN
            ERROR lstr_msg
            CONTINUE DIALOG
          END IF
          LET lint_action = C_APPACTION_ACCEPT
          EXIT DIALOG
        END IF
      END IF
    ON ACTION cancel
      LET lint_ret = 0
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    BEFORE DIALOG
      CALL layout.display_currencysymbol(mrec_campaignpricegrid.campaign.cmp_currency_id,"cur,cur1,cur2,cur3,cur4,cur5,cur6")
      LET ffimage_value = "fa-check-circle-gray"
      DISPLAY BY NAME ffimage_value
  END DIALOG
  RETURN lint_ret, lint_action
END FUNCTION

#+ Initializes the campaign price business record
#+
#+ @param pint_campaign_id current campaign
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignprice_get_data_by_key(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  INITIALIZE mrec_campaignpricegrid.* TO NULL
  INITIALIZE mrec_db_campaign.* TO NULL

  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, mrec_campaignpricegrid.campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET mrec_db_campaign.* = mrec_campaignpricegrid.campaign.*
  CALL campaignprice_get_salfatix_prices(pint_campaign_id)
    RETURNING lint_ret, lstr_msg, mrec_campaignpricegrid.influencersestimatedcost, mrec_campaignpricegrid.influencerscost, mrec_campaignpricegrid.alreadypaidtoinfluencers
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL campaignprice_get_brand_prices(pint_campaign_id)
    RETURNING lint_ret, lstr_msg, mrec_campaignpricegrid.brandestimatedcost, mrec_campaignpricegrid.brandcost, mrec_campaignpricegrid.campaign.cmp_deposit
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Get the influencer costs for salfatixmedia
#+
#+ @param pint_campaign_id current campaign
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignprice_get_salfatix_prices(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_estimatedcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    lint_cost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    lint_alreadypaid LIKE campaignuserlist.cmpusrl_salfatixtotalprice
  TRY
    SELECT SUM(campaignuserlist.cmpusrl_usertotalprice)
      INTO lint_estimatedcost
    FROM campaignuserlist
    WHERE cmpusrl_campaign_id = pint_campaign_id
      AND cmpusrl_isacceptedbysalfatix = 1
      AND (cmpusrl_isacceptedbybrand IS NULL
        OR cmpusrl_isacceptedbybrand = 1)
  CATCH
    RETURN SQLCA.SQLCODE, SQLERRMESSAGE, NULL, NULL, NULL
  END TRY
  TRY
    SELECT SUM(campaignuserlist.cmpusrl_usertotalprice)
      INTO lint_cost
    FROM campaignuserlist
    WHERE cmpusrl_campaign_id = pint_campaign_id
      AND cmpusrl_isacceptedbybrand = 1
  CATCH
    RETURN SQLCA.SQLCODE, SQLERRMESSAGE, NULL, NULL, NULL
  END TRY
  TRY
    SELECT SUM(campaignuserlist.cmpusrl_userpaid)
      INTO lint_alreadypaid
    FROM campaignuserlist
    WHERE cmpusrl_campaign_id = pint_campaign_id
  CATCH
    RETURN SQLCA.SQLCODE, SQLERRMESSAGE, NULL, NULL, NULL
  END TRY
  RETURN 0, NULL, lint_estimatedcost, lint_cost, lint_alreadypaid
END FUNCTION

#+ Get the influencer costs for the brand
#+
#+ @param pint_campaign_id current campaign
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignprice_get_brand_prices(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_estimatedcost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    lint_cost LIKE campaignuserlist.cmpusrl_salfatixtotalprice,
    lint_alreadypaid LIKE campaignuserlist.cmpusrl_salfatixtotalprice
  TRY
    SELECT SUM(campaignuserlist.cmpusrl_salfatixtotalprice)
      INTO lint_estimatedcost
    FROM campaignuserlist
    WHERE cmpusrl_campaign_id = pint_campaign_id
      AND cmpusrl_isacceptedbysalfatix = 1
      AND (cmpusrl_isacceptedbybrand IS NULL
        OR cmpusrl_isacceptedbybrand = 1)
  CATCH
    RETURN SQLCA.SQLCODE, SQLERRMESSAGE, NULL, NULL, NULL
  END TRY
  TRY
    SELECT SUM(campaignuserlist.cmpusrl_salfatixtotalprice)
      INTO lint_cost
    FROM campaignuserlist
    WHERE cmpusrl_campaign_id = pint_campaign_id
      AND cmpusrl_isacceptedbybrand = 1
  CATCH
    RETURN SQLCA.SQLCODE, SQLERRMESSAGE, NULL, NULL, NULL
  END TRY
  TRY
    SELECT campaigns.cmp_deposit
      INTO lint_alreadypaid
    FROM campaigns
    WHERE cmp_id = pint_campaign_id
  CATCH
    RETURN SQLCA.SQLCODE, SQLERRMESSAGE, NULL, NULL, NULL
  END TRY
  RETURN 0, NULL, lint_estimatedcost, lint_cost, lint_alreadypaid
END FUNCTION
