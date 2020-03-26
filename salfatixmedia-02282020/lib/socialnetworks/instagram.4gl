IMPORT util
IMPORT FGL fgldbutl
IMPORT FGL core_db

SCHEMA salfatixmedia

PUBLIC TYPE
  t_instagramUser RECORD
    access_token STRING,
    user RECORD
      id STRING,
      username STRING,
      profile_picture STRING,
      full_name STRING,
      bio STRING,
      website STRING,
      is_business BOOLEAN
    END RECORD
  END RECORD

FUNCTION instagramUserNameExist( pusr_instagram_username LIKE users.usr_instagram_username )
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_user RECORD LIKE users.*

  CALL core_db.users_select_row_by_instagram_username(pusr_instagram_username, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_user.*
  RETURN (lint_ret==0)
END FUNCTION

#+ Update influencer's instagram data into database
#+
#+ @param pint_usr_id user account id
#+ @param p_socialnetwork_answer data coming from the social network API
#+
#+ @returnType INTEGER, STRING
#+ @return     0|error, error message
FUNCTION update_influencer_data(pint_usr_id LIKE users.usr_id, p_socialnetwork_answer STRING)
  DEFINE
    lint_ret INTEGER,
    lstr_msg STRING,
    instagramUser t_instagramUser,
    lrec_db_user RECORD LIKE users.*,
    lrec_user RECORD LIKE users.*,
    lint_status INTEGER,
    l_timestamp DATETIME YEAR TO SECOND

  TRY
    CALL util.JSON.parse(p_socialnetwork_answer, instagramUser)
  CATCH
    LET lint_ret = STATUS
    LET lstr_msg = SQLCA.SQLERRM
    RETURN lint_ret, lstr_msg
  END TRY
  CALL core_db.users_select_row(pint_usr_id, FALSE)
    RETURNING lint_ret, lstr_msg, lrec_db_user.*
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET l_timestamp = CURRENT
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    RETURN lint_ret, lstr_msg
  END IF
  INITIALIZE lrec_user.* TO NULL
  LET lrec_user.* = lrec_db_user.*
  LET lrec_user.usr_instagram_userid = instagramUser.user.id
  LET lrec_user.usr_instagram_username = instagramUser.user.username
  LET lrec_user.usr_instagram_fullname = instagramUser.user.full_name
  LET lrec_user.usr_instagram_profilepicture = instagramUser.user.profile_picture
  LET lrec_user.usr_instagram_biography = instagramUser.user.bio
  LET lrec_user.usr_instagram_website = instagramUser.user.website
  LET lrec_user.usr_instagram_is_business = instagramUser.user.is_business
  LET lrec_user.usr_instagram_token = instagramUser.access_token
  CALL core_db.users_update_row(lrec_db_user.*, lrec_user.*)
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