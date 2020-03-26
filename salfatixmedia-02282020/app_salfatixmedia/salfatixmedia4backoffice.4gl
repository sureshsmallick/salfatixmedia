IMPORT FGL setup
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_automaton
IMPORT FGL string
IMPORT FGL campaigns
IMPORT FGL brands
IMPORT FGL backofficeusers
IMPORT FGL backofficemainpanel
IMPORT FGL users
IMPORT FGL hash
IMPORT FGL passwords

SCHEMA salfatixmedia

TYPE
  t_credentials RECORD
    email STRING,
    password STRING
  END RECORD

MAIN
  DEFINE
    lint_ret INTEGER,
    lint_action SMALLINT,
    lint_bousr_id LIKE backofficeusers.bousr_id,
    lint_job_id INTEGER,
    lstr_where STRING

  OPTIONS
    INPUT WRAP
  WHENEVER ERROR CALL errormgt

  CALL setup.initialize("backoffice")

  LET lint_action = C_APPACTION_SIGNIN
  WHILE TRUE
    CASE lint_action
      WHEN C_APPACTION_SIGNIN
        LET lint_action = _credentials()
      WHEN C_APPACTION_BACKOFFICE_MAINPANEL
        CALL backofficemainpanel.mainpanel_open_form()
          RETURNING lint_ret, lint_action, lint_job_id
        IF lint_ret == 0 THEN
          CASE lint_action
            WHEN C_APPACTION_VIEWBRANDS
              CASE lint_job_id
                WHEN C_MAINPANEL_JOB_UNVALIDATEDBRAND
                  CALL brands.setBrandFormStyle("list")
                  CALL brands.brandlist_open_form(SFMT("brands.brnd_accountstatus_id = %1", C_ACCOUNTSTATUS_INCOMPLETE) , brandlist_get_default_sqlorderby(), %"Unvalidated brands")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_BRANDSWANTTOLEAVE
                  CALL brands.setBrandFormStyle("list")
                  CALL brands.brandlist_open_form(SFMT("brands.brnd_accountstatus_id = %1", C_ACCOUNTSTATUS_WANTTOLEAVE) , brandlist_get_default_sqlorderby(), %"Brands who want to close their account")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_LISTALL
                  CALL brands.setBrandFormStyle("list")
                  CALL brands.brandlist_open_form(NULL , brandlist_get_default_sqlorderby(), %"All brands")
                    RETURNING lint_ret, lint_action
              END CASE
            WHEN C_APPACTION_VIEWINFLUENCERS
              CASE lint_job_id
                WHEN C_MAINPANEL_JOB_UNVALIDATEDINFLUENCER
                  CALL users.userlist_open_form(SFMT("users.usr_accountstatus_id = %1", C_ACCOUNTSTATUS_INCOMPLETE) , userlist_get_default_sqlorderby(), %"Unvalidated influencers")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_UNVALIDATEDPOSTPRICES
                  CALL users.userlist_open_form("users.usr_id IN (SELECT DISTINCT usrpp_usr_id FROM userpostprices WHERE usrpp_isvalidatedbysalfatix=0)"
                    , userlist_get_default_sqlorderby(), %"Post price to validate for these influencers")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_LISTALL
                  CALL users.userlist_open_form(NULL , userlist_get_default_sqlorderby(), %"All influencers")
                    RETURNING lint_ret, lint_action
              END CASE
            WHEN C_APPACTION_VIEWCAMPAIGNS
              CASE lint_job_id
                WHEN C_MAINPANEL_JOB_UNSUBMITTEDCAMPAIGN
                  CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_campaignstatus_id IN (%1,%2)", C_CAMPAIGNSTATUS_CREATED, C_CAMPAIGNSTATUS_PENDING) , campaignlist_get_default_sqlorderby(), %"Campaigns under construction")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_UNVALIDATEDCAMPAIGN
                  CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_SUBMITTED) , campaignlist_get_default_sqlorderby(), %"Campaigns to validate")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_UNCOLLECTEDMONEY
                  CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_campaignstatus_id IN (%1,%2,%3) AND campaigns.cmp_deposit IS NULL", C_CAMPAIGNSTATUS_VALIDATED, C_CAMPAIGNSTATUS_PUBLISHED, C_CAMPAIGNSTATUS_CLOSED) , campaignlist_get_default_sqlorderby(), %"Campaigns where no money has been received yet")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_UNPAIDCAMPAIGN
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id IN (%1,%2,%3)", C_CAMPAIGNSTATUS_VALIDATED, C_CAMPAIGNSTATUS_PUBLISHED, C_CAMPAIGNSTATUS_CLOSED)
                    ," AND campaigns.cmp_deposit IS NOT NULL"
                    ," AND campaigns.cmp_deposit < "
                    ," (SELECT NVL(SUM(campaignuserlist.cmpusrl_salfatixtotalprice),0)"
                    ,"    FROM campaignuserlist"
                    ,"  WHERE cmpusrl_campaign_id = campaigns.cmp_id)"
                  CALL campaigns.campaignlist_open_form(lstr_where, campaignlist_get_default_sqlorderby(), %"Campaign(s) where the brand didn't fully pay you")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_UNPUBLISHEDCAMPAIGN
                  CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_VALIDATED) , campaignlist_get_default_sqlorderby(), %"Unpublished campaigns")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_PUBLISHEDCAMPAIGN
                  CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED) , campaignlist_get_default_sqlorderby(), %"Published campaigns")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_CLOSEDCAMPAIGN
                  CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_CLOSED) , campaignlist_get_default_sqlorderby(), %"Closed campaigns")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_WAITSALFATIXANSWER
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptbyuser = 1"
                    ," AND campaignuserlist.cmpusrl_userwantedprice IS NULL"
                    ," AND campaignuserlist.cmpusrl_isacceptedbysalfatix IS NULL)"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where influencers have applied and accepted the proposed remuneration")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_WAITSALFATIXNEWREMUNERATION
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptbyuser = 1"
                    ," AND campaignuserlist.cmpusrl_userwantedprice IS NOT NULL"
                    ," AND campaignuserlist.cmpusrl_isacceptedbysalfatix IS NULL)"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where influencers have applied and negociate the remuneration")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_WAITBRANDANSWER
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptedbysalfatix = 1"
                    ," AND campaignuserlist.cmpusrl_isacceptedbybrand IS NULL)"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where brand should accept or reject the influencers")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_INFLREJECTEDBYBRAND
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptedbysalfatix = 1"
                    ," AND campaignuserlist.cmpusrl_isacceptedbybrand = 0)"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where influencers have been rejected by brand")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_INFLVALIDATEDBYBRAND
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptedbybrand = 1)"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where influencers have been validated by brand")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_INFLUNPAID
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptedbybrand = 1"
                    ," AND campaignuserlist.cmpusrl_isuserpaid IS NULL)"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where you have to pay the influencers")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_INFLGOTPRODUCT
                  LET lstr_where = SFMT("campaigns.cmp_campaignstatus_id = %1", C_CAMPAIGNSTATUS_PUBLISHED)
                    ," AND campaigns.cmp_isproductneeded = 1"
                    ,"AND EXISTS (SELECT campaignuserlist.cmpusrl_campaign_id" 
                    ," FROM campaignuserlist "
                    ," WHERE campaignuserlist.cmpusrl_campaign_id == campaigns.cmp_id"
                    ," AND campaignuserlist.cmpusrl_isacceptedbybrand = 1"
                    ," AND (campaignuserlist.cmpusrl_usergotproduct IS NULL OR campaignuserlist.cmpusrl_usergotproduct = 0))"
                  CALL campaigns.campaignlist_open_form(lstr_where , campaignlist_get_default_sqlorderby(), %"Campaign(s) where influencer(s) did not acknowledge the reception of the product")
                    RETURNING lint_ret, lint_action
                WHEN C_MAINPANEL_JOB_LISTALL
                  CALL campaigns.campaignlist_open_form(NULL , campaignlist_get_default_sqlorderby(), %"All campaigns")
                    RETURNING lint_ret, lint_action
              END CASE
          END CASE
        END IF
      WHEN C_APPACTION_VIEWBRANDS
        CALL brands.setBrandFormStyle("list")
        CALL brands.brandlist_open_form(NULL, brandlist_get_default_sqlorderby(),NULL)
          RETURNING lint_ret, lint_action
      WHEN C_APPACTION_VIEWCAMPAIGNS
        CALL campaigns.campaignlist_open_form(NULL, campaignlist_get_default_sqlorderby(), NULL)
          RETURNING lint_ret, lint_action
      WHEN C_APPACTION_VIEWINFLUENCERS
        CALL users.userlist_open_form(NULL, userlist_get_default_sqlorderby(), NULL)
          RETURNING lint_ret, lint_action
      WHEN C_APPACTION_VIEWBOUSERS
        CALL backofficeusers.bouserlist_open_form(NULL, "backofficeusers.bousr_firstname asc",NULL)
          RETURNING lint_ret, lint_action
      WHEN C_APPACTION_EDITPROFILE
        CALL backofficeusers.bousergrid_open_form_by_key(setup.g_loggedin_id, C_APPSTATE_UPDATE)
          RETURNING lint_ret, lint_action, lint_bousr_id
      WHEN C_APPACTION_LOGOUT
        LET lint_action = _credentials()
      OTHERWISE
        EXIT WHILE
    END CASE
  END WHILE

END MAIN

#+ Handle the credentials window for a salfatix user
#+
#+ @returnType INTEGER, INTEGER
#+ @return     0|error, logged-in id
PRIVATE FUNCTION _credentials()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lrec_credential t_credentials,
    lrec_bousr RECORD LIKE backofficeusers.*,
    frontcall_return STRING,
    dev STRING

  CALL setup.initialize_login_data()
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_salfatix_credentials WITH FORM "salfatix_credentials"
  CALL FGL_SETTITLE(%"Sign in")
  INITIALIZE lrec_credential.* TO NULL
  IF base.Application.getArgumentCount() > 0 THEN
    LET dev = base.Application.getArgument(base.Application.getArgumentCount())
    IF dev.subString(1,3) = "dev" THEN
      LET lrec_credential.email = "admin@4js.com"
      LET lrec_credential.password = dev.subString(5,dev.getLength())
    END IF
  END IF
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT lrec_credential.* FROM scr_credentials.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION login ATTRIBUTES (ACCELERATOR="return")
      LET lrec_credential.email = string.trim(lrec_credential.email)
      IF lrec_credential.email IS NULL THEN
        ERROR %"Email required"
        NEXT FIELD email
        CONTINUE DIALOG
      END IF
      LET lrec_credential.password = string.trim(lrec_credential.password)
      IF lrec_credential.password IS NULL THEN
        ERROR %"Password required"
        NEXT FIELD password
        CONTINUE DIALOG
      END IF
      CALL core_db.backofficeusers_select_row_by_email(lrec_credential.email, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_bousr.*
      IF lint_ret <> 0 THEN
        ERROR %"Invalid credentials"
        NEXT FIELD email
        CONTINUE DIALOG
      END IF
      IF NOT hash.verify_hash(lrec_bousr.bousr_password, lrec_credential.password, "BCRYPT", FALSE) THEN
        ERROR %"Invalid credentials"
        NEXT FIELD password
        CONTINUE DIALOG
      END IF
      IF lrec_bousr.bousr_accountstatus_id <> C_ACCOUNTSTATUS_COMPLETED THEN
        ERROR %"Invalid account"
        NEXT FIELD CURRENT
        CONTINUE DIALOG
      END IF
      LET setup.g_loggedin_id = lrec_bousr.bousr_id
      LET setup.g_signin_method = C_SIGNIN_VIA_EMAIL
      CALL setup.refresh_loggedin_name()
      LET lint_action = C_APPACTION_BACKOFFICE_MAINPANEL
      EXIT DIALOG
    ON ACTION forgotpassword
      CALL passwords.forgot_password(C_USERTYPE_SALFATIX)
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"credentials_page", NULL) RETURNING frontcall_return
    BEFORE DIALOG
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"credentials_page", NULL) RETURNING frontcall_return
  END DIALOG
  CLOSE WINDOW w_salfatix_credentials
  RETURN lint_action
END FUNCTION