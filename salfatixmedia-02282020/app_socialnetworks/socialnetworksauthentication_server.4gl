Import com
Import FGL OAuthUser
 
Main
  Define
    retCode     Integer,
    httpReq     com.HttpServiceRequest

  Call setParameters()
  Let OAuthUser.oauthDebug = base.Application.getResourceEntry("salfatix.oauthserver.debug")
  --If Length(fgl_getenv("FGLAPPSERVER")) = 0 Then
  --  Call fgl_setenv("FGLAPPSERVER",defaultPort)
  --End If


  Call com.WebServiceEngine.Start()
  While True
    Try
      Let httpReq = com.WebServiceEngine.getHTTPServiceRequest(-1)
      Let retCode = OAuthUser.processReq(httpReq)
    Catch
      Let retCode = STATUS
      Display "Webservice Engine Error: ",retCode
      Case retCode
        When -15565
          Display "incoming request cannot be returned"
        When -15575
          Display SFMT("WebService Engine shutdown by GAS (Status=%1)",retCode)
          Exit While
        OTHERWISE
          Display SFMT("WebService Engine exits with code %1",retCode)
          Exit While
      End Case
    End Try
  End While
End Main

Function setParameters()
  Call OAuthUser.setRedirectUri(base.Application.getResourceEntry("salfatix.oauthserver.url"))
  Call OAuthUser.setUrlPathToIgnore(base.Application.getResourceEntry("salfatix.oauthserver.urlpathtoignore"))

  Call OAuthUser.setSocialNetworkUriHead("Instagram","https://api.instagram.com")
  Call OAuthUser.setSocialNetworkPath("Instagram","code","/oauth/authorize/")
  Call OAuthUser.addSocialNetworkQuery("Instagram","code","client_id",base.Application.getResourceEntry("salfatix.oauthserver.clientid"))
  Call OAuthUser.addSocialNetworkQuery("Instagram","code","response_type","code")
  Call OAuthUser.addSocialNetworkQuery("Instagram","code","redirect_uri","val")

  Call OAuthUser.setSocialNetworkPath("Instagram","token","/oauth/access_token")
  Call OAuthUser.addSocialNetworkQuery("Instagram","token","client_id",base.Application.getResourceEntry("salfatix.oauthserver.clientid"))
  Call OAuthUser.addSocialNetworkQuery("Instagram","token","client_secret",base.Application.getResourceEntry("salfatix.oauthserver.clientsecret"))
  Call OAuthUser.addSocialNetworkQuery("Instagram","token","grant_type","authorization_code")
  Call OAuthUser.addSocialNetworkQuery("Instagram","token","code","val")
  Call OAuthUser.addSocialNetworkQuery("Instagram","token","redirect_uri","val")

  Call OAuthUser.setSocialNetworkPath("Instagram","logout",base.Application.getResourceEntry("salfatix.oauthserver.logouturl"))
End Function