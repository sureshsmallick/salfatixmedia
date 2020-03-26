Import com
Import util
Import security
Import FGL setup
Import FGL core_ui

SCHEMA salfatixmedia


#TODO: change keys in table params (id=5) (id=6)

Public Function allowNotification( allow Boolean, userId Like users.usr_id, deviceId String )
  Define
    registrationToken String,
    deviceType        String

  If setup.g_app_is_mobile Then
    If allow Then
      If Not notificationTokenExists(userId,deviceId) Then
        Let registrationToken = registerForNotifications()
        If registrationToken Is Not Null Then
          Let deviceType = ui.Interface.getFrontEndName()
          Call addNewNotificationToken(userId,deviceId,deviceType,registrationToken)
        End If
      End If
    Else
      Call unregisterFromNotifications(userId,deviceId)
    End If
  End If
End Function

Public Function sendNotification( userId Like users.usr_id, ttl String, msg String )
  Define
    recipients Dynamic Array Of Record Like notificationtokens.*,
    i          Integer,
    msgJson    util.JsonObject,
    apsJson    util.JsonObject,
    dataJson   util.JsonObject,
    sts        Integer,
    res        STRING

  Call getRecipients(userId,recipients)
  For i = 1 To recipients.getLength()
    Case recipients[i].ntt_device_type
      When "GMI"
        Let msgJson = util.JSONObject.create()
        Let apsJson = util.JSONObject.create()
        Call apsJson.put("alert", ttl)
        Call apsJson.put("sound", "default")
        Let recipients[i].ntt_meter = recipients[i].ntt_meter + 1
        Call apsJson.put("badge", recipients[i].ntt_meter)
        Call saveNewMeter(recipients[i].*)
        Call apsJson.put("content-available", 1)
        Call msgJson.put("aps", apsJson)
        Let dataJson = util.JSONObject.create()
        Call dataJson.put("other_info", msg)
        Call msgJson.put("custom_data", dataJson)
        Call postAppleNotification( recipients[i].ntt_token, msgJson) RETURNING sts, res
        Initialize msgJson, apsJson, dataJson To Null
      When "GMA"
        Call postGoogleNotification( recipients[i].ntt_token, msg )
      Otherwise
    End Case

  End For
End Function

Private Function registerForNotifications()
  Define
    registration_token String,
    senderId           String

  Let senderId = getSenderId()
  Let registration_token = Null
  Try
    #TODO: Old GCM won't work after April 2019
    Call ui.Interface.frontCall("mobile","registerForRemoteNotifications",[senderId], [registration_token] )
  Catch
    Let registration_token = Null
  End Try

  Return registration_token
End Function

Private Function unregisterFromNotifications( userId Like users.usr_id, deviceId String )
  Define
    senderId           String

  Let senderId = getSenderId()
  Try
    Delete From notificationtokens Where notificationtokens.ntt_usr_id = userId And notificationtokens.ntt_unique_id = deviceId
    Call ui.Interface.frontCall("mobile", "unregisterFromRemoteNotifications",[ senderId ], [ ] )
  Catch
    IF core_ui.ui_message(%"Error",%"Notification delete \n"||Status||"\n"||NVL(SQLERRMESSAGE," "),"ok","ok","cancel-red") THEN END IF
  End Try
End Function

-- Database
Private Function getRecipients(userId Like users.usr_id,recipients Dynamic Array Of Record Like notificationtokens.* )
  Define
    rUserTokens Record Like notificationtokens.*

  Call recipients.clear()
  Declare cNtt Cursor For Select * From notificationtokens Where ntt_usr_id = userId
  Foreach cNtt Into rUserTokens.*
    Call recipients.appendElement()
    Let recipients[recipients.getLength()]. * = rUserTokens.*
  End Foreach
  Free cNtt
End Function

Private Function saveNewMeter( recipient Record Like notificationtokens.* )
  Update notificationtokens
     Set notificationtokens.ntt_meter = recipient.ntt_meter
   Where notificationtokens.ntt_usr_id = recipient.ntt_usr_id
     And notificationtokens.ntt_token = recipient.ntt_token
     And notificationtokens.ntt_device_type = "GMI"
End Function

Private Function getSenderId()
  Define
    senderId String

  Try
    SELECT params.par_des INTO senderId FROM params WHERE params.par_typ = 2 AND params.par_id = 5
  Catch
    If core_ui.ui_message(%"Error",%"Param 5 \n"||SQLCA.sqlcode||"\n"||NVL(sqlErrMessage," "),"ok","ok","cancel-red") THEN END IF
    Let senderId = Null
  End Try

  RETURN senderId
End Function

Private Function getFcmApiKey()
  Define
    fcmApiKey String

  Try
    SELECT params.par_des INTO fcmApiKey FROM params WHERE params.par_typ = 2 AND params.par_id = 6
  Catch
    If core_ui.ui_message(%"Error",%"Param 6 \n"||SQLCA.sqlcode||"\n"||NVL(sqlErrMessage," "),"ok","ok","cancel-red") THEN END IF
    Let fcmApiKey = Null
  End Try

  Return fcmApiKey
End Function

Private Function notificationTokenExists( userId Like users.usr_id, deviceId String )
  Define
    itExists Boolean

  Try
    Select count(*) From notificationtokens Where notificationtokens.ntt_usr_id = userId And notificationtokens.ntt_unique_id = deviceId
    If sqlca.sqlcode = NOTFOUND Then
      Let itExists = False
    Else
      Let itExists = True
    End If
  Catch
    If core_ui.ui_message(%"Error",%"Notification token read \n"||SQLCA.sqlcode||"\n"||NVL(SQLERRMESSAGE," "),"ok","ok","cancel-red") THEN END IF
    Let itExists = False
  End Try

  Return itExists
End Function

Private Function addNewNotificationToken( userId Like users.usr_id, deviceId String, deviceType String, registrationToken String )
  Try
    Insert Into notificationtokens Values (0,userId,deviceId,deviceType,0,registrationToken)
  Catch
    If core_ui.ui_message(%"Error",%"Notification token write \n"||SQLCA.sqlcode||"\n"||NVL(SQLERRMESSAGE," "),"ok","ok","cancel-red") THEN END IF
  End Try
End Function

-- Web Services
Private Function postGoogleNotification( recipient String, msg String )
  Define
    recipients     Dynamic Array Of String,
    httpRequest    com.httpRequest,
    httpResponse   com.httpResponse,
    fcmApiKey      String,
    jsonObjToSend  util.JSONObject

  #TODO: before April 2019 get access token ...
  --Let accessToken = getAccessToken()

  Let fcmApiKey = getFcmApiKey()
  If fcmApiKey Is Not Null Then
    Let recipients[1] = recipient
    Try
      #TODO: before April 2019 ...
--    Let httpRequest = com.HTTPRequest.create("https://fcm.googleapis.com/v1/projects/testnotifsgenero/messages:send")
      Let httpRequest = com.HTTPRequest.Create("https://gcm-http.googleapis.com/gcm/send")
      Let jsonObjToSend = util.JSONObject.create()
      Call jsonObjToSend.put("registration_ids",Recipients)
      Call jsonObjToSend.put("data",util.JSONObject.parse(msg))
      -- 4096 bytes for Android
      -- 2000 bytes for iOS
      If jsonObjToSend.toString().getLength() <= 4096 Then
        Call httpRequest.setHeader("Content-Type", "application/json")
        #TODO: before April 2019 ...
--      Call httpRequest.setHeader("Authorization","Bearer"||accessToken)
        Call httpRequest.setHeader("Authorization","key="||getFcmApiKey())
        Call httpRequest.setMethod("POST")
        Call httpRequest.setTimeOut(5)
        Call httpRequest.doTextRequest(jsonObjToSend.toString())
        Let httpResponse = httpRequest.getResponse()
        If httpResponse.getStatusCode() = 200 Then
        Else
        End If
      Else
      End If
    Catch
      If core_ui.ui_message(%"Error",%"Notification post \n"||Status,"ok","ok","cancel-red") THEN END IF
    End Try
  End If

End Function

Private Function postAppleNotification( token String, msg util.JSONObject )
  Define
    uuid        String,
    ecode       Integer,
    exp         Integer,
    sts         Integer,
    res         String,
    data        Byte,
    resp        Byte,
    tcpRequest  com.tcpRequest,
    tcpResponse com.TCPResponse

  Locate data In Memory
  Locate resp In Memory

  Try
    Let tcpRequest = com.TCPRequest.create( "tcps://gateway.sandbox.push.apple.com:2195" )
    Call tcpRequest.setKeepConnection(true)
    Call tcpRequest.setTimeout(2)
    Let uuid = security.RandomGenerator.createRandomString(4)
    Let exp = util.Datetime.toSecondsSinceEpoch(Current + Interval(10) Minute To Minute)
    Call com.APNS.EncodeMessage(data,security.HexBinary.ToBase64(token),msg.toString(),uuid,exp,10)
    Call tcpRequest.doDataRequest(data)
  Catch
    Let sts = Status
    Let res = "Error: ",sts," ",sqlca.sqlerrm
  End Try
  If sts = 0 Then
    Try
      Let tcpResponse = tcpRequest.getResponse()
      Call tcpResponse.getDataResponse(resp)
      Call com.APNS.DecodeError(resp) Returning uuid, ecode
    Catch
      Let sts = Status
      Case sts
        When -15553 Let res = "Timeout Push sent without error"
        When -15566 Let res = "Operation failed :", SQLCA.SQLERRM
        When -15564 Let res = "Server has shutdown"
        Otherwise   Let res = "ERROR :",STATUS
      End Case
    End Try
  End If

  Return sts,res
End Function
