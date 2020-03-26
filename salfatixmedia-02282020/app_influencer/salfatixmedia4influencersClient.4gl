Import FGL core_os
Import FGL core_ui
Import util
Import Security

Main
  Define
    foot     String,
    retCode  Integer,
    i        Smallint,
    fileName String,
    Internet String,
    uniqueId String,
    dev      Smallint

  --use fjswifi

  Call ui.Interface.loadStyles("influencerclient")

  Close Window Screen
  Open Window wWelcome With Form "welcome"

  Display "header.png" To head
  Display %"...Initializing..." To msg

  Let i = 0
  Let dev = 0
  Let internet = False

  Menu ""
    Before menu
      Let foot = "footer"||i+1||".jpg"
      Display By Name foot
      Let fileName = core_os.checkFile("param.db",fgl_getenv("DBPATH"))
      If fileName Is Null Then
        Let fileName = "param.db"
        If (retCode:=core_os.createFile(fileName)) <> 0 Then
          If ui_message("Error","An error occured\ncontact the developer: "||retCode,"ok","ok","cancel-red") Then End If
          Exit Program -1
        End If
      End If
      If (retCode:=connectToDatabase("param.db+driver='dbmsqt'")) <> 0 Then
        If ui_message("Error","An error occured\ncontact the developer: "||retCode,"ok","ok","cancel-red") Then End If
        Exit Program -2
      End If
      Try
        Select count(*) From params
      Catch
        If (retCode:=createParamSchema()) <> 0 Then
          If ui_message("Error","An error occured\ncontact the developer: "||retCode,"ok","ok","cancel-red") Then End If
          Exit Program -3
        End If
      End Try
      Let uniqueId = generateUniqueId()
      Let uniqueId = util.Strings.urlEncode(uniqueId)
      Call ui.Interface.frontCall("mobile", "connectivity", [], [internet] )
      If internet.toLowerCase() = "none" Then
        Display %"No Internet connection" To msg
        Call Dialog.setActionActive("go",False)
      Else
        Display "" To msg
        Call Dialog.setActionActive("go",True)
      End If

    --On Action close
      --Exit Menu
    On Action dev
      If i=0 Then
        Let i=1
      End If
      Let dev = dev+1
      If dev=5 Then
        Call Dialog.setActionText("go",%"Test")
        Display %"Test Mode On" To msg
      End If
      If dev=6 Then
        Call Dialog.setActionText("go",%"Start")
        Display "" To msg
        Let dev=0
      End If

    On Action go
      --LET s = "10.253.0.89"
      --PROMPT "Ip: " FOR s ATTRIBUTES(WITHOUT DEFAULTS)
      If Not connectToServer(uniqueId,dev=5) Then
        Call Dialog.setActionActive("go",False)
      End If
      --CALL ui.Interface.frontCall("mobile", "runOnServer", ["http://192.168.1.13:6394/ua/r/salfatixmedia4influencers_dh"], [])

    On Timer 15
      If i=0 Then
        Let i=1
        If internet.toLowerCase() <> "none" Then
          If Not connectToServer(uniqueId,dev=5) Then
            Call Dialog.setActionActive("go",False)
          End If
        End If
      End If
      If dev>1 Then
        Let dev=0
        Display "" To msg
      End If
      Let i = Iif(i=9,1,i+1)
      Let foot = "footer"||i||".jpg"
      Display By Name foot
      If internet.toLowerCase() = "none" Then
        Call ui.Interface.frontCall("mobile", "connectivity", [], [internet] )
        If internet.toLowerCase() = "none" Then
          Display %"No Internet connection" To lb1
          Call Dialog.setActionActive("go",False)
        Else
          Display NULL To msg
          Call Dialog.setActionActive("go",True)
        End If
        If internet Is Null Then
          Display %"Please Upgrade" To lb1
          Call Dialog.setActionActive("go",False)
        End If
      End If

    --On Action cancel
      --Exit Menu
  End Menu
End Main

Private Function connectToServer(uniqueId String, dev Boolean)
  Define
    s  String,
    r  Boolean,
    lg String

  --TRY
    --CALL ui.Interface.frontCall("standard","feInfo","userPreferredLang",[lg])
  --CATCH
    --LET lg = "default"
  --END TRY
  --LET s = SFMT("%1?Arg=%2Arg=%3",base.Application.getResourceEntry("salfatix.influencer.url"),uniqueId,lg)

  If dev Then
    LET s = SFMT("%1?Arg=%2&Arg=dev",base.Application.getResourceEntry("salfatix.influencer.urltest"),uniqueId)
  Else
    LET s = SFMT("%1?Arg=%2",base.Application.getResourceEntry("salfatix.influencer.url"),uniqueId)
  End If
  IF s IS NULL THEN
    IF ui_message("Error","You are not using the last version\nOf the application\nPlease upgrade","ok","ok","cancel-red") Then End If
    Let r = False
  ELSE
    Let r = True
    Display NULL To msg
    TRY
      CALL ui.Interface.frontCall("mobile", "runOnServer", [s], [])
    CATCH
      Display %"Please log in again" To msg
    END TRY
  END IF

  Return r
End Function

Public Function connectToDatabase( dbName String )
  Try
    Connect To dbName
  Catch
  End Try
  Return sqlCa.sqlCode
End Function

Public Function createParamSchema()
  Define
    ok Boolean

  Call dropParamTables()
  Let ok = createParamTables()
  Return ok
End Function

Private Function createParamTables()
  Define
    ok Integer

  Let ok = 0
  Try
    Execute Immediate "Create Table params (
          id Integer Not Null,
          desc Varchar(20) Not Null,
          value Varchar(200) Not Null)"
  Catch
    Let ok = SqlCa.sqlcode
  End Try
  Return ok
End Function

Private Function dropParamTables()
  Whenever Error Continue
    Execute Immediate "Drop Table params"
  Whenever Error Stop
End Function

Private Function generateUniqueId()
  Define
    uniqueId String,
    uniqueNo Integer,
    dgst     security.Digest

  Try
    Select params.value Into uniqueId From params Where params.id = 1
  Catch
    Let uniqueId = Null
  End Try

  If uniqueId Is Null Then
    Let uniqueNo = fgl_getpid()
    Call util.Math.srand()
    Let uniqueId = uniqueNo||util.Math.rand(uniqueNo)||Current Year To Fraction(5)
    Let dgst = security.Digest.CreateDigest("MD5")
    Call dgst.AddStringData(uniqueId)
    Let uniqueId = dgst.DoBase64Digest()
    Insert Into params Values (1,"Unique Id",uniqueId)
  End If

  Return uniqueId
End Function