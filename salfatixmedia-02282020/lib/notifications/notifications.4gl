IMPORT util
IMPORT FGL fgldbutl
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL string
IMPORT FGL setup
IMPORT FGL hash
IMPORT os

SCHEMA salfatixmedia

PRIVATE FUNCTION send_message_to(pint_message_id LIKE messages.msg_id, 
                                 pint_brand_id LIKE brands.brnd_id, 
                                 pint_user_id LIKE users.usr_id, 
                                 pint_bouser_id LIKE backofficeusers.bousr_id, 
                                 pint_campaign_id LIKE campaigns.cmp_id, 
                                 pint_send_to_usertype SMALLINT, 
                                 pbool_send_mobile_notification BOOLEAN)
  DEFINE
    lint_ret, lint_err INTEGER,
    lstr_msg STRING,
    lstr_message_lang LIKE messages.msg_lang,
    lrec_message RECORD LIKE messages.*,
    lrec_brand RECORD LIKE brands.*,
    lrec_campaign RECORD LIKE campaigns.*,
    lrec_user RECORD LIKE users.*,
    lrec_bouser RECORD LIKE backofficeusers.*,
    lstr_buffer base.StringBuffer,
    lstr_server_filename STRING,
    ch base.Channel,
    lstr_run_command STRING,
    lint_country_id LIKE countries.cntr_id,
    lrec_country RECORD LIKE countries.*,
    lstr_email_to STRING,
    lstr_email_basename STRING,
    lstr_tmp STRING,
    lcar_email_style LIKE users.usr_email_style

  IF pint_send_to_usertype <> C_USERTYPE_BRAND
    AND pint_send_to_usertype <> C_USERTYPE_INFLUENCER
    AND pint_send_to_usertype <> C_USERTYPE_SALFATIX
  THEN
    RETURN -1, %"Unknown user type"
  END IF

  INITIALIZE lrec_brand.* TO NULL
  IF pint_brand_id IS NOT NULL THEN
    CALL core_db.brands_select_row(pint_brand_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_brand.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lcar_email_style = lrec_brand.brnd_email_style
  END IF
  INITIALIZE lrec_user.* TO NULL
  IF pint_user_id IS NOT NULL THEN
    CALL core_db.users_select_row(pint_user_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_user.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lcar_email_style = lrec_user.usr_email_style
  END IF
  INITIALIZE lrec_bouser.* TO NULL
  IF pint_bouser_id IS NOT NULL THEN
    CALL core_db.backofficeusers_select_row(pint_bouser_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_bouser.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    LET lcar_email_style = lrec_bouser.bousr_email_style
  END IF
  IF pint_campaign_id IS NOT NULL THEN
    --if we have a campaign and we didn't pass a brand by argument, then we get brand informations from campaign
    CALL core_db.campaigns_select_row(pint_campaign_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_campaign.*
    IF lint_ret <> 0 THEN
      RETURN lint_ret, lstr_msg
    END IF
    IF pint_brand_id IS NULL THEN
      CALL core_db.brands_select_row(lrec_campaign.cmp_brand_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_brand.*
      IF lint_ret <> 0 THEN
        RETURN lint_ret, lstr_msg
      END IF
      LET lcar_email_style = lrec_brand.brnd_email_style
    END IF
  END IF
  #TODO: review the message language selection according to brand/influencer language?
  LET lstr_message_lang = "en"
  CASE pint_send_to_usertype
    WHEN C_USERTYPE_BRAND
      LET lint_country_id = lrec_brand.brnd_country_id
      LET lstr_email_to = lrec_brand.brnd_email
      LET lstr_email_basename = "mail_brand"
    WHEN C_USERTYPE_INFLUENCER
      LET lint_country_id = lrec_user.usr_country_id
      LET lstr_email_to = lrec_user.usr_email
      LET lstr_email_basename = "mail_influencer"
    WHEN C_USERTYPE_SALFATIX
      LET lint_country_id = lrec_bouser.bousr_country_id
      LET lstr_email_to = lrec_bouser.bousr_email
      LET lstr_email_basename = "mail_backofficeuser"
  END CASE
  CALL core_db.country_select_row(lint_country_id, FALSE)
    RETURNING lint_err, lstr_msg, lrec_country.*
  IF lint_err == 0 THEN
    IF lrec_country.cntr_name == "France" THEN
      LET lstr_message_lang = "fr"
    END IF
  END IF

  CALL core_db.messages_select_row(pint_message_id, lstr_message_lang, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_message.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF

  LET lstr_buffer = base.StringBuffer.create()
  CASE lcar_email_style
    WHEN C_EMAILSTYLE_HTML
      IF lrec_message.msg_htmlcontent IS NULL THEN
        CALL lstr_buffer.append(lrec_message.msg_textcontent)
        LET lcar_email_style = C_EMAILSTYLE_TEXT
      ELSE
        CALL lstr_buffer.append(lrec_message.msg_htmlcontent)
      END IF
    WHEN C_EMAILSTYLE_TEXT
      CALL lstr_buffer.append(lrec_message.msg_textcontent)
    OTHERWISE
      CALL lstr_buffer.append(lrec_message.msg_textcontent)
      LET lcar_email_style = C_EMAILSTYLE_TEXT
  END CASE
  IF lstr_buffer.getIndexOf("#BRAND_NAME#", 1) > 0 THEN
    CALL lstr_buffer.replace("#BRAND_NAME#", lrec_brand.brnd_name,0)
  END IF
  IF lstr_buffer.getIndexOf("#INFLUENCER_FIRSTNAME#", 1) > 0 THEN
    CALL lstr_buffer.replace("#INFLUENCER_FIRSTNAME#", lrec_user.usr_firstname,0)
  END IF
  IF lstr_buffer.getIndexOf("#CAMPAIGN_NAME#", 1) > 0 THEN
    CALL lstr_buffer.replace("#CAMPAIGN_NAME#", lrec_campaign.cmp_title,0)
  END IF
  IF lstr_buffer.getIndexOf("#LINK_EMAIL_VALIDATION#", 1) > 0 THEN
    LET lstr_tmp = base.Application.getResourceEntry("salfatixmedia.link.emailvalidation")
    CASE pint_send_to_usertype
      WHEN C_USERTYPE_BRAND
        CALL lstr_buffer.replace("#LINK_EMAIL_VALIDATION#", _build_email_link(lstr_tmp, pint_brand_id, pint_send_to_usertype),0)
      WHEN C_USERTYPE_INFLUENCER
        CALL lstr_buffer.replace("#LINK_EMAIL_VALIDATION#", _build_email_link(lstr_tmp, pint_user_id, pint_send_to_usertype),0)
      WHEN C_USERTYPE_SALFATIX
        CALL lstr_buffer.replace("#LINK_EMAIL_VALIDATION#", _build_email_link(lstr_tmp, pint_bouser_id, pint_send_to_usertype),0)
    END CASE
  END IF
  IF lstr_buffer.getIndexOf("#SALFATIXMEDIA_WWW#", 1) > 0 THEN
    CALL lstr_buffer.replace("#SALFATIXMEDIA_WWW#", base.Application.getResourceEntry("salfatixmedia.www.url"),0)
  END IF
  IF lstr_buffer.getIndexOf("#SALFATIXMEDIA_FACEBOOK#", 1) > 0 THEN
    CALL lstr_buffer.replace("#SALFATIXMEDIA_FACEBOOK#", base.Application.getResourceEntry("salfatixmedia.account.facebook"),0)
  END IF
  IF lstr_buffer.getIndexOf("#LINK_SIGNATURE_LOGO#", 1) > 0 THEN
    CALL lstr_buffer.replace("#LINK_SIGNATURE_LOGO#", base.Application.getResourceEntry("salfatixmedia.logo.url"),0)
  END IF
  IF lstr_buffer.getIndexOf("#SALFATIXMEDIA_INSTAGRAM#", 1) > 0 THEN
    CALL lstr_buffer.replace("#SALFATIXMEDIA_INSTAGRAM#", base.Application.getResourceEntry("salfatixmedia.account.instagram"),0)
  END IF
  IF lstr_buffer.getIndexOf("#LINK_RESET_PASSWORD#", 1) > 0 THEN
    LET lstr_tmp = base.Application.getResourceEntry("salfatixmedia.link.resetpassword")
    CASE pint_send_to_usertype
      WHEN C_USERTYPE_BRAND
        CALL lstr_buffer.replace("#LINK_RESET_PASSWORD#", _build_email_link(lstr_tmp, pint_brand_id, pint_send_to_usertype),0)
      WHEN C_USERTYPE_INFLUENCER
        CALL lstr_buffer.replace("#LINK_RESET_PASSWORD#", _build_email_link(lstr_tmp, pint_user_id, pint_send_to_usertype),0)
      WHEN C_USERTYPE_SALFATIX
        CALL lstr_buffer.replace("#LINK_RESET_PASSWORD#", _build_email_link(lstr_tmp, pint_bouser_id, pint_send_to_usertype),0)
    END CASE
  END IF

  IF pbool_send_mobile_notification THEN
    --we send an email to the influencer in case he does not want to get notifications on his device
    IF lrec_user.usr_mobile_notifications == 0 THEN
      LET pbool_send_mobile_notification = FALSE
    END IF
  END IF
  --TODO : remove the below line as we currently force email instead of notifications
  LET pbool_send_mobile_notification = FALSE

  IF NOT pbool_send_mobile_notification THEN
    LET lstr_server_filename = os.Path.join(base.Application.getResourceEntry("salfatixmedia.email.dir"), string.get_report_name(lstr_email_basename,".txt"))
    LET ch = base.Channel.create()
    CALL ch.openFile(lstr_server_filename,"w")
    CALL ch.writeLine(SFMT("From: %1",base.Application.getResourceEntry("salfatixmedia.email.sender")))
    CALL ch.writeLine(SFMT("To: %1",lstr_email_to))
    CASE lcar_email_style
      WHEN C_EMAILSTYLE_HTML
        CALL ch.writeLine("Content-Type: text/html; charset=UTF-8")
        CALL ch.writeLine(SFMT("Subject: %1",lrec_message.msg_htmltitle))
      WHEN C_EMAILSTYLE_TEXT
        CALL ch.writeLine("Content-Type: text/plain; charset=UTF-8")
        CALL ch.writeLine(SFMT("Subject: %1",lrec_message.msg_texttitle))
    END CASE
    CALL ch.writeLine("")
    CALL ch.writeLine(lstr_buffer.toString())
    CALL ch.close()
    LET lstr_run_command = SFMT("%1 '%2'", base.Application.getResourceEntry("salfatixmedia.email.scriptpath"), lstr_server_filename)
    RUN lstr_run_command RETURNING lint_ret
    IF lint_ret <> 0 THEN --error occured within the script
      CALL setup.error_log(lint_ret, SFMT("send_message_to() - RUN %1 Failed", lstr_run_command))
      RETURN lint_ret, "Error with sendmail script"
    END IF
  ELSE
    --TODO send notification on user device
  END IF
  RETURN 0, NULL
END FUNCTION

FUNCTION sendmail_brand_reset_password(pint_id LIKE brands.brnd_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_RESET_PASSWORD, pint_id, NULL, NULL, NULL, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_reset_password(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_brand_creation(pint_id LIKE brands.brnd_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_BRAND_CREATION, pint_id, NULL, NULL, NULL, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_creation(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_brand_emailupdate(pint_id LIKE brands.brnd_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_BRAND_EMAILUPDATE, pint_id, NULL, NULL, NULL, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_emailupdate(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_brand_validated(pint_id LIKE brands.brnd_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_BRAND_VALIDATED, pint_id, NULL, NULL, NULL, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_validated(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_brand_rejected(pint_id LIKE brands.brnd_id, pint_old_accountstatus_id LIKE brands.brnd_accountstatus_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  --only send email when the account is incomplete and has been rejected
  IF pint_old_accountstatus_id <> C_ACCOUNTSTATUS_INCOMPLETE THEN RETURN END IF

  CALL send_message_to(C_MESSAGE_BRAND_REJECTED, pint_id, NULL, NULL, NULL, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_rejected(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

--send an email to the brand to inform he must review the campaign data
FUNCTION sendmail_brand_campaign_validated(pint_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  CALL send_message_to(C_MESSAGE_CAMPAIGN_VALIDATED, NULL, NULL, NULL, pint_id, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_campaign_validated(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

--send an email to the brand to inform he must review the campaign data
FUNCTION sendmail_brand_campaign_to_review(pint_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  CALL send_message_to(C_MESSAGE_BRAND_REVIEWCAMPAIGN, NULL, NULL, NULL, pint_id, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_campaign_to_review(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_brand_check_campaign_proposed_influencers(pint_id LIKE campaigns.cmp_id)
  --send an email to the brand to inform he must review the proposed influencer list for a campaign
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_BRAND_CHECKPROPOSEDINFLUENCER, NULL, NULL, NULL, pint_id, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_check_campaign_proposed_influencers(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_brand_check_campaign_post(pint_id LIKE campaigns.cmp_id)
  --send an email to the brand to inform he must validate/reject the received campaign posts
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_BRAND_CHECKCAMPAIGNPOSTS, NULL, NULL, NULL, pint_id, C_USERTYPE_BRAND, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_brand_check_campaign_post(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_influencer_reset_password(pint_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_RESET_PASSWORD, NULL, pint_id, NULL, NULL, C_USERTYPE_INFLUENCER, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_influencer_reset_password(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_influencer_creation(pint_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_INFLUENCER_CREATION, NULL, pint_id, NULL, NULL, C_USERTYPE_INFLUENCER, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_influencer_creation(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_influencer_emailupdate(pint_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_INFLUENCER_EMAILUPDATE, NULL, pint_id, NULL, NULL, C_USERTYPE_INFLUENCER, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_influencer_emailupdate(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_influencer_validated(pint_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_INFLUENCER_VALIDATED, NULL, pint_id, NULL, NULL, C_USERTYPE_INFLUENCER, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_influencer_validated(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_influencer_rejected(pint_id LIKE users.usr_id, pint_old_accountstatus_id LIKE users.usr_accountstatus_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  --only send email when the account is incomplete and has been rejected
  IF pint_old_accountstatus_id <> C_ACCOUNTSTATUS_INCOMPLETE THEN RETURN END IF
  CALL send_message_to(C_MESSAGE_INFLUENCER_REJECTED, NULL, pint_id, NULL, NULL, C_USERTYPE_INFLUENCER, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_influencer_rejected(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

FUNCTION sendmail_backofficeuser_reset_password(pint_id LIKE backofficeusers.bousr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_RESET_PASSWORD, NULL, NULL, pint_id, NULL, C_USERTYPE_SALFATIX, FALSE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("sendmail_backofficeuser_reset_password(%1) - %2 ", pint_id, lstr_msg))
  END IF
END FUNCTION

--send notification when influencer is negociating the price and SalfatixMedia rejected influencer's proposed price
FUNCTION notif_influencers_proposed_priced_rejected(pint_id LIKE users.usr_id, pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  CALL send_message_to(C_MESSAGE_CAMPAIGN_PRICENEGOCIATED, NULL, pint_id, NULL, pint_campaign_id, C_USERTYPE_INFLUENCER, TRUE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_proposed_priced_rejected_E1(%1,%3) - %2 ", pint_id, lstr_msg, pint_campaign_id))
  END IF

END FUNCTION

--send notif for accepted and rejected/not-selected influencer
FUNCTION notif_influencer_brand_decision(pint_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id, pbool_accepted BOOLEAN)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING

  --send notifications
  CALL send_message_to(IIF(pbool_accepted, C_MESSAGE_CAMPAIGN_INFLUENCERSELECTED, C_MESSAGE_CAMPAIGN_INFLUENCERREJECTED), NULL, pint_usr_id, NULL, pint_id, C_USERTYPE_INFLUENCER, TRUE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_brand_decision_for_proposal_E3(%1) - %3 - %2 ", pint_id, lstr_msg, pint_usr_id))
  END IF

END FUNCTION

FUNCTION notif_influencers_deal_has_started(pint_id LIKE campaigns.cmp_id, pint_usr_id LIKE users.usr_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING
  CALL send_message_to(C_MESSAGE_CAMPAIGN_HASSTARTED, NULL, pint_usr_id, NULL, pint_id, C_USERTYPE_INFLUENCER, TRUE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_deal_has_started_E1(%1) - %3 - %2 ", pint_id, lstr_msg, pint_usr_id))
  END IF

END FUNCTION

#+ Send notification to influencers who didn't send any posts or who didn't send all awaited posts for a campaign
#+
#+ @param p_ids list of influencers id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION notif_influencers_posts_are_awaited(pint_id LIKE campaigns.cmp_id, p_ids DYNAMIC ARRAY OF INTEGER)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    i INTEGER
  FOR i = 1 TO p_ids.getLength()
    CALL send_message_to(C_MESSAGE_CAMPAIGN_POSTAWAITED, NULL, p_ids[i], NULL, pint_id, C_USERTYPE_INFLUENCER, TRUE)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      CALL setup.error_log(lint_ret, SFMT("notif_influencers_posts_are_awaited(%1) - %3 - %2 ", pint_id, lstr_msg, p_ids[i]))
    END IF
  END FOR

END FUNCTION

FUNCTION notif_influencers_post_has_been_rejected(pint_id LIKE campaigns.cmp_id, pbool_rejected_by_brand BOOLEAN, pint_post_id LIKE campaignposts.cmppost_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*
  CALL core_db.campaignposts_select_row(pint_post_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignpost.*
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_post_has_been_rejected_E1(%1,%3) - %2 ", pint_id, lstr_msg, pint_post_id))
    RETURN
  END IF
  CALL send_message_to(C_MESSAGE_CAMPAIGN_POSTREJECTED, NULL, lrec_campaignpost.cmppost_usr_id, NULL, pint_id, C_USERTYPE_INFLUENCER, TRUE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_post_has_been_rejected_E2(%1,%3) - %4 - %2 ", pint_id, lstr_msg, pint_post_id, lrec_campaignpost.cmppost_usr_id))
  END IF

END FUNCTION

FUNCTION notif_influencers_post_must_be_set_public(pint_id LIKE campaigns.cmp_id, pint_post_id LIKE campaignposts.cmppost_id)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_campaignpost RECORD LIKE campaignposts.*
  CALL core_db.campaignposts_select_row(pint_post_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_campaignpost.*
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_post_must_be_set_public_E1(%1,%3) - %2 ", pint_id, lstr_msg, pint_post_id))
    RETURN
  END IF
  CALL send_message_to(C_MESSAGE_CAMPAIGN_POSTSETTOPUBLIC, NULL, lrec_campaignpost.cmppost_usr_id, NULL, pint_id, C_USERTYPE_INFLUENCER, TRUE)
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL setup.error_log(lint_ret, SFMT("notif_influencers_post_must_be_set_public_E2(%1,%3) - %4 - %2 ", pint_id, lstr_msg, pint_post_id, lrec_campaignpost.cmppost_usr_id))
  END IF
END FUNCTION

#+ Send notification to request statistics of posts done by the given influencer list
#+
#+ @param parec_data list of influencers id
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION notif_influencers_to_get_post_statistics(p_ids DYNAMIC ARRAY OF INTEGER, pint_campaign_id LIKE campaigns.cmp_id)
  DEFINE
    lint_ret, lint_err INTEGER,
    lstr_msg STRING,
    lint_status INTEGER,
    i,s INTEGER

  LET s = p_ids.getLength()
  IF s == 0 THEN
    RETURN -1, %"Can not request statistics from an empty list of influencers"
  END IF
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  FOR i = 1 TO s
    CALL send_message_to(C_MESSAGE_CAMPAIGN_STATISTICSAWAITED, NULL, p_ids[i], NULL, pint_campaign_id, C_USERTYPE_INFLUENCER, TRUE)
      RETURNING lint_err, lstr_msg
    IF lint_err <> 0 THEN
      CALL setup.error_log(lint_err, SFMT("notif_influencers_to_get_post_statistics_E1(%1,%3) - %2 ", pint_campaign_id, lstr_msg, p_ids[i]))
      CONTINUE FOR
    END IF
  END FOR
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Build the url to validate the email of the given brand/influencer/salfatix user
#+
#+ @param pint_url url of the application to run when clicking on the link
#+ @param pint_id brand/influencer/salfatix user id
#+ @param pint_usertype type of the user C_USERTYPE_BRAND|C_USERTYPE_INFLUENCER|C_USERTYPE_SALFATIX
#+
#+ @returnType STRING
#+ @return     email validation url
FUNCTION _build_email_link(pint_url STRING, pint_id INTEGER, pint_usertype INTEGER)
  DEFINE
    lint_time INTEGER,
    lstr_args STRING,
    lstr_signature STRING

  LET lint_time = util.Datetime.toSecondsSinceEpoch(CURRENT YEAR TO SECOND)
  LET lstr_args = SFMT("%4Arg%2=%1&Arg%3=%2&Arg%1=%3%4",pint_id, pint_usertype, lint_time, base.Application.getResourceEntry("salfatixmedia.link.secretkey"))
  LET lstr_signature = hash.compute_hash(lstr_args, "SHA512", FALSE)
  RETURN SFMT("%1?Arg=%2&Arg=%3&Arg=%4&Arg=%5", pint_url, pint_id, pint_usertype, lint_time, lstr_signature)
END FUNCTION