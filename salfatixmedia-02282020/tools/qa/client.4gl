MAIN

  DEFINE uri STRING, x STRING
  MENU ""
    ON ACTION read_photo
      LET uri = ui.Interface.filenameToURI("image_upload_15232_20190212163312.jpg")
      CALL ui_launch_url(uri)
    ON ACTION read_video
      --LET uri = ui.Interface.filenameToURI("xxx.mp4")
      --CALL ui_launch_url(uri)
      LET uri = "xxx.mp4"
      LET x = "yy.test"
      CALL FGL_PUTFILE(uri,x)
END MENU

END MAIN

#+ Launch the given URL
#+
#+ @param pstr_url url
FUNCTION ui_launch_url(pstr_url STRING)
  TRY
    CALL ui.Interface.frontcall("standard", "launchURL", [pstr_url] , [])
  CATCH
  END TRY
END FUNCTION