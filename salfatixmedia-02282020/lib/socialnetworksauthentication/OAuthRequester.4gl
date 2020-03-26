Import com
Import util
Import security
Import xml

Private Type
  tMyValues Record
    items     Dictionary Of Record
      myValue   String,
      encrypt   Boolean
              End Record
            End Record

Private Define
  redirectUri    String,
  mySecretKey    xml.CryptoKey,
  hisSymetricKey xml.CryptoKey

Public Define
  userDebug Boolean,
  userId    String

Public Function setRedirectUri( redirUri String )
  Let redirectUri = redirUri
End Function

Public Function connectThroughSocialNetwork( socialNetwork String )
  Define
    resourceOwnerUrl   String,
    id                 String,
    urlStr             String,
    httpRetCode        SmallInt,
    myValues           Dictionary of tMyValues,
    myPublicKey        String

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: start connection"
  End If

  Let resourceOwnerUrl = redirectUri
  If resourceOwnerUrl.getCharAt(resourceOwnerUrl.getLength()) != "/" Then
    Let resourceOwnerUrl = resourceOwnerUrl.append("/")
  End If

  Call GetSharedSecret() Returning myPublicKey
  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: Public key is: ",myPublicKey
  End If
  Call myValues.clear()
  Let id = getUniqueId()
  Let userId = id
  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: my id is: ",id
  End If

  Let myValues["params"].items["method"].myValue = "POST"
  Let myValues["params"].items["method"].encrypt = False
  Let myValues["body"].items["pubkey"].myValue   = myPublicKey
  Let myValues["body"].items["pubkey"].encrypt   = False
  Let myValues["query"].items["id"].myValue      = id
  Let myValues["query"].items["id"].encrypt      = False
  Let httpRetCode = doRequest(resourceOwnerUrl.append("social/login/authorization/share"),myValues)

  If httpRetCode = 200 Then
    Let hisSymetricKey = decryptXmlMessage(myValues["body"].items["sharedSecret"].myValue)
    If userDebug Then
      Display "[",Current Hour To Fraction(5),
              SFMT("] OAuthRequester: %1 %2",
                   Iif(httpRetCode=200,"Got symetric key:","Share Request returned"),
                   Iif(httpRetCode=200,hisSymetricKey.saveToString(),httpRetCode))
    End If
  End If

  If httpRetCode = 200 Then
    Call myValues.clear()
    Let myValues["params"].items["method"].myValue = "GET"
    Let myValues["params"].items["method"].encrypt = False
    Let myValues["query"].items["id"].myValue = id
    Let myValues["query"].items["id"].encrypt = False
    Let myValues["query"].items["socialNetwork"].myValue = socialNetwork
    Let myValues["query"].items["socialNetwork"].encrypt = True
    Let httpRetCode = doRequest(resourceOwnerUrl.append("social/login/authorization/connect"),myValues)
    If userDebug Then
      Display "[",Current Hour To Fraction(5),
              SFMT("] OAuthRequester: %1 %2",
                   Iif(httpRetCode=200,"Connect Request said ","Connect Request returned"),
                   Iif(httpRetCode=200,"go on",httpRetCode))
    End If
  End If

  If httpRetCode = 200 Then
    Call requestCodeFromSocialNetwork( myValues ) Returning httpRetCode
    If httpRetCode = 302 Then
      Let urlStr = myValues["head"].items["Location"].myValue
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: New URL is ",urlStr
      End If
      Call doRedirectionTo(urlStr) Returning httpRetCode,urlStr
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: Redirection Result: ",httpRetCode," ",urlStr
      End If
      If httpRetCode = 200 Then
        Call myValues.clear()
        Let myValues["params"].items["method"].myValue = "GET"
        Let myValues["params"].items["method"].encrypt = False
        Let myValues["query"].items["id"].myValue = id
        Let myValues["query"].items["id"].encrypt = False
        Let httpRetCode = doRequest(resourceOwnerUrl.append("social/login/authorization/isokay"),myValues)
        If userDebug Then
          If httpRetCode = 200 Then
            Display "[",Current Hour To Fraction(5),"] OAuthRequester: ", myValues["body"].items["user"].myValue
          Else
            Display "[",Current Hour To Fraction(5),"] OAuthRequester: Connection not allowed"
          End If
        End If
      End If
    Else
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: Got: ",httpRetCode," ",urlStr
      End If
    End If
  Else
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: authorizationRequest returned ",httpRetCode
    End If
  End If

  Return httpRetCode, myValues["body"].items["user"].myValue
End Function

Public Function disconnectFromSocialNetwork( socialNetwork String )
  Define
    resourceOwnerUrl   String,
    urlStr             String,
    httpRetCode        SmallInt,
    myValues           Dictionary of tMyValues

  Let resourceOwnerUrl = redirectUri
  If resourceOwnerUrl.getCharAt(resourceOwnerUrl.getLength()) != "/" Then
    Let resourceOwnerUrl = resourceOwnerUrl.append("/")
  End If
  Call myValues.clear()
  Let myValues["params"].items["method"].myValue = "GET"
  Let myValues["params"].items["method"].encrypt = False
  Let myValues["query"].items["socialNetwork"].myValue = socialNetwork
  Let myValues["query"].items["socialNetwork"].encrypt = False
  Let httpRetCode = doRequest(resourceOwnerUrl.append("social/logout"),myValues)
  If httpRetCode = 200 Then
    Let urlStr = myValues["body"].items["Location"].myValue
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Got: ",httpRetCode," ",urlStr
    End If
    Call doRedirectionTo(urlStr) Returning httpRetCode,urlStr
  Else
  End If
End Function

Private Function doRequest( urlStr String, myValues Dictionary Of tMyValues )
  Define
    httpRetCode     SmallInt,
    url             com.HttpRequest,
    resp            com.HttpResponse,
    qryStr          String,
    body            String,
    i               SmallInt,
    keys            Dynamic Array Of String

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: do request"
  End If
  If myValues.getLength() = 0 Then
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error no directive defined"
    End If
    Return 400
  End If
  If Not myValues.contains("params") Then
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error no parameters defined"
    End If
    Return 400
  End If
  If Not myValues["params"].items.contains("method") Then
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error no method defined"
    End If
    Return 400
  End If

  If myValues.contains("body") Then
    If myValues["params"].items["method"].myValue <> "POST" And myValues["params"].items["method"].myValue <> "PUT" Then
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error wrong method"
      End If
      Return 400
    End If
    Let keys = myValues["body"].items.getKeys()
    If keys.getLength() = 0 Then
      Let myValues["body"].items["empty"].myValue = "empty"
      Let myValues["body"].items["empty"].encrypt = False
    Else
      For i=1 To keys.getLength()
        If myValues["body"].items[keys[i]].encrypt Then
          If hisSymetricKey Is Not Null Then
            Let myValues["body"].items[keys[i]].myValue = xml.Encryption.EncryptString(hisSymetricKey,myValues["body"].items[keys[i]].myValue)
          Else
            Let myValues["body"].items[keys[i]].encrypt = False
          End If
        End If
      End For
    End If
    Let body = util.JSONObject.fromFGL(myValues["body"].items).toString()
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: With body: ",body
    End If
  End If

  If myValues.contains("query") Then
    Let qryStr = Null
    Let keys = myValues["query"].items.getKeys()
    If keys.getLength() > 0 Then
      For i=1 To keys.getLength()
        If myValues["query"].items[keys[i]].encrypt Then
          If hisSymetricKey Is Not Null Then
            Let qryStr = qryStr,
                         Iif(qryStr Is Not Null,"&",""),
                         "sig"||keys[i],
                         "=",
                         xml.Encryption.EncryptString(hisSymetricKey,myValues["query"].items[keys[i]].myValue)
          Else
            If userDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error query encryption without key"
            End If
            Return 400
          End If
        Else
          Let qryStr = qryStr,
                       Iif(qryStr Is Not Null,"&",""),
                       keys[i],
                       "=",
                       myValues["query"].items[keys[i]].myValue
        End If
      End For
    Else
      Let qryStr = Null
    End If
  End If

  If myValues["params"].items["method"].myValue = "POST" Or myValues["params"].items["method"].myValue = "PUT" Then
    If qryStr Is Not Null Then
      Let urlStr = urlStr,"?",qryStr
    End If
  End If

  Try
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: With Url: ",urlStr
    End If
    Let url = com.HttpRequest.Create(urlStr)
    Call url.setMethod(myValues["params"].items["method"].myValue)

    If myValues.contains("head") Then
      Let keys = myValues["head"].items.getKeys()
      If keys.getLength() > 0 Then
        For i=1 To keys.getLength()
          If myValues["head"].items[keys[i]].encrypt Then
            If hisSymetricKey Is Not Null Then
              Call url.setHeader("sig"||keys[i],xml.Encryption.EncryptString(hisSymetricKey,myValues["head"].items[keys[i]].myValue))
              If userDebug Then
                Display "[",Current Hour To Fraction(5),"] OAuthRequester: With Header: ","sig"||keys[i],"=",myValues["head"].items[keys[i]].myValue
              End If
            Else
              If userDebug Then
                Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error head encryption without key"
              End If
              Return 400
            End If
          Else
            Call url.setHeader(keys[i],myValues["head"].items[keys[i]].myValue)
            If userDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthRequester: With Header: ",keys[i],"=",myValues["head"].items[keys[i]].myValue
            End If
          End If
        End For
      End If
    End If

    --Call url.setAutoReply(False)
    If myValues["params"].items["method"].myValue = "POST" Or myValues["params"].items["method"].myValue = "PUT" Then
      Call url.doTextRequest(body)
    Else
      If qryStr Is Not Null Then
        If userDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthRequester: With Query: ",qryStr
        End If
        Call url.doFormEncodedRequest(qryStr,True)
      Else
        Call url.doRequest()
      End If
    End If
    Let resp = url.getResponse()

    Call myValues.clear()
    Let httpRetCode = resp.getStatusCode()
    Case httpRetCode
      When 200
        If userDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthRequester: Status 200"
        End If
        Call getHeaders(resp, myValues)
        If myValues["head"].items["Content-Length"].myValue > 0 Then
          If userDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthRequester: there's a body"
          End If
          Call explodeBody(resp.getTextResponse(),myValues)
        End If
      Otherwise
        #TODO: HTTP error
        Call myValues.clear()
        If userDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthRequester: Error, Http Return code: ",httpRetCode
        End If
    End Case
  Catch
    #TODO: Program error
    Let httpRetCode = Status
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Program Error ",Status," ",sqlCa.sqlerrm
    End If
  End Try

  Return httpRetCode
End Function

Private Function requestCodeFromSocialNetwork( myValues Dictionary Of tMyValues )
  Define
    url         com.HttpRequest,
    resp        com.HttpResponse,
    urlStr      String,
    msg         String,
    keys        Dynamic Array Of String,
    i           SmallInt,
    httpRetCode SmallInt

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: Request code from Social authorization server"
  End If
  If myValues.getLength() > 0 Then
    If myValues["body"].items.contains("Location") Then
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: Request code from ",myValues["body"].items["Location"].myValue
      End If
      Try
        Let urlStr = myValues["body"].items["Location"].myValue
        Call myValues["body"].items.remove("Location")
        Let keys = myValues["body"].items.getKeys()
        Let msg = Null
        For i = 1 To keys.getLength()
          If userDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthRequester: with query ",keys[i],"=",myValues["body"].items[keys[i]].myValue
          End If
          Let msg = msg.append(Iif(msg Is Null,"?","&")||keys[i]||"="||myValues["body"].items[keys[i]].myValue)
        End For
        If msg Is Not Null Then
          Let urlStr = urlStr,msg
        End If
        If userDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthRequester: URL is ",urlStr
        End If
        Let url = com.HttpRequest.Create(urlStr)
        Call url.setMethod("POST")
        Call url.setAutoCookies(True)
        Call url.doTextRequest("Request code")
        Let resp = url.getResponse()
        Call showResponse(resp)
        Let httpRetCode = resp.getStatusCode()
        Call getHeaders(resp, myValues)
      Catch
        #TODO: Program error
        Let msg = "Program error: ",Status," ",httpRetCode
        If userDebug Then
          Display "[",Current Hour To Fraction(5),"] OAuthRequester: ",msg
        End If
        Let httpRetCode = -1
      End Try
    Else
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: missing headers"
      End If
    End If
  Else
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: headers missing"
    End If
  End If

  Return httpRetCode
End Function

Private Function doRedirectionTo( urlStr String )
  Define
    frontEnd    String,
    retCode     SmallInt,
    strData     String, 
    jsonData    String

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: redirect to ",urlStr
  End If
  Let frontEnd = ui.Interface.getFrontEndName()
  Case frontEnd
    When "GDC"
      Call showHtmlPage(urlstr) Returning retCode,urlStr
    When "GBC"
      Call showHtmlPage(urlstr) Returning retCode,urlStr
    When "GMA"
      Call showHtmlPage(urlstr) Returning retCode,urlStr
      --Call ui.Interface.frontCall("standard", "launchURL",urlStr,[])
      {
      CALL ui.Interface.frontCall("android", "startActivityForResult",
                                  [ "com.instagram.android",
                                  urlStr ],
                                  [ strData, jsonData ])
      Display strData
      Display jsonData
      }
    When "GMI"
      Call showHtmlPage(urlstr) Returning retCode,urlStr
      --Call ui.Interface.frontCall("standard", "launchURL",urlStr,[])
      --Let urlStr = "wait"
      --Let retCode = 1
    Otherwise
      -- Unknown front end
      Let urlStr = Null
      Let retCode = 400
  End Case

  Return retCode,urlStr
End Function

Private Function explodeBody( body String,myValues Dictionary Of tMyValues )
  Define
    i         Integer,
    items     Dictionary Of Record
      myValue   String,
      encrypt   Boolean
              End Record,
    keys      Dynamic Array Of String,
    jsonObj   util.JSONObject

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: explode body ",body
  End If
  Let jsonObj = util.JSONObject.parse(body)
  If jsonObj.getLength() > 0 Then
    Call jsonObj.toFGL(items)
  End If
  If items.getLength() > 0 Then
    Let keys = items.getKeys()
    For i = 1 To keys.getLength()
      Let myValues["body"].items[keys[i]].myValue = Iif(items[keys[i]].encrypt,
                                                        xml.Encryption.DecryptString(hisSymetricKey,items[keys[i]].myValue),
                                                        items[keys[i]].myValue)
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: Add to body: ",keys[i]," = ",myValues["body"].items[keys[i]].myValue
      End If
    End For
  Else
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: nothing in this body"
    End If
  End If
End Function

Private Function getUniqueId()
  Define
    csrfToken String,
    str       base.StringBuffer

  Let csrfToken = security.RandomGenerator.CreateRandomString(32)
  Let str = base.StringBuffer.create()
  Call str.append(csrfToken)
  If str.getIndexOf("+",1)> 0 Then
    While str.getIndexOf("+",1)> 0
      Call str.replaceAt(str.getIndexOf("+",1),1,"o")
    End While
  End If
  If str.getIndexOf(" ",1)> 0 Then
    While str.getIndexOf(" ",1)> 0
      Call str.replaceAt(str.getIndexOf(" ",1),1,"a")
    End While
  End If
  If str.getIndexOf("/",1)> 0 Then
    While str.getIndexOf("/",1)> 0
      Call str.replaceAt(str.getIndexOf("/",1),1,"b")
    End While
  End If
  If str.getIndexOf("=",1)> 0 Then
    While str.getIndexOf("=",1)> 0
      Call str.replaceAt(str.getIndexOf("=",1),1,"c")
    End While
  End If
  Let csrfToken = str.toString()
  Let csrfToken = util.Strings.urlEncode(csrfToken)
  Return csrfToken
End Function

Private Function getHeaders( resp com.HttpResponse, myValues Dictionary Of tMyValues )
  Define
    nbHeaders   Integer,
    headName    String,
    i           SmallInt

  Let nbHeaders = resp.getHeaderCount()
  If nbHeaders > 0 Then
    For i = 1 To nbHeaders
      Let headName = resp.getHeaderName(i)
      If headName.subString(1,3) = "sig" Then
        If hisSymetricKey Is Not Null Then
          Let myValues["head"].items[headName.subString(4,headName.getLength())].myValue = xml.Encryption.DecryptString(hisSymetricKey,resp.getHeaderValue(i))
        Else
          Let myValues["head"].items[resp.getHeaderName(i)].myValue = resp.getHeaderValue(i)
        End If
      Else
        Let myValues["head"].items[resp.getHeaderName(i)].myValue = resp.getHeaderValue(i)
      End If
    End For
  End If
End Function

Private Function showHtmlPage(htmlPage String)
  Define
    httpRetCode     SmallInt,
    i               SmallInt,
    url             String,
    myValues        Dictionary of tMyValues

  Open Window whtmlPage With Form "html"

    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Open URL in webview (web component) ",htmlPage
    End If
    If htmlPage.getIndexOf("logout",1) > 0 Then
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: log out ",htmlPage
      End If
      CALL FGL_SETTITLE(%"Sign out")
      Let int_flag = False
      Input By Name htmlPage Without DEFAULTS
        ATTRIBUTES (ACCEPT=FALSE,CANCEL=FALSE)
        On Idle 5
          If userDebug Then
            Display "[",Current Hour To Fraction(5),"] OAuthRequester: logout done ",htmlPage
          End If
          Exit Input
      End Input
    Else
      If userDebug Then
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: log in ",htmlPage
      End If
      CALL FGL_SETTITLE(%"Sign in")
      Let url = htmlPage
      Let i = 3
      While url = htmlPage And i > 0
        Let int_flag = False
        Input By Name htmlPage Without DEFAULTS
          ATTRIBUTES (ACCEPT=FALSE)
          On Change htmlPage
            If userDebug Then
              Display "[",Current Hour To Fraction(5),"] OAuthRequester: address was ",url
              Display "[",Current Hour To Fraction(5),"] OAuthRequester: address has changed ",htmlPage
            End If
            If htmlPage.getIndexOf("www.salfatixmedia.com",1) > 0 Then
              Exit Input
            End If
            If htmlPage.getIndexOf(redirectUri,1) > 0
               And htmlPage.getIndexOf("code=",1) > 0
               And htmlPage.getIndexOf("id=",1) = 0 Then
              --Let htmlPage = htmlPage.append("&id="||userId)
              If userDebug Then
                Display "[",Current Hour To Fraction(5),"] OAuthRequester: wrong return from instagram, correct it ",htmlPage
              End If
              Let htmlPage=url
              Let i = i - 1
              Exit Input
            End IF
        End Input
      End While
    End If

  Close Window whtmlpage
  Return Iif(Not int_flag,200,400),htmlPage
End Function

Private Function showResponse( resp com.HttpResponse )
  Define
    nbHeaders   Integer,
    i           SmallInt

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: Status: ",resp.getStatusCode()," ",resp.getStatusDescription()
    Let nbHeaders = resp.getHeaderCount()
    If nbHeaders > 0 Then
      For i = 1 To nbHeaders
        Display "[",Current Hour To Fraction(5),"] OAuthRequester: ",resp.getHeaderName(i)," = ",resp.getHeaderValue(i)
      End For
    End If
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: Body: ",NVL(resp.getTextResponse(),"NULL")
  End If
End Function

Private Function GetSharedSecret()
  Define
    myPublicKey        xml.DomDocument,
    myPublicKeyStr     String

  If userDebug Then
    Display "[",Current Hour To Fraction(5),"] OAuthRequester: Generating Key"
  End If
  -- Key have been created with RSA algorythm, care about choosing the right URL
  -- in create method according with the key 
  Let mySecretKey = xml.CryptoKey.CREATE("http://www.w3.org/2001/04/xmlenc#rsa-1_5")

  Try
    -- Create Private Key
    Call mySecretKey.generateKey(1024)
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Private Key"
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Key Size: ",mySecretKey.getSize()
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Key Type: ",mySecretKey.getType()
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Key Usage: ",mySecretKey.getUsage()
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Key Object: ",mySecretKey.saveToString()
    End If

    -- Create Public Key
    Let myPublicKeyStr = mySecretKey.savePublicToString()
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Public Key: ",myPublicKeyStr
    End If

  Catch
    Let myPublicKeyStr = Null
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Key Error: ",Status," ",sqlCa.sqlerrm
    End If
  End Try

  Return myPublicKeyStr
End Function

Private Function decryptXmlMessage( msg String )
  Define
    xmlDoc             xml.DomDocument,
    encrypted          xml.Encryption

  Let xmlDoc = xml.DomDocument.Create()
    If userDebug Then
      Display "[",Current Hour To Fraction(5),"] OAuthRequester: Xml message to decrypt: ",msg
    End If
  Call xmlDoc.loadFromString(msg)
  Let encrypted = xml.Encryption.Create()
  Call encrypted.setKeyEncryptionKey(mySecretKey)
  Return encrypted.decryptKey(xmlDoc,"http://www.w3.org/2001/04/xmlenc#aes256-cbc")
End Function