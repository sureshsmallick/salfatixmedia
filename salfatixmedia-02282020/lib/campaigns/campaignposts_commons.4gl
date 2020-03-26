IMPORT os
IMPORT FGL core_cst
IMPORT FGL core_db
IMPORT FGL setup

SCHEMA salfatixmedia

FUNCTION campaignpost_build_filepath(pstr_filename STRING)
  RETURN os.Path.join(base.Application.getResourceEntry("salfatixmedia.export.posts"),pstr_filename)
END FUNCTION

--p_image must be located first before calling this function
FUNCTION campaignpost_load_image(p_filename STRING, p_posttype_id LIKE posttypes.pstt_id)
  DEFINE
    l_image BYTE,
    lint_ret INTEGER,
    lstr_msg STRING,
    lstr_filepath STRING,
    lrec_pic RECORD LIKE pics.*
  LET lstr_filepath = campaignpost_build_filepath(p_filename)
  IF NOT os.Path.exists(lstr_filepath) THEN
    CALL setup.error_log(-1, SFMT("_load_image() File not found on disk : %1.", lstr_filepath))
  ELSE
    CASE
      WHEN p_posttype_id == C_POSTTYPE_INSTAGRAM_PUBLICATION
        TRY
          LOCATE l_image IN FILE
          CALL l_image.readFile(lstr_filepath)
        CATCH
          LET lint_ret = STATUS
        END TRY
      WHEN p_posttype_id == C_POSTTYPE_INSTAGRAM_INSTASTORY
        TRY
          LOCATE l_image IN FILE
          CALL l_image.readFile(lstr_filepath)
        CATCH
          LET lint_ret = STATUS
        END TRY
      WHEN p_posttype_id == C_POSTTYPE_YOUTUBE
        CALL core_db.pics_select_row(C_PIC_DEFAULTMOVIEICON, FALSE)
          RETURNING lint_ret, lstr_msg, lrec_pic.*
        IF lint_ret == 0 THEN
          LET l_image = lrec_pic.pic_value
        END IF
      OTHERWISE
        CALL setup.error_log(-1, SFMT("_load_image() Post type id (%1) is not managed...", p_posttype_id))
    END CASE
  END IF
  RETURN l_image
END FUNCTION
