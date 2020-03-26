IMPORT FGL setup
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_automaton
IMPORT FGL string
IMPORT FGL users
IMPORT FGL campaigns_mobile
IMPORT FGL passwords
IMPORT FGL hash
Import FGL OAuthRequester
IMPORT util
IMPORT FGL instagram

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
    lint_user_id LIKE users.usr_id

  OPTIONS
    INPUT WRAP

  WHENEVER ERROR CALL errormgt

  CALL setup.initialize("influencer")

  --display setup.g_device_id

  LET lint_action = C_APPACTION_SIGNIN
  WHILE TRUE
    CASE lint_action
      WHEN C_APPACTION_SIGNIN
        CALL _credentials() RETURNING lint_action
      WHEN C_APPACTION_INFLUENCER_MAINPANEL
        CALL usermenu_open_form_by_key(setup.g_loggedin_id)
          RETURNING lint_ret, lint_action, lint_user_id
      WHEN C_APPACTION_VIEWCAMPAIGNS
        CALL campaigns_mobile.campaignlist_open_form_mobile()
          RETURNING lint_ret, lint_action
      WHEN C_APPACTION_ADDINFLUENCER --for a connected influencer - it is the registration 
        CALL users.usergrid_open_form_by_key(0, C_APPSTATE_ADD, NULL)
          RETURNING lint_ret, lint_action, lint_user_id
        IF lint_ret == 0 THEN
          CASE lint_action
            WHEN C_APPACTION_ACCEPT
              LET lint_action = C_APPACTION_INFLUENCER_MAINPANEL
            WHEN C_APPACTION_CANCEL
              LET lint_action = C_APPACTION_LOGOUT
          END CASE
        END IF
      WHEN C_APPACTION_LOGOUT
        IF setup.g_signin_method == C_SIGNIN_VIA_INSTAGRAM THEN
          CALL OAuthRequester.disconnectFromSocialNetwork("Instagram")
        END IF
        EXIT WHILE
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
    lint_action SMALLINT,
    lboo_dev    BOOLEAN

  CALL setup.initialize_login_data()
  LET lint_action = C_APPACTION_UNDEFINED
  LET lboo_dev = FALSE
  IF base.Application.getArgumentCount() > 1 THEN
    IF base.Application.getArgument(base.Application.getArgumentCount()) = "dev" THEN
      LET lboo_dev = TRUE
    END IF
  END IF
  IF lboo_dev THEN
    LET lint_action = _credentials_all(0)
  ELSE
    --LET lint_action = _credentials_all(2) # For Apple testers
    LET lint_action = _credentials_instagram_only()
  END IF

  RETURN lint_action
END FUNCTION

#+ Handle the credentials window for a brand user
#+
#+ @returnType STRING
#+ @return     next action to do
PRIVATE FUNCTION _credentials_all( credentialOptions Smallint )
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lint_action SMALLINT,
    lrec_credential t_credentials,
    lrec_user RECORD LIKE users.*,
    instagramUser t_instagramUser,
    lstr_socialnetwork_answer STRING,
    lstr_tmp STRING

  OPEN WINDOW w_influencer_credentials WITH FORM "influencer_credentials"
  CALL FGL_SETTITLE(%"Sign in")
  Display "header.png" To head
  INITIALIZE lrec_credential.* TO NULL
  --LET lrec_credential.email = "aa@aa.com"
  --LET lrec_credential.password = "xx"

  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT lrec_credential.* FROM scr_credentials.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION instagram
      Call connectThroughInstagram() Returning lint_ret,lint_action
      If lint_ret = 1 Then
        Exit Dialog
      Else
        Continue Dialog
      End If
    ON ACTION login
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
      CALL core_db.users_select_row_by_email(lrec_credential.email, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_user.*
      IF lint_ret <> 0 THEN
        ERROR %"Invalid credentials"
        NEXT FIELD email
        CONTINUE DIALOG
      END IF
      IF NOT hash.verify_hash(lrec_user.usr_password, lrec_credential.password, "BCRYPT", FALSE) THEN
        ERROR %"Invalid credentials"
        NEXT FIELD password
        CONTINUE DIALOG
      END IF
      LET setup.g_loggedin_id = lrec_user.usr_id
      LET setup.g_signin_method = C_SIGNIN_VIA_EMAIL
      LET lint_action = C_APPACTION_INFLUENCER_MAINPANEL
      EXIT DIALOG
    ON ACTION forgotpassword
      CALL passwords.forgot_password(C_USERTYPE_INFLUENCER)
    ON ACTION register
      LET lint_action = C_APPACTION_ADDINFLUENCER
      EXIT DIALOG
    ON ACTION close ATTRIBUTE(TEXT=%"Back") --mobile action - TEXT is for mobile IOS
      LET lint_action = C_APPACTION_LOGOUT
      EXIT DIALOG
    BEFORE DIALOG
      Case credentialOptions
        When 2
          Call Dialog.setActionActive("instagram",False)
      End Case
  END DIALOG
  CLOSE WINDOW w_influencer_credentials
  RETURN lint_action
END FUNCTION

Function connectThroughInstagram()
  DEFINE
    lstr_socialnetwork_answer STRING,
    instagramUser t_instagramUser,
    lstr_tmp STRING,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*,
    lint_action SMALLINT,
    lint_ret INTEGER

  LET OAuthRequester.userDebug = base.Application.getResourceEntry("salfatix.oauthserver.debug")
  CALL OAuthRequester.setRedirectUri(base.Application.getResourceEntry("salfatix.oauthserver.url"))
  CALL OAuthRequester.connectThroughSocialNetwork("Instagram")
    RETURNING lint_ret, lstr_socialnetwork_answer
  IF lint_ret == 400 THEN
    RETURN 1,C_APPACTION_LOGOUT
  END IF
  IF lstr_socialnetwork_answer IS NULL THEN
    CALL OAuthRequester.disconnectFromSocialNetwork("Instagram")
    ERROR %"Connection not allowed"
    RETURN 1,C_APPACTION_LOGOUT
  END IF
  --parse social network answer
  CALL util.JSON.parse(lstr_socialnetwork_answer, instagramUser)
  LET lstr_tmp = instagramUser.user.id
  CALL core_db.users_select_row_by_instagram_userid(lstr_tmp.trim(), FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  CASE lint_ret
    WHEN 0 --instagram account exist
      CALL instagram.update_influencer_data(lrec_user.usr_id, lstr_socialnetwork_answer)
        RETURNING lint_ret, lstr_msg
      LET setup.g_loggedin_id = lrec_user.usr_id
      LET setup.g_signin_method = C_SIGNIN_VIA_INSTAGRAM
      LET setup.g_signin_socialnetwork_answer = lstr_socialnetwork_answer
      CALL core_db.users_select_row(lrec_user.usr_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_user.*
      IF lint_ret ==0 THEN
        IF lrec_user.usr_accountstatus_id == C_ACCOUNTSTATUS_VALIDATED THEN
          LET lint_action = C_APPACTION_VIEWCAMPAIGNS
        ELSE
          LET lint_action = C_APPACTION_INFLUENCER_MAINPANEL
        END IF
      ELSE
        LET lint_action = C_APPACTION_LOGOUT
      END IF
      RETURN 1,lint_action
    WHEN NOTFOUND --instagram account does not exist
      LET setup.g_signin_socialnetwork_answer = lstr_socialnetwork_answer
      LET setup.g_signin_method = C_SIGNIN_VIA_INSTAGRAM
      LET lint_action = C_APPACTION_ADDINFLUENCER
      RETURN 1,lint_action
    OTHERWISE
      ERROR SFMT(%"Connection not allowed..%1 %2",lint_ret, lstr_msg)
      RETURN 0,lint_action
  END CASE

  Return lint_ret,lint_action
End Function

#+ Handle the credentials window for a brand user
#+
#+ @returnType STRING
#+ @return     next action to do
PRIVATE FUNCTION _credentials_instagram_only()
  DEFINE
    lint_action SMALLINT,
    lint_ret INTEGER,
    foot String,
    i Integer

  OPEN WINDOW w_influencer_credentials_instagram_only WITH FORM "influencer_credentials_instagram_only"
  CALL FGL_SETTITLE(%"Sign in")
  Display "header.png" To head
  Let i = 1
  Display "footer-credentials-1.jpg" To foot
  MENU ""
    BEFORE MENU
      Call connectThroughInstagram() Returning lint_ret,lint_action
      If lint_ret = 1 Then
        Exit Menu
      End If
    ON ACTION instagram
      Call connectThroughInstagram() Returning lint_ret,lint_action
      If lint_ret = 1 Then
        Exit Menu
      End If
    ON ACTION cancel
      LET lint_action = C_APPACTION_LOGOUT
      EXIT MENU
    On Timer 15
      Let i = Iif(i=3,1,i+1)
      Let foot = "footer-credentials-"||i||".jpg"
      Display By Name foot
  END MENU
  CLOSE WINDOW w_influencer_credentials_instagram_only
  RETURN lint_action
END FUNCTION
