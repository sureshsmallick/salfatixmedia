Import com
Import util
Import xml

Public Define
  oauthDebug Boolean

Private Constant
  STATE_AVAILABLE  = "Available",
  STATE_REFERENCED = "Referenced",
  STATE_CODE       = "Code Requested",
  STATE_TOKEN      = "Token Requested",
  STATE_CONNECTED  = "Connected",
  MAX_TRIALS       = 3,
  EXPIRY_TIME      = 1, --Day
  KIND_OF_KEY      = "http://www.w3.org/2001/04/xmlenc#rsa-1_5"

Private Type
  t_instagramUser      Record
    access_token        String,
    user                Record
      id                  String,
      username            String,
      profile_picture     String,
      full_name           String,
      bio                 String,
      website             String,
      is_business         Boolean
                        End Record
                      End Record,
  tItems              Record
    name                String,
    value               String
                      End Record,
  tParam              Record
    uriHead             String,
    uriPaths            Dictionary Of Record
      path                String,
      items               Dynamic Array Of Record
        name                String,
        value               String
                          End Record
                        End Record
                      End Record,
  tClient             Record
    state               String,
    mySecretKey         xml.CryptoKey,
    hisPublicKey        xml.CryptoKey,
    created             DateTime Year To Second,
    lastRequest         DateTime Year To Second,
    expiryDate          DateTime Year To Second,
    trials              Smallint,
    network             String,
    values              Dictionary Of String
                      End Record,
  tHttpReqInfo        Record
    method              String,
    path                String,
    host                String,
    port                String,
    headers             Dictionary Of String,
    items               Dictionary Of String,
    body                String
                      End Record,
  tMyValues Record
    items     Dictionary Of Record
      myValue   String,
      encrypt   Boolean
              End Record
            End Record

Private Define
  redirectUri    String,
  ignoreUrlPath  STRING,
  mSocialParams  Dictionary Of tParam,
  clients        Dictionary Of tClient

Public Function setSocialNetworkUriHead( socialNetwork String, uriHead String )
  If uriHead.getCharAt(uriHead.getLength()) = "/" Then
    Let uriHead = uriHead.subString(1,uriHead.getLength()-1)
  End If
  Let mSocialParams[socialNetwork.toLowerCase()].uriHead = uriHead
End Function

Public Function setSocialNetworkPath( socialNetwork String, pathType String, path String )
  If path.getCharAt(1) <> "/" And path.getIndexOf("http",1)<>1 Then
    Let path = "/",path
  End If
  Let mSocialParams[socialNetwork.toLowerCase()].uriPaths[pathType.toLowerCase()].path = path
End Function

Public Function addSocialNetworkQuery( socialNetwork String, pathType String, queryName String, val String )
  Call mSocialParams[socialNetwork.toLowerCase()].uriPaths[pathType.toLowerCase()].items.appendElement()
  Let mSocialParams[socialNetwork.toLowerCase()].uriPaths[pathType.toLowerCase()].items[mSocialParams[socialNetwork.toLowerCase()].uriPaths[pathType.toLowerCase()].items.getLength()].name = queryName
  Let mSocialParams[socialNetwork.toLowerCase()].uriPaths[pathType.toLowerCase()].items[mSocialParams[socialNetwork.toLowerCase()].uriPaths[pathType.toLowerCase()].items.getLength()].value = val
End Function

Public Function setRedirectUri( uri String )
  If uri.getCharAt(uri.getLength()) = "/" Then
    Let uri = uri.subString(1,uri.getLength()-1)
  End If
  Let redirectUri = uri
End FUNCTION

Public Function setUrlPathToIgnore( uri String )
  If uri.getCharAt(uri.getLength()) = "/" Then
    Let uri = uri.subString(1,uri.getLength()-1)
  End If
  Let ignoreUrlPath = uri
End Function


Public Function processReq( httpReq com.HttpServiceRequest )
  Define
    httpReqInfo   tHttpReqInfo,
    id            String,
    nbHeaders     Integer,
    answerValues  Dictionary Of tMyValues,
    httpCode      Integer

  Let httpReqInfo.method       = httpReq.getMethod()
  Let httpReqInfo.path         = httpReq.getUrlPath()
  LET httpReqInfo.path = _ignoreUrlPath(httpReqInfo.path)
  Let httpReqInfo.host         = httpReq.getUrlHost()
  Let httpReqInfo.port         = httpReq.getUrlPort()
  Call getRequestHeader(httpReq,httpReqInfo.headers)
  Call getRequestItems(httpReq,httpReqInfo.items)
  Call getRequestBody(httpReq, httpReqInfo.headers) Returning httpReqInfo.body
  Call showServiceRequest(httpReq, httpReqInfo.*)

  Call cleanTable()
  Let nbHeaders = httpReq.getRequestHeaderCount()
  If nbHeaders > 0 Then
    Case
      When httpReqInfo.method = "POST"
           And httpReqInfo.path = "/social/login/authorization/share"
           And httpReqInfo.items.contains("id")
        Let httpCode = processShareRequest(httpReq,httpReqInfo.*)

      When httpReqInfo.method = "GET"
           And httpReqInfo.path = "/social/login/authorization/connect"
           And httpReqInfo.items.contains("id")
        Let httpCode = processConnectRequest(httpReq,httpReqInfo.*)

      When httpReqInfo.method = "GET"
           And httpReqInfo.path = "/"
           And httpReqInfo.items.contains("id")
           And httpReqInfo.items.contains("code")
        Let httpCode = processCodeRequest(httpReq,httpReqInfo.*)

      When httpReqInfo.method = "GET"
           And httpReqInfo.path = "/favicon.ico"
           And httpReqInfo.headers.contains("Referer")
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthUser: got a ping request (favicon.ico)"
        End If
        Let httpCode = 200
        Call answerValues.clear()
        Call reply(id,httpReq,httpCode,answerValues)

      When httpReqInfo.method = "GET"
           And httpReqInfo.path = "/social/login/authorization/isokay"
           And httpReqInfo.items.contains("id")
        Let httpCode = processValidationRequest(httpReq,httpReqInfo.*)

      When httpReqInfo.method = "GET"
           And httpReqInfo.path = "/social/logout"
           And httpReqInfo.items.contains("socialNetwork")
        Let httpCode = processLogoutRequest(httpReq,httpReqInfo.*)

      Otherwise
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthUser: got unknown request"
        End If
        Let httpCode = 406
        Call answerValues.clear()
        Call reply(id,httpReq,httpCode,answerValues)
    End Case
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: got request without headers"
    End If
    Let httpCode = 400
    Call answerValues.clear()
    Call reply(id,httpReq,httpCode,answerValues)
  End If

  Return httpCode
End Function

Private Function processLogoutRequest( httpReq com.HttpServiceRequest, httpReqInfo tHttpReqInfo )
  Define
    retrievedValues Dictionary Of tMyValues,
    responseValues  Dictionary Of tMyValues,
    socialNetwork   String,
    httpCode        Integer

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: got logout request"
  End If
  Let httpCode = 200
  Call responseValues.clear()
  Call retrievedValues.clear()
  If httpCode = 200 Then
    Let httpCode = retrieveValues(Null,httpReqInfo.*,retrievedValues)
  End If
  If httpCode = 200 Then
    If Not retrievedValues["query"].items.contains("socialNetwork") Then
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Wrong request"
      End If
      Let httpCode = 404
      Call responseValues.clear()
    End If
  End If
  If httpCode = 200 Then
    Let socialNetwork = retrievedValues["query"].items["socialNetwork"].myValue.toLowerCase()
    If Not mSocialParams.contains(socialNetwork.toLowerCase()) Then
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Unknown network"
      End If
      Let httpCode = 400
      Call responseValues.clear()
      Let responseValues["body"].items["error"].myValue = "Unknown social network"
      Let responseValues["body"].items["error"].encrypt = False
    End If
  End If
  If httpCode = 200 Then
    Call responseValues.clear()
    Let responseValues["body"].items["Location"].myValue = mSocialParams[socialNetwork].uriPaths["logout"].path
    Let responseValues["body"].items["Location"].encrypt = False
  End If
  Call reply(Null,httpReq,httpCode,responseValues)

  Return httpCode
End Function

Private Function processShareRequest( httpReq com.HttpServiceRequest, httpReqInfo tHttpReqInfo )
  Define
    id              String,
    retrievedValues Dictionary Of tMyValues,
    responseValues  Dictionary Of tMyValues,
    encryption      xml.encryption,
    xmlDoc          xml.DomDocument,
    httpCode        Integer,
    jsonObj         util.JSONObject

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: got share request"
  End If
  Let id = util.Strings.urlDecode(httpReqInfo.items["id"])
  Let httpCode = 200
  Call responseValues.clear()
  Call retrievedValues.clear()
  If referenceClient(id) Then
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: got public key: ",httpReqInfo.body
    End If
    Try
      If httpReqInfo.body Is Not Null Then
        Let jsonObj = util.JSONObject.parse(httpReqInfo.body)
        Call jsonObj.toFGL(retrievedValues["body"].items)
      End If
      Call clients[id].hisPublicKey.loadPublicFromString(retrievedValues["body"].items["pubkey"].myValue)
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Public key Infos"
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Key Size: ",clients[id].hisPublicKey.getSize()
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Key Type: ",clients[id].hisPublicKey.getType()
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Key Usage: ",clients[id].hisPublicKey.getUsage()
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Key Object: ",clients[id].hisPublicKey.saveToString()
      End If
      If generateSharedSecret(id) Then
        Let encryption = xml.Encryption.Create()
        Call encryption.setKeyEncryptionKey(clients[id].hisPublicKey)
        Let xmlDoc = encryption.encryptKey(clients[id].mySecretKey)
        Let responseValues["body"].items["sharedSecret"].myValue = xmlDoc.saveToString()
        Let responseValues["body"].items["sharedSecret"].encrypt = False
      Else
        Let responseValues["body"].items["error"].myValue = "Could not generate shared secret"
        Let responseValues["body"].items["error"].encrypt = False
        Let httpCode = 400
      End If
    Catch
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: error while reading his public key: ",Status," ",Sqlca.sqlerrm
      End If
      Let responseValues["body"].items["error"].myValue = "Could not read public key"
      Let responseValues["body"].items["error"].encrypt = False
      Let httpCode = 400
    End Try
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Client not referenced"
    End If
    Let responseValues["body"].items["id"].myValue     = util.Strings.urlEncode(id)
    Let responseValues["body"].items["id"].encrypt     = False
    Let responseValues["body"].items["result"].myValue = "Retry"
    Let responseValues["body"].items["result"].encrypt = False
  End If
  Call reply(id,httpReq,httpCode,responseValues)

  Return httpCode
End Function

Private Function processConnectRequest( httpReq com.HttpServiceRequest, httpReqInfo tHttpReqInfo )
  Define
    id              String,
    retrievedValues Dictionary Of tMyValues,
    responseValues  Dictionary Of tMyValues,
    i               Smallint,
    socialNetwork   String,
    httpCode        Integer

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: got connection request"
  End If
  Call responseValues.clear()
  Call retrievedValues.clear()
  Let id = util.Strings.urlDecode(httpReqInfo.items["id"])
  Let httpCode = 200
  If Not clients.contains(id) Then
    Let httpCode = 400
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Client not referenced"
    End If
  End If

  If httpCode = 200 Then
    Let httpCode = retrieveValues(id,httpReqInfo.*,retrievedValues)
  End If

  If httpCode = 200 Then
    If Not retrievedValues["query"].items.contains("socialNetwork") Then
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Wrong request"
      End If
      Let httpCode = 404
      Call responseValues.clear()
      Let responseValues["body"].items["id"].myValue    = util.Strings.urlEncode(id)
      Let responseValues["body"].items["id"].encrypt    = False
    End If
  End If
  If httpCode = 200 Then
    Let socialNetwork = retrievedValues["query"].items["socialNetwork"].myValue.toLowerCase()
    If Not referenceNetwork(id,socialNetwork) Then
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Social Network not referenced"
      End If
      Let httpCode = 400
      Call responseValues.clear()
      Let responseValues["body"].items["id"].myValue    = util.Strings.urlEncode(id)
      Let responseValues["body"].items["id"].encrypt    = False
      Let responseValues["body"].items["error"].myValue = "Unknown social network"
      Let responseValues["body"].items["error"].encrypt = False
    End If
  End If
  If httpCode = 200 Then
    Call responseValues.clear()
    Let responseValues["body"].items["Location"].myValue = mSocialParams[socialNetwork].uriHead
                                                           ||mSocialParams[socialNetwork].uriPaths["code"].path
    Let responseValues["body"].items["Location"].encrypt = True
    For i = 1 To mSocialParams[socialNetwork].uriPaths["code"].items.getLength()
      If mSocialParams[socialNetwork].uriPaths["code"].items[i].value = "val" Then
        Case mSocialParams[socialNetwork].uriPaths["code"].items[i].name
          When "redirect_uri"
            Let responseValues["body"].items["redirect_uri"].myValue = redirectUri,"?id=",id
            Let responseValues["body"].items["redirect_uri"].encrypt = True
          Otherwise
            Let responseValues["body"].items[mSocialParams[socialNetwork].uriPaths["code"].items[i].name].myValue = clients[id].values[mSocialParams[socialNetwork].uriPaths["code"].items[i].name]
            Let responseValues["body"].items[mSocialParams[socialNetwork].uriPaths["code"].items[i].name].encrypt = True
        End Case
      Else
        Let responseValues["body"].items[mSocialParams[socialNetwork].uriPaths["code"].items[i].name].myValue = mSocialParams[retrievedValues["query"].items["socialNetwork"].myValue.toLowerCase()].uriPaths["code"].items[i].value
        Let responseValues["body"].items[mSocialParams[socialNetwork].uriPaths["code"].items[i].name].encrypt = True
      End If
    End For
  End If
  Call reply(id,httpReq,httpCode,responseValues)

  Return httpCode
End Function

Private Function processCodeRequest( httpReq com.HttpServiceRequest, httpReqInfo tHttpReqInfo )
  Define
    id              String,
    responseValues  Dictionary Of tMyValues,
    httpCode        Integer

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: got code value"
  End If
  Let id = util.Strings.urlDecode(httpReqInfo.items["id"])
  If clients.contains(id) Then
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Code stored for ",id
    End If
    Let clients[id].values["code"] = httpReqInfo.items["code"]

    Call getTokenFromSocialNetwork( id, clients[id].network ) Returning httpCode
    Let httpCode = Iif(getCodeText(httpCode) Is Null,401,httpCode)
    Call responseValues.clear()
    Let responseValues["body"].items["plain"].myValue = '<html><head><meta http-equiv="refresh" content="0; url=https://www.salfatixmedia.com/"><style>h1 { text-align: center; } svg { display: block; margin-left: auto; margin-right: auto; }</style></head><body><h1><a href="https://www.salfatixmedia.com/">It Worth the Wait!!</a></h1><br /><svg width="300" height="300"><g><circle id="circle-60m" fill-opacity="1"    cx="150" cy="55" r="30" /><circle id="circle-12m" fill-opacity="0.87" cx="220.5" cy="86" r="28.5" /><circle id="circle-15m" fill-opacity="0.75" cx="248" cy="150" r="27" /><circle id="circle-20m" fill-opacity="0.63" cx="239" cy="210" r="19" /><circle id="circle-25m" fill-opacity="0.63" cx="199" cy="246" r="17" /><circle id="circle-30m" fill-opacity="0.50" cx="150" cy="260" r="15" /><circle id="circle-32m" fill-opacity="0.48" cx="109" cy="253" r="13" /><circle id="circle-34m" fill-opacity="0.46" cx="77" cy="237" r="11" /><circle id="circle-36m" fill-opacity="0.44" cx="55" cy="215" r="9" /><circle id="circle-38m" fill-opacity="0.42" cx="41" cy="192" r="7" /><circle id="circle-40m" fill-opacity="0.40" cx="33" cy="170" r="5.5" /><circle id="circle-45m" fill-opacity="0.25" cx="30" cy="150" r="5" /><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 150 150" to="360 150 150" begin="1s" dur="2s" fill="freeze" repeatCount="indefinite" /></g>SVG Not supported</svg></body></html>'
    Let responseValues["body"].items["plain"].encrypt = False
    --Let responseValues["body"].items["id"].myValue = util.Strings.urlEncode(id)
    --Let responseValues["body"].items["id"].encrypt = False
    If httpCode = 200 Then
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Welcome ",clients[id].values["body"]
      End If
    End If
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Client not referenced"
    End If
    Let httpCode = 406
    Call responseValues.clear()
    Let responseValues["body"].items["id"].myValue = util.Strings.urlEncode(id)
    Let responseValues["body"].items["id"].encrypt = False
    Let responseValues["body"].items["error"].myValue = "Client not referenced"
    Let responseValues["body"].items["error"].encrypt = False
  End If
  Call reply(id,httpReq,httpCode,responseValues)

  Return httpCode
End Function

Private Function processValidationRequest( httpReq com.HttpServiceRequest, httpReqInfo tHttpReqInfo )
  Define
    id              String,
    responseValues  Dictionary Of tMyValues,
    httpCode        Integer

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: got login acknowledgement"
  End If
  Call responseValues.clear()
  Let id = util.Strings.urlDecode(httpReqInfo.items["id"])
  If clients.contains(id) Then
    If clients[id].values.contains("body") Then
      If clients[id].values["body"].getLength() > 0 Then
        Let responseValues["body"].items["user"].myValue = clients[id].values["body"]
        Let responseValues["body"].items["user"].encrypt = True
        Let httpCode = 200
      Else
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthUser: Body empty"
        End If
        Let httpCode = 401
      End If
    Else
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: No Body"
      End If
      Let httpCode = 401
    End If
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Client unknown"
    End If
    Let httpCode = 401
  End If
  Call reply(id,httpReq,httpCode,responseValues)

  Return httpCode
End Function

Private Function referenceClient( id String )
  Define
    retCode Boolean

  Let retCode = True
  If clients.getLength() > 0 Then
    If clients.contains(id) Then
      If clients[id].state <> STATE_AVAILABLE Then
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthUser: Wrong state ",clients[id].state
        End If
        Let clients[id].trials = clients[id].trials + 1
        If clients[id].trials > MAX_TRIALS Then
          Call clients.remove(id)
          Let retCode = False
        End If
        Let retCode = False
      Else
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthUser: Existing client who connects, no problem"
        End If
        Let clients[id].lastRequest = Current Year To Second
        Let clients[id].hisPublicKey = xml.cryptoKey.Create(KIND_OF_KEY)
      End If
    Else
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: New client (",clients.getLength(),")"
      End If
      Let clients[id].state       = STATE_AVAILABLE
      Let clients[id].created     = Current Year To Second
      Let clients[id].lastRequest = Current Year To Second
      Let clients[id].values["id"] = id
      Let clients[id].hisPublicKey = xml.cryptoKey.Create(KIND_OF_KEY)
    End If
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: First new client"
    End If
    Let clients[id].state       = STATE_AVAILABLE
    Let clients[id].created     = Current Year To Second
    Let clients[id].lastRequest = Current Year To Second
    Let clients[id].values["id"] = id
    Let clients[id].hisPublicKey = xml.cryptoKey.Create(KIND_OF_KEY)
  End If

  Return retCode
End Function

Private Function referenceNetwork( id String, socialNetwork String )
  Define
    retCode Boolean

  Let retCode = True
  If Not mSocialParams.contains(socialNetwork.toLowerCase()) Then
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Unknown network"
    End If
    Let retCode = False
  Else
    If clients.contains(id) Then
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Network for client added"
      End If
      Let clients[id].network = socialNetwork.toLowerCase()
      Let clients[id].lastRequest = Current Year To Second
      Let clients[id].lastRequest = Current Year To Second + EXPIRY_TIME Units Day
    Else
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Unknown client, can't add this network"
      End If
      Let retCode = False
    End If
  End If

  Return retCode
End Function

Private Function getTokenFromSocialNetwork( id String, socialNetwork String )
  Define
    url           com.HttpRequest,
    resp          com.HttpResponse,
    urlStr        String,
    msg           String,
    i             SmallInt,
    httpRetCode   SmallInt

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: Request Token From social network"
  End If
  If clients[id].network = socialNetwork.toLowerCase() Then
    Let msg = Null
    For i = 1 To mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items.getLength()
      If mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].value <> "val" Then
        Let msg = msg.append(Iif(msg Is Null,"?","&")
                           ||mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].name
                           ||"="
                           ||mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].value
                          )
      Else
        Case mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].name
          When "redirect_uri"
            Let msg = msg.append(Iif(msg Is Null,"?","&")
                           ||mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].name
                           ||"="
                           ||redirectUri||"?id="||id
                          )
          Otherwise
            Let msg = msg.append(Iif(msg Is Null,"?","&")
                           ||mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].name
                           ||"="
                           ||clients[id].values[mSocialParams[socialNetwork.toLowerCase()].uriPaths["token"].items[i].name]
                          )
        End Case
      End If
    End For
    Let msg = msg.subString(2,msg.getLength())

    Let urlStr = mSocialParams[socialNetwork].uriHead
                 ||mSocialParams[socialNetwork].uriPaths["token"].path
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: ",urlStr
      Display "[",Current Hour To Fraction(5),"] OAuthUser: ",msg
    End If
    Try
      Let url = com.HttpRequest.Create(urlStr)
      Call url.setMethod("POST")
      Call url.setAutoCookies(True)
      Call url.setHeader("user-agent","GeneroDVM/3.10.09")
      Call url.setHeader("accept","*/*")
      Call url.setHeader("accept-encoding","gzip, deflate")
      Call url.doFormEncodedRequest(msg,True)
      Let resp = url.getResponse()
      Let httpRetCode = resp.getStatusCode()
      Case httpRetCode
        When 200
          Let msg = resp.getTextResponse()
          If oauthDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthUser: Response",msg
          End If
          Let clients[id].values["body"]  = msg
        Otherwise
          #TODO: HTTP error
          Let msg = "HTTP error: ",httpRetCode
          If oauthDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthUser: ",msg
          End If
      End Case
    Catch
      #TODO: Program error
      Let msg = "Program error: ",Status," ",sqlCa.sqlerrm
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: ",msg
      End If
      Let httpRetCode = -1
    End Try
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Wrong network"
    End If
    Let httpRetCode = 400
  End If

  Return httpRetCode
End Function

-- Utils
Private Function retrieveValues( id String,httpReqInfo tHttpReqInfo,retrievedValues Dictionary Of tMyValues )
  Define
    keys     Dynamic Array Of String,
    i        Smallint,
    jsonObj  util.JSONObject,
    httpCode Smallint

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthUser: Read recieved values"
  End If
  Let httpCode = 200
  If httpReqInfo.body Is Not Null Then
    Let jsonObj = util.JSONObject.parse(httpReqInfo.body)
    Call jsonObj.toFGL(retrievedValues["body"].items)
    Let keys = retrievedValues["body"].items.getKeys()
    For i=1 To keys.getLength()
      If retrievedValues["body"].items[keys[i]].encrypt Then
        Try
          Let retrievedValues["body"].items[keys[i]].myValue = xml.Encryption.DecryptString(clients[id].mySecretKey,retrievedValues["body"].items[keys[i]].myValue)
        Catch
          Let httpCode = 400
          If oauthDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthUser: Decrypt body failed: ",Status," ",sqlca.sqlerrm
          End If
        End Try
      End If
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Read from body: ",keys[i]," ",retrievedValues["body"].items[ keys[i] ].myValue
      End If
    End For
  Else
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Nothing in the body"
    End If
  End If
  If httpCode = 200 Then
    If httpReqInfo.items.getLength() > 0 Then
      Let keys = httpReqInfo.items.getKeys()
      For i=1 To keys.getLength()
        If keys[i].subString(1,3) = "sig" Then
          Try
            Let retrievedValues["query"].items[ keys[i].subString( 4,keys[i].getLength() ) ].myValue = xml.Encryption.DecryptString(clients[id].mySecretKey,httpReqInfo.items[keys[i]])
            If oauthDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthUser: Read from queries: ",keys[i].subString( 4,keys[i].getLength() )," ",retrievedValues["query"].items[ keys[i].subString( 4,keys[i].getLength() ) ].myValue
            End If
          Catch
            Let httpCode = 400
            If oauthDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthUser: Decrypt query failed: ",Status," ",sqlca.sqlerrm
            End If
          End Try
        Else
          Let retrievedValues["query"].items[keys[i]].myValue = httpReqInfo.items[keys[i]]
          If oauthDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthUser: Read from queries: ",keys[i]," ",retrievedValues["query"].items[ keys[i] ].myValue
          End If
        End If
      End For
    Else
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Nothing in the queries"
      End If
    End If
  End If
  If httpCode = 200 Then
    If httpReqInfo.headers.getLength() > 0 Then
      Let keys = httpReqInfo.headers.getKeys()
      For i=1 To keys.getLength()
        If keys[i].subString(1,3) = "sig" Then
          Try
            Let retrievedValues["head"].items[ keys[i].subString( 4,keys[i].getLength() ) ].myValue = xml.Encryption.DecryptString(clients[id].mySecretKey,httpReqInfo.headers[keys[i]])
            If oauthDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthUser: Read from head: ",keys[i].subString( 4,keys[i].getLength() )," ",retrievedValues["head"].items[ keys[i].subString( 4,keys[i].getLength() ) ].myValue
            End If
          Catch
            Let httpCode = 400
            If oauthDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthUser: Decrypt head failed: ",Status," ",sqlca.sqlerrm
            End If
          End Try
        Else
          Let retrievedValues["head"].items[keys[i]].myValue = httpReqInfo.items[keys[i]]
          If oauthDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthUser: Read from head: ",keys[i]," ",retrievedValues["head"].items[ keys[i] ].myValue
          End If
        End If
      End For
    Else
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Nothing in the headers"
      End If
    End If
  End If

  Return httpCode
End Function

Private Function reply( id String, httpReq com.HttpServiceRequest, httpCode Integer, responseValues Dictionary Of tMyValues )
  Define
    i       SmallInt,
    body    String,
    keys    Dynamic Array Of String

  Try
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthUser: Reply ",httpCode," ",getCodeText(httpCode)
    End If
    Let body = Null
    If responseValues.getLength() > 0 Then
      If responseValues.contains("body") Then
        If responseValues["body"].items.contains("plain") Then
          Let body = responseValues["body"].items["plain"].myValue
        Else
          Let keys = responseValues["body"].items.getKeys()
          For i = 1 To keys.getLength()
            If responseValues["body"].items[keys[i]].encrypt Then
              Try
                Let responseValues["body"].items[keys[i]].myValue = xml.Encryption.EncryptString(clients[id].mySecretKey,responseValues["body"].items[keys[i]].myValue)
              Catch
                If oauthDebug Then
                  Display "[",Current Hour To Fraction(5),"] OAuthUser: Error encrypting body ",Status," ",sqlca.sqlerrm
                End If
                Let httpCode = 400
                Call responseValues.remove("body")
              End Try
            End If
          End For
          If responseValues.contains("body") Then
            Let body = util.JSONObject.fromFGL(responseValues["body"].items).toString()
          End If
        End If
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthUser: With body ",body
        End If
      End If
      If responseValues.contains("head") Then
        Let keys = responseValues["head"].items.getKeys()
        For i = 1 To keys.getLength()
          If responseValues["head"].items[keys[i]].encrypt Then
            Try
              Let responseValues["head"].items[keys[i]].myValue = xml.Encryption.EncryptString(clients[id].mySecretKey,responseValues["head"].items[keys[i]].myValue)
              Call httpReq.setResponseHeader("sig"||keys[i],responseValues["head"].items[keys[i]].myValue)
              If oauthDebug Then
                Display "[",Current Hour To Fraction(5),"] OAuthUser: With encrypted header ","sig"||keys[i],responseValues["head"].items[keys[i]].myValue
              End If
            Catch
              If oauthDebug Then
                Display "[",Current Hour To Fraction(5),"] OAuthUser: Error encrypting head ",Status," ",sqlca.sqlerrm
              End If
              Let httpCode = 400
              Call responseValues.remove("head")
            End Try
          Else
            Call httpReq.setResponseHeader(keys[i],responseValues["head"].items[keys[i]].myValue)
            If oauthDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthUser: With header ",keys[i],responseValues["head"].items[keys[i]].myValue
            End If
          End If
        End For
      End If
    Else
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthUser: Reply without body or headers"
      End If
    End If

    If body Is Not Null Then
      If responseValues["body"].items.contains("plain") Then
        Call httpReq.setResponseHeader("Content-Type","text/html")
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OauthUser: plain text response"
        End If
      Else
        Call httpReq.setResponseHeader("Content-Type","application/json")
        If oauthDebug Then
          Display "[",Current Hour To Fraction(5),"] OauthUser: json response"
        End If
      End If
      Call httpReq.sendTextResponse(httpCode,getCodeText(httpCode),body)
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OauthUser: Response with body sent"
      End If
    Else
      Call httpReq.sendResponse(httpCode,getCodeText(httpCode))
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OauthUser: Response without body sent"
      End If
    End If
  Catch
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OauthUser: Reply error ",Status," ",sqlCa.sqlerrm
    End If
  End Try
End Function

Private Function getRequestHeader( httpReq com.HttpServiceRequest, headers Dictionary Of String )
  Define
   i SmallInt

  Call headers.clear()
  For i = 1 To httpReq.getRequestHeaderCount()
    Let headers[httpReq.getRequestHeaderName(i)] = httpReq.getRequestHeaderValue(i)
  End For
End Function

Private Function getRequestItems( httpReq com.HttpServiceRequest, items Dictionary Of String )
  Define
   i SmallInt,
   query Dynamic Array Of tItems

  Call items.clear()
  Call httpReq.getUrlQuery(query)
  For i = 1 To query.getLength()
    Let items[query[i].name] = query[i].value
  End For
  Call query.clear()
End Function

Private Function getHeaders( resp com.HttpResponse, headers Dictionary Of String )
  Define
    nbHeaders   Integer,
    i           SmallInt

  Call headers.clear()
  Let nbHeaders = resp.getHeaderCount()
  If nbHeaders > 0 Then
    For i = 1 To nbHeaders
      Let headers[resp.getHeaderName(i)] = resp.getHeaderValue(i)
    End For
  End If
End Function

Private Function getRequestBody( httpReq com.HttpServiceRequest, headers Dictionary Of String )
  Define
    body String

  If headers.contains("Content-Length") And headers["Content-Length"] > 0 Then
    Let body = httpReq.readTextRequest()
  Else
    Let body = Null
  End If

  Return body
End Function

Private Function showServiceRequest( httpReq com.HttpServiceRequest, httpReqInfo tHttpReqInfo )
  Define
    nbHeaders   Integer,
    keys        Dynamic Array OF String,
    hasBody     Boolean,
    i           SmallInt

  If oauthDebug THEN
    Display "[",Current Hour To Fraction(5),"] OauthUser: Request info:"
    Display "[",Current Hour To Fraction(5),"] OauthUser: URL: ",httpReq.getURL()
    Display "[",Current Hour To Fraction(5),"] OauthUser: Method: ",httpReq.getMethod()
    Display "[",Current Hour To Fraction(5),"] OauthUser: Path: ",httpReq.getUrlPath()
    Display "[",Current Hour To Fraction(5),"] OauthUser: ProcessedPath: ",_ignoreUrlPath(httpReq.getUrlPath())
    Let nbHeaders = httpReq.getRequestHeaderCount()
    Let hasBody = False
    If nbHeaders > 0 Then
      For i = 1 To nbHeaders
        Display "[",Current Hour To Fraction(5),"] OauthUser: Request header: ",httpReq.getRequestHeaderName(i)," = ",util.Strings.urlDecode(httpReq.getRequestHeaderValue(i))
        If httpReq.getRequestHeaderName(i) = "Content-Length" Then
          If httpReq.getRequestHeaderValue(i) > 0 Then
            Let hasBody = True
          End If
        End If
      End For
    End If
    If httpReqInfo.items.getLength() > 0 Then
      Display "[",Current Hour To Fraction(5),"] OauthUser: Queries:"
      Let keys = httpReqInfo.items.getKeys()
      For i = 1 To httpReqInfo.items.getLength()
        Display "[",Current Hour To Fraction(5),"] OauthUser: ",keys[i]," = ",httpReqInfo.items[keys[i]]
      End For
    End If
    If hasBody Then
      Display "[",Current Hour To Fraction(5),"] OauthUser: Body:"
      Display "[",Current Hour To Fraction(5),"] OauthUser: ",httpReqInfo.body
    End If
  End If
End Function

Private Function showResponse( resp com.HttpResponse )
  Define
    nbHeaders   Integer,
    i           SmallInt

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OauthUser: Status: ",resp.getStatusCode()," ",resp.getStatusDescription()
    Let nbHeaders = resp.getHeaderCount()
    If nbHeaders > 0 Then
      For i = 1 To nbHeaders
        Display "[",Current Hour To Fraction(5),"] OauthUser: Header: ",resp.getHeaderName(i)," = ",resp.getHeaderValue(i)
      End For
    End If
    Display "[",Current Hour To Fraction(5),"] OauthUser: Content: ",NVL(resp.getTextResponse(),"Null")
  End If
End Function

Private Function generateSharedSecret( id String )
  Define
    retCode Boolean

  If oauthDebug Then
    Display "[",Current Hour To Fraction(5),"] OauthUser: Generate shared secret"
  End If
  Let clients[id].mySecretKey = xml.cryptoKey.Create("http://www.w3.org/2001/04/xmlenc#aes256-cbc")
  Let retCode = True

  Try
    -- Create Private Key
    Call clients[id].mySecretKey.generateKey(0)
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OauthUser: Key Size: ",clients[id].mySecretKey.getSize()
      Display "[",Current Hour To Fraction(5),"] OauthUser: Key Type: ",clients[id].mySecretKey.getType()
      Display "[",Current Hour To Fraction(5),"] OauthUser: Key Usage: ",clients[id].mySecretKey.getUsage()
      Display "[",Current Hour To Fraction(5),"] OauthUser: Key Object: ",clients[id].mySecretKey.saveToString()
    End If
  Catch
    Let retCode = False
    If oauthDebug Then
      Display "[",Current Hour To Fraction(5),"] OauthUser: Key Error: ",Status," ",sqlCa.sqlerrm
    End If
  End Try

  Return retCode
End Function

Private Function cleanTable()
  Define
    i Integer,
    k Dynamic Array Of String

  Let k = clients.getKeys()
  For i = 1 To k.getLength()
    If clients.contains(k[i]) Then
      If clients[k[i]].expiryDate < Current Year To Second Then
        Try
          Call clients.remove(k[i])
        Catch
        End Try
      End If
    End If
  End For
End Function


Private Function getCodeText( errorCode Integer )
  Define
    errorMsg String

  Case errorCode
    When 100  Let errorMsg = "Continue"
    When 101  Let errorMsg = "Switching Protocols"
    When 102  Let errorMsg = "Processing"
    When 103  Let errorMsg = "Early Hints"

    When 200  Let errorMsg = "OK"
    When 201  Let errorMsg = "Created"
    When 202  Let errorMsg = "Accepted"
    When 203  Let errorMsg = "Non-Authoritative Information"
    When 204  Let errorMsg = "No Content"
    When 205  Let errorMsg = "Reset Content"
    When 206  Let errorMsg = "Partial Content"
    When 207  Let errorMsg = "Multi-Status"
    When 208  Let errorMsg = "Already Reported"
    When 210  Let errorMsg = "Content Different"
    When 226  Let errorMsg = "IM Used"

    When 300  Let errorMsg = "Multiple Choices"
    When 301  Let errorMsg = "Moved Permanently"
    When 302  Let errorMsg = "Found"
    When 303  Let errorMsg = "See Other"
    When 304  Let errorMsg = "Not Modified"
    When 305  Let errorMsg = "Use Proxy"
    When 306  Let errorMsg = ""
    When 307  Let errorMsg = "Temporary Redirect"
    When 308  Let errorMsg = "Permanent Redirect"
    When 310  Let errorMsg = "Too many Redirects"

    When 400  Let errorMsg = "Bad Request"
    When 401  Let errorMsg = "Unauthorized"
    When 402  Let errorMsg = "Payment Required"
    When 403  Let errorMsg = "Forbidden"
    When 404  Let errorMsg = "Not Found"
    When 405  Let errorMsg = "Method Not Allowed"
    When 406  Let errorMsg = "Not Acceptable"
    When 407  Let errorMsg = "Proxy Authentication Required"
    When 408  Let errorMsg = "Request Time-out"
    When 409  Let errorMsg = "Conflict"
    When 410  Let errorMsg = "Gone"
    When 411  Let errorMsg = "Length Required"
    When 412  Let errorMsg = "Precondition Failed"
    When 413  Let errorMsg = "Request Entity Too Large"
    When 414  Let errorMsg = "Request-URI Too Long"
    When 415  Let errorMsg = "Unsupported Media Type"
    When 416  Let errorMsg = "Requested range unsatisfiable"
    When 417  Let errorMsg = "Expectation failed"
    When 418  Let errorMsg = "I?m a teapot"
    When 421  Let errorMsg = "Bad mapping / Misdirected Request"
    When 422  Let errorMsg = "Unprocessable entity"
    When 423  Let errorMsg = "Locked"
    When 424  Let errorMsg = "Method failure"
    When 425  Let errorMsg = "Unordered Collection"
    When 426  Let errorMsg = "Upgrade Required"
    When 428  Let errorMsg = "Precondition Required"
    When 429  Let errorMsg = "Too Many Requests"
    When 431  Let errorMsg = "Request Header Fields Too Large"
    When 449  Let errorMsg = "Retry With"
    When 450  Let errorMsg = "Blocked by Windows Parental Controls"
    When 451  Let errorMsg = "Unavailable For Legal Reasons"
    When 456  Let errorMsg = "Unrecoverable Error"

    When 444  Let errorMsg = "No Response"
    When 495  Let errorMsg = "SSL Certificate Error"
    When 496  Let errorMsg = "SSL Certificate Required"
    When 497  Let errorMsg = "HTTP Request Sent to HTTPS Port"
    When 499  Let errorMsg = "Client Closed Request"

    When 500  Let errorMsg = "Internal Server Error"
    When 501  Let errorMsg = "Not Implemented"
    When 502  Let errorMsg = "Bad Gateway ou Proxy Error"
    When 503  Let errorMsg = "Service Unavailable"
    When 504  Let errorMsg = "Gateway Time-out"
    When 505  Let errorMsg = "HTTP Version not supported"
    When 506  Let errorMsg = "Variant Also Negotiates"
    When 507  Let errorMsg = "Insufficient storage"
    When 508  Let errorMsg = "Loop detected"
    When 509  Let errorMsg = "Bandwidth Limit Exceeded"
    When 510  Let errorMsg = "Not extended"
    When 511  Let errorMsg = "Network authentication required"

    When 520  Let errorMsg = "Unknown Error"
    When 521  Let errorMsg = "Web Server Is Down"
    When 522  Let errorMsg = "Connection Timed Out"
    When 523  Let errorMsg = "Origin Is Unreachable"
    When 524  Let errorMsg = "A Timeout Occurred"
    When 525  Let errorMsg = "SSL Handshake Failed"
    When 526  Let errorMsg = "Invalid SSL Certificate"
    When 527  Let errorMsg = "Railgun Error"
    Otherwise 
      Let errorMsg = Null
      If oauthDebug Then
        Display "[",Current Hour To Fraction(5),"] OauthUser: Http code unkonwn: ",errorCode
      End If
  End Case

  Return errorMsg
End FUNCTION

PRIVATE FUNCTION _ignoreUrlPath(s STRING)
  IF s.subString(1, ignoreUrlPath.getLength()) MATCHES ignoreUrlPath THEN
    LET s = s.subString(ignoreUrlPath.getLength()+1, s.getLength())
  END IF
  RETURN s
END FUNCTION