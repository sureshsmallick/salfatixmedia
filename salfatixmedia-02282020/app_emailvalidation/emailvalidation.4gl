IMPORT util
IMPORT os
IMPORT FGL fgldbutl
IMPORT FGL setup
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL hash

SCHEMA salfatixmedia

MAIN
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_lang STRING,
    lstr_pathlang STRING,
    lstr_res  STRING,
    lint_id INTEGER,
    lint_usertype_id INTEGER,
    lint_time INTEGER,
    lstr_signature STRING,
    lstr_computed_signature STRING,
    lstr_args STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_db_brand RECORD LIKE brands.*,
    lrec_user RECORD LIKE users.*,
    lrec_db_user RECORD LIKE users.*,
    lrec_backofficeuser RECORD LIKE backofficeusers.*,
    lrec_db_backofficeuser RECORD LIKE backofficeusers.*,
    lint_status INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  OPTIONS
    INPUT WRAP
  WHENEVER ERROR CALL errormgt

  LET lint_id = ARG_VAL(1)
  LET lint_usertype_id = ARG_VAL(2)
  LET lint_time = ARG_VAL(3)
  LET lstr_signature = ARG_VAL(4)

  While lstr_signature.getIndexOf(" ",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf(" ",1)-1),lstr_signature.subString(lstr_signature.getIndexOf(" ",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("!",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("!",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("!",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("\n",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("\n",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("\n",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("\f",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("\f",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("\f",1)+1,lstr_signature.getLength())
  End While
  While lstr_signature.getIndexOf("\r",1)>0
    Let lstr_signature = lstr_signature.subString(1,lstr_signature.getIndexOf("\r",1)-1),lstr_signature.subString(lstr_signature.getIndexOf("\r",1)+1,lstr_signature.getLength())
  End While

  CALL start_log()
  CALL core_db.connect("salfatixmedia")
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL error_log(lint_ret, lstr_msg)
    EXIT PROGRAM lint_ret
  END IF

  TRY
    CALL ui.Interface.frontCall("standard","feInfo","userPreferredLang",[lstr_lang])
  CATCH
    LET lstr_lang = base.Application.getResourceEntry("salfatix.lang.default")
  END TRY
  LET lstr_lang = NVL(lstr_lang.subString(1,2),base.Application.getResourceEntry("salfatix.lang.default"))
  LET lstr_pathlang = os.Path.join(os.Path.join(os.Path.join(os.Path.join(base.Application.getProgramDir(),".."),"res"),"lang"),lstr_lang)
  IF os.Path.exists(lstr_pathlang) AND os.Path.isDirectory(lstr_pathlang) THEN
  ELSE
    LET lstr_pathlang = os.Path.join(os.Path.join(os.Path.join(os.Path.join(base.Application.getProgramDir(),".."),"res"),"lang"),base.Application.getResourceEntry("salfatix.lang.default"))
  END IF

  LET lstr_res = NVL(lstr_pathlang||os.Path.pathSeparator()||fgl_getenv("FGLRESOURCEPATH"),lstr_pathlang)
  CALL base.Application.reloadResources(lstr_res.trim())

  CALL ui.Interface.loadStyles("salfatixmedia")
  CALL ui.Interface.loadActionDefaults("salfatixmedia")
  IF lstr_signature.trim().getLength()==0 THEN
    CALL error_log(-1, SFMT("Invalid argument: %1-%2-%3-%4",lint_id,lint_usertype_id,lint_time,lstr_signature))
    IF core_ui.ui_message(%"Error",%"We're sorry.\nWe cannot confirm your account.\nLink is invalid (1).","ok","ok","cancel-red") THEN END IF
    EXIT PROGRAM -1
  END IF
  --check message integrity
  LET lstr_args = SFMT("%4Arg%2=%1&Arg%3=%2&Arg%1=%3%4",lint_id, lint_usertype_id, lint_time, base.Application.getResourceEntry("salfatixmedia.link.secretkey"))
  LET lstr_computed_signature = hash.compute_hash(lstr_args, "SHA512", FALSE)
  IF lstr_signature.equals(lstr_computed_signature) THEN
    CASE lint_usertype_id
      WHEN C_USERTYPE_BRAND
        CALL core_db.brands_select_row(lint_id, FALSE)
          RETURNING lint_ret, lstr_msg, lrec_db_brand.*
      WHEN C_USERTYPE_INFLUENCER
        CALL core_db.users_select_row(lint_id, FALSE)
          RETURNING lint_ret, lstr_msg, lrec_db_user.*
      WHEN C_USERTYPE_SALFATIX
        CALL core_db.backofficeusers_select_row(lint_id, FALSE)
          RETURNING lint_ret, lstr_msg, lrec_db_backofficeuser.*
      OTHERWISE
        CALL error_log(-1, SFMT("Wrong user type. Prg argument: %1-%2-%3-%4",lint_id,lint_usertype_id,lint_time,lstr_signature))
        IF core_ui.ui_message(%"Error",%"We're sorry.\nWe cannot confirm your account.\nInternal Error (1).","ok","ok","cancel-red") THEN END IF
        EXIT PROGRAM -1
    END CASE 
    --start a database transaction
    LET lint_ret = DB_START_TRANSACTION()
    LET lstr_msg = SQLERRMESSAGE
    IF lint_ret <> 0 THEN
      CALL error_log(lint_ret, SFMT("DB_START_TRANSACTION() - Msg=%5 Prg argument: %1-%2-%3-%4",lint_id,lint_usertype_id,lint_time,lstr_signature, lstr_msg))
      IF core_ui.ui_message(%"Error",%"We're sorry.\nWe cannot confirm your account.\nInternal Error (2).","ok","ok","cancel-red") THEN END IF
      EXIT PROGRAM -1
    END IF
    LET l_timestamp = CURRENT 
    CASE lint_usertype_id
      WHEN C_USERTYPE_BRAND
        INITIALIZE lrec_brand.* TO NULL
        LET lrec_brand.* = lrec_db_brand.*
        LET lrec_brand.brnd_emailvalidationdate = l_timestamp
        LET lrec_brand.brnd_lastupdatedate = l_timestamp
        CALL core_db.brands_update_row(lrec_db_brand.*, lrec_brand.*)
          RETURNING lint_ret, lstr_msg
      WHEN C_USERTYPE_INFLUENCER
        INITIALIZE lrec_user.* TO NULL
        LET lrec_user.* = lrec_db_user.*
        LET lrec_user.usr_emailvalidationdate = l_timestamp
        LET lrec_user.usr_lastupdatedate = l_timestamp
        CALL core_db.users_update_row(lrec_db_user.*, lrec_user.*)
          RETURNING lint_ret, lstr_msg
      WHEN C_USERTYPE_SALFATIX
        INITIALIZE lrec_backofficeuser.* TO NULL
        LET lrec_backofficeuser.* = lrec_db_backofficeuser.*
        --LET lrec_backofficeuser.bousr_email
        LET lrec_backofficeuser.bousr_lastupdatedate = l_timestamp
        CALL core_db.backofficeusers_update_row(lrec_db_backofficeuser.*, lrec_backofficeuser.*)
          RETURNING lint_ret, lstr_msg
    END CASE 
    --commit SQL transaction if no error occured, otherwise rollback SQL transaction
    IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
      --commit or rollback failed
      LET lint_ret = lint_status
      LET lstr_msg = SQLERRMESSAGE
      CALL error_log(-1, SFMT("DB_FINISH_TRANSACTION() Err=%5 - Msg=%6. Prg argument: %1-%2-%3-%4",lint_id,lint_usertype_id,lint_time,lstr_signature, lint_ret, lstr_msg))
      IF core_ui.ui_message(%"Error",%"We're sorry.\nWe cannot confirm your account.\nInternal Error (3).","ok","ok","cancel-red") THEN END IF
      EXIT PROGRAM -1
    END IF
    IF lint_ret <> 0 THEN
      CALL error_log(lint_ret, SFMT("Email validation failed - Msg=%5 Prg argument: %1-%2-%3-%4",lint_id,lint_usertype_id,lint_time,lstr_signature, lstr_msg))
      IF core_ui.ui_message(%"Error",%"We're sorry.\nWe cannot confirm your account.\nInternal Error (4).","ok","ok","cancel-red") THEN END IF
      EXIT PROGRAM -1
    END IF
    IF core_ui.ui_message(%"Information",%"Email validated\nThank you!","ok","ok","fa-check") THEN END IF
  ELSE
    CALL error_log(-1, SFMT("Bad link. Prg argument: %1-%2-%3-%4. Computed=%5",lint_id,lint_usertype_id,lint_time,lstr_signature, lstr_computed_signature))
    IF core_ui.ui_message(%"Error",%"We're sorry.\nWe cannot confirm your account.\nLink is invalid (2).","ok","ok","cancel-red") THEN END IF
    EXIT PROGRAM -1
  END IF
  --redirection to salfatix.com website
  EXIT PROGRAM 0
END MAIN