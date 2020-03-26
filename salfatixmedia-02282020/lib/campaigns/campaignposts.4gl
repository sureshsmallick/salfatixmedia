IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL combobox
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL layout
IMPORT FGL notifications
IMPORT os
IMPORT xml
IMPORT FGL campaignposts_commons

SCHEMA salfatixmedia

CONSTANT C_POST_VIEWPOST STRING = "fa-eye"
CONSTANT C_POST_EDITPOST STRING = "fa-pencil"
CONSTANT C_POST_VIEWFILE STRING = "fa-arrow-circle-down"

TYPE
  t_campaignpost_list RECORD
    campaignpost RECORD LIKE campaignposts.*,
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    editpost STRING,
    viewpost STRING,
    viewscreenshotpost STRING,
    viewscreenshotstat STRING,
    acceptedbysalfatiximage STRING,
    acceptedbybrandimage STRING,
    ispublicimage STRING,
    viewfile STRING,
    pic_value LIKE pics.pic_value
  END RECORD
TYPE
  t_campaignpost_grid RECORD
    campaignpost RECORD LIKE campaignposts.*,
    user RECORD LIKE users.*,
    usr_instagram_profilepicture LIKE users.usr_instagram_profilepicture,
    ispublicimage STRING
  END RECORD

DEFINE --list data
  marec_campaignpostlist DYNAMIC ARRAY OF t_campaignpost_list
DEFINE --grid data
  mrec_campaignpostgrid t_campaignpost_grid

DEFINE
  mrec_campaign RECORD LIKE campaigns.*

#+ Fetch and display the list of posts for a campaign
#+
#+ @param pint_campaign_id Campaign Id (Required)
#+ @param pint_user_id Influencer Id or null
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id (ACCEPT|CANCEL|CUSTOMACTION
FUNCTION campaignpostlist_open_form_by_key(pint_campaign_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lint_action_tmp SMALLINT,
    i INTEGER,
    ff_formtitle STRING

  LET lint_action = C_APPACTION_CANCEL
  LET ff_formtitle = %"Posts for the campaign"
  CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
    RETURNING lint_ret, lstr_msg, mrec_campaign.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF
  CALL campaignpostlist_get_list(pint_campaign_id, pint_usr_id, marec_campaignpostlist)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg, lint_action
  END IF

  OPEN WINDOW w_campaignpostlist WITH FORM "campaignpost_list"
  CALL FGL_SETTITLE(ff_formtitle)
  DISPLAY ARRAY marec_campaignpostlist TO scr_campaignpost_list.*
    ATTRIBUTES(UNBUFFERED,ACCEPT=FALSE,CANCEL=FALSE)
    BEFORE DISPLAY
      DISPLAY BY NAME ff_formtitle
      CALL campaignpostlist_ui_set_action_state(DIALOG, TRUE)
    BEFORE ROW
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      CALL campaignpostlist_ui_set_action_state_by_post(DIALOG, i)
    ON ACTION editpost
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        INITIALIZE mrec_campaignpostgrid.* TO NULL
        LET mrec_campaignpostgrid.campaignpost.* = marec_campaignpostlist[i].campaignpost.*
        LET mrec_campaignpostgrid.user.* = marec_campaignpostlist[i].user.*
        LET mrec_campaignpostgrid.usr_instagram_profilepicture = marec_campaignpostlist[i].usr_instagram_profilepicture
        LET mrec_campaignpostgrid.ispublicimage = marec_campaignpostlist[i].ispublicimage
        CALL campaignpostgrid_input()
          RETURNING lint_ret, lint_action_tmp
        IF lint_ret == 0 THEN
          IF lint_action_tmp == C_APPACTION_ACCEPT THEN
            --refresh row and actions
            CALL campaignpostlist_get_row_by_key(marec_campaignpostlist[i].campaignpost.cmppost_id, marec_campaignpostlist, i)
              RETURNING lint_ret, lstr_msg
            CALL campaignpostlist_ui_set_action_state(DIALOG, FALSE)
          END IF
        END IF
      END IF
    ON ACTION viewpost
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        IF marec_campaignpostlist[i].campaignpost.cmppost_url IS NOT NULL THEN
          CALL core_ui.ui_launch_url(marec_campaignpostlist[i].campaignpost.cmppost_url)
        END IF
      END IF
    ON ACTION viewfile
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        IF marec_campaignpostlist[i].campaignpost.cmppost_filename IS NOT NULL THEN          
          CALL core_ui.ui_launch_url(ui.Interface.filenameToURI(campaignposts_commons.campaignpost_build_filepath(marec_campaignpostlist[i].campaignpost.cmppost_filename)))
        END IF
      END IF
    ON ACTION viewscreenshotpost
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        IF marec_campaignpostlist[i].campaignpost.cmppost_screenshot_post IS NOT NULL THEN
          CALL core_ui.ui_launch_url(marec_campaignpostlist[i].campaignpost.cmppost_screenshot_post)
        END IF
      END IF
    ON ACTION viewscreenshotstat
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        IF marec_campaignpostlist[i].campaignpost.cmppost_screenshot_stat IS NOT NULL THEN
          CALL core_ui.ui_launch_url(marec_campaignpostlist[i].campaignpost.cmppost_screenshot_stat)
        END IF
      END IF
    ON ACTION validatepost
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_SFMD_VALIDATE)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
      END IF
    ON ACTION rejectpost
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_SFMD_REJECT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
      END IF
    ON ACTION validatepostbybrand
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_BRAND_VALIDATE)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
      END IF
    ON ACTION rejectpostbybrand
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_BRAND_REJECT)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
      END IF
    ON ACTION verifiedpublic
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_SFMD_POSTISPUBLIC)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
      END IF
    ON ACTION reviewprivacy
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_SFMD_REVIEWPOSTPRIVACY)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
        IF core_ui.ui_message(%"Information",%"A notification has been sent to the influencer.","ok","ok","fa-check") THEN END IF
      END IF
    ON ACTION askpoststatistics
      LET i = DIALOG.getCurrentRow("scr_campaignpost_list")
      IF i > 0 THEN
        CALL campaignpostlist_process_data(DIALOG, i, C_APPACTION_CAMPAIGNPOST_STATISTICSREQUESTED)
          RETURNING lint_ret, lstr_msg
        IF lint_ret <> 0 THEN
          ERROR lstr_msg
          CONTINUE DISPLAY
        END IF
      END IF
    ON ACTION exportstatistics
      CALL campaignpostlist_export_statistics()
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DISPLAY
      END IF
    ON ACTION sendnotification
      CALL campaignpostlist_send_notification()
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DISPLAY
      END IF
      IF core_ui.ui_message(%"Information",%"A notification has been sent to the influencer.","ok","ok","fa-check") THEN END IF
    ON ACTION refresh
      CALL campaignpostlist_get_list(pint_campaign_id, pint_usr_id, marec_campaignpostlist)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DISPLAY
      END IF
      CALL campaignpostlist_ui_set_action_state(DIALOG, FALSE)
    ON ACTION backtocampaign
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DISPLAY
    ON ACTION customaction
      LET lint_ret = 0
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      EXIT DISPLAY
  END DISPLAY
  CLOSE WINDOW w_campaignpostlist
  RETURN lint_ret, lstr_msg, lint_action
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+ @param pbool_beforedialog TRUE if DIALOG is initialized
#+
FUNCTION campaignpostlist_ui_set_action_state(p_dialog ui.DIALOG, pbool_beforedialog BOOLEAN)
  DEFINE
    lbool_can_see_statistics BOOLEAN,
    lbool_allow_export_statistics BOOLEAN,
    lbool_allow_send_notification BOOLEAN,
    i INTEGER

  LET lbool_can_see_statistics = FALSE
  LET lbool_allow_export_statistics = FALSE
  LET lbool_allow_send_notification = FALSE

  IF pbool_beforedialog THEN
    CALL posttype_combobox_initializer()
    CALL core_ui.ui_set_node_attribute("Label","name","label_validatepost","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Button","name","validatepost","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Label","name","label_rejectpost","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Button","name","rejectpost","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Label","name","label_validatepostbybrand","hidden", NOT setup.g_app_brand)
    CALL core_ui.ui_set_node_attribute("Button","name","validatepostbybrand","hidden", NOT setup.g_app_brand)
    CALL core_ui.ui_set_node_attribute("Label","name","label_rejectpostbybrand","hidden", NOT setup.g_app_brand)
    CALL core_ui.ui_set_node_attribute("Button","name","rejectpostbybrand","hidden", NOT setup.g_app_brand)
    CALL core_ui.ui_set_node_attribute("Label","name","label_verifiedpublic","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Button","name","verifiedpublic","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Label","name","label_reviewprivacy","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Button","name","reviewprivacy","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Label","name","label_askpoststatistics","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Button","name","askpoststatistics","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Label","name","label_sendnotification","hidden", NOT setup.g_app_backoffice)
    CALL core_ui.ui_set_node_attribute("Button","name","sendnotification","hidden", NOT setup.g_app_backoffice)
    IF setup.g_app_brand THEN
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.editpost","hidden", "1")
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.acceptedbysalfatiximage","hidden", "1")
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.viewscreenshotpost","hidden", "1")
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignposts.cmppost_screenshot_post","hidden", "1")
      CALL core_ui.ui_set_node_attribute("TableColumn","name","formonly.viewscreenshotstat","hidden", "1")
      CALL core_ui.ui_set_node_attribute("TableColumn","name","campaignposts.cmppost_screenshot_stat","hidden", "1")
    END IF
  END IF

  LET lbool_allow_export_statistics = campaignpost_allow_export_statistics(mrec_campaign.cmp_id, mrec_campaign.cmp_campaignstatus_id)
  CALL p_dialog.setActionActive("exportstatistics",lbool_allow_export_statistics AND (marec_campaignpostlist.getLength()>0))

  LET lbool_allow_send_notification = campaignpost_allow_send_notification(mrec_campaign.cmp_campaignstatus_id)
  CALL p_dialog.setActionActive("sendnotification",lbool_allow_send_notification)

  LET i = p_dialog.getCurrentRow("scr_campaignpost_list")
  CALL campaignpostlist_ui_set_action_state_by_post(p_dialog, i)
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive for a post
#+
#+ @param p_dialog current DIALOG
#+ @param pint_index index of the current row
#+
FUNCTION campaignpostlist_ui_set_action_state_by_post(p_dialog ui.Dialog, i INTEGER)
  DEFINE
    lbool_allow_editpost BOOLEAN,
    lbool_allow_viewscreenshotpost BOOLEAN,
    lbool_allow_viewscreenshotstat BOOLEAN,
    lbool_allow_validatepost BOOLEAN,
    lbool_allow_rejectpost BOOLEAN,
    lbool_allow_validatepostbybrand BOOLEAN,
    lbool_allow_rejectpostbybrand BOOLEAN,
    lbool_allow_verifiedpublic BOOLEAN,
    lbool_allow_reviewprivacy BOOLEAN,
    lbool_allow_askpoststatistics BOOLEAN

  LET lbool_allow_editpost = IIF(i>0,campaignpost_allow_editpost(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_viewscreenshotpost = IIF(i>0,campaignpost_allow_viewscreenshotpost(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_viewscreenshotstat = IIF(i>0,campaignpost_allow_viewscreenshotstat(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_validatepost = IIF(i>0,campaignpost_allow_salfatix_validation(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_rejectpost = IIF(i>0,campaignpost_allow_salfatix_rejection(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_validatepostbybrand = IIF(i>0,campaignpost_allow_brand_validation(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_rejectpostbybrand = IIF(i>0,campaignpost_allow_brand_rejection(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_verifiedpublic = IIF(i>0,campaignpost_allow_verifiedpublic(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_reviewprivacy = IIF(i>0,campaignpost_allow_reviewprivacy(marec_campaignpostlist[i].*),FALSE)
  LET lbool_allow_askpoststatistics = IIF(i>0,campaignpost_allow_askpoststatistics(marec_campaignpostlist[i].*),FALSE)

  CALL p_dialog.setActionActive("editpost",lbool_allow_editpost AND (i>0))
  CALL p_dialog.setActionActive("viewpost", (i>0))
  CALL p_dialog.setActionActive("viewscreenshotpost",lbool_allow_viewscreenshotpost AND (i>0))
  CALL p_dialog.setActionActive("viewscreenshotstat",lbool_allow_viewscreenshotstat AND (i>0))
  CALL p_dialog.setActionActive("validatepost",lbool_allow_validatepost AND (i>0))
  CALL p_dialog.setActionActive("rejectpost",lbool_allow_rejectpost AND (i>0))
  CALL p_dialog.setActionActive("validatepostbybrand",lbool_allow_validatepostbybrand AND (i>0))
  CALL p_dialog.setActionActive("rejectpostbybrand",lbool_allow_rejectpostbybrand AND (i>0))
  CALL p_dialog.setActionActive("verifiedpublic",lbool_allow_verifiedpublic AND (i>0))
  CALL p_dialog.setActionActive("reviewprivacy",lbool_allow_reviewprivacy AND (i>0))
  CALL p_dialog.setActionActive("askpoststatistics",lbool_allow_askpoststatistics AND (i>0))
  CALL p_dialog.setActionActive("viewfile", (i>0))

END FUNCTION

#+ Get the list of posts for a campaign
#+
#+ @param pint_campaign_id current campaign
#+ @param parec_campaignpostlist output list of posts
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_get_list(pint_campaign_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id, parec_campaignpostlist DYNAMIC ARRAY OF t_campaignpost_list)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*,
    lrec_user RECORD LIKE users.*,
    lstr_sql STRING,
    i INTEGER

  CALL parec_campaignpostlist.clear()
  LET lstr_sql = "SELECT campaignposts.*, users.*"
    ," FROM campaignposts, users"
    ," WHERE campaignposts.cmppost_usr_id = users.usr_id"
    ,SFMT(" AND campaignposts.cmppost_campaign_id = %1", pint_campaign_id)
  IF pint_usr_id IS NOT NULL THEN
    LET lstr_sql = lstr_sql
      ,SFMT(" AND campaignposts.cmppost_usr_id = %1", pint_usr_id)
  END IF
  IF setup.g_app_brand THEN
    LET lstr_sql = lstr_sql
    ," AND campaignposts.cmppost_isacceptedbysalfatix = 1"
  END IF
  LET lstr_sql = lstr_sql
    ," ORDER BY campaignposts.cmppost_usr_id, campaignposts.cmppost_posttype_id, campaignposts.cmppost_postno, campaignposts.cmppost_uiorder"
  TRY
    DECLARE c_campaignpostlist_get_list CURSOR FROM lstr_sql
    FOREACH c_campaignpostlist_get_list
      INTO lrec_campaignpost.*, lrec_user.*
      LET i = i + 1
      CALL _fill_up_array(parec_campaignpostlist, i, lrec_campaignpost.*, lrec_user.*)
    END FOREACH
    FREE c_campaignpostlist_get_list
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  RETURN 0, NULL
END FUNCTION

#+ Get a specifiy post for a campaign
#+
#+ @param pint_id current campaignpost id
#+ @param parec_campaignpostlist output list of posts
#+ @param pint_index row index in the list
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_get_row_by_key(pint_id LIKE campaignposts.cmppost_id, parec_campaignpostlist DYNAMIC ARRAY OF t_campaignpost_list, pint_index INTEGER)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*,
    lrec_user RECORD LIKE users.*,
    lstr_sql STRING

  LET lstr_sql = "SELECT campaignposts.*, users.*"
    ," FROM campaignposts, users"
    ," WHERE campaignposts.cmppost_usr_id = users.usr_id"
    ,SFMT(" AND campaignposts.cmppost_id = %1", pint_id)
  TRY
    PREPARE p_campaignpostlist_get_row_by_key FROM lstr_sql
    EXECUTE p_campaignpostlist_get_row_by_key
      INTO lrec_campaignpost.*, lrec_user.*
    IF SQLCA.SQLCODE <> 0 THEN
      RETURN SQLCA.SQLCODE, SQLERRMESSAGE
    END IF
    FREE p_campaignpostlist_get_row_by_key
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END TRY
  CALL _fill_up_array(parec_campaignpostlist, pint_index, lrec_campaignpost.*, lrec_user.*)
  RETURN 0, NULL
END FUNCTION

PRIVATE FUNCTION _fill_up_array(parec_campaignpostlist, pint_index, prec_campaignpost, prec_user)
  DEFINE
    parec_campaignpostlist DYNAMIC ARRAY OF t_campaignpost_list,
    pint_index INTEGER,
    prec_campaignpost RECORD LIKE campaignposts.*,
    prec_user RECORD LIKE users.*,
    lbool_allow_editpost BOOLEAN,
    lbool_allow_viewscreenshotpost BOOLEAN,
    lbool_allow_viewscreenshotstat BOOLEAN,
    lbool_allow_see_statistics BOOLEAN

  INITIALIZE parec_campaignpostlist[pint_index].* TO NULL
  LET parec_campaignpostlist[pint_index].campaignpost.* = prec_campaignpost.*
  LET parec_campaignpostlist[pint_index].user.* = prec_user.*
  LET parec_campaignpostlist[pint_index].usr_instagram_profilepicture = _get_default_photo(prec_user.usr_instagram_profilepicture)
  LET parec_campaignpostlist[pint_index].ispublicimage = _get_image_for_publication(prec_campaignpost.cmppost_ispublic)
  LET parec_campaignpostlist[pint_index].pic_value = campaignposts_commons.campaignpost_load_image(prec_campaignpost.cmppost_filename, prec_campaignpost.cmppost_posttype_id)

  LET lbool_allow_editpost = campaignpost_allow_editpost(marec_campaignpostlist[pint_index].*)
  LET lbool_allow_viewscreenshotpost = campaignpost_allow_viewscreenshotpost(marec_campaignpostlist[pint_index].*)
  LET lbool_allow_viewscreenshotstat = campaignpost_allow_viewscreenshotstat(marec_campaignpostlist[pint_index].*)

  LET parec_campaignpostlist[pint_index].editpost = IIF(lbool_allow_editpost, C_POST_EDITPOST, NULL)
  LET parec_campaignpostlist[pint_index].viewpost = C_POST_VIEWPOST
  LET parec_campaignpostlist[pint_index].viewscreenshotpost = IIF(lbool_allow_viewscreenshotpost, C_POST_VIEWPOST, NULL)
  LET parec_campaignpostlist[pint_index].viewscreenshotstat = IIF(lbool_allow_viewscreenshotstat, C_POST_VIEWPOST, NULL)
  LET parec_campaignpostlist[pint_index].acceptedbysalfatiximage = _get_image_for_validation(prec_campaignpost.cmppost_isacceptedbysalfatix)
  LET parec_campaignpostlist[pint_index].acceptedbybrandimage = _get_image_for_validation(prec_campaignpost.cmppost_isacceptedbybrand)
  LET parec_campaignpostlist[pint_index].ispublicimage = _get_image_for_publication(prec_campaignpost.cmppost_ispublic)
  LET parec_campaignpostlist[pint_index].viewfile = IIF(prec_campaignpost.cmppost_filename IS NOT NULL, C_POST_VIEWFILE, NULL)

  LET lbool_allow_see_statistics = campaignpost_can_see_statistics(marec_campaignpostlist[pint_index].*)
  IF NOT lbool_allow_see_statistics THEN
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_youtube_viewcount TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_youtube_likecount TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_youtube_dislikecount TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_youtube_favoritecount TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_youtube_commentcount TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_likes TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_comments TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_saved TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_profilevisits TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_follows TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_websiteclicks TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_discovery TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_reach TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_ig_impressions TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_impressions TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_reach TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_tapsforward TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_tapsback TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_replies TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_swipeaway TO NULL
    INITIALIZE parec_campaignpostlist[pint_index].campaignpost.cmppost_instastory_exists TO NULL
  END IF

END FUNCTION

PRIVATE FUNCTION _get_image_for_validation(p_value SMALLINT)
  IF p_value == 0 THEN
    RETURN "fa-times-circle-red"
  END IF
  IF p_value == 1 THEN
    RETURN "fa-check-circle-green"
  END IF
  RETURN "fa-times-circle-grey"
END FUNCTION

PRIVATE FUNCTION _get_image_for_publication(p_value SMALLINT)
  IF p_value == C_POST_ISPUBLIC_YES THEN
    RETURN "fa-exclamation-orange"
  END IF
  IF p_value == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX THEN
    RETURN "fa-check-circle-green"
  END IF
  RETURN "fa-times-circle-grey"
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

#+ Process the data of business record fields (CRUD operations or UI operations)
#+
#+ @param p_dialog current DIALOG
#+ @param p_dialogtouched TRUE when dialog has been touched, FALSE otherwise
#+ @param pint_dialog_action dialog action which triggered the operation
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_process_data(p_dialog ui.DIALOG, pint_index INTEGER, pint_dialog_action SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*,
    lrec_db_campaignpost RECORD LIKE campaignposts.*,
    lint_status INTEGER,
    larec_ids DYNAMIC ARRAY OF INTEGER

  CALL core_db.campaignposts_select_row(marec_campaignpostlist[pint_index].campaignpost.cmppost_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignpost.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET lrec_db_campaignpost.* = lrec_campaignpost.*
  CASE pint_dialog_action
    WHEN C_APPACTION_CAMPAIGNPOST_SFMD_VALIDATE
      LET lrec_campaignpost.cmppost_isacceptedbysalfatix = 1
      INITIALIZE lrec_campaignpost.cmppost_isacceptedbybrand TO NULL
    WHEN C_APPACTION_CAMPAIGNPOST_SFMD_REJECT
      LET lrec_campaignpost.cmppost_isacceptedbysalfatix = 0
      INITIALIZE lrec_campaignpost.cmppost_isacceptedbybrand TO NULL
    WHEN C_APPACTION_CAMPAIGNPOST_BRAND_VALIDATE
      LET lrec_campaignpost.cmppost_isacceptedbybrand = 1
    WHEN C_APPACTION_CAMPAIGNPOST_BRAND_REJECT
      LET lrec_campaignpost.cmppost_isacceptedbybrand = 0
    WHEN C_APPACTION_CAMPAIGNPOST_SFMD_POSTISPUBLIC
      LET lrec_campaignpost.cmppost_ispublic = C_POST_ISPUBLIC_VERIFIEDBYSALFATIX
    WHEN C_APPACTION_CAMPAIGNPOST_SFMD_REVIEWPOSTPRIVACY
      LET lrec_campaignpost.cmppost_ispublic = C_POST_ISPUBLIC_NO
    WHEN C_APPACTION_CAMPAIGNPOST_STATISTICSREQUESTED
    OTHERWISE --do nothing
  END CASE
  --update campaign post into database
  CALL core_db.campaignposts_update_row(lrec_db_campaignpost.*, lrec_campaignpost.*, CURRENT)
    RETURNING lint_ret, lstr_msg
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END IF
  IF lint_ret == 0 THEN
    CASE --handle notifications
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_SFMD_VALIDATE
        CALL notifications.sendmail_brand_check_campaign_post(mrec_campaign.cmp_id)
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_SFMD_REJECT
        CALL notifications.notif_influencers_post_has_been_rejected(mrec_campaign.cmp_id, FALSE, marec_campaignpostlist[pint_index].campaignpost.cmppost_id)
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_BRAND_VALIDATE
        CALL notifications.notif_influencers_post_must_be_set_public(mrec_campaign.cmp_id, marec_campaignpostlist[pint_index].campaignpost.cmppost_id)
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_BRAND_REJECT
        CALL notifications.notif_influencers_post_has_been_rejected(mrec_campaign.cmp_id, TRUE, marec_campaignpostlist[pint_index].campaignpost.cmppost_id)
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_SFMD_POSTISPUBLIC
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_SFMD_REVIEWPOSTPRIVACY
        CALL notifications.notif_influencers_post_must_be_set_public(mrec_campaign.cmp_id, marec_campaignpostlist[pint_index].campaignpost.cmppost_id)
      WHEN pint_dialog_action == C_APPACTION_CAMPAIGNPOST_STATISTICSREQUESTED
        LET larec_ids[1] = marec_campaignpostlist[pint_index].campaignpost.cmppost_usr_id
        CALL notifications.notif_influencers_to_get_post_statistics(larec_ids, mrec_campaign.cmp_id)
          RETURNING lint_ret, lstr_msg
    END CASE
    CALL campaignpostlist_get_row_by_key(marec_campaignpostlist[pint_index].campaignpost.cmppost_id, marec_campaignpostlist, pint_index)
      RETURNING lint_ret, lstr_msg
    CALL campaignpostlist_ui_set_action_state(p_dialog, FALSE)
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Update proposed user of a campaign proposal
#+
#+ @param prec_proposedusergrid proposed user
#+ @param pint_dialog_state dialog state
#+
#+ @returnType INTEGER, SMALLINT
#+ @return     0|error, next performed action id
FUNCTION campaignpostgrid_input()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    ff_formtitle STRING,
    lrec_db_campaignpost RECORD LIKE campaignposts.*

  LET lint_action = C_APPACTION_CANCEL
  LET ff_formtitle = %"Edit post"
  CALL FGL_SETTITLE(ff_formtitle)

  LET lrec_db_campaignpost.* = mrec_campaignpostgrid.campaignpost.*
  OPEN WINDOW w_campaignpostgrid WITH FORM "campaignpost_grid"
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT mrec_campaignpostgrid.* FROM scr_campaignpostgrid.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION save
      CALL campaignpostgrid_validate_data(mrec_campaignpostgrid.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      --call update
      CALL campaignposts_update_into_dabatase(lrec_db_campaignpost.*, mrec_campaignpostgrid.campaignpost.*)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        ERROR lstr_msg
        CONTINUE DIALOG
      END IF
      LET lint_action = C_APPACTION_ACCEPT
      EXIT DIALOG
    ON ACTION close
      LET lint_action = C_APPACTION_CANCEL
      EXIT DIALOG
    BEFORE DIALOG
      CALL campaignpostgrid_ui_set_action_state(mrec_campaignpostgrid.campaignpost.*, DIALOG)
  END DIALOG
  CLOSE WINDOW w_campaignpostgrid
  RETURN lint_ret, lint_action
END FUNCTION

#+ Check business rules of a campaign proposed user
#+
#+ @param prec_proposeduser proposed user record
#+
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
FUNCTION campaignpostgrid_validate_data(prec_campaingpostgrid)
  DEFINE
    prec_campaingpostgrid t_campaignpost_grid

  IF prec_campaingpostgrid.campaignpost.cmppost_id IS NULL THEN
    RETURN -1, %"Post missing"
  END IF
  IF prec_campaingpostgrid.campaignpost.cmppost_campaign_id IS NULL THEN
    RETURN -1, %"Campaign missing"
  END IF
  IF prec_campaingpostgrid.campaignpost.cmppost_usr_id IS NULL THEN
    RETURN -1, %"Influencer missing"
  END IF
  IF prec_campaingpostgrid.campaignpost.cmppost_posttype_id IS NULL THEN
    RETURN -1, %"Post type missing"
  END IF

  RETURN 0, NULL
END FUNCTION

#+ Sets the state of the dialog actions to active or inactive
#+
#+ @param p_dialog current DIALOG
#+
FUNCTION campaignpostgrid_ui_set_action_state(prec_campaignpost RECORD LIKE campaignposts.*, p_dialog ui.Dialog)
  CALL layout.display_savebutton(TRUE)
  CALL posttype_combobox_initializer()
  CALL core_ui.ui_set_node_attribute("Group","name","group_youtube","hidden", NOT ((prec_campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX) AND (prec_campaignpost.cmppost_posttype_id==C_POSTTYPE_YOUTUBE)))
  CALL core_ui.ui_set_node_attribute("Group","name","group_ig","hidden", NOT ((prec_campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX) AND (prec_campaignpost.cmppost_posttype_id==C_POSTTYPE_INSTAGRAM_PUBLICATION)))
  CALL core_ui.ui_set_node_attribute("Group","name","group_instastory","hidden", NOT ((prec_campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX) AND (prec_campaignpost.cmppost_posttype_id==C_POSTTYPE_INSTAGRAM_INSTASTORY)))
END FUNCTION

#+ Update a campaign post into database
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignposts_update_into_dabatase(prec_campaignpost_db RECORD LIKE campaignposts.*, prec_campaignpost RECORD LIKE campaignposts.*)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*,
    lint_status INTEGER,
    l_timestamp LIKE campaignposts.cmppost_lastmetricsdate

  INITIALIZE lrec_campaignpost.* TO NULL
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  LET l_timestamp = CURRENT
  --update campaign post into database
  LET lrec_campaignpost.* = prec_campaignpost.*
  --in case the metrics have changed then update the post online date
  IF _metrics_have_changed(prec_campaignpost.*, prec_campaignpost_db.*) THEN
    LET lrec_campaignpost.cmppost_lastmetricsdate = l_timestamp
  END IF

  CALL core_db.campaignposts_update_row(prec_campaignpost_db.*, lrec_campaignpost.*, l_timestamp)
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

#+ Initializer of the post type combobox
#+
FUNCTION posttype_combobox_initializer()
  CALL combobox.posttype_initializer(ui.ComboBox.forName("campaignposts.cmppost_posttype_id"))
END FUNCTION

#+ Checks if a campaign post can be edited
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_editpost(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbybrand == 1 THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can view the screenshot of a post
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_viewscreenshotpost(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_screenshot_post IS NOT NULL THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can view the statistics of a post
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_viewscreenshotstat(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_screenshot_stat IS NOT NULL THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can validate a post
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_salfatix_validation(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbysalfatix IS NULL
      OR prec_campaignpostlist.campaignpost.cmppost_isacceptedbysalfatix==0 THEN --salfatix did not already validate the user
        RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can reject a post
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_salfatix_rejection(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbysalfatix IS NULL THEN
      RETURN TRUE
    END IF
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbysalfatix == 1
      AND prec_campaignpostlist.campaignpost.cmppost_isacceptedbybrand IS NULL
    THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can validate a post
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_brand_validation(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_brand THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbysalfatix == 1 THEN
      IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbybrand IS NULL THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand can reject a post
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_brand_rejection(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_brand THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbysalfatix == 1 THEN
      IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbybrand IS NULL THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one has verified the post is public when the influencer has confirmed it is public
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_verifiedpublic(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbybrand == 1 THEN
      IF prec_campaignpostlist.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_NO
        OR prec_campaignpostlist.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_YES
      THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can check the post is public
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_reviewprivacy(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_isacceptedbybrand == 1 THEN
      IF prec_campaignpostlist.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_NO
        OR prec_campaignpostlist.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_YES
      THEN
        RETURN TRUE
      END IF
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if one can set the post status to "statistics received"
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_askpoststatistics(prec_campaignpostlist t_campaignpost_list)
  IF setup.g_app_backoffice THEN
    IF prec_campaignpostlist.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX THEN
      RETURN TRUE
    END IF
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand or salatix user can see the statistics in the list of posts
#+
#+ @param prec_campaignpostlist selected post
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_can_see_statistics(prec_campaignpostlist t_campaignpost_list)
  IF NOT (setup.g_app_backoffice OR setup.g_app_brand) THEN
    RETURN FALSE
  END IF
  IF prec_campaignpostlist.campaignpost.cmppost_ispublic == C_POST_ISPUBLIC_VERIFIEDBYSALFATIX THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand or salatix user can export the statistics in the list of posts
#+
#+ @param pint_campaignpoststatus_id current campaign post status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_export_statistics(pint_campaign_id LIKE campaigns.cmp_id, pint_campaignstatus_id LIKE campaignstatus.cmpst_id)
  IF NOT (setup.g_app_backoffice OR setup.g_app_brand) THEN
    RETURN FALSE
  END IF
  IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED
   OR pint_campaignstatus_id == C_CAMPAIGNSTATUS_CLOSED
  THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Checks if a brand or salatix user can export the statistics in the list of posts
#+
#+ @param pint_campaignpoststatus_id current campaign post status
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if operation is allowed, FALSE otherwise
FUNCTION campaignpost_allow_send_notification(pint_campaignstatus_id LIKE campaignstatus.cmpst_id)
  IF NOT setup.g_app_backoffice THEN
    RETURN FALSE
  END IF
  IF pint_campaignstatus_id == C_CAMPAIGNSTATUS_PUBLISHED THEN
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Export the campaign post statistics
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_export_statistics()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i, s INTEGER,
    lstr_server_filename STRING,
    lstr_client_filename STRING,
    lrec_data RECORD ATTRIBUTE(XMLName="Post")
      number INTEGER ATTRIBUTE(XMLName="Number"),
      usr_instagram_username LIKE users.usr_instagram_username ATTRIBUTE(XMLName="InstagramAccount"),
      pstt_name LIKE posttypes.pstt_name ATTRIBUTE(XMLName="PostType"),
      cmppost_url LIKE campaignposts.cmppost_url ATTRIBUTE(XMLName="PostLink"),
	  cmppost_youtube_viewcount LIKE campaignposts.cmppost_youtube_viewcount ATTRIBUTE(XMLName="YoutubeViewCount", XMLNillable),
	  cmppost_youtube_likecount LIKE campaignposts.cmppost_youtube_likecount ATTRIBUTE(XMLName="YoutubeLikeCount", XMLNillable),
	  cmppost_youtube_dislikecount LIKE campaignposts.cmppost_youtube_dislikecount ATTRIBUTE(XMLName="YoutubeDislikeCount", XMLNillable),
	  cmppost_youtube_favoritecount LIKE campaignposts.cmppost_youtube_favoritecount ATTRIBUTE(XMLName="YoutubeFavoriteCount", XMLNillable),
	  cmppost_youtube_commentcount LIKE campaignposts.cmppost_youtube_commentcount ATTRIBUTE(XMLName="YoutubeCommentCount", XMLNillable),
	  cmppost_ig_likes LIKE campaignposts.cmppost_ig_likes ATTRIBUTE(XMLName="IGlikes", XMLNillable),
	  cmppost_ig_comments LIKE campaignposts.cmppost_ig_comments ATTRIBUTE(XMLName="IGcomments", XMLNillable),
	  cmppost_ig_saved LIKE campaignposts.cmppost_ig_saved ATTRIBUTE(XMLName="IGsaved", XMLNillable),
	  cmppost_ig_profilevisits LIKE campaignposts.cmppost_ig_profilevisits ATTRIBUTE(XMLName="IGprofileVisits", XMLNillable),
	  cmppost_ig_follows LIKE campaignposts.cmppost_ig_follows ATTRIBUTE(XMLName="IGfollows", XMLNillable),
	  cmppost_ig_websiteclicks LIKE campaignposts.cmppost_ig_websiteclicks ATTRIBUTE(XMLName="IGwebsiteClicks", XMLNillable),
	  cmppost_ig_discovery LIKE campaignposts.cmppost_ig_discovery ATTRIBUTE(XMLName="IGdiscovery", XMLNillable),
	  cmppost_ig_reach LIKE campaignposts.cmppost_ig_reach ATTRIBUTE(XMLName="IGreach", XMLNillable),
	  cmppost_ig_impressions LIKE campaignposts.cmppost_ig_impressions ATTRIBUTE(XMLName="IGimpressions", XMLNillable),
	  cmppost_instastory_impressions LIKE campaignposts.cmppost_instastory_impressions ATTRIBUTE(XMLName="InstastoryImpressions", XMLNillable),
	  cmppost_instastory_reach LIKE campaignposts.cmppost_instastory_reach ATTRIBUTE(XMLName="InstastoryReach", XMLNillable),
	  cmppost_instastory_tapsforward LIKE campaignposts.cmppost_instastory_tapsforward ATTRIBUTE(XMLName="InstastoryTapsForward", XMLNillable),
	  cmppost_instastory_tapsback LIKE campaignposts.cmppost_instastory_tapsback ATTRIBUTE(XMLName="InstastoryTapsBack", XMLNillable),
	  cmppost_instastory_replies LIKE campaignposts.cmppost_instastory_replies ATTRIBUTE(XMLName="InstastoryReplies", XMLNillable),
	  cmppost_instastory_swipeaway LIKE campaignposts.cmppost_instastory_swipeaway ATTRIBUTE(XMLName="InstastorySwipeAway", XMLNillable),
	  cmppost_instastory_exists LIKE campaignposts.cmppost_instastory_exists ATTRIBUTE(XMLName="InstastoryExists", XMLNillable)
    END RECORD,
    doc xml.DomDocument,
    node xml.DomNode,
    lrec_posttype RECORD LIKE posttypes.*

  LET s = marec_campaignpostlist.getLength()
  LET lstr_server_filename = os.Path.join(base.Application.getResourceEntry("salfatixmedia.export.tmpdir"), string.get_report_name("campaign",".xml"))
  LET doc = xml.DomDocument.Create()
  CALL doc.setFeature("format-pretty-print",TRUE)
  LET node = doc.createElement("Posts")
  FOR i = 1 TO marec_campaignpostlist.getLength()
    INITIALIZE lrec_data.* TO NULL
    LET lrec_data.number = i
    LET lrec_data.usr_instagram_username = marec_campaignpostlist[i].user.usr_instagram_username
    CALL core_db.posttype_select_row(marec_campaignpostlist[i].campaignpost.cmppost_posttype_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_posttype.*
    IF lint_ret <> 0 THEN EXIT FOR END IF
    LET lrec_data.pstt_name = lrec_posttype.pstt_name
    LET lrec_data.cmppost_url = marec_campaignpostlist[i].campaignpost.cmppost_url
    LET lrec_data.cmppost_youtube_viewcount = marec_campaignpostlist[i].campaignpost.cmppost_youtube_viewcount
    LET lrec_data.cmppost_youtube_likecount = marec_campaignpostlist[i].campaignpost.cmppost_youtube_likecount
    LET lrec_data.cmppost_youtube_dislikecount = marec_campaignpostlist[i].campaignpost.cmppost_youtube_dislikecount
    LET lrec_data.cmppost_youtube_favoritecount = marec_campaignpostlist[i].campaignpost.cmppost_youtube_favoritecount
    LET lrec_data.cmppost_youtube_commentcount = marec_campaignpostlist[i].campaignpost.cmppost_youtube_commentcount
    LET lrec_data.cmppost_ig_likes = marec_campaignpostlist[i].campaignpost.cmppost_ig_likes
    LET lrec_data.cmppost_ig_comments = marec_campaignpostlist[i].campaignpost.cmppost_ig_comments
    LET lrec_data.cmppost_ig_saved = marec_campaignpostlist[i].campaignpost.cmppost_ig_saved
    LET lrec_data.cmppost_ig_profilevisits = marec_campaignpostlist[i].campaignpost.cmppost_ig_profilevisits
    LET lrec_data.cmppost_ig_follows = marec_campaignpostlist[i].campaignpost.cmppost_ig_follows
    LET lrec_data.cmppost_ig_websiteclicks = marec_campaignpostlist[i].campaignpost.cmppost_ig_websiteclicks
    LET lrec_data.cmppost_ig_discovery = marec_campaignpostlist[i].campaignpost.cmppost_ig_discovery
    LET lrec_data.cmppost_ig_reach = marec_campaignpostlist[i].campaignpost.cmppost_ig_reach
    LET lrec_data.cmppost_ig_impressions = marec_campaignpostlist[i].campaignpost.cmppost_ig_impressions
    LET lrec_data.cmppost_instastory_impressions = marec_campaignpostlist[i].campaignpost.cmppost_instastory_impressions
    LET lrec_data.cmppost_instastory_reach = marec_campaignpostlist[i].campaignpost.cmppost_instastory_reach
    LET lrec_data.cmppost_instastory_tapsforward = marec_campaignpostlist[i].campaignpost.cmppost_instastory_tapsforward
    LET lrec_data.cmppost_instastory_tapsback = marec_campaignpostlist[i].campaignpost.cmppost_instastory_tapsback
    LET lrec_data.cmppost_instastory_replies = marec_campaignpostlist[i].campaignpost.cmppost_instastory_replies
    LET lrec_data.cmppost_instastory_swipeaway = marec_campaignpostlist[i].campaignpost.cmppost_instastory_swipeaway
    LET lrec_data.cmppost_instastory_exists = marec_campaignpostlist[i].campaignpost.cmppost_instastory_exists
    CALL xml.Serializer.VariableToDom(lrec_data,node)
  END FOR
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

#+ Send notification to the influencers that posts are awaited for the campaign
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION campaignpostlist_send_notification()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    larec_campaignusers DYNAMIC ARRAY OF RECORD LIKE campaignuserlist.*,
    larec_campaignposts DYNAMIC ARRAY OF RECORD LIKE campaignposts.*,
    i,j, nb_awaited_post INTEGER,
    larec_ids DYNAMIC ARRAY OF INTEGER,
    lbool_post_awaited BOOLEAN,
    l_dict DICTIONARY OF BOOLEAN,
    larec_tmp DYNAMIC ARRAY OF STRING

  --get number of awaited posts for the campaign
  --CALL core_db.get_campaign_number_of_awaited_post_per_influencer(mrec_campaign.cmp_id)
    --RETURNING lint_ret, lstr_msg, nb_awaited_post
  --IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
--
  --if nothing is awaited then return
  --IF nb_awaited_post == 0 THEN RETURN 0, NULL END IF
--
  --get list of influencers
--
  --CALL core_db.campaignuserlist_fetch_all_rows(SFMT("WHERE cmpusrl_campaign_id = %1 AND cmpusrl_isacceptedbybrand=1",mrec_campaign.cmp_id), NULL, larec_campaignusers)
    --RETURNING lint_ret, lstr_msg
  --IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
--
  --FOR i = 1 TO larec_campaignusers.getLength()
    --LET lbool_post_awaited = FALSE
    --CALL core_db.campaignposts_fetch_all_rows(SFMT("WHERE campaignposts.cmppost_campaign_id = %1 AND campaignposts.cmppost_usr_id = %2", mrec_campaign.cmp_id, larec_campaignusers[i].cmpusrl_user_id), NULL, larec_campaignposts)
      --RETURNING lint_ret, lstr_msg
    --IF lint_ret <> 0 THEN RETURN lint_ret, lstr_msg END IF
    --IF larec_campaignposts.getLength() == 0 THEN --there is no post for the influencer
      --LET lbool_post_awaited = TRUE
    --ELSE
      --IF nb_awaited_post > larec_campaignposts.getLength() THEN --there are not enough post done by the influencer
        --LET lbool_post_awaited = TRUE
      --ELSE
        --there are egal number of awaited post and received posts.
        --Check if some posts need to be reworked by the influencer
        --FOR j = 1 TO larec_campaignposts.getLength()
          --IF (larec_campaignposts[j].cmppost_isacceptedbysalfatix IS NOT NULL AND larec_campaignposts[j].cmppost_isacceptedbysalfatix == 0)
            --OR (larec_campaignposts[j].cmppost_isacceptedbybrand IS NOT NULL AND larec_campaignposts[j].cmppost_isacceptedbybrand == 0)
          --THEN
            --LET lbool_post_awaited = TRUE
            --EXIT FOR
          --END IF
        --END FOR
      --END IF
    --END IF
    --IF lbool_post_awaited THEN
      --LET larec_ids[larec_ids.getLength() + 1] = larec_campaignusers[i].cmpusrl_user_id
    --END IF
  --END FOR
  FOR i = 1 TO marec_campaignpostlist.getLength()
    LET l_dict[marec_campaignpostlist[i].campaignpost.cmppost_usr_id] = TRUE 
  END FOR
  LET larec_tmp = l_dict.getKeys()
  FOR i = 1 TO larec_tmp.getLength()
    LET larec_ids[i] = larec_tmp[i]
  END FOR
  IF lint_ret == 0 THEN
    CALL notifications.notif_influencers_posts_are_awaited(mrec_campaign.cmp_id, larec_ids)
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

PRIVATE FUNCTION _metrics_have_changed(prec_post RECORD LIKE campaignposts.*, prec_old_post RECORD LIKE campaignposts.*)
  IF _diff_integer(prec_post.cmppost_youtube_viewcount, prec_old_post.cmppost_youtube_viewcount) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_youtube_likecount, prec_old_post.cmppost_youtube_likecount) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_youtube_dislikecount, prec_old_post.cmppost_youtube_dislikecount) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_youtube_favoritecount, prec_old_post.cmppost_youtube_favoritecount) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_youtube_commentcount, prec_old_post.cmppost_youtube_commentcount) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_likes, prec_old_post.cmppost_ig_likes) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_comments, prec_old_post.cmppost_ig_comments) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_saved, prec_old_post.cmppost_ig_saved) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_profilevisits, prec_old_post.cmppost_ig_profilevisits) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_follows, prec_old_post.cmppost_ig_follows) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_websiteclicks, prec_old_post.cmppost_ig_websiteclicks) THEN RETURN TRUE END IF
  IF _diff_decimal(prec_post.cmppost_ig_discovery, prec_old_post.cmppost_ig_discovery) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_reach, prec_old_post.cmppost_ig_reach) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_ig_impressions, prec_old_post.cmppost_ig_impressions) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_impressions, prec_old_post.cmppost_instastory_impressions) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_reach, prec_old_post.cmppost_instastory_reach) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_tapsforward, prec_old_post.cmppost_instastory_tapsforward) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_tapsback, prec_old_post.cmppost_instastory_tapsback) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_replies, prec_old_post.cmppost_instastory_replies) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_swipeaway, prec_old_post.cmppost_instastory_swipeaway) THEN RETURN TRUE END IF
  IF _diff_integer(prec_post.cmppost_instastory_exists, prec_old_post.cmppost_instastory_exists) THEN RETURN TRUE END IF
  RETURN FALSE
END FUNCTION

FUNCTION _diff_integer(a INTEGER, b INTEGER)
  RETURN NOT ((a IS NULL AND b IS NULL) OR (a IS NOT NULL AND b IS NOT NULL AND a==b))
END FUNCTION

FUNCTION _diff_decimal(a DECIMAL(10,2), b DECIMAL(10,2))
  RETURN NOT ((a IS NULL AND b IS NULL) OR (a IS NOT NULL AND b IS NOT NULL AND a==b))
END FUNCTION
