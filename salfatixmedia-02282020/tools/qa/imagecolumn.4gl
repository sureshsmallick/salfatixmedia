TYPE
  t_list RECORD
    myname VARCHAR(32),
    myimage VARCHAR(32)
  END RECORD

MAIN

  DEFINE
    l DYNAMIC ARRAY OF t_list,
    i INTEGER

  CLOSE WINDOW SCREEN

  FOR i = 1 TO 10
    LET l[i].myname = "myname",i USING "<<<<"
    LET l[i].myimage = "fa-square-o"
  END FOR

  OPEN WINDOW w WITH FORM "imagecolumn"
  DIALOG
  ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY l TO s.*
      ON ACTION selectrow
        LET l[arr_curr()].myimage = IIF(l[arr_curr()].myimage=="fa-square-o","fa-check-square","fa-square-o")
    END DISPLAY
    ON ACTION accept
      DISPLAY "on action accept"
      EXIT DIALOG
  END DIALOG

  CLOSE WINDOW w

END MAIN
