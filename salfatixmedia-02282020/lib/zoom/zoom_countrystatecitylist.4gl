IMPORT FGL core_db
IMPORT FGL core_ui

Function zoomCountryStateCity(wTtl String, qryBody String, wcl String, wclCol String, wclVal String)
  Type 
    trec  Record
      cle   Integer,
      lbl   String
          End Record

  Define
    arr   Dynamic Array Of trec,
    rec   trec,
    qry   String,
    lbool_is_mobile Boolean

  Let lbool_is_mobile = core_ui.ui_is_mobile()
  Open Window wZoom With Form "zoom_countrystatecitylist"

    Call FGL_SETTITLE(wTtl)
    Let qry = qryBody
    If wcl Is Not Null Then
      Let qry = qry.append(" Where "||wcl)
    End If
    If wclCol Is Not Null And wclVal Is Not Null Then
      Let qry = qry.append(Iif(wcl Is Null," Where ", " And ")||wclCol||" Like '"||wclVal||"%'")
    End If
    If wclCol Is Not Null Then
      Let qry = qry.append(" Order By "||wclCol)
    End If
    Declare cZoom Cursor From qry

    Call arr.clear()
    Foreach cZoom Into rec.*
      Call arr.appendElement()
      Let arr[arr.getLength()].* = rec.*
    End Foreach

    Let int_flag = FALSE
    Dialog Attributes(Unbuffered, Field Order Form)
      Display Array arr To srTbl.*
      End Display
      On Action accept
        Exit Dialog
      On Action cancel
        Let int_flag = True
        Exit Dialog
      On Action done
        Exit Dialog
      On Action back
        Let int_flag = True
        Exit Dialog
      Before Dialog
        Call Dialog.setActionActive("close",NOT lbool_is_mobile)
        Call Dialog.setActionHidden("close",lbool_is_mobile)
        CALL DIALOG.setActionActive("done", (NOT lbool_is_mobile))
        CALL DIALOG.setActionHidden("done", (lbool_is_mobile))
        CALL DIALOG.setActionActive("back", (NOT lbool_is_mobile))
        CALL DIALOG.setActionHidden("back", (lbool_is_mobile))
        IF lbool_is_mobile THEN
          CALL core_ui.ui_set_node_attribute("Image","name","img_back","hidden", TRUE)
          CALL core_ui.ui_set_node_attribute("Image","name","img_accept","hidden", TRUE)
        END IF
    End Dialog

    If Not int_flag Then
      Let rec.* = arr[arr_curr()].*
    Else
      Let rec.cle = Null
    End If

  Close Window wZoom

  Return rec.cle
End Function
