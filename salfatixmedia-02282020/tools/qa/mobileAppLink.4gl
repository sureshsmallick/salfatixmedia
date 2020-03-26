MAIN
  DEFINE s STRING
  LET s = "salfatixmedia"
  MENU
    ON ACTION open_instagram_account
      LET s = "instagram://user?username="||s
      TRY
        CALL ui.Interface.frontcall("standard", "launchURL", [s] , [])
      CATCH
      END TRY
    ON ACTION open_instagram_app
      --do not work on GMA
      LET s = "instagram://app"
      TRY
        CALL ui.Interface.frontcall("standard", "launchURL", [s] , [])
      CATCH
      END TRY
    ON ACTION accept ATTRIBUTES(TEXT="Accept") EXIT MENU
    ON ACTION cancel ATTRIBUTES(TEXT="Cancel") EXIT MENU
  END MENU

END MAIN
