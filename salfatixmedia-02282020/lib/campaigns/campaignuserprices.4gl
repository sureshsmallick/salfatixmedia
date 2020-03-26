IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL layout

SCHEMA salfatixmedia

TYPE
  t_campaignuserpricegrid RECORD
    campaignuser RECORD LIKE campaignuserlist.*,
    generalterms SMALLINT
  END RECORD

#+ Fetch and display the campaign user prices for a campaign
#+
#+ @param pstr_title window title
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignuserprice_open_form(pint_campaign_id, pint_usr_id)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_usr_id LIKE users.usr_id,
    lrec_campaignuserlist RECORD LIKE campaignuserlist.*,
    lrec_campaignuserpricegrid t_campaignuserpricegrid,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    i INTEGER,
    lstr_sql STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lstr_crr_symbol LIKE currencies.crr_symbol,
    l_dialogtouched BOOLEAN

  LET lint_action = C_APPACTION_UNDEFINED
  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  CALL core_db.campaignuserlist_select_row_by_campaign_and_user(pint_campaign_id, pint_usr_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignuserlist.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  INITIALIZE lrec_campaignuserpricegrid.* TO NULL
  LET lrec_campaignuserpricegrid.campaignuser.* = lrec_campaignuserlist.*
  LET lrec_campaignuserpricegrid.generalterms = 0

  OPEN WINDOW w_campaignuserprice_open_form WITH FORM "campaign_apply"

  INPUT lrec_campaignuserpricegrid.* FROM scr_campaignuserprice_grid.*
    ATTRIBUTES(WITHOUT DEFAULTS, UNBUFFERED, FIELD ORDER FORM)

    BEFORE INPUT
      CALL campaignuserprice_ui_set_action_state(DIALOG, l_dialogtouched, lrec_campaignuserpricegrid.*, TRUE)
      CALL layout.display_currencysymbol(lrec_campaign.cmp_currency_id,"cur,cur1")

    ON CHANGE generalterms
      CALL campaignuserprice_ui_set_action_state(DIALOG, True, lrec_campaignuserpricegrid.*, TRUE)

    ON ACTION generalterms
      CALL core_ui.ui_launch_url(base.Application.getResourceEntry("salfatixmedia.generaltermsofbusiness.cgu"))

    ON ACTION accept
      CALL campaignuserprice_validate_data(pint_campaign_id, pint_usr_id, lrec_campaignuserpricegrid.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE INPUT
      END IF
      CALL campaignuserprice_update_dabatase(pint_campaign_id, pint_usr_id, lrec_campaignuserpricegrid.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE INPUT
      END IF
      LET lint_ret = 0
      LET lint_action = C_APPACTION_ACCEPT
      EXIT INPUT

    ON ACTION cancel
      LET lint_ret = 0
      LET lint_action = C_APPACTION_CANCEL
      EXIT INPUT
  END INPUT

  CLOSE WINDOW w_campaignuserprice_open_form
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignuserprice_ui_set_action_state(p_dialog, p_dialogtouched, prec_campaignuserpricegrid, pbool_loaddialog)
  DEFINE
    p_dialog ui.DIALOG,
    p_dialogtouched BOOLEAN,
    prec_campaignuserpricegrid t_campaignuserpricegrid,
    pbool_loaddialog BOOLEAN
  --CALL p_dialog.setActionActive("dialogtouched", NOT p_dialogtouched)
  --CALL p_dialog.setActionHidden("dialogtouched", TRUE)
  CALL p_dialog.setActionActive("accept", p_dialogtouched)
  --CALL p_dialog.setActionHidden("close", TRUE)
--
  --IF pbool_loaddialog THEN
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.posttype_label","hidden", prec_campaignuserpricegrid.posttype_label IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cmpusrp_price","hidden", prec_campaignuserpricegrid.posttype_label IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cur","hidden", prec_campaignuserpricegrid.posttype_label IS NULL)
--
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.posttype_label1","hidden", prec_campaignuserpricegrid.posttype_label1 IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cmpusrp_price1","hidden", prec_campaignuserpricegrid.posttype_label1 IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cur1","hidden", prec_campaignuserpricegrid.posttype_label1 IS NULL)
--
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.posttype_label2","hidden", prec_campaignuserpricegrid.posttype_label2 IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cmpusrp_price2","hidden", prec_campaignuserpricegrid.posttype_label2 IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cur2","hidden", prec_campaignuserpricegrid.posttype_label2 IS NULL)
--
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.posttype_label3","hidden", prec_campaignuserpricegrid.posttype_label3 IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cmpusrp_price3","hidden", prec_campaignuserpricegrid.posttype_label3 IS NULL)
    --CALL core_ui.ui_set_node_attribute("FormField","name","formonly.cur3","hidden", prec_campaignuserpricegrid.posttype_label3 IS NULL)
  --END IF
END FUNCTION

#+ Check business rules for campaign user prices
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignuserprice_validate_data(pint_campaign_id, pint_usr_id, prec_campaignuserpricegrid)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_usr_id LIKE users.usr_id,
    prec_campaignuserpricegrid t_campaignuserpricegrid

  IF prec_campaignuserpricegrid.generalterms IS NULL OR prec_campaignuserpricegrid.generalterms==0 THEN
    RETURN -1, %"General Terms of Business must be validated"
  END IF

  RETURN 0, NULL
END FUNCTION

#+ Update user prices for a campaign into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignuserprice_update_dabatase(pint_campaign_id, pint_usr_id, prec_campaignuserpricegrid)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_usr_id LIKE users.usr_id,
    prec_campaignuserpricegrid t_campaignuserpricegrid,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  IF lint_ret == 0 THEN
    --in case the influencer input the same price has the proposed price, there is no negociation
    IF prec_campaignuserpricegrid.campaignuser.cmpusrl_usertotalprice IS NOT NULL
      AND prec_campaignuserpricegrid.campaignuser.cmpusrl_userwantedprice IS NOT NULL
      AND (prec_campaignuserpricegrid.campaignuser.cmpusrl_usertotalprice == prec_campaignuserpricegrid.campaignuser.cmpusrl_userwantedprice)
    THEN
      INITIALIZE prec_campaignuserpricegrid.campaignuser.cmpusrl_userwantedprice TO NULL
    END IF
    --apply to campaign 
    CALL campaign_update_by_influencer(pint_campaign_id, pint_usr_id, TRUE, prec_campaignuserpricegrid.campaignuser.cmpusrl_userwantedprice)
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

#+ Reject a campaign for an influencer
#+
#+ @param pint_campaign_id campaign id
#+ @param pint_user_id influencer id
#+ @param pbool_isacceptbyuser TRUE to apply|FALSE to reject
#+ @param p_wantedprice wanted price by the influencer when he applies
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, campaign id
FUNCTION campaign_update_by_influencer(pint_campaign_id, pint_user_id, pbool_isacceptbyuser, p_wantedprice)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    pint_user_id LIKE users.usr_id,
    pbool_isacceptbyuser BOOLEAN,
    p_wantedprice LIKE campaignuserlist.cmpusrl_userwantedprice,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignuserlist RECORD LIKE campaignuserlist.*,
    lrec_campaignuserlist_db RECORD LIKE campaignuserlist.*,
    lint_status INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  CALL core_db.campaignuserlist_select_row_by_campaign_and_user(pint_campaign_id, pint_user_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignuserlist.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET lrec_campaignuserlist_db.* = lrec_campaignuserlist.*
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET l_timestamp = CURRENT
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  IF pbool_isacceptbyuser THEN
    LET lrec_campaignuserlist.cmpusrl_userwantedprice = p_wantedprice
  END IF
  LET lrec_campaignuserlist.cmpusrl_isacceptbyuser = pbool_isacceptbyuser
  LET lrec_campaignuserlist.cmpusrl_useranswerdate = l_timestamp
  CALL core_db.campaignuserlist_update_row(lrec_campaignuserlist_db.*, lrec_campaignuserlist.*)
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