IMPORT FGL core_db
IMPORT FGL core_ui
IMPORT FGL core_cst
IMPORT os

SCHEMA salfatixmedia

PUBLIC DEFINE
  g_app_is_mobile BOOLEAN, --TRUE for mobile app, FALSE otherwise
  g_app_brand BOOLEAN, --TRUE for brand app, FALSE otherwise
  g_app_influencer BOOLEAN, --TRUE for influencer app, FALSE otherwise
  g_app_backoffice BOOLEAN, --TRUE for backoffice app, FALSE otherwise
  g_loggedin_id BIGINT, --id on logged-in user
  g_loggedin_name STRING, --name of the logged-in user
  g_frontcall_module STRING, --name of the customized frontcall module if any
  g_device_id STRING, --unique (for a user) id of a mobile device
  g_signin_method SMALLINT, --sign-in method to the appplication
  g_signin_socialnetwork_answer STRING --string received when connecting to the app throught social network

#+ Global module initialization
#+
#+ It initializes the database connection, logs and the UI management.
#+
#+ @param pstr_apptype "brand"|"influencer"|"backoffice"
#+
FUNCTION initialize(pstr_apptype)
  DEFINE
    pstr_apptype STRING,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_lang STRING,
    lstr_pathlang STRING,
    lstr_res  STRING,
    lint_i    INTEGER

  LET g_app_is_mobile = FALSE
  LET g_app_brand = FALSE
  LET g_app_influencer = FALSE
  LET g_app_backoffice = FALSE
  INITIALIZE g_frontcall_module TO NULL
  INITIALIZE g_device_id TO NULL
  LET g_signin_method = C_SIGNIN_UNDEFINED
  INITIALIZE g_signin_socialnetwork_answer TO NULL
  CALL initialize_login_data()

  CALL start_log()
  CALL core_db.connect("salfatixmedia")
    RETURNING lint_ret, lstr_msg
  IF lint_ret <> 0 THEN
    CALL error_log(lint_ret, lstr_msg)
    EXIT PROGRAM lint_ret
  END IF
  LET g_app_is_mobile = core_ui.ui_is_mobile()
  CASE pstr_apptype
    WHEN "brand"
      LET g_app_brand = TRUE
      LET g_frontcall_module = "mybrandmodule"

      LET lstr_lang = base.Application.getResourceEntry("salfatix.lang.force.brand")
      IF lstr_lang IS NULL THEN
        IF base.Application.getArgumentCount() > 0 THEN
          LET lstr_lang = base.Application.getArgument(1)
        END IF
      END IF
    WHEN "influencer"
      LET g_app_influencer = TRUE
      LET g_device_id = ARG_VAL(1)
      IF g_device_id.trim().getLength()==0 THEN
        CALL error_log(-1, "Missing argument device id")
        EXIT PROGRAM -1
      END IF
      LET lstr_lang = base.Application.getResourceEntry("salfatix.lang.force.influencer")
      IF lstr_lang IS NULL THEN
        IF base.Application.getArgumentCount() > 1 THEN
          LET lstr_lang = base.Application.getArgument(2)
          IF lstr_lang = "dev" THEN
            LET lstr_lang = NULL
          END IF
        END IF
      END IF
    WHEN "backoffice"
      LET g_app_backoffice = TRUE
      LET g_frontcall_module = "mybackofficemodule"
      LET lstr_lang = base.Application.getResourceEntry("salfatix.lang.force.backoffice")
      IF lstr_lang IS NULL THEN
        IF base.Application.getArgumentCount() > 0 THEN
          LET lstr_lang = base.Application.getArgument(1)
        END IF
      END IF
    OTHERWISE
      CALL error_log(-1, %"Unknown apptype")
      EXIT PROGRAM -1
  END CASE

  IF lstr_lang IS NULL THEN
    TRY
      CALL ui.Interface.frontCall("standard","feInfo","userPreferredLang",[lstr_lang])
    CATCH
      LET lstr_lang = base.Application.getResourceEntry("salfatix.lang.default")
    END TRY
  END IF
  IF lstr_lang.toLowerCase() = "default" THEN
    LET lstr_lang = base.Application.getResourceEntry("salfatix.lang.default")
  END IF

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
END FUNCTION

#+ Global module initialization of login data
#+
FUNCTION initialize_login_data()
  LET g_loggedin_id = 0
  INITIALIZE g_loggedin_name TO NULL
END FUNCTION

#+ Starts the error log
#+
#+ Start the error log
#+
FUNCTION start_log()
  DEFINE
    s STRING
  LET s = os.Path.JOIN(base.Application.getResourceEntry("salfatixmedia.log.dir"), SFMT("%1.log",base.Application.getProgramName()))
  TRY
    CALL STARTLOG(s)
  CATCH
    DISPLAY SFMT(%"Unable to start log |%1|",s)
    EXIT PROGRAM
  END TRY
END FUNCTION

#+ Starts the error log
#+
#+ Start the error log
#+
FUNCTION error_log(p_error_id, p_error_name)
  DEFINE
    p_error_id STRING,
    p_error_name STRING

  TRY
    CALL ERRORLOG(SFMT(%"Error=%1 - Message=%2\n%3", p_error_id, p_error_name, base.Application.getStackTrace()))
  CATCH
    DISPLAY SFMT(%"Error=%1 - Message=%2\n%3", p_error_id, p_error_name, base.Application.getStackTrace())
  END TRY
END FUNCTION

#+ Initialization of the logged-in user name
#+
#+ It initializes the database connection, logs and the UI management.
#+
FUNCTION refresh_loggedin_name()
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_backofficeuser RECORD LIKE backofficeusers.*

  INITIALIZE g_loggedin_name TO NULL
  IF g_app_brand THEN
    CALL core_db.brands_select_row(g_loggedin_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_brand.*
    IF lint_ret == 0 THEN
      LET g_loggedin_name = SFMT("%1 %2", lrec_brand.brnd_firstname, lrec_brand.brnd_lastname)
      LET g_loggedin_name = g_loggedin_name.trim()
    END IF
  END IF
  IF g_app_backoffice THEN
    CALL core_db.backofficeusers_select_row(g_loggedin_id, FALSE)
      RETURNING lint_ret, lstr_msg, lrec_backofficeuser.*
    IF lint_ret == 0 THEN
      LET g_loggedin_name = SFMT("%1 %2", lrec_backofficeuser.bousr_firstname, lrec_backofficeuser.bousr_lastname)
      LET g_loggedin_name = g_loggedin_name.trim()
    END IF
  END IF

END FUNCTION

FUNCTION errormgt()
  IF STATUS <> -6302 THEN
    IF core_ui.ui_message("Error",
                          %"An error occured, please warn the developer with following message:\nStatus: "
                          ||STATUS||"\n"||base.Application.getStackTrace(),"ok","ok","cancel-red") THEN END IF
    EXIT PROGRAM -1
  END IF
  EXIT PROGRAM 0
END FUNCTION
