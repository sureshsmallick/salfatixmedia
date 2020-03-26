IMPORT FGL core_cst
IMPORT FGL core_db

SCHEMA salfatixmedia

#+ Check if the given email string has a valid format
#+
#+ @param pstr_mail email string
#+
#+ @returnType BOOLEAN
#+ @return     TRUE if string has a valid format for emails, FALSE otherwise
FUNCTION check_format(pstr_mail)
  DEFINE
    pstr_mail STRING,
    i,j,s1,s2 INTEGER,
    lstr_usr STRING,
    lstr_domain STRING,
    lstr_domain_name STRING,
    lstr_domain_scope STRING

  LET pstr_mail = pstr_mail.trim()
  LET s1 = pstr_mail.getLength()
  IF s1 > 0 THEN
    LET i = pstr_mail.getIndexOf("@", 1)
    LET lstr_usr = pstr_mail.subString(1, i - 1)
    IF lstr_usr.getLength() == 0 THEN
      RETURN FALSE
    END IF
    LET lstr_domain = pstr_mail.subString(i + 1, s1)
    LET s2 = lstr_domain.getLength()
    IF s2 == 0 THEN
      RETURN FALSE
    END IF
    LET j = lstr_domain.getIndexOf(".", 1)
    LET lstr_domain_name = lstr_domain.subString(1, j - 1)
    IF lstr_domain_name.getLength() == 0 THEN
      RETURN FALSE
    END IF
    LET lstr_domain_scope = lstr_domain.subString(j + 1, s2)
    IF lstr_domain_scope.getLength() == 0 THEN
      RETURN FALSE
    END IF
    RETURN TRUE
  END IF
  RETURN FALSE
END FUNCTION

#+ Get user id and its type from a given email
#+
#+ @param pstr_email email
#+ @param usertype C_USERTYPE_BRAND|C_USERTYPE_INFLUENCER|C_USERTYPE_SALFATIX
#+
#+ @returnType INTEGER, INTEGER, SMALLINT
#+ @return     0|error, user id, user type
FUNCTION get_usertype_and_id(pstr_mail,userType)
  DEFINE
    pstr_mail STRING,
    userType  SMALLINT,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_brand RECORD LIKE brands.*,
    lrec_user RECORD LIKE users.*,
    lrec_bouser RECORD LIKE backofficeusers.*

  LET pstr_mail = pstr_mail.trim()
  CASE userType 
    WHEN C_USERTYPE_BRAND
      CALL brands_select_row_by_email(pstr_mail, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_brand.*
      CASE lint_ret
        WHEN 0
          RETURN 0, lrec_brand.brnd_id, C_USERTYPE_BRAND
        WHEN NOTFOUND
          RETURN NOTFOUND, NULL, NULL
        OTHERWISE
          RETURN -1, NULL, NULL
      END CASE

    WHEN C_USERTYPE_INFLUENCER
      CALL users_select_row_by_email(pstr_mail, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_user.*
      CASE lint_ret
        WHEN 0
          RETURN 0, lrec_user.usr_id, C_USERTYPE_INFLUENCER
        WHEN NOTFOUND
          RETURN NOTFOUND, NULL, NULL
        OTHERWISE
          RETURN -1, NULL, NULL
      END CASE

    WHEN C_USERTYPE_SALFATIX
      CALL backofficeusers_select_row_by_email(pstr_mail, FALSE)
        RETURNING lint_ret, lstr_msg, lrec_bouser.*
      CASE lint_ret
        WHEN 0
          RETURN 0, lrec_bouser.bousr_id, C_USERTYPE_SALFATIX
        WHEN NOTFOUND
          RETURN NOTFOUND, NULL, NULL
        OTHERWISE
          RETURN -1, NULL, NULL
      END CASE
  END CASE

  RETURN -1, NULL, NULL
END FUNCTION