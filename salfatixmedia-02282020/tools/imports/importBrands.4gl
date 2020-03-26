Import util
Import com

Schema salfatixmedia

type
    tBrand      Record Like brands.*,
    tInfluencer Record Like users.*

Main
  --Call createSqlInfluencer(True)
  --Call createSqlInfluencer(False)
  --Call createSqlBrand()
  Connect To "salfatixmedia"
  --Call importBrands()
  --Call importInfluencersANSI()
  Call importInfluencersAdditionals()
End Main

Function createSqlInfluencer(withEmos Boolean)
  Define
    fileName  String,
    fileId1   base.Channel,
    fileId2   base.Channel,
    i         Integer,
    rec       tInfluencer,
    qry       String,
    data      String,
    buf       base.stringBuffer

  Display "Import influencers ",IIF(withEmos,"with emoticons","")
  Let fileName = "Influencers.csv"
  Let fileId1 = base.Channel.create()
  Call fileId1.openFile(fileName,"r")
  Call fileId1.setDelimiter(";")
  Let fileId2 = base.Channel.create()
  If withEmos Then
    Call fileId2.openFile("InfluencersEmos.sql","w")
  Else
    Call fileId2.openFile("Influencers.sql","w")
  End If

  Let i = 1
  While fileId1.read([rec.*])
    If rec.usr_instagram_username Is Null Then
      Display "Pas de username sur ligne n",i
      Display rec.*
      Continue While
    Else
      Let data = getData(rec.usr_instagram_username)
      If data Is Not Null Then
        Let rec.usr_instagram_userid = getInterestingData(data,"id")
        Let rec.usr_instagram_is_private = getInterestingData(data,"is_private")
        Let rec.usr_instagram_is_verified = getInterestingData(data,"is_verified")
        If withEmos Then
          Let rec.usr_instagram_fullname = getInterestingData(data,"full_name")
          Let buf = base.StringBuffer.create()
          Call buf.append(getInterestingData(data,"biography"))
          Call buf.replace("\n","\\n",0)
          Call buf.replace("\"","\\\"",0)
          Let rec.usr_instagram_biography = buf.toString()
        End If
        Let rec.usr_instagram_is_business = getInterestingData(data,"is_business_account")
      Else
        Display "Problème... ",rec.usr_instagram_username
        Let i = i + 1
        Continue While
      End If
    End If
    Let qry = "Insert into users values ("
    Let qry = qry.append(NVL(rec.usr_id,0))
    Let qry = qry.append(",")
    Let qry = qry.append(rec.usr_gender_id)
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_firstname||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_lastname||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_birthday||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_email||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_password||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(rec.usr_country_id)
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_state_id,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_city_id,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_address_number||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_address_street||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_address_zipcode||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_address_town||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_address_more||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_mobile_phone,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(rec.usr_instagram_userid)
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_instagram_username||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_instagram_fullname||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_instagram_profilepicture||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_instagram_biography||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_instagram_website||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_instagram_is_private,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_instagram_is_verified,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_instagram_is_business,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_bank_name||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_bank_iban||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_bank_swift||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_paypal||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(1) -- usr_mobile_notifications
    Let qry = qry.append(",")
    Let qry = qry.append("\"T\"")  -- usr_notif_style
    Let qry = qry.append(",")
    Let qry = qry.append(0) -- usr_email_notifications
    Let qry = qry.append(",")
    Let qry = qry.append("\"H\"") -- usr_email_style
    Let qry = qry.append(",")
    Let qry = qry.append(1)   -- usr_currency_id
    Let qry = qry.append(",")
    Let qry = qry.append(3)   -- usr_accountstatus_id
    Let qry = qry.append(",")
    Let qry = qry.append(1)   -- usr_createdby_id
    Let qry = qry.append(",")
    Let qry = qry.append("TODAY") -- usr_creationdate
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_deletiondate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_validationdate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_canceldate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_suspendeddate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_stopdate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_emailvalidationdate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_lastupdatedate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.usr_lastlogindate,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.usr_instagram_token||"\"","\"\""))

    Let qry = qry.append(");")

    If qry Is Null Then
      Display NVL(qry,rec.usr_instagram_username||" IS NULL !!!")
    Else
      Call fileId2.writeLine(qry)
    End If
    Let i = i + 1
  End While
  Call fileId2.close()
  Call fileId1.close()
  Display "Done"
End Function

Function importInfluencersAdditionals()
  Define
    rec Record
      dkey String,
      InstUrl String,
      firstname String,
      lastname String,
      followers Integer,
      reach decimal(5,2),
      gender String,
      birthday String,
      phone String,
      email String,
      email2 String,
      fb String,
      twi String,
      blog String,
      Tumblr String,
      yt String,
      yt2 String,
      postadd String,
      zip String,
      state String,
      country String,
      access String,
      snapchat String,
      Category String
    End Record,
    usr Record Like users.*,
    fileId1    base.Channel,
    i,j        Integer

  Let fileId1 = base.Channel.create()
  Call fileId1.openFile("InfluencersAdditionals.csv","r")
  Call fileId1.setDelimiter(";")
  LEt j = 0
  While fileId1.read([rec.*])
    Select * Into usr.* From users
     Where users.usr_firstname = rec.firstname
       And users.usr_lastname  = rec.lastname
    If Sqlca.sqlcode=100 Then
      Select * Into usr.* From users
       Where users.usr_email = rec.email
    End If
    If Sqlca.sqlcode<>0 Then
      Display j," ",rec.firstname," ",rec.lastname,SFMT(" (%1) ",i)
    End If
    If rec.yt Is Not Null Then
      Display "Insert into usersocialnetworks Values (0,",usr.usr_id,",2,\"",rec.yt,"\",Null)"
    End If
    If rec.yt2 Is Not Null Then
      Display "Insert into usersocialnetworks Values (0,",usr.usr_id,",2,\"",rec.yt2,"\",Null)"
    End If
    If rec.twi Is Not Null Then
      Display "Insert into usersocialnetworks Values (0,",usr.usr_id,",4,\"",rec.twi,"\",Null)"
    End If
    Let j = j + 1
  End While
  Display j
End Function

Function getData(userName String)
  Define
    s   String,
    i   Integer,
    j   Integer,
    req com.HTTPRequest,
    res com.HTTPResponse

  Try
    Let req = com.HTTPRequest.Create("https://www.instagram.com/"||userName.trim())
    Call req.setMethod("GET")
    Call req.setTimeOut(6)
    Call req.setConnectionTimeOut(6)
    Call req.doRequest()
    Let res = req.getResponse()
    Let s   = res.getTextResponse()
    Let i = s.getIndexOf("<script type=\"text/javascript\">window._sharedData",1)
    Let j = s.getIndexOf(";</script>",i)
    Let s = s.subString(i,j)
    Let i = s.getIndexOf("{\"",1)
    Let j = s.getIndexOf("};",i)
    Let s = s.subString(i,j)
  Catch
    Display "Error on ",userName," (",Status,") ",Sqlca.Sqlerrm
    Let s = Null
  End Try

  Return s
End Function

Function getInterestingData(s String,strId String)
  Define
    jsStr util.JSONObject,
    jsArr util.JSONArray

  --Try
    Let jsStr = util.JSONObject.parse(s)
    Let jsStr = jsStr.get("entry_data")
    Let jsArr = jsStr.get("ProfilePage")
    Let jsStr = jsArr.get(1)
    Let jsStr = jsStr.get("graphql")
    Let jsStr = jsStr.get("user")
    Let s = jsStr.get(strId)
  --Catch
    --Display "Loupé"
    --Let s = Null
  --End Try

  Return s
End Function

Function createSqlBrand()
  Define
    fileName  String,
    fileId    base.Channel,
    i         Integer,
    rec       tbrand,
    qry       String

  Display "Import brands"
  Let fileName = "brands.csv"
  Let fileId = base.Channel.create()
  Call fileId.openFile(fileName,"r")
  Call fileId.setDelimiter(";")
  Let i = 1
  While fileId.read(rec)
    Let qry = "Insert into brands values ("
    Let qry = qry.append(rec.brnd_id)
    Let qry = qry.append(",")
    Let qry = qry.append(rec.brnd_pic_id)
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_name||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_website||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(rec.brnd_country_id)
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.brnd_state_id,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.brnd_city_id,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_address_number||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_address_street||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_address_zipcode||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_address_town||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_address_more||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(rec.brnd_currency_id)
    Let qry = qry.append(",")
    Let qry = qry.append(rec.brnd_gender_id)
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_firstname||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_lastname||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_contact_rank||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_email||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_email_style||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL("\""||rec.brnd_password||"\"","\"\""))
    Let qry = qry.append(",")
    Let qry = qry.append(NVL(rec.brnd_mobile_phonenumber,"NULL"))
    Let qry = qry.append(",")
    Let qry = qry.append(rec.brnd_accountstatus_id)
    Let qry = qry.append(",")
    Let qry = qry.append(rec.brnd_createdby_id)
    Let qry = qry.append(",")
    Let qry = qry.append("TODAY")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(",")
    Let qry = qry.append("TODAY")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(",")
    Let qry = qry.append("NULL")
    Let qry = qry.append(");")

    Display NVL(qry,rec.brnd_id||" IS NULL !!!")
  End While
  Call fileId.close()

End Function

Function importBrands()
Insert into brands values (1,1,"Brand A","www.4js.com",75,953,74133,"55","Rue du Faubourg Saint Honoré","75000","","",1,2,"Jean","Dubois","Head of development","dummy-a@4js.com","H","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",NULL,4,1,TODAY,NULL,TODAY,NULL,NULL,NULL,NULL,NULL,NULL);
Insert into brands values (2,1,"Brand B","www.fourjs.com",75,953,74133,"40B","Avenue de Suffren","75015","","",1,3,"Jeanne","Denfer","CEO","dummy-b@4js.com","H","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",NULL,4,1,TODAY,NULL,TODAY,NULL,NULL,NULL,NULL,NULL,NULL);
End Function

Function importInfluencersANSI()
Insert into users values (0,3,"Rebecca","Westberg","22/07/1980","rebecca.isabelle.w@gmail.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",2,3407,318518,"","Emirates Airline Service delivery","25155","","",97200000000000,9322788,"miss.rebeccaisabelle","","","","",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
Insert into users values (0,3,"irina","peicu","12/06/1985","contact.irinahp@gmail.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO3",12,205,NULL,"","","","","",4312341234,13327500,"irinahp","","","","https://www.instagram.com/irinahp/",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
End Function

Function importInfluencersUTF8()
Insert into users values (0,3,"Rebecca","Westberg","22/07/1980","rebecca.isabelle.w@gmail.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO2",2,3407,318518,"","Emirates Airline Service delivery","25155","","",97200000000000,9322788,"miss.rebeccaisabelle","Rebecca Isabelle","","#Swedish #globalista 👱🏽‍♀️Based in #Dubai 🇦🇪","",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
Insert into users values (0,3,"irina","peicu","12/06/1985","contact.irinahp@gmail.com","$2a$10$BIJgYjaxaSErt1WOkEhxC.8Bg94pEYdHGSE1ofoAFPZL/8dVEfaO3",12,205,NULL,"","","","","",4312341234,13327500,"irinahp","Irina","","forever young\nVienna based\n👫 @me_and_mango 😜\n🔜 Barcelona, Istanbul, Capadoccia, Spain","https://www.instagram.com/irinahp/",0,0,1,"","","","",1,"T",0,"H",1,3,1,TODAY,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,"");
End Function
