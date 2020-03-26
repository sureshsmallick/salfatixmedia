MAIN
    CONNECT TO "salfatixmedia"
    IF num_args() <> 2 THEN
      DISPLAY "usage : fglrun load_a_picture <pics.id> <file_to_load>"
      EXIT PROGRAM
    END IF
    CALL load_a_picture(ARG_VAL(1), ARG_VAL(2))
END MAIN

FUNCTION load_a_picture(pint_pic_id INTEGER, pint_pic_path STRING)
  DEFINE
    lint_pic_id INTEGER,
    lint_ret INTEGER,
    lstr_msg STRING,
    lrec_pic RECORD
      pic_id INTEGER,
      pic_value BYTE
    END RECORD,
    lint_status INTEGER

  INITIALIZE lrec_pic.* TO NULL
  LET lrec_pic.pic_id = pint_pic_id
  LOCATE lrec_pic.pic_value IN FILE
  CALL lrec_pic.pic_value.readFile(pint_pic_path)

  --start a database transaction
  LET lint_ret = DB_START_TRANSACTION()
  LET lstr_msg = SQLERRMESSAGE
  IF lint_ret <> 0 THEN
    DISPLAY lstr_msg
    RETURN
  END IF

  TRY
    SELECT pics.pic_id INTO lint_pic_id FROM pics WHERE pics.pic_id = pint_pic_id
    IF SQLCA.SQLCODE == NOTFOUND THEN
      INSERT INTO pics VALUES (lrec_pic.*)
      LET lrec_pic.pic_id = SQLCA.SQLERRD[2]
    ELSE
      UPDATE pics SET pic_value = lrec_pic.pic_value WHERE pic_id = lint_pic_id
    END IF
  CATCH
    LET lint_ret = SQLCA.SQLCODE
    LET lstr_msg = SQLERRMESSAGE
  END TRY

  --commit SQL transaction if no error occured, otherwise rollback SQL transaction
  IF (lint_status := DB_FINISH_TRANSACTION(lint_ret == 0)) <> 0 THEN
    --commit or rollback failed
    LET lint_ret = lint_status
    LET lstr_msg = SQLERRMESSAGE
    DISPLAY lstr_msg
    RETURN
  END IF

END FUNCTION