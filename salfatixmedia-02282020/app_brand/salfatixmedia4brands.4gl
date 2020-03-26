IMPORT FGL setup
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_automaton
IMPORT FGL string
IMPORT FGL brands
IMPORT FGL campaigns
IMPORT FGL passwords
IMPORT FGL hash

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
    lint_brand_id LIKE brands.brnd_id,
    lint_campaign_id LIKE campaigns.cmp_id

  OPTIONS
    INPUT WRAP

  WHENEVER ERROR CALL errormgt

  CALL setup.initialize("brand")

  LET lint_action = C_APPACTION_SIGNIN
  WHILE TRUE
    CASE lint_action
      WHEN C_APPACTION_SIGNIN
        LET lint_action = _credentials()
      WHEN C_APPACTION_VIEWCAMPAIGNS
        CALL campaigns.campaignlist_open_form(SFMT("campaigns.cmp_brand_id = %1", setup.g_loggedin_id) , campaignlist_get_default_sqlorderby(), NULL)
          RETURNING lint_ret, lint_action
      WHEN C_APPACTION_ADDCAMPAIGN
        CALL campaigns.campaigngrid_open_form_by_key(0, C_APPSTATE_ADD, campaigns.C_CAMPAIGNMENU_ALLGROUPS)
          RETURNING lint_ret, lint_action, lint_campaign_id
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_ACCEPT THEN
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
          END IF
        END IF
        --CALL campaigns.campaignmenu_open_form_by_key(0, C_APPSTATE_ADD)
          --RETURNING lint_ret, lint_action, lint_campaign_id
        LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      WHEN C_APPACTION_ADDBRAND --for a connected brand - it is the registration 
        CALL brands.brandgrid_open_form_by_key(0, C_APPSTATE_ADD)
          RETURNING lint_ret, lint_action, lint_brand_id
        IF lint_ret == 0 THEN
          IF lint_action == C_APPACTION_ACCEPT THEN
            LET lint_action = C_APPACTION_VIEWCAMPAIGNS
          END IF
        END IF
      WHEN C_APPACTION_EDITPROFILE
        CALL brands.brandgrid_open_form_by_key(setup.g_loggedin_id, C_APPSTATE_UPDATE)
          RETURNING lint_ret, lint_action, lint_brand_id
      WHEN C_APPACTION_LOGOUT
        LET lint_action = _credentials()
      OTHERWISE
        EXIT WHILE
    END CASE
  END WHILE
END MAIN

#+ Handle the credentials window for a brand user
#+
#+ @returnType STRING
#+ @return     next action to do
PRIVATE FUNCTION _credentials()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lrec_credential t_credentials,
    lrec_brand RECORD LIKE brands.*,
    frontcall_return STRING

  CALL setup.initialize_login_data()
  LET lint_action = C_APPACTION_UNDEFINED
  OPEN WINDOW w_brand_credentials WITH FORM "brand_credentials"
  CALL FGL_SETTITLE(%"Sign in")
  INITIALIZE lrec_credential.* TO NULL
  --LET lrec_credential.email = "dh@4js.com"
  --LET lrec_credential.password = "xx"
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
      CALL core_db.brands_select_row_by_email(lrec_credential.email, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_brand.*
      IF lint_ret <> 0 THEN
        ERROR %"Invalid credentials"
        NEXT FIELD email
        CONTINUE DIALOG
      END IF
      IF NOT hash.verify_hash(lrec_brand.brnd_password, lrec_credential.password, "BCRYPT", FALSE) THEN
        ERROR %"Invalid credentials"
        NEXT FIELD password
        CONTINUE DIALOG
      END IF
      IF (lrec_brand.brnd_accountstatus_id <> C_ACCOUNTSTATUS_INCOMPLETE)
       AND (lrec_brand.brnd_accountstatus_id <> C_ACCOUNTSTATUS_VALIDATED)
      THEN
        ERROR %"Invalid account"
        NEXT FIELD CURRENT
        CONTINUE DIALOG
      END IF
      LET setup.g_loggedin_id = lrec_brand.brnd_id
      LET setup.g_signin_method = C_SIGNIN_VIA_EMAIL
      CALL setup.refresh_loggedin_name()
      LET lint_action = C_APPACTION_VIEWCAMPAIGNS
      EXIT DIALOG
    ON ACTION forgotpassword
      CALL passwords.forgot_password(C_USERTYPE_BRAND)
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"credentials_page", NULL) RETURNING frontcall_return
    ON ACTION register
      LET lint_action = C_APPACTION_ADDBRAND
      EXIT DIALOG
    BEFORE DIALOG
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"credentials_page", NULL) RETURNING frontcall_return
  END DIALOG
  CLOSE WINDOW w_brand_credentials
  RETURN lint_action
END FUNCTION
