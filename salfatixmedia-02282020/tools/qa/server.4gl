IMPORT util
IMPORT os

PUBLIC CONSTANT
  C_FE_UNDEFINED SMALLINT = 0,
  C_FE_GDC SMALLINT = 1,
  C_FE_WEB SMALLINT = 2,
  C_FE_GMA SMALLINT = 4,
  C_FE_GMI SMALLINT = 8,
  C_FE_GBC SMALLINT = 16,
  C_FE_CONSOLE SMALLINT = 32

DEFINE 
  m_front_end_type SMALLINT

TYPE
  t_dynfield RECORD
    name STRING, -- a column name
    type STRING  -- a column type
  END RECORD

MAIN
  DEFINE
    l_dialog ui.DIALOG,
    larec_dynfields DYNAMIC ARRAY OF t_dynfield,
    lstr_event STRING,
    i INTEGER,
    l_image BYTE,
    ret INTEGER

  OPEN WINDOW w_xx WITH 1 ROWS, 1 COLUMNS
  CALL _build_dynamic_form(larec_dynfields)
  LET l_dialog = ui.Dialog.createInputByName(larec_dynfields)
  CALL l_dialog.addTrigger("ON ACTION accept")
  CALL l_dialog.addTrigger("ON ACTION cancel")
  CALL l_dialog.addTrigger("ON ACTION upload_image")
  CALL l_dialog.addTrigger("ON ACTION upload_video")
  FOR i = 1 TO 5
    CALL l_dialog.setFieldValue(larec_dynfields[i].name, "foobar"||i)
  END FOR

  WHILE TRUE
    LET lstr_event = l_dialog.nextEvent()
    CASE lstr_event
      WHEN "ON ACTION accept"
        DISPLAY "ON ACTION accept"
        EXIT WHILE
      WHEN "ON ACTION cancel"
        DISPLAY "ON ACTION cancel"
        EXIT WHILE
      WHEN "ON ACTION upload_image"
        DISPLAY "ON ACTION upload_image"
        LET ret = upload_image(l_image, "choosePhoto")
      WHEN "ON ACTION upload_video"
        DISPLAY "ON ACTION upload_video"
        LET ret = upload_image(l_image, "chooseVideo")
      WHEN "BEFORE INPUT"
        DISPLAY "BEFORE INPUT"
      WHEN "AFTER INPUT"
        EXIT WHILE
      OTHERWISE
        DISPLAY "event = ", lstr_event
    END CASE
  END WHILE
  CALL l_dialog.close()
  CLOSE WINDOW w_xx

END MAIN

PRIVATE FUNCTION _build_dynamic_form(parec_dynfields DYNAMIC ARRAY OF t_dynfield)
  DEFINE
    w ui.window,
    f ui.form,
    form, grid, screenRecord, formfield, edit, l_label, link om.DomNode,
    i,j,fieldId,posY INTEGER

  CALL parec_dynfields.clear()
  LET w = ui.Window.getCurrent()
  LET f = w.createForm("foobar")
  LET form = f.getNode()

  LET grid = form.createChild("Grid")
  CALL grid.setAttribute("name", "salfatixmedia1")
  CALL grid.setAttribute("width", 17)
  CALL grid.setAttribute("height", 12)

  LET screenRecord = form.createChild("RecordView")
  CALL screenRecord.setAttribute("tabName", "formonly")

  LET fieldId = 0
  LET j = 0
  LET posY = 0
  FOR i = 1 TO 5
    --build the Label field
    LET l_label = grid.createChild("Label")
    CALL l_label.setAttribute("text", "label"||i)
    CALL l_label.setAttribute("posY", posY) LET posY = posY + 1
    CALL l_label.setAttribute("posX", 0)
    CALL l_label.setAttribute("gridWidth", 17)

    --build the Edit field for url input
    LET j = j + 1
    LET parec_dynfields[j].name = "url"||(i-1)
    LET parec_dynfields[j].type = "VARCHAR(255)"
    --FormField
    LET formfield = grid.createChild("FormField")
    CALL formfield.setAttribute("name", "formonly." || parec_dynfields[j].name)
    CALL formfield.setAttribute("colName", parec_dynfields[j].name)
    --CALL formfield.setAttribute("sqlType", colType)
    CALL formfield.setAttribute("fieldId", fieldId:=fieldId+1)
    CALL formfield.setAttribute("sqlTabName", "formonly")
    CALL formfield.setAttribute("tabIndex", fieldId)
    --Edit
    LET edit = formfield.createChild("Edit")
    CALL edit.setAttribute("width", 13)
    CALL edit.setAttribute("scroll", 1)
    CALL edit.setAttribute("posY", posY) LET posY = posY + 1
    CALL edit.setAttribute("posX", 1)
    CALL edit.setAttribute("gridWidth", 13)
    --Link
    LET link = screenRecord.createChild("Link")
    CALL link.setAttribute("colName", parec_dynfields[j].name)
    CALL link.setAttribute("fieldIdRef", fieldId)

  END FOR
  --CALL form.writeXml("toto.42f")
END FUNCTION

#+ Upload an image/photo on the client side
#+ The given BYTE is only changed when the user uploads an image
#+
#+ @param p_image BYTE image
#+
#+ @returnType BYTE
#+ @return     image/photo binary, NULL in case of cancel
FUNCTION upload_image(p_image BYTE, method STRING)
  DEFINE
    lstr_os STRING,
    lstr_client_path STRING,
    lstr_client_filename STRING,
    lstr_server_filename STRING,
    lint_ret INTEGER

  DISPLAY "method=",method
  TRY
    CALL ui.interface.frontcall("mobile",method,[],[lstr_client_filename])
  CATCH
  END TRY
  IF lstr_client_filename.getLength() = 0 THEN --user cancels the directory selection
    RETURN -1
  END IF
  LET lstr_server_filename = SFMT("image_upload_%1_%2",FGL_GETPID(), util.Datetime.format(CURRENT, "%Y%m%d%H%M%S%F"))
  TRY
    DISPLAY "lstr_client_filename = ",lstr_client_filename
    DISPLAY "baseName = ",os.Path.basename(lstr_client_filename)
    DISPLAY "lstr_server_filename = ",lstr_server_filename
    CALL FGL_GETFILE(lstr_client_filename,lstr_server_filename)
    --release image resource is any
    IF p_image IS NOT NULL THEN FREE p_image END IF
    LOCATE p_image IN FILE lstr_server_filename
  CATCH
    LET lint_ret = STATUS
  END TRY
  RETURN lint_ret

END FUNCTION

#+ Get the front end type identifier
#+
#+ @returnType SMALLINT
#+ @return     front end type identifier
#+ @return     C_FE_GDC the front end is Genera Desktop Client
#+ @return     C_FE_WEB the front end is Genero Web Client
#+ @return     C_FE_GMA the front end is Genero Mobile for Android
#+ @return     C_FE_GMI the front end is Genero Mobile for iOS
#+ @return     C_FE_UNDEFINED the front end is undefined
#+
FUNCTION ui_get_front_end_type()
  IF m_front_end_type == C_FE_UNDEFINED THEN
    CASE ui.Interface.getFrontEndName()
      WHEN "GWC"
        LET m_front_end_type = C_FE_WEB
      WHEN "GBC"
        LET m_front_end_type = C_FE_GBC
      WHEN "GDC"
        LET m_front_end_type = C_FE_GDC
      WHEN "GMA"
        LET m_front_end_type = C_FE_GMA
      WHEN "GMI"
        LET m_front_end_type = C_FE_GMI
      WHEN "Console"
        LET m_front_end_type = C_FE_CONSOLE
    END CASE
  END IF
  RETURN m_front_end_type
END FUNCTION

#+ Check if the user interface is GDC
#+
#+ @returnType SMALLINT
#+ @return     1 when the user interface is GDC, 0 otherwise
FUNCTION ui_is_gdc()
  DEFINE
    lint_front_end_type SMALLINT

  LET lint_front_end_type = ui_get_front_end_type()
  RETURN (lint_front_end_type == C_FE_GDC)
END FUNCTION

#+ Check if the user interface is GMA or GMI
#+
#+ @returnType SMALLINT
#+ @return     1 when the user interface is GMA/GMI, 0 otherwise
FUNCTION ui_is_mobile()
  DEFINE
    lint_front_end_type SMALLINT

  LET lint_front_end_type = ui_get_front_end_type()
  RETURN (lint_front_end_type == C_FE_GMA) OR (lint_front_end_type == C_FE_GMI)
END FUNCTION