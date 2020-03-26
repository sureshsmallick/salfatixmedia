TYPE
  t_list RECORD
    cmp_title VARCHAR(255),
    pic_value BYTE,
    brnd_name VARCHAR(255),
    cmpst_name VARCHAR(255)
  END RECORD


MAIN

  DEFINE
    l DYNAMIC ARRAY OF t_list,
    i INTEGER

  CLOSE WINDOW SCREEN

  CALL ui.Interface.loadStyles("scrollgrid_resizable")
  
  FOR i = 1 TO 10
    LET l[i].cmp_title = "Title",i USING "<<<<"
    LET l[i].brnd_name = "Brand",i USING "<<<<"
    LET l[i].cmpst_name = "Status",i USING "<<<<"
    LOCATE l[i].pic_value IN FILE "scrollgrid_resizable.png"
  END FOR

  OPEN WINDOW w WITH FORM "scrollgrid_resizable"
  DIALOG
  ATTRIBUTES(UNBUFFERED, FIELD ORDER FORM)
    DISPLAY ARRAY l TO scr_list.*
      --ON ACTION imageclick
        --MESSAGE "action IMAGE launched..."||CURRENT
    END DISPLAY
    ON ACTION accept
      MESSAGE "on action accept..."||CURRENT
      EXIT DIALOG
    --ON ACTION imageclick
      --MESSAGE "action IMAGE launched..."||CURRENT
    ON ACTION dbl_click
      MESSAGE "action DOUBLECLICK launched..."||CURRENT
  END DIALOG

  CLOSE WINDOW w

END MAIN
