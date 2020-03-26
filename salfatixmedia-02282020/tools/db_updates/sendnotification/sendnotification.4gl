Import os
Import FGL notifications
Import FGL core_db
Import FGL string
Import FGL setup

Schema salfatixmedia

Main
  Define
    lrBrand   Record Like brands.*,
    lrInflu   Record Like users.*,
    lrMsg     Record Like messages.*,
    lsMailTo  String,
    lsMsgLg   Like messages.msg_lang,
    lsMsg     String,
    lsMsgTtl  String,
    lsBuffer  base.StringBuffer,
    minId     Integer,
    maxId     Integer,
    lastId    Integer,
  	li        Integer

  Call setup.start_log()
  Connect To "salfatixmedia"

  Declare cBrands Cursor For Select * From brands Where brnd_emailvalidationdate Is Null
  Display "Brands"
  Let li = 0
  Foreach cBrands Into lrBrand.*
    If li > 0 Then
	  Sleep 2
	End If
	Let li = li + 1
    Let lsMsgLg  = getLang(lrBrand.brnd_country_id)
    Let lsMailTo = lrBrand.brnd_email
    Let lsBuffer = base.StringBuffer.create()
    If lrBrand.brnd_email_style = "H" Then
      If lsMsgLg = "fr" Then
        Let lsMsgTtl = "Notre plateforme est en ligne!"
        Call lsBuffer.append("<p>Bonjour #BRAND_NAME#</p>")
        Call lsBuffer.append("<p>Nous sommes fiers de vous annoncer le lancement de la plateforme en ligne <a href=\"https://apps.salfatix.com/salfatix/ua/r/brands\">Salfatix Media</a>.<br />Elle vous permettra de traiter vos campagnes, briefs et sélection d’influenceurs en toute simplicité!</p>")
        Call lsBuffer.append("<p>Etant répertorié dans notre database, vos données ont été automatiquement transférées dans notre nouveau système de gestion de données.<br />Il vous suffit de valider votre adresse mail en cliquant <a href=\"#LINK_EMAIL_VALIDATION#\">ici</a>.</p>")
        Call lsBuffer.append("<p>Si, pour une quelconque raison, ce lien ne devait pas fonctionner, copiez-collez l'URL suivant dans le navigateur de votre choix :<br />")
        Call lsBuffer.append("<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br /></p>")
        Call lsBuffer.append("<p>*** A très vite sur notre <a href=\"https://apps.salfatix.com/salfatix/ua/r/brands\">plateforme</a>!!<br />Et surtout, nous restons a votre écoute concernant la gestion de l’outil et vos recommandations sur son utilisation.</p><br />")
        Call lsBuffer.append("<p> Team <a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a> <a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>")
      Else
        Let lsMsgTtl = "Our platform is out!!!"
        Call lsBuffer.append("Hi #BRAND_NAME#")
        Call lsBuffer.append("<p>In the name of Salfatix Media, we are proudly happy to annonce the final release of our new <a href=\"https://apps.salfatix.com/salfatix/ua/r/brands\">data management system</a>.</p>")
        Call lsBuffer.append("<p>As known in our database, you have been automatically transferred into our new system.</p>")
        Call lsBuffer.append("<p>Please confirm your email address by clicking <a href=\"#LINK_EMAIL_VALIDATION#\">here</a>.</p>")
        Call lsBuffer.append("<p>If for some reason, this link doesn't work, please copy paste the following URL in your favorite browser:<br />")
        Call lsBuffer.append("<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.</p><br />")
        Call lsBuffer.append("<p>*** See you soon on our <a href=\"https://apps.salfatix.com/salfatix/ua/r/brands\">platform</a>!!!<br />And of course, we stay fully opened to any recommandation or idea about it.<br />Don’t hesitate to contact us for any inquiry.</p><br />")
        Call lsBuffer.append("<p> Team <a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a> <a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>")
      End If
    Else
      If lsMsgLg = "fr" Then
        Let lsMsgTtl = "Notre plateforme est en ligne!"
        Call lsBuffer.append("Bonjour #BRAND_NAME#\n\n")
        Call lsBuffer.append("Nous sommes fiers de vous annoncer le lancement de la plateforme en ligne Salfatix Media : https://apps.salfatix.com/salfatix/ua/r/brands.\nElle vous permettra de traiter vos campagnes, briefs et sélection d’influenceurs en toute simplicité!\n")
        Call lsBuffer.append("Etant répertorié dans notre database, vos données ont été automatiquement transférées dans notre nouveau système de gestion de données.\nIl vous suffit de valider votre adresse mail en cliquant sur le lien suivant : \n#LINK_EMAIL_VALIDATION#\n")
        Call lsBuffer.append("*** A très vite sur notre plateforme!!\nEt surtout, nous restons a votre écoute concernant la gestion de l’outil et vos recommandations sur son utilisation.\n\n")
        Call lsBuffer.append("Team @SalfatixMedia\nwww.salfatixmedia.com\n#SALFATIXMEDIA_INSTAGRAM#\n#SALFATIXMEDIA_WWW#\n")
      Else
        Let lsMsgTtl = "Our platform is out!!"
        Call lsBuffer.append("Hi #BRAND_NAME#\n\n")
        Call lsBuffer.append("In the name of Salfatix Media, we are proudly happy to annonce the final release of our new data management system:\nhttps://apps.salfatix.com/salfatix/ua/r/brands\n")
        Call lsBuffer.append("As known in our database, you have been automatically transferred into our new system.\n")
        Call lsBuffer.append("Please confirm your email address by clicking following link:\n #LINK_EMAIL_VALIDATION#\n\n")
        Call lsBuffer.append("*** See you soon on our platform!!!\nAnd of course, we stay fully opened to any recommandation or idea about it.\nDon’t hesitate to contact us for any inquiry.\n\n")
        Call lsBuffer.append("Team @SalfatixMedia\nwww.salfatixmedia.com\n#SALFATIXMEDIA_INSTAGRAM#\n#SALFATIXMEDIA_WWW#\n")
      End If
    End If
  	Display SFMT("%1: Sending mail to %2 in %3",li,lsMailTo,IIF(lrBrand.brnd_email_style="H","HTML mode","Text mode"))
    Call sendMessageTo(lsMailTo,lrBrand.brnd_email_style,lsBuffer,"mail_brand",True,lrBrand.brnd_name,lrBrand.brnd_id,lsMsgTtl)
    Let lsBuffer = Null
  End Foreach
  Free cBrands

  Display "Influencers"
  Let minId = 0 - li
  Let li = 0
  Select max(usr_id) Into lastId From users
  While True
    If minId > lastId Then
      Exit While
    Else
      If li <> 0 Then
        # Max 200 mails per hour !
        Display "Sleeping 1 hour and 5 munites"
        Sleep 3900
      End If
    End If
    Let maxId = minId + 190
    Declare cInfluencers Cursor For
      Select * From users
       Where usr_emailvalidationdate Is Null
         And usr_id > minId and usr_id <= maxId
    Foreach cInfluencers Into lrInflu.*
      If li > 0 Then
	      Sleep 2
    	End If
    	Let li = li + 1
      Let lsMsgLg  = getLang(lrInflu.usr_country_id)
      Let lsMailTo = lrInflu.usr_email
      Let lsBuffer = base.StringBuffer.create()
      If lrInflu.usr_email_style = "H" Then
        If lsMsgLg = "fr" Then
          Let lsMsgTtl = "L’application est en ligne!!"
          Call lsBuffer.append("Bonjour #INFLUENCER_FIRSTNAME#")
          Call lsBuffer.append("<p>Après plusieurs mois de travail, nous sommes fiers de vous annoncer que l’application Salfatix Media est en ligne! 🥂</p>")
          Call lsBuffer.append("<p>Etant déjà répertorié en tant qu'influenceur dans notre agence, vous avez été automatiquement enregistré(e) dans l’application.</p>")
          Call lsBuffer.append("<p>Il vous suffit de la télécharger sur <a href=\"https://apps.apple.com/us/app/salfatix-media/id1439567048?l=fr&ls=1\">l’Apple store</a> ou sur <a href=\"https://play.google.com/store/apps/details?id=com.salfatixmedia.influencers\">Android Play Store</a>.</p>")
          Call lsBuffer.append("<p>Veuillez valider votre adresse mail en cliquant <a href=\"#LINK_EMAIL_VALIDATION#\">ici</a>.</p>")
          Call lsBuffer.append("<p>Si, pour une quelconque raison, ce lien ne devrait pas fonctionner, copiez-collez l'URL suivant dans votre navigateur préféré :<br />")
          Call lsBuffer.append("<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br /></p>")
          Call lsBuffer.append("<p>*** L’application est nouvelle et nécessite toujours des modifications. N’hésitez pas a nous en faire part, commentaires et idées sont les bienvenus.<br /></p>")
          Call lsBuffer.append("<p> Team <a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a> <a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>")
        Else
          Let lsMsgTtl = "Our app is out!!"
          Call lsBuffer.append("Hello #INFLUENCER_FIRSTNAME#")
          Call lsBuffer.append("<p>After a while working on our new project, we are proud to annonce the final release of Salfatix Media Influencers application !</p>")
          Call lsBuffer.append("<p><br />🥂<br /></p>")
          Call lsBuffer.append("<p>As you were known as a subscribed influencer in our data base system, your profile has been automatically registered into the app.</p>")
          Call lsBuffer.append("<p>You just need to download it on the <a href=\"https://apps.apple.com/us/app/salfatix-media/id1439567048?l=fr&ls=1\">Apple store</a> or <a href=\"https://play.google.com/store/apps/details?id=com.salfatixmedia.influencers\">Android Play Store</a>.</p>")
          Call lsBuffer.append("<p>But first, validate you email address by clicking <a href=\"#LINK_EMAIL_VALIDATION#\">here</a>.</p>")
          Call lsBuffer.append("<p>If this link doesn't work, please copy paste following URL in your favorite browser:<br />")
          Call lsBuffer.append("<a href=\"#LINK_EMAIL_VALIDATION#\">#LINK_EMAIL_VALIDATION#</a>.<br /></p>")
          Call lsBuffer.append("<p>*** as the app is new, we still need to work on some details. Please feel free to send us your recommandations and ideas about it!<br /></p>")
          Call lsBuffer.append("<p> Team <a href=\"#SALFATIXMEDIA_INSTAGRAM#\">@SalfatixMedia</a> <a href=\"#SALFATIXMEDIA_WWW#\" target=\"_blank\"><br>www.salfatixmedia.com</a></p>")
        End If
      Else
        If lsMsgLg = "fr" Then
          Let lsMsgTtl = "L’application est en ligne!!"
          Call lsBuffer.append("Bonjour #INFLUENCER_FIRSTNAME# !\n\n")
          Call lsBuffer.append("Après plusieurs mois de travail, nous sommes fiers de vous annoncer que l’application Salfatix Media est en ligne!\n")
          Call lsBuffer.append("Etant déjà répertorié en tant qu'influenceur dans notre agence, vous avez été automatiquement enregistré(e) dans l’application.\n\n")
          Call lsBuffer.append("Il vous suffit de la télécharger sur :\n")
          Call lsBuffer.append("Apple Store: https://apps.apple.com/us/app/salfatix-media/id1439567048?l=fr&ls=1 \n")
		      Call lsBuffer.append("Android Play Store: https://play.google.com/store/apps/details?id=com.salfatixmedia.influencers \n\n")
          Call lsBuffer.append("Veuillez valider votre adresse mail en cliquant sur le lien suivant : \n #LINK_EMAIL_VALIDATION# \n\n")
          Call lsBuffer.append("Team @SalfatixMedia\nwww.salfatixmedia.com\n#SALFATIXMEDIA_INSTAGRAM#\n#SALFATIXMEDIA_WWW#\n")
        Else
          Let lsMsgTtl = "Our app is out!!"
          Call lsBuffer.append("Hello #INFLUENCER_FIRSTNAME#!\n\n")
          Call lsBuffer.append("After a while working on our new project, we are proud to annonce the final release of Salfatix Media Influencers application !\n")
          Call lsBuffer.append("As you were known as a subscribed influencer in our data base system, your profile has been automatically registered into the app.\n\n")
          Call lsBuffer.append("You just need to download it on the :\n")
          Call lsBuffer.append("Apple Store: https://apps.apple.com/us/app/salfatix-media/id1439567048?l=fr&ls=1 \n")
       		Call lsBuffer.append("Android Play Store: https://play.google.com/store/apps/details?id=com.salfatixmedia.influencers \n\n")
          Call lsBuffer.append("But first, validate you email address by clicking on following link:\n #LINK_EMAIL_VALIDATION# \n\n")
          Call lsBuffer.append("Team @SalfatixMedia\nwww.salfatixmedia.com\n#SALFATIXMEDIA_INSTAGRAM#\n#SALFATIXMEDIA_WWW#\n")
        End If
      End If
  	  Display SFMT("%1: Sending mail to %2 (id:%3) in %4",li,lsMailTo,lrInflu.usr_id,IIF(lrInflu.usr_email_style="H","HTML mode","Text mode"))
      Call sendMessageTo(lsMailTo,lrInflu.usr_email_style,lsBuffer,"mail_influencer",False,lrInflu.usr_firstname,lrInflu.usr_id,lsMsgTtl)
      Let lsBuffer = Null
    End Foreach
    Let minId = maxId
    Free cInfluencers
  End While
End Main

Function getLang(countryId Like countries.cntr_id)
  Define
    liErr     Integer,
    lsMsg     String,
    lsLang    String,
    lrCountry Record Like countries.*

  Let lsLang = "en"
  Call core_db.country_select_row(countryId, False) Returning liErr, lsMsg, lrCountry.*
  If liErr == 0 Then
    If lrCountry.cntr_name == "France" Then
      Let lsLang = "fr"
    End If
  End If
  Return lsLang
End Function

Function sendMessageTo(lsMailTo String,
                       lcMailType Char(1),
                       lsBuffer base.StringBuffer,
                       lsMailBaseName String,
                       lbIsBrand Boolean,
                       contactName String,
                       contactId Integer,
                       lsMsgTtl String)
  Define
    lsTmp String,
    ch base.Channel,
    lstr_run_command String,
    lint_ret Integer,
    lsServerFilename String

  If lsBuffer.getIndexOf("#BRAND_NAME#", 1) > 0 Then
    Call lsBuffer.replace("#BRAND_NAME#", contactName,0)
  End If
  If lsBuffer.getIndexOf("#INFLUENCER_FIRSTNAME#", 1) > 0 Then
    Call lsBuffer.replace("#INFLUENCER_FIRSTNAME#", contactName,0)
  End If
  If lsBuffer.getIndexOf("#LINK_EMAIL_VALIDATION#", 1) > 0 Then
    LET lsTmp = base.Application.getResourceEntry("salfatixmedia.link.emailvalidation")
    If lbIsBrand Then
      Call lsBuffer.replace("#LINK_EMAIL_VALIDATION#", notifications._build_email_link(lsTmp, contactId, 0),0)
    Else
      Call lsBuffer.replace("#LINK_EMAIL_VALIDATION#", notifications._build_email_link(lsTmp, contactId, 1),0)
    End If
  End If
  If lsBuffer.getIndexOf("#SALFATIXMEDIA_WWW#", 1) > 0 Then
    Call lsBuffer.replace("#SALFATIXMEDIA_WWW#", base.Application.getResourceEntry("salfatixmedia.www.url"),0)
  End If
  If lsBuffer.getIndexOf("#SALFATIXMEDIA_FACEBOOK#", 1) > 0 Then
    Call lsBuffer.replace("#SALFATIXMEDIA_FACEBOOK#", base.Application.getResourceEntry("salfatixmedia.account.facebook"),0)
  End If
  If lsBuffer.getIndexOf("#LINK_SIGNATURE_LOGO#", 1) > 0 Then
    Call lsBuffer.replace("#LINK_SIGNATURE_LOGO#", base.Application.getResourceEntry("salfatixmedia.logo.url"),0)
  End If
  If lsBuffer.getIndexOf("#SALFATIXMEDIA_INSTAGRAM#", 1) > 0 Then
    Call lsBuffer.replace("#SALFATIXMEDIA_INSTAGRAM#", base.Application.getResourceEntry("salfatixmedia.account.instagram"),0)
  End If

  Let lsServerFilename = os.Path.join(base.Application.getResourceEntry("salfatixmedia.email.dir"), string.get_report_name(lsMailBaseName,".txt"))
  Let lsServerFilename = os.Path.join("..", lsServerFilename)
  Let lsServerFilename = os.Path.join("..", lsServerFilename)
  Let ch = base.Channel.create()
  Call ch.openFile(lsServerFilename,"w")
  Call ch.writeLine(SFMT("From: %1",base.Application.getResourceEntry("salfatixmedia.email.sender")))
  Call ch.writeLine(SFMT("To: %1",lsMailTo))
  Case lcMailType
    When "H"
      Call ch.writeLine("Content-Type: text/html; charset=UTF-8")
    Otherwise
      Call ch.writeLine("Content-Type: text/plain; charset=UTF-8")
  End Case
  Call ch.writeLine(SFMT("Subject: %1",lsMsgTtl))
  Call ch.writeLine("")
  Call ch.writeLine(lsbuffer.toString())
  Call ch.close()

  Let lstr_run_command = SFMT("../../%1 '%2'", base.Application.getResourceEntry("salfatixmedia.email.scriptpath"), lsServerFilename)
  Run lstr_run_command Returning lint_ret
  If lint_ret <> 0 Then --error occured within the script
    Call setup.error_log(lint_ret, SFMT("send_message_to() - RUN %1 Failed", lstr_run_command))
  End If
End Function
