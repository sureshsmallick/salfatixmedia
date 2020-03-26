IMPORT util
IMPORT os
IMPORT FGL fgldbutl
IMPORT FGL setup
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL hash
IMPORT FGL passwords

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
    lstr_args STRING

  OPTIONS
    INPUT WRAP
  WHENEVER ERROR CALL errormgt

  LET lint_id = ARG_VAL(1)
  LET lint_usertype_id = ARG_VAL(2)
  LET lint_time = ARG_VAL(3)
  LET lstr_signature = ARG_VAL(4)

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
    IF core_ui.ui_message(%"Error",%"We're sorry. We cannot access to your request. Link is invalid (1).","ok","ok","cancel-red") THEN END IF
    EXIT PROGRAM -1
  END IF
  --check message integrity
  LET lstr_args = SFMT("%4Arg%2=%1&Arg%3=%2&Arg%1=%3%4",lint_id, lint_usertype_id, lint_time, base.Application.getResourceEntry("salfatixmedia.link.secretkey"))
  LET lstr_computed_signature = hash.compute_hash(lstr_args, "SHA512", FALSE)
  IF lstr_signature.equals(lstr_computed_signature) THEN
    CALL passwords.update_password(lint_id, lint_usertype_id, TRUE, setup.g_app_is_mobile)
      RETURNING lint_ret, lstr_msg
    IF lint_ret <> 0 THEN
      CALL error_log(lint_ret, SFMT("%5. Prg argument: %1-%2-%3-%4",lint_id,lint_usertype_id,lint_time,lstr_signature, lstr_msg))
      EXIT PROGRAM -1
    END IF
  ELSE
    CALL error_log(-1, SFMT("Bad link. Prg argument: %1-%2-%3-%4. Computed=%5",lint_id,lint_usertype_id,lint_time,lstr_signature, lstr_computed_signature))
    IF core_ui.ui_message(%"Error",%"We're sorry. We cannot access to your request. Link is invalid (2).","ok","ok","cancel-red") THEN END IF
    EXIT PROGRAM -1
  END IF
  --redirection to salfatix.com website
  EXIT PROGRAM 0
END MAIN