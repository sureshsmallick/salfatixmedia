Import util
Import FGL OAuthRequester

type
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
                      End Record

Main
  Define
    socialNetwork   String,
    instagramUser   t_instagramUser,
    msg             STRING,
    ret INTEGER

  Close Window Screen
  --Call ui.Interface.loadStyles("mystyles")
  --Call ui.Interface.loadActionDefaults("myactions")

  Let OAuthRequester.userDebug = True
  Call OAuthRequester.setRedirectUri("http://127.0.0.1:8099/")
  --http://safatixmedia.com/ua/r/myservice

  Open Window w1 With Form "login"

    Let int_flag = False
    Input By Name socialNetwork
    If Not int_flag Then
      Call OAuthRequester.connectThroughSocialNetwork(socialNetwork) RETURNING ret, msg
    End If

    If msg Is Not Null And socialNetwork = "Instagram" Then
      Call util.JSON.parse(msg,instagramUser)
      Display "Welcome ",instagramUser.user.full_name
    Else
      Display "Connection not allowed"
    End If

  Close Window w1
End Main
