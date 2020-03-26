MAIN
  DEFINE s STRING

  LET s = "http://10.254.0.39:6394/ua/r/server_dh"
  --LET s = "https://intranet.4js.com/salfatixmedia/ua/r/server"
  PROMPT "Server App: " FOR s ATTRIBUTES(WITHOUT DEFAULTS)
  IF s.trim().getLength() > 0 THEN
    TRY
      CALL ui.Interface.frontCall("mobile", "runOnServer", [s], [])
    CATCH
      EXIT PROGRAM STATUS
    END TRY
  END IF

END MAIN
