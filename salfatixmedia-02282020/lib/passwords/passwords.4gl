IMPORT FGL fgldbutl
IMPORT security
IMPORT FGL core_ui
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_automaton
IMPORT FGL setup
IMPORT FGL hash
IMPORT FGL emails
IMPORT FGL notifications

SCHEMA salfatixmedia

TYPE
  t_change_password RECORD
    old_password LIKE brands.brnd_password,
    new_password LIKE brands.brnd_password,
    confirm_password LIKE brands.brnd_password
  END RECORD

TYPE
  t_forgot_password RECORD
    email LIKE brands.brnd_email
  END RECORD

#+ Change a user password
#+
#+ @param pstr_old_db_password old database password
#+ @param pbool_reset_password TRUE->reset the password, FALSE-> update current password
#+ @param pbool_is_mobile TRUE->form runs on mobile device, FALSE otherwise
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, new password
PRIVATE FUNCTION _change_password_dialog(pstr_old_db_password, pbool_reset_password, pbool_is_mobile)
  DEFINE
    pstr_old_db_password LIKE brands.brnd_password,
    pbool_reset_password BOOLEAN,
    pbool_is_mobile BOOLEAN,
    lrec_ui_change_password t_change_password,
    lint_ret INTEGER,
    lstr_msg STRING

  OPEN WINDOW w_change_password WITH FORM "passwords"
  INITIALIZE lrec_ui_change_password.* TO NULL
  CALL FGL_SETTITLE(IIF(pbool_reset_password,%"Reset Password", %"Change Password"))
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT lrec_ui_change_password.* FROM scr_password.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION save
      CALL _validate_input(lrec_ui_change_password.*, pstr_old_db_password, pbool_reset_password)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        IF core_ui.ui_message(%"Error",lstr_msg,"ok","ok","fa-check") THEN END IF
        CONTINUE DIALOG
      END IF
      LET lint_ret = 0
      EXIT DIALOG
    ON ACTION save_mobile ATTRIBUTE(TEXT=%"Done") --gmi action panel
      CALL _validate_input(lrec_ui_change_password.*, pstr_old_db_password, pbool_reset_password)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        IF core_ui.ui_message(%"Error",lstr_msg,"ok","ok","fa-check") THEN END IF
        CONTINUE DIALOG
      END IF
      LET lint_ret = 0
      EXIT DIALOG
    ON ACTION cancel ATTRIBUTE(TEXT=%"Cancel")
      LET lint_ret = -1
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionActive("save", NOT pbool_is_mobile)
      CALL DIALOG.setActionActive("save_mobile", pbool_is_mobile)
      CALL DIALOG.setActionHidden("save_mobile", NOT pbool_is_mobile)
      CALL core_ui.ui_set_node_attribute("Button","name","save","hidden",pbool_is_mobile)
      IF pbool_reset_password THEN
        CALL core_ui.ui_set_node_attribute("Label","name","old_password","hidden",1)
        CALL core_ui.ui_set_node_attribute("FormField","name","formonly.old_password","hidden",1)
        CALL DIALOG.setActionActive("cancel", FALSE)
        CALL DIALOG.setActionHidden("cancel", TRUE)
      END IF
  END DIALOG
  IF lint_ret == 0 THEN
    IF core_ui.ui_message(%"Information",%"Your password has been successfully updated !!","ok","ok","fa-check") THEN END IF
  END IF
  CLOSE WINDOW w_change_password
  RETURN lint_ret, lrec_ui_change_password.new_password
END FUNCTION

#+ Validate the input of the passwords string
#+
#+ @param prec_ui_change_password record of type t_change_password
#+ @param pstr_old_db_password old encrypted database password
#+ @param pbool_reset_password TRUE->reset the password, FALSE-> update current password
#+ 
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
PRIVATE FUNCTION _validate_input(prec_ui_change_password, pstr_old_db_password, pbool_reset_password)
  DEFINE
    prec_ui_change_password t_change_password,
    pstr_old_db_password LIKE brands.brnd_password,
    pbool_reset_password BOOLEAN

  IF NOT pbool_reset_password THEN
    IF prec_ui_change_password.old_password IS NULL THEN
      RETURN -1, %"Old password required"
    END IF
  END IF
  IF prec_ui_change_password.new_password IS NULL THEN
    RETURN -1, %"New password required"
  END IF
  IF prec_ui_change_password.confirm_password IS NULL THEN
    RETURN -1, %"Confirmed password required"
  END IF
  IF prec_ui_change_password.new_password <> prec_ui_change_password.confirm_password THEN
    RETURN -1, %"New passwords don't match"
  END IF
  IF NOT pbool_reset_password THEN
    IF NOT hash.verify_hash(pstr_old_db_password, prec_ui_change_password.old_password, "BCRYPT", FALSE) THEN
      RETURN -1, %"Old password invalid"
    END IF
  END IF
  RETURN 0, NULL
END FUNCTION

#+ Update a password for a brand/influencer/salfatixuser
#+
#+ @param pint_id id of the brand/influencer/salfatixuser
#+ @param pint_user_type C_USERTYPE_BRAND|C_USERTYPE_INFLUENCER|C_USERTYPE_SALFATIX
#+ @param pbool_reset_password TRUE->reset the password, FALSE-> update current password
#+ @param pbool_is_mobile TRUE->form runs on mobile device, FALSE otherwise
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION update_password(pint_id, pint_user_type, pbool_reset_password, pbool_is_mobile)
  DEFINE
    pint_id INTEGER,
    pint_user_type SMALLINT,
    pbool_reset_password BOOLEAN,
    pbool_is_mobile BOOLEAN,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_tmp STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_db_brand RECORD LIKE brands.*,
    lrec_user RECORD LIKE users.*,
    lrec_db_user RECORD LIKE users.*,
    lrec_backofficeuser RECORD LIKE backofficeusers.*,
    lrec_db_backofficeuser RECORD LIKE backofficeusers.*,
    lint_status INTEGER,
    lstr_db_password STRING

  CASE pint_user_type
    WHEN C_USERTYPE_BRAND
      CALL core_db.brands_select_row(pint_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_db_brand.*
      LET lstr_db_password = lrec_db_brand.brnd_password
    WHEN C_USERTYPE_INFLUENCER
      CALL core_db.users_select_row(pint_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_db_user.*
      LET lstr_db_password = lrec_db_user.usr_password
    WHEN C_USERTYPE_SALFATIX
      CALL core_db.backofficeusers_select_row(pint_id, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_db_backofficeuser.*
      LET lstr_db_password = lrec_db_backofficeuser.bousr_password
    OTHERWISE
      LET lint_ret = -1
      LET lstr_msg = %"Wrong user type"  
  END CASE 
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CALL _change_password_dialog(lstr_db_password, pbool_reset_password, pbool_is_mobile)
    RETURNING lint_ret, lstr_tmp
  IF lint_ret <> 0 THEN --user cancelled 
    RETURN 0, NULL
  END IF
  LET lstr_tmp = hash.compute_hash(lstr_tmp, "BCRYPT", FALSE)
  IF lstr_tmp IS NULL THEN
    RETURN -1, %"Error during encryption"
  END IF
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  CASE pint_user_type
    WHEN C_USERTYPE_BRAND
      INITIALIZE lrec_brand.* TO NULL
      LET lrec_brand.* = lrec_db_brand.*
      LET lrec_brand.brnd_password = lstr_tmp
      LET lrec_brand.brnd_lastupdatedate = CURRENT
      CALL core_db.brands_update_row(lrec_db_brand.*, lrec_brand.*)
        RETURNING lint_ret, lstr_msg
    WHEN C_USERTYPE_INFLUENCER
      INITIALIZE lrec_user.* TO NULL
      LET lrec_user.* = lrec_db_user.*
      LET lrec_user.usr_password = lstr_tmp
      LET lrec_user.usr_lastupdatedate = CURRENT
      CALL core_db.users_update_row(lrec_db_user.*, lrec_user.*)
        RETURNING lint_ret, lstr_msg
    WHEN C_USERTYPE_SALFATIX
      INITIALIZE lrec_backofficeuser.* TO NULL
      LET lrec_backofficeuser.* = lrec_db_backofficeuser.*
      LET lrec_backofficeuser.bousr_password = lstr_tmp
      LET lrec_backofficeuser.bousr_lastupdatedate = CURRENT
      CALL core_db.backofficeusers_update_row(lrec_db_backofficeuser.*, lrec_backofficeuser.*)
        RETURNING lint_ret, lstr_msg
  END CASE 
  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    RETURN lint_ret, lstr_msg
  END IF
  RETURN lint_ret, lstr_msg
END FUNCTION

#+ Forgot a password for a brand/influencer/salfatixuser
#+
#+ @param pint_id id of the brand/influencer/salfatixuser
#+ @param pint_user_type C_USERTYPE_BRAND|C_USERTYPE_INFLUENCER|C_USERTYPE_SALFATIX
#+ @param pbool_is_mobile TRUE->form runs on mobile device, FALSE otherwise
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION forgot_password(pint_user_type SMALLINT)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_ui_forgot_password t_forgot_password,
    lint_action SMALLINT,
    lint_id BIGINT,
    lint_usertype SMALLINT,
    frontcall_return STRING

  OPEN WINDOW w_forgot_password WITH FORM "forgotpassword"
  INITIALIZE lrec_ui_forgot_password.* TO NULL
  CALL FGL_SETTITLE(%"Forgot Password")
  DIALOG
    ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    INPUT lrec_ui_forgot_password.* FROM scr_forgot_password.*
      ATTRIBUTE (WITHOUT DEFAULTS)
    END INPUT
    ON ACTION forgotpassword
      CALL _validate_forgotpassword_input(lrec_ui_forgot_password.*,pint_user_type)
        RETURNING lint_ret, lstr_msg
      IF lint_ret <> 0 THEN
        IF core_ui.ui_message(%"Error",lstr_msg,"ok","ok","fa-check") THEN END IF
        CONTINUE DIALOG
      END IF
      CALL emails.get_usertype_and_id(lrec_ui_forgot_password.email,pint_user_type)
        RETURNING lint_ret, lint_id, lint_usertype
      IF lint_ret <> 0 THEN
        ERROR %"Email not found"
      END IF
      CASE lint_usertype
        WHEN C_USERTYPE_BRAND
          CALL notifications.sendmail_brand_reset_password(lint_id)
        WHEN C_USERTYPE_INFLUENCER
          CALL notifications.sendmail_influencer_reset_password(lint_id)
        WHEN C_USERTYPE_SALFATIX
          CALL notifications.sendmail_backofficeuser_reset_password(lint_id)
      END CASE
      LET lint_ret = 0
      EXIT DIALOG
    ON ACTION close
      LET lint_ret = -1
    ON ACTION login
      LET lint_ret = -1
      EXIT DIALOG
    ON ACTION customaction
      LET lint_action = core_automaton.get_action_from_ui(setup.g_frontcall_module)
      --we behave as if we have closed the window
      LET lint_ret = -1
      EXIT DIALOG
    BEFORE DIALOG
      CALL DIALOG.setActionHidden("customaction", TRUE)
      CALL core_automaton.update_webmenu(setup.g_frontcall_module,"forgotpassword_page", NULL) RETURNING frontcall_return
  END DIALOG
  IF lint_ret == 0 THEN
    IF core_ui.ui_message(%"Information",%"An email to reset your password has been sent.","ok","ok","fa-check") THEN END IF
  END IF
  CLOSE WINDOW w_forgot_password
END FUNCTION

#+ Validate the input of the passwords string
#+
#+ @param prec_ui_forgot_password record of type t_forgot_password
#+ @param pstr_old_db_password old encrypted database password
#+ @param pbool_reset_password TRUE->reset the password, FALSE-> update current password
#+ 
#+ @returnType INTEGER, STRING
#+ @return     0|FAILURE, error message
PRIVATE FUNCTION _validate_forgotpassword_input(prec_ui_forgot_password,pint_user_type)
  DEFINE
    prec_ui_forgot_password t_forgot_password,
    pint_user_type SMALLINT,
    lint_ret INTEGER,
    lint_id BIGINT,
    lint_usertype SMALLINT

  IF prec_ui_forgot_password.email IS NULL THEN
    RETURN -1, %"Email missing"
  END IF
  IF NOT emails.check_format(prec_ui_forgot_password.email) THEN
    RETURN -1, %"Email format invalid"
  END IF
  CALL emails.get_usertype_and_id(prec_ui_forgot_password.email,pint_user_type)
    RETURNING lint_ret, lint_id, lint_usertype
  CASE lint_ret
    WHEN 0
    WHEN NOTFOUND
      RETURN -1, %"Email not found"
    OTHERWISE --error case
      RETURN -1, %"Email not found"
  END CASE
  RETURN 0, NULL
END FUNCTION