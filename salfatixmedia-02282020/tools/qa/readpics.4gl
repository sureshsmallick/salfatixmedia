Schema salfatixmedia

Main
  Define
    pics Record Like pics.*,
    st  Boolean

  Connect To "salfatixmedia"

  --Close Window screen
  --Open Window w1 With Form "readpics"

    Let st = False
    Locate pics.pic_value In File
    Declare cpic Cursor for Select pics.* From pics
    Foreach cpic Into pics.*
      --Display By Name pics.pic_value
      --Menu ""
        --On Action cancel
          --Let st = True
          --Exit Menu
        --On Action next
          --Exit Menu
        --On Action accept
          Call pics.pic_value.writeFile(pics.pic_id||".png")
      --End Menu
      --If st Then
        --Exit Foreach
      --End If
    End Foreach
    Free cpic

  Close Window w1
End Main