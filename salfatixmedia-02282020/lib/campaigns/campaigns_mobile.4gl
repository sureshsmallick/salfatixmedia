IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL campaignposttypes
IMPORT FGL campaignuserprices
IMPORT FGL campaignposts_mobile

SCHEMA salfatixmedia

TYPE
  t_campaignlist_mobile RECORD
    campaign RECORD LIKE campaigns.*,
    pic_value LIKE pics.pic_value,
    brnd_name LIKE brands.brnd_name,
    cmpusrl_usertotalprice LIKE campaignuserlist.cmpusrl_usertotalprice,
    curcost LIKE currencies.crr_name,
    pic_usertotalprice STRING
  END RECORD

TYPE
  t_campaigngrid_mobile RECORD
    campaign RECORD LIKE campaigns.*,
    pic_value LIKE pics.pic_value,
    campaign_posttypes STRING,
    pic_id1 LIKE pics.pic_id,
    pic_value1 LIKE pics.pic_value,
    pic_id2 LIKE pics.pic_id,
    pic_value2 LIKE pics.pic_value,
    pic_id3 LIKE pics.pic_id,
    pic_value3 LIKE pics.pic_value,
    instagram_usertag STRING,
    instagram_hashtag STRING,
    crr_symbol1 LIKE currencies.crr_name, --currency symbol next to product
    poststarttime STRING,
    postendtime STRING,
    postduration STRING,
    cmpusrl_usertotalprice LIKE campaignuserlist.cmpusrl_usertotalprice,
    curcost LIKE currencies.crr_name
  END RECORD

CONSTANT
  C_LISTTYPE_OPENCAMPAIGNS SMALLINT = 1,
  C_LISTTYPE_APPLIEDCAMPAIGNS SMALLINT = 2,
  C_LISTTYPE_WORKABLECAMPAIGNS SMALLINT = 3
DEFINE --list data
  marec_campaignlist_mobile DYNAMIC ARRAY OF t_campaignlist_mobile

DEFINE
  mrec_campaigngrid_mobile t_campaigngrid_mobile,
  mrec_db_campaign_mobile RECORD LIKE campaigns.*

#+ Fetch and display the list campaigns on a mobile phone
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignlist_open_form_mobile()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lbool_flag BOOLEAN,
    lint_listtype SMALLINT

  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_campaign_list_mobile WITH FORM "campaign_list_mobile"
  LET lbool_flag = TRUE
  LET lint_listtype = C_LISTTYPE_OPENCAMPAIGNS
  WHILE lbool_flag
    LET lbool_flag = FALSE
    CALL _get_campaign_list_from_type(lint_listtype)
      RETURNING lint_ret, lstr_msg
    IF marec_campaignlist_mobile.getLength()==0 THEN
      LET lint_listtype = campaignlist_empty_mobile(lint_listtype)
    ELSE
      LET lint_listtype = campaignlist_display_mobile(lint_listtype)
    END IF
    CASE lint_listtype
      WHEN C_LISTTYPE_OPENCAMPAIGNS
        LET lbool_flag = TRUE
      WHEN C_LISTTYPE_APPLIEDCAMPAIGNS
        LET lbool_flag = TRUE
      WHEN C_LISTTYPE_WORKABLECAMPAIGNS
        LET lbool_flag = TRUE
      OTHERWISE
        LET lbool_flag = FALSE
        LET lint_action = C_APPACTION_INFLUENCER_MAINPANEL
    END CASE
  END WHILE
  CLOSE WINDOW w_campaign_list_mobile
  RETURN lint_ret, lint_action
END FUNCTION

#+ Dialog an empty campaign list
#+
#+ @param pint_type list type
#+
#+ @returnType SMALLINT
#+ @return     the list type of the displayed list
FUNCTION campaignlist_display_mobile(pint_type SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_type SMALLINT,
    i INTEGER,
    lint_action INTEGER

  LET lint_type = pint_type
  DISPLAY ARRAY marec_campaignlist_mobile TO scr_campaign_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY
      CALL _set_title(lint_type)
      CALL campaignlist_ui_set_action_state_mobile(DIALOG, lint_type)
    ON ACTION infl_viewopencampaigns
      LET lint_type = C_LISTTYPE_OPENCAMPAIGNS
      CALL _set_title(lint_type)
      CALL _get_campaign_list_from_type(lint_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF marec_campaignlist_mobile.getLength() == 0 THEN EXIT DISPLAY END IF
        CALL campaignlist_ui_set_action_state_mobile(DIALOG, lint_type)
      END IF
    ON ACTION infl_viewappliedcampaigns
      LET lint_type = C_LISTTYPE_APPLIEDCAMPAIGNS
      CALL _set_title(lint_type)
      CALL _get_campaign_list_from_type(lint_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF marec_campaignlist_mobile.getLength() == 0 THEN EXIT DISPLAY END IF
        CALL campaignlist_ui_set_action_state_mobile(DIALOG, lint_type)
      END IF
    ON ACTION infl_viewworkablecampaigns
      LET lint_type = C_LISTTYPE_WORKABLECAMPAIGNS
      CALL _set_title(lint_type)
      CALL _get_campaign_list_from_type(lint_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF marec_campaignlist_mobile.getLength() == 0 THEN EXIT DISPLAY END IF
        CALL campaignlist_ui_set_action_state_mobile(DIALOG, lint_type)
      END IF

    ON ACTION reject ATTRIBUTES(ROWBOUND, TEXT="Hide")
      LET i = DIALOG.getCurrentRow("scr_campaign_list")
      IF i > 0 THEN
        CALL campaignuserprices.campaign_update_by_influencer(marec_campaignlist_mobile[i].campaign.cmp_id, setup.g_loggedin_id, FALSE, NULL)
          RETURNING lint_ret, lstr_msg
        IF lint_ret == 0 THEN
          CALL marec_campaignlist_mobile.deleteElement(i)
        END IF
        IF marec_campaignlist_mobile.getLength() == 0 THEN EXIT DISPLAY END IF
        CALL campaignlist_ui_set_action_state_mobile(DIALOG, lint_type)
      END IF
    ON ACTION display_campaign
      LET i = DIALOG.getCurrentRow("scr_campaign_list")
      IF i > 0 THEN
        CALL campaigngrid_open_form_by_key_mobile(marec_campaignlist_mobile[i].campaign.cmp_id)
          RETURNING lint_ret, lint_action
        IF lint_ret == 0 THEN
          IF lint_action = C_APPACTION_ACCEPT THEN --campaign applied
            CALL marec_campaignlist_mobile.deleteElement(i)
          END IF
        END IF
        IF marec_campaignlist_mobile.getLength() == 0 THEN EXIT DISPLAY END IF
        CALL campaignlist_ui_set_action_state_mobile(DIALOG, lint_type)
      END IF
    ON ACTION cancel ATTRIBUTES(TEXT=%"Back")
      LET lint_type = 0
      EXIT DISPLAY
  END DISPLAY
  RETURN lint_type
END FUNCTION

#+ Dialog an empty campaign list
#+
#+ @param pint_type list type
#+
#+ @returnType SMALLINT
#+ @return     the list type of the displayed list
FUNCTION campaignlist_empty_mobile(pint_type SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_type SMALLINT

  LET lint_type = pint_type
  OPEN WINDOW w_campaign_list_empty_mobile WITH FORM "campaign_list_empty"
  MENU ""
    BEFORE MENU
      CALL _set_title(lint_type)
    ON ACTION infl_viewopencampaigns
      LET lint_type = C_LISTTYPE_OPENCAMPAIGNS
      CALL _set_title(lint_type)
      CALL _get_campaign_list_from_type(lint_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF marec_campaignlist_mobile.getLength() > 0 THEN EXIT MENU END IF
      END IF
    ON ACTION infl_viewappliedcampaigns
      LET lint_type = C_LISTTYPE_APPLIEDCAMPAIGNS
      CALL _set_title(lint_type)
      CALL _get_campaign_list_from_type(lint_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF marec_campaignlist_mobile.getLength() > 0 THEN EXIT MENU END IF
      END IF
    ON ACTION infl_viewworkablecampaigns
      LET lint_type = C_LISTTYPE_WORKABLECAMPAIGNS
      CALL _set_title(lint_type)
      CALL _get_campaign_list_from_type(lint_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret == 0 THEN
        IF marec_campaignlist_mobile.getLength() > 0 THEN EXIT MENU END IF
      END IF
    ON ACTION close ATTRIBUTES(TEXT=%"Back")
      LET lint_type = 0
      EXIT MENU
  END MENU
  CLOSE WINDOW w_campaign_list_empty_mobile

  RETURN lint_type
END FUNCTION
  
#+ Wrapper to get list of campaigns from a type
#+
#+ @param pint_type list type
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _get_campaign_list_from_type(pint_type SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  CASE pint_type
    WHEN C_LISTTYPE_OPENCAMPAIGNS
      CALL campaignlist_get_all_opened_campaigns_mobile(setup.g_loggedin_id, marec_campaignlist_mobile)
        RETURNING lint_ret, lstr_msg
    WHEN C_LISTTYPE_APPLIEDCAMPAIGNS
      CALL campaignlist_get_all_applied_campaigns_mobile(setup.g_loggedin_id, marec_campaignlist_mobile)
        RETURNING lint_ret, lstr_msg
    WHEN C_LISTTYPE_WORKABLECAMPAIGNS
      CALL campaignlist_get_all_workable_campaigns_mobile(setup.g_loggedin_id, marec_campaignlist_mobile)
        RETURNING lint_ret, lstr_msg
  END CASE
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Wrapper to set the title of a campaign list
#+
#+ @param pint_type list type
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
PRIVATE FUNCTION _set_title(pint_type SMALLINT)
  CASE pint_type
    WHEN C_LISTTYPE_OPENCAMPAIGNS
      CALL FGL_SETTITLE(%"Campaigns")
    WHEN C_LISTTYPE_APPLIEDCAMPAIGNS
      CALL FGL_SETTITLE(%"Applied Campaigns")
    WHEN C_LISTTYPE_WORKABLECAMPAIGNS
      CALL FGL_SETTITLE(%"Campaign Jobs")
  END CASE
END FUNCTION

#+ Get all opened campaigns for a influencer
#+
#+ @param pint_usr_id influencer id
#+ @param parec_list list of campaigns t_campaignlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_all_opened_campaigns_mobile(pint_usr_id LIKE users.usr_id, parec_list DYNAMIC ARRAY OF t_campaignlist_mobile)
  DEFINE
    lstr_from STRING,
    lstr_where STRING,
    lstr_orderby STRING,
    lint_ret INTEGER,
    lstr_msg STRING
  LET lstr_from = "campaigns, campaignuserlist"
  LET lstr_where = "campaigns.cmp_id = campaignuserlist.cmpusrl_campaign_id"
    ,SFMT(" AND campaignuserlist.cmpusrl_user_id = %1", pint_usr_id)
    ,SFMT(" AND campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
    ," AND campaignuserlist.cmpusrl_visibilitydate <= TODAY"
    ," AND campaignuserlist.cmpusrl_isacceptbyuser IS NULL"
  LET lstr_orderby = "campaignuserlist.cmpusrl_visibilitydate DESC"
  CALL campaignlist_get_data_mobile(lstr_from, lstr_where, lstr_orderby, parec_list)
    RETURNING lint_ret, lstr_msg
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get all applied campaigns for a influencer
#+
#+ @param pint_usr_id influencer id
#+ @param parec_list list of campaigns t_campaignlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_all_applied_campaigns_mobile(pint_usr_id LIKE users.usr_id, parec_list DYNAMIC ARRAY OF t_campaignlist_mobile)
  DEFINE
    lstr_from STRING,
    lstr_where STRING,
    lstr_orderby STRING,
    lint_ret INTEGER,
    lstr_msg STRING
  LET lstr_from = "campaigns, campaignuserlist"
  LET lstr_where = "campaigns.cmp_id = campaignuserlist.cmpusrl_campaign_id"
    ,SFMT(" AND campaignuserlist.cmpusrl_user_id = %1", pint_usr_id)
    ,SFMT(" AND campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
    ," AND campaignuserlist.cmpusrl_isacceptbyuser = 1"
    ," AND (campaignuserlist.cmpusrl_isacceptedbysalfatix IS NULL 
      OR (campaignuserlist.cmpusrl_isacceptedbysalfatix = 1
        AND campaignuserlist.cmpusrl_isacceptedbybrand IS NULL))"
  LET lstr_orderby = "campaignuserlist.cmpusrl_useranswerdate DESC"
  CALL campaignlist_get_data_mobile(lstr_from, lstr_where, lstr_orderby, parec_list)
    RETURNING lint_ret, lstr_msg
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get all campaigns for which a influencer has to work on
#+
#+ @param pint_usr_id influencer id
#+ @param parec_list list of campaigns t_campaignlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_all_workable_campaigns_mobile(pint_usr_id LIKE users.usr_id, parec_list DYNAMIC ARRAY OF t_campaignlist_mobile)
  DEFINE
    lstr_from STRING,
    lstr_where STRING,
    lstr_orderby STRING,
    lint_ret INTEGER,
    lstr_msg STRING
  LET lstr_from = "campaigns, campaignuserlist"
  LET lstr_where = "campaigns.cmp_id = campaignuserlist.cmpusrl_campaign_id"
    ,SFMT(" AND campaignuserlist.cmpusrl_user_id = %1", pint_usr_id)
    ,SFMT(" AND campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
    ," AND campaignuserlist.cmpusrl_isacceptedbybrand = 1"
  LET lstr_orderby = "campaigns.cmp_publisheddate DESC"
  CALL campaignlist_get_data_mobile(lstr_from, lstr_where, lstr_orderby, parec_list)
    RETURNING lint_ret, lstr_msg
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Get the campaign list data on mobile device
#+
#+ @param pint_usr_id Current user Id
#+ @param pstr_from SQL FROM clause to select data
#+ @param pstr_where SQL WHERE clause to select data
#+ @param pstr_orderby SQL ORDER BY clause to select data
#+ @param parec_list list of campaigns t_campaignlist
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_data_mobile(pstr_from STRING, pstr_where STRING, pstr_orderby STRING, parec_list DYNAMIC ARRAY OF t_campaignlist_mobile)
  DEFINE
    lstr_sql STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_campaign_id LIKE campaigns.cmp_id,
    lrec_campaignuser RECORD LIKE campaignuserlist.*,
    i INTEGER

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
    DECLARE c_campaignlist_get_data_mobile CURSOR FROM lstr_sql
    FOREACH c_campaignlist_get_data_mobile
      INTO lint_campaign_id
      LET i = i + 1
      CALL campaignlist_get_data_by_key_mobile(lint_campaign_id, parec_list, i)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      CALL core_db.campaignuserlist_select_row_by_campaign_and_user(lint_campaign_id, setup.g_loggedin_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
      IF lint_ret == 0 THEN
        LET parec_list[i].cmpusrl_usertotalprice = NVL(lrec_campaignuser.cmpusrl_userwantedprice, lrec_campaignuser.cmpusrl_usertotalprice)
        LET parec_list[i].curcost = core_db.currency_get_symbol(parec_list[i].campaign.cmp_currency_id)
        LET parec_list[i].pic_usertotalprice = campaignlist_get_pic_cost(parec_list[i].cmpusrl_usertotalprice)
      END IF
    END FOREACH
    FREE c_campaignlist_get_data_mobile
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get the picture name according the cost
#+ Reads table params with type = 1
#+
#+ @param userCost User total Cost
#+
#+ @returnType STRING
#+ @return     name of a picture
FUNCTION campaignlist_get_pic_cost(userCost LIKE campaignuserlist.cmpusrl_usertotalprice)
  DEFINE
    picName String

  IF userCost IS NULL THEN
    LET userCost = 0
  END IF

  TRY
    SELECT params.par_des INTO picName FROM params WHERE par_typ = 1 AND userCost BETWEEN params.par_min AND params.par_max
  CATCH
    IF core_ui.ui_message(%"Error",%"Selection of cost picture \n"||SQLCA.sqlcode||"\n"||SQLERRMESSAGE,"ok","ok","cancel-red") THEN END IF
    LET picName = "euro-1-0.png"
  END TRY

  RETURN picName
END FUNCTION

#+ Get the campaign list data for a given row
#+
#+ @param pint_campaign_id campaign id
#+ @param parec_list list of campaigns t_campaignlist
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignlist_get_data_by_key_mobile(pint_campaign_id LIKE campaigns.cmp_id, parec_list DYNAMIC ARRAY OF t_campaignlist_mobile, pint_index INTEGER)
  DEFINE
    lstr_sql STRING,
    lrec_data t_campaignlist_mobile,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_pic RECORD LIKE pics.*

  --get campaign data
  LET lstr_sql = "SELECT campaigns.*, brands.brnd_name"
    ," FROM campaigns, brands"
    ," WHERE campaigns.cmp_brand_id = brands.brnd_id"
    ,SFMT(" AND campaigns.cmp_id = %1", pint_campaign_id)
  TRY
    PREPARE p_campaignlist_get_data_by_key_mobile FROM lstr_sql
    EXECUTE p_campaignlist_get_data_by_key_mobile
      INTO lrec_data.campaign.*, lrec_data.brnd_name
    CALL core_db.pics_select_row(lrec_data.campaign.cmp_pic_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_pic.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET parec_list[pint_index].campaign.* = lrec_data.campaign.*
    LET parec_list[pint_index].brnd_name = lrec_data.brnd_name
    LET parec_list[pint_index].pic_value = lrec_pic.pic_value
    FREE p_campaignlist_get_data_by_key_mobile
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
#+ @param pint_type campaign list type
#+
FUNCTION campaignlist_ui_set_action_state_mobile(p_dialog ui.Dialog, pint_type SMALLINT)
  CALL p_dialog.setActionActive("display_campaign", (marec_campaignlist_mobile.getLength()>0))
  CALL p_dialog.setActionActive("reject", (pint_type==C_LISTTYPE_OPENCAMPAIGNS))
  CALL core_ui.ui_hideOrShowFieldOnCurrentForm("campaignuserlist.cmpusrl_usertotalprice",(pint_type==C_LISTTYPE_OPENCAMPAIGNS))
  CALL core_ui.ui_hideOrShowFieldOnCurrentForm("curcost",(pint_type==C_LISTTYPE_OPENCAMPAIGNS))
  CALL core_ui.ui_hideOrShowFieldOnCurrentForm("pic_usertotalprice",(pint_type<>C_LISTTYPE_OPENCAMPAIGNS))

END FUNCTION

#+ Fetch and display a campaign on a mobile
#+
#+ @param pint_campaign_id current campaign
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaigngrid_open_form_by_key_mobile(pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action INTEGER

  INITIALIZE mrec_campaigngrid_mobile.* TO NULL
  INITIALIZE mrec_db_campaign_mobile.* TO NULL

  LET lint_action = C_APPACTION_CLOSE
  CALL campaigngrid_get_data_by_key_mobile(pint_campaign_id)
    RETURNING lint_ret, lstr_msg, mrec_campaigngrid_mobile.*, mrec_db_campaign_mobile.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lint_action
  END IF

  OPEN WINDOW w_campaign_grid_mobile WITH FORM "campaign_grid_mobile"
  CALL FGL_SETTITLE(%"Brief")

  MENU ""
    BEFORE MENU
      CALL campaigngrid_ui_set_action_state_mobile(DIALOG)
      DISPLAY mrec_campaigngrid_mobile.* TO scr_campaign_grid.*
    ON ACTION apply
      CALL campaignuserprice_open_form(pint_campaign_id, setup.g_loggedin_id)
        RETURNING lint_ret, lstr_msg, lint_action
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE MENU
      END IF
      CASE lint_action
        WHEN C_APPACTION_ACCEPT
          LET lint_ret = 0
          LET lint_action = C_APPACTION_ACCEPT
          EXIT MENU
        WHEN C_APPACTION_CANCEL
      END CASE
    ON ACTION confirmreception
      CALL campaignproductreception_open_form(pint_campaign_id, setup.g_loggedin_id)
        RETURNING lint_ret, lstr_msg, lint_action
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE MENU
      END IF
      CASE lint_action
        WHEN C_APPACTION_ACCEPT
          LET lint_ret = 0
          LET lint_action = C_APPACTION_CLOSE
          EXIT MENU
        WHEN C_APPACTION_CANCEL
      END CASE
    ON ACTION editposts
      CALL campaignposts_mobile.campaignpostlistmobile_open_form_by_key(pint_campaign_id, setup.g_loggedin_id)
        RETURNING lint_ret, lint_action
      IF lint_ret <> 0 THEN
        CONTINUE MENU
      END IF
      CASE lint_action
        WHEN C_APPACTION_ACCEPT
        WHEN C_APPACTION_CANCEL
      END CASE
    ON ACTION close
      LET lint_action = C_APPACTION_CLOSE
      EXIT MENU
  END MENU
  CLOSE WINDOW w_campaign_grid_mobile
  RETURN lint_ret, lint_action
END FUNCTION

#+ Get the data for the record type t_campaigngrid_mobile
#+
#+ @param pint_campaign_id campaign id
#+
#+ @returnType INTEGER, STRING, RECORD, RECORD
#+ @return     0|error, error message, t_campaigngrid_mobile business record
FUNCTION campaigngrid_get_data_by_key_mobile(pint_campaign_id)
  DEFINE
    pint_campaign_id LIKE campaigns.cmp_id,
    larec_campaignposttypes DYNAMIC ARRAY OF RECORD LIKE campaignposttypes.*,
    larec_photos DYNAMIC ARRAY OF RECORD LIKE campaignphotos.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_ui_campaign t_campaigngrid_mobile,
    lrec_db_campaign RECORD LIKE campaigns.*,
    lrec_pic RECORD LIKE pics.*,
    lrec_pic_tmp RECORD LIKE pics.*,
    lint_id1 LIKE pics.pic_id,
    l_pic1 LIKE pics.pic_value,
    lint_id2 LIKE pics.pic_id,
    l_pic2 LIKE pics.pic_value,
    lint_id3 LIKE pics.pic_id,
    l_pic3 LIKE pics.pic_value,
    lstr_sql STRING,
    lrec_posttype RECORD LIKE posttypes.*,
    lrec_campaignposttype RECORD LIKE campaignposttypes.*,
    larec_tags DYNAMIC ARRAY OF RECORD LIKE tags.*,
    lrec_tag RECORD LIKE tags.*,
    i INTEGER,
    lstr_duration LIKE postdurations.pstdr_name,
    lrec_campaignuser RECORD LIKE campaignuserlist.*

  INITIALIZE lrec_ui_campaign.* TO NULL
  INITIALIZE lrec_db_campaign.* TO NULL
  --get campaign data
  LET lstr_sql = "SELECT campaigns.*, postdurations.pstdr_name"
    ," FROM campaigns, OUTER postdurations"
    ,SFMT(" WHERE campaigns.cmp_id = %1", pint_campaign_id)
    ," AND campaigns.cmp_postduration_id = postdurations.pstdr_id"
  TRY
    PREPARE p_campaigngrid_get_data_by_key_mobile FROM lstr_sql
    EXECUTE p_campaigngrid_get_data_by_key_mobile
      INTO lrec_campaign.*, lstr_duration
      CALL core_db.pics_select_row(lrec_campaign.cmp_pic_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_pic.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
      END IF
    FREE p_campaignlist_get_data_by_key_mobile
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END TRY

  CALL larec_campaignposttypes.clear()
  --get campaign post types
  LET lstr_sql = "SELECT campaignposttypes.*, posttypes.* FROM campaignposttypes, posttypes"
    ,SFMT(" WHERE campaignposttypes.cmppst_campaign_id = %1", pint_campaign_id)
    ," AND campaignposttypes.cmppst_posttype_id = posttypes.pstt_id"
    ," ORDER BY posttypes.pstt_uiorder"
  TRY
    DECLARE c_campaigngrid_get_data_by_key_mobile2 CURSOR FROM lstr_sql
    FOREACH c_campaigngrid_get_data_by_key_mobile2
      INTO lrec_campaignposttype.*, lrec_posttype.*
      LET larec_campaignposttypes[larec_campaignposttypes.getLength() + 1].* = lrec_campaignposttype.*
    END FOREACH
    FREE c_campaigngrid_get_data_by_key_mobile2
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END TRY

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
  CALL larec_tags.clear()
  LET lstr_sql = "SELECT tags.* FROM campaigntags, tags"
    ,SFMT(" WHERE campaigntags.cmptg_campaign_id = %1", pint_campaign_id)
    ," AND campaigntags.cmptg_tag_id = tags.tag_id"
    ," ORDER BY tags.tag_type_id, campaigntags.cmptg_uiorder"
  TRY
    DECLARE c_campaigngrid_get_data_by_key_mobile3 CURSOR FROM lstr_sql
    FOREACH c_campaigngrid_get_data_by_key_mobile3
      INTO lrec_tag.*
      LET larec_tags[larec_tags.getLength() + 1].* = lrec_tag.*
    END FOREACH
    FREE c_campaigngrid_get_data_by_key_mobile3
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    CALL larec_tags.clear()
    RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
  END TRY

  LET lrec_ui_campaign.campaign.* = lrec_campaign.*
  LET lrec_ui_campaign.pic_value = lrec_pic.pic_value
  LET lrec_ui_campaign.campaign_posttypes = campaignposttypes.serialize_campaignposttypes(larec_campaignposttypes)
  LET lrec_ui_campaign.pic_id1 = lint_id1
  LET lrec_ui_campaign.pic_value1 = l_pic1
  LET lrec_ui_campaign.pic_id2 = lint_id2
  LET lrec_ui_campaign.pic_value2 = l_pic2
  LET lrec_ui_campaign.pic_id3 = lint_id3
  LET lrec_ui_campaign.pic_value3 = l_pic3
  LET lrec_ui_campaign.instagram_hashtag = string.serialize_tags(larec_tags, C_TAGTYPE_HASHTAG)
  LET lrec_ui_campaign.instagram_usertag = string.serialize_tags(larec_tags, C_TAGTYPE_USERTAG)
  LET lrec_ui_campaign.crr_symbol1 = core_db.currency_get_symbol(lrec_campaign.cmp_currency_id)
  LET lrec_ui_campaign.poststarttime = string.get_posttime_string(lrec_campaign.cmp_post_time_starttime)
  LET lrec_ui_campaign.postendtime = string.get_posttime_string(lrec_campaign.cmp_post_time_endtime)
  LET lrec_ui_campaign.postduration = lstr_duration

  CALL core_db.campaignuserlist_select_row_by_campaign_and_user(pint_campaign_id, setup.g_loggedin_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
  IF lint_ret == 0 THEN
    LET lrec_ui_campaign.cmpusrl_usertotalprice = NVL(lrec_campaignuser.cmpusrl_userwantedprice, lrec_campaignuser.cmpusrl_usertotalprice)
    LET lrec_ui_campaign.curcost = core_db.currency_get_symbol(lrec_campaign.cmp_currency_id)
  END IF
  LET lrec_db_campaign.* = lrec_campaign.*
  RETURN lint_ret, lstr_msg, lrec_ui_campaign.*, lrec_db_campaign.*
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaigngrid_ui_set_action_state_mobile(p_dialog ui.DIALOG)
  DEFINE
    lbool_allow_apply BOOLEAN,
    lbool_allow_confirmproductreception BOOLEAN,
    lbool_allow_editposts BOOLEAN
  LET lbool_allow_apply = campaign_allow_apply(mrec_campaigngrid_mobile.campaign.cmp_id, mrec_campaigngrid_mobile.campaign.cmp_campaignstatus_id, setup.g_loggedin_id)
  LET lbool_allow_confirmproductreception = campaign_allow_confirmproductreception(mrec_campaigngrid_mobile.campaign.*, setup.g_loggedin_id)
  LET lbool_allow_editposts = campaign_allow_influencer_editposts(mrec_campaigngrid_mobile.campaign.*, setup.g_loggedin_id)
  --IF lbool_allow_apply THEN
    --CALL core_ui.ui_hideOrShowFieldOnCurrentForm("campaignuserlist.cmpusrl_usertotalprice",True)
    --CALL core_ui.ui_hideOrShowFieldOnCurrentForm("curcost",True)
    --CALL core_ui.ui_hideOrShowFieldOnCurrentForm("pic_usertotalprice",False)
  --ELSE
    --CALL core_ui.ui_hideOrShowFieldOnCurrentForm("campaignuserlist.cmpusrl_usertotalprice",False)
    --CALL core_ui.ui_hideOrShowFieldOnCurrentForm("curcost",False)
    --CALL core_ui.ui_hideOrShowFieldOnCurrentForm("pic_usertotalprice",True)
  --END IF
  CALL p_dialog.setActionActive("apply", lbool_allow_apply)
  CALL core_ui.ui_set_node_attribute("Button","name","apply","hidden", NOT lbool_allow_apply)
  CALL p_dialog.setActionActive("confirmreception", lbool_allow_confirmproductreception)
  CALL core_ui.ui_set_node_attribute("Button","name","confirmreception","hidden", NOT lbool_allow_confirmproductreception)
  CALL p_dialog.setActionActive("editposts", lbool_allow_editposts)
  CALL core_ui.ui_set_node_attribute("Button","name","editposts","hidden", NOT lbool_allow_editposts)
END FUNCTION

#+ Checks if a campaign can be applied by an influencer
#+
#+ @param pint_campaign_id campaign id
#+ @param pint_campaignstatus_id campaign status id
#+ @param pint_usr_id influencer id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_apply(pint_campaign_id LIKE campaigns.cmp_id, pint_campaignstatus_id LIKE campaigns.cmp_campaignstatus_id, pint_usr_id LIKE users.usr_id)
  DEFINE
    lrec_campaignuser RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING

  IF NOT setup.g_app_influencer THEN
    RETURN FALSE
  END IF
  IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
    CALL core_db.campaignuserlist_select_row_by_campaign_and_user(pint_campaign_id, pint_usr_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
    CASE lint_ret
      WHEN 0
        --can not view campaign
        IF lrec_campaignuser.cmpusrl_visibilitydate > TODAY THEN
          RETURN FALSE
        END IF
        IF lrec_campaignuser.cmpusrl_selectionstartdate > TODAY THEN
          RETURN FALSE
        END IF
        IF lrec_campaignuser.cmpusrl_selectionenddate < TODAY THEN
          RETURN FALSE
        END IF
        --can not apply to a campaign we already answered apply/reject
        IF lrec_campaignuser.cmpusrl_isacceptbyuser IS NOT NULL THEN
          RETURN FALSE
        END IF
        RETURN TRUE
      WHEN NOTFOUND
        RETURN FALSE
      OTHERWISE
        RETURN FALSE
    END CASE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if an influencer can confirm the reception of a product for a given campaign
#+
#+ @param prec_campaign campaign record
#+ @param pint_usr_id influencer id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_confirmproductreception(prec_campaign RECORD LIKE campaigns.*, pint_usr_id LIKE users.usr_id)
  DEFINE
    lrec_campaignuser RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING

  IF NOT setup.g_app_influencer THEN
    RETURN FALSE
  END IF
  IF prec_campaign.cmp_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
    IF prec_campaign.cmp_isproductneeded == 1 THEN
      CALL core_db.campaignuserlist_select_row_by_campaign_and_user(prec_campaign.cmp_id, pint_usr_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
      IF lint_ret == 0 THEN
        IF lrec_campaignuser.cmpusrl_isacceptedbybrand == 1
          AND (lrec_campaignuser.cmpusrl_usergotproduct IS NULL OR lrec_campaignuser.cmpusrl_usergotproduct == 0)
        THEN
          RETURN TRUE
        END IF
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if an influencer can edit the post datafor a given campaign
#+
#+ @param prec_campaign campaign record
#+ @param pint_usr_id influencer id
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaign_allow_influencer_editposts(prec_campaign RECORD LIKE campaigns.*, pint_usr_id LIKE users.usr_id)
  DEFINE
    lrec_campaignuser RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING

  IF NOT setup.g_app_influencer THEN
    RETURN FALSE
  END IF
  IF prec_campaign.cmp_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
    CALL core_db.campaignuserlist_select_row_by_campaign_and_user(prec_campaign.cmp_id, pint_usr_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
    IF lint_ret == 0 THEN
      IF lrec_campaignuser.cmpusrl_isacceptedbybrand == 1 THEN
        --influencer can access to posts only if campaign does not need a product, or the product has already been received
        IF NOT prec_campaign.cmp_isproductneeded THEN
          RETURN TRUE
        END IF
        IF prec_campaign.cmp_isproductneeded AND lrec_campaignuser.cmpusrl_usergotproduct THEN
          RETURN TRUE
        END IF
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Confirm product reception for a influencer in a campaign
#+
#+ @param pint_campaign_id campaign id
#+ @param pint_usr_id influencer id
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignproductreception_open_form(pint_campaign_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id)
  DEFINE
    lrec_campaignuser RECORD LIKE campaignuserlist.*,
    lrec_campaignuser_db RECORD LIKE campaignuserlist.*,
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    l_dialogtouched BOOLEAN

  --todo : try dynamic dialog when more time...
  LET lint_action = C_APPACTION_UNDEFINED
  CALL core_db.campaignuserlist_select_row_by_campaign_and_user(pint_campaign_id, pint_usr_id , FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignuser.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  LET lrec_campaignuser_db.* = lrec_campaignuser.*
  OPEN WINDOW w_campaignproductreception_open_form WITH FORM "campaign_productreception_mobile"

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT lrec_campaignuser.* FROM scr_productreception_grid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION dialogtouched
      LET l_dialogtouched = TRUE
      CALL campaignproductreception_ui_set_action_state(DIALOG, l_dialogtouched)
    ON ACTION accept
      CALL campaignproductreception_process_data(lrec_campaignuser.*, lrec_campaignuser_db.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      LET lint_ret = 0
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION cancel
      LET lint_ret = 0
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    BEFORE DIALOG
      LET l_dialogtouched = FALSE
      CALL campaignproductreception_ui_set_action_state(DIALOG, l_dialogtouched)
  END DIALOG
  CLOSE WINDOW w_campaignproductreception_open_form
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignproductreception_ui_set_action_state(p_dialog, p_dialogtouched)
  DEFINE
    p_dialog ui.DIALOG,
    p_dialogtouched BOOLEAN
  CALL p_dialog.setActionActive("dialogtouched", NOT p_dialogtouched)
  CALL p_dialog.setActionHidden("dialogtouched", TRUE)
  CALL p_dialog.setActionActive("accept", p_dialogtouched)
  CALL p_dialog.setActionHidden("close", TRUE)
END FUNCTION

#+ Check business rules for campaign product reception
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignproductreception_validate_data(prec_campaignuser RECORD LIKE campaignuserlist.*)

  IF prec_campaignuser.cmpusrl_usergotproduct IS NULL OR prec_campaignuser.cmpusrl_usergotproduct == 0 THEN
    RETURN -1, %"Please indicate you have received the campaign product"
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Update a proposed user of a campaign proposal
#+
#+ @returnType INTEGER, STRING, INTEGER
#+ @return     0|error, error message, campaign user list id
FUNCTION campaignproductreception_process_data(prec_campaignuser RECORD LIKE campaignuserlist.*, prec_campaignuser_db RECORD LIKE campaignuserlist.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_status INTEGER

  CALL campaignproductreception_validate_data(prec_campaignuser.*)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL core_db.campaignuserlist_update_row(prec_campaignuser_db.*, prec_campaignuser.*)
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