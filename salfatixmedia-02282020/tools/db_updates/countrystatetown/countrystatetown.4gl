Import util

type
    trec     Record
      ISO      String,
      ISO3     String,
      ISONumeric String,
      fips       String,
      Country    String,
      Capital    String,
      Area       String,
      Population String,
      Continent  String,
      tld        String,
      CurrencyCode String,
      CurrencyName String,
      Phone        String,
      PostalCode   String,
      PcFormat     String,
      PostalCodeRegex String,
      Languages String,
      geonameid String,
      neighbours String,
      EquivalentFipsCode String
      End Record,
      trec2 Record
        UID String,
        GID_0 String, -- Country code ISO3
        ID_0,
        NAME_0, -- Country name
        GID_1,
        ID_1,
        NAME_1, -- State name
        VARNAME_1,
        NL_NAME_1,
        HASC_1,
        CC_1,
        TYPE_1,
        ENGTYPE_1, -- Province, region, County, District, Parish, Sovereign Base Area, Municipality
        VALIDFR_1,
        VALIDTO_1,
        REMARKS_1,
        GID_2,
        ID_2,
        NAME_2,
        VARNAME_2,
        NL_NAME_2,
        HASC_2,
        CC_2,
        TYPE_2,
        ENGTYPE_2,
        VALIDFR_2,
        VALIDTO_2,
        REMARKS_2,
        GID_3,
        ID_3,
        NAME_3,
        VARNAME_3,
        NL_NAME_3,
        HASC_3,
        CC_3,
        TYPE_3,
        ENGTYPE_3,
        VALIDFR_3,
        VALIDTO_3,
        REMARKS_3,
        GID_4,
        ID_4,
        NAME_4,
        VARNAME_4,
        CC_4,
        TYPE_4,
        ENGTYPE_4,
        VALIDFR_4,
        VALIDTO_4,
        REMARKS_4,
        GID_5,
        ID_5,
        NAME_5, -- Town Name
        CC_5,
        TYPE_5,
        ENGTYPE_5,
        REGION,
        VARREGION,
        zone String
        End Record

Main
  Define
    fileName  String,
    fileId    base.Channel,
    i         Integer,
    oldCountry String,
    oldState   String,
    oldTown    String,
    townName   String,
    countryId  Integer,
    stateId    Integer,
    rec       trec,
    rec2      trec2,
    fileId2   base.Channel,
    qry       String,
    countries Dynamic Array Of Record
      id        Integer,
      shortName String,
      longName  String,
      dialCode  Integer
              End Record,
    states    Dynamic Array Of Record
      id        Integer,
      longName  String,
      countryId Integer
              End Record,
    cities    Dynamic Array OF Record
      id        Integer,
      longName  String,
      stateId   Integer
              End Record

  Display "Countries"
  Let fileName = "countryinfo.txt"
  Let fileId = base.Channel.create()
  Call fileId.openFile(fileName,"r")
  Call fileId.setDelimiter("\t")
  Let i = 1
  While fileId.read(rec)
    If rec.ISO.getCharAt(1) <> "#" Then
      Let rec.phone = clean(rec.Phone)
      Let countries[i].id = i
      Let countries[i].shortName = rec.ISO3
      Let countries[i].longName  = rec.Country
      Let countries[i].dialCode  = rec.Phone
      Let i = i + 1
    End If
  End While
  Call fileId.close()

  Display "States"
  Let fileName = "gadm36.csv"
  Let fileId = base.Channel.create()
  Call fileId.openFile(fileName,"r")
  Call fileId.setDelimiter("\t")
  Let i = 0
  Let countryId = 0
  Let oldCountry = " "
  Let oldState   = " "
  While fileId.read(rec2)
    If i = 0 Then
      Let i = i + 1
      Continue While
    End If
    If rec2.GID_0 <> oldCountry Then
      Let countryId = countries.search("shortname",rec2.GID_0)
      If countryId <> 0 Then
        Let countryId = countries[countryId].id
      Else
        Display "Country ",rec2.GID_0,"/",rec2.NAME_0," does not exist"
      End If
      Let oldCountry = rec2.GID_0
    End If
    If countryId <> 0 Then
      If Not oldState.equals(Iif(rec2.NAME_1.trim().getLength() = 0,rec2.NAME_0,rec2.NAME_1)) Then
        Let oldState = Iif(rec2.NAME_1.trim().getLength() = 0,rec2.NAME_0,rec2.NAME_1)
        Let states[i].id = i
        Let states[i].longName = Iif(rec2.NAME_1.trim().getLength() = 0,rec2.NAME_0,rec2.NAME_1)
        Let states[i].countryId = countryId
        Let i = i + 1
      End If
    End If
  End While
  Call fileId.close()

  Display "Cities"
  Let fileName = "gadm36.csv"
  Let fileId = base.Channel.create()
  Call fileId.openFile(fileName,"r")
  Call fileId.setDelimiter("\t")
  Let i = 0
  Let stateId = 0
  Let oldState   = " "
  Let oldTown = " "
  While fileId.read(rec2)
    If i = 0 Then
      Let i = i + 1
      Continue While
    End If
    Let townName = Iif(rec2.NAME_5.trim().getLength() > 0 And Not isNumeric(rec2.NAME_5),rec2.NAME_5,
                       Iif(rec2.NAME_4.trim().getLength() > 0 And Not isNumeric(rec2.NAME_4),rec2.NAME_4,
                       Iif(rec2.NAME_3.trim().getLength() > 0 And Not isNumeric(rec2.NAME_3),rec2.NAME_3,
                       Iif(rec2.NAME_2.trim().getLength() > 0 And Not isNumeric(rec2.NAME_2),rec2.NAME_2,
                       Iif(rec2.NAME_1.trim().getLength() > 0 And Not isNumeric(rec2.NAME_1),rec2.NAME_1,
                           rec2.NAME_0)))))

    If Not oldState.equals(Iif(rec2.NAME_1.trim().getLength() = 0,rec2.NAME_0,rec2.NAME_1)) Then
      Let stateId = states.search("longname",Iif(rec2.NAME_1.trim().getLength() = 0,rec2.NAME_0,rec2.NAME_1))
      If stateId <> 0 Then
        Let stateId = states[stateId].id
      Else
        Display "State ",rec2.NAME_0,"/",rec2.NAME_1," does not exist"
      End If
      Let oldState = Iif(rec2.NAME_1.trim().getLength() = 0,rec2.NAME_0,rec2.NAME_1)
    End If
    If stateId <> 0 Then
      If Not oldTown.equals(townName) Then
        Let oldTown = townName
        Let cities[i].id = i
        Let cities[i].longName = townName
        Let cities[i].stateId = stateId
        Let i = i + 1
      End If
    End If
  End While
  Call fileId.close()

  Let fileId2 = base.Channel.create()
  Call fileId2.openFile("countries.sql","w")
  For i = 1 To countries.getLength()
    Let qry = "Insert Into countries values (",countries[i].id,",\"",countries[i].shortName,"\",\"",countries[i].longName,"\",",countries[i].dialCode,")"
    --Display qry
    Call fileId2.writeLine(qry)
  End For
  Call fileId2.close()
  Call fileId2.openFile("states.sql","w")
  For i = 1 To states.getLength()
    Let qry = "Insert into states values (",states[i].id,",\"",states[i].longName,"\",",states[i].countryId,")"
    --Display qry
    Call fileId2.writeLine(qry)
  End For
  Call fileId2.close()
  Call fileId2.openFile("cities.sql","w")
  For i = 1 To cities.getLength()
    Let qry = "Insert into cities values (",cities[i].id,",\"",cities[i].longName,"\",",cities[i].stateId,")"
    --Display qry
    Call fileId2.writeLine(qry)
  End For
  Call fileId2.close()
End Main

Function clean( str String )
  Define
    i SmallInt

  For i=1 To str.getLength()
    If str.getCharAt(i) = "+" Or str.getCharAt(i) = "-" Then
      Let str = Iif(i=1,str.subString(2,str.getLength()),Iif(i=str.getLength(),str.subString(1,str.getLength()-1),str.subString(1,i-1)||str.subString(i+1,str.getLength())))
    End If
  End For
  Return str
End Function

Function isNumeric( s String )
  Define
    i Integer

  Let i = s.trim()

  Return Iif(i Is Null,False,True)
End Function