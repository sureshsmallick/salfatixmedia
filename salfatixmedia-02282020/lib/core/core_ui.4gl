IMPORT util
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

FUNCTION formatdecimal(decimalValue DECIMAL(10,2), fieldName STRING, formatWith STRING, formatWithout STRING)
  IF ( (decimalValue - fgl_decimal_truncate(decimalValue,0)) > 0 ) THEN
    CALL ui_change_format(fieldName,formatWith)
  ELSE
    CALL ui_change_format(fieldName,formatWithout)
  END IF
END FUNCTION

#+ Change display format of a field
#+
#+ @param field name as described in name attribute
#+ @param new format (see FORMAT attribute)
FUNCTION ui_change_format( fieldName String, newFormat String)
  Define
    wid ui.window,
    nid om.DomNode

  Let wid = ui.window.getCurrent()
  Let nid = wid.findNode("FormField",fieldName)
  Let nid = nid.getFirstChild()
  Call nid.setAttribute("format",newFormat)
END FUNCTION

#+ Display a message to the user who will have multiple choices
#+
#+ @param pstr_title title of the window
#+ @param pstr_message message displayed to the user
#+ @param pstr_answer default answer
#+ @param pstr_answer_list list of possible answers separated by |
#+ @param pstr_icon_name icon name to display - 'info','exclamation','stop','question'
#+
#+ @returnType STRING
#+ @return     answer that has been chosen, 'error' in case of error
FUNCTION ui_message(pstr_title,pstr_message,pstr_answer,pstr_answer_list,pstr_icon_name)
  DEFINE
    pstr_title STRING,
    pstr_message STRING,
    pstr_answer STRING,
    pstr_answer_list STRING,
    pstr_icon_name STRING, -- fa-info, fa-question, fa-warning, stop
    lstr_answer STRING,
    lstr_token STRING,
    lstr_tok base.StringTokenizer

  LET pstr_icon_name = pstr_icon_name.trim()
  LET pstr_title = pstr_title.trim()
  LET pstr_message = pstr_message.trim()
  LET pstr_icon_name = pstr_icon_name.trim()

  LET pstr_answer = pstr_answer.toLowerCase()
  MENU pstr_title ATTRIBUTES(STYLE="dialog",COMMENT=pstr_message,IMAGE=pstr_icon_name)
    BEFORE MENU
      CALL DIALOG.setActionActive("yes",0)
      CALL DIALOG.setActionHidden("yes",1)
      CALL DIALOG.setActionActive("no",0)
      CALL DIALOG.setActionHidden("no",1)
      CALL DIALOG.setActionActive("ok",0)
      CALL DIALOG.setActionHidden("ok",1)
      CALL DIALOG.setActionActive("cancel",0)
      CALL DIALOG.setActionHidden("cancel",1)
      LET lstr_tok = base.StringTokenizer.create(pstr_answer_list,"|")
      IF NOT lstr_tok.hasMoreTokens() THEN
        RETURN "error"
      END IF
      WHILE lstr_tok.hasMoreTokens()
        LET lstr_token = lstr_tok.nextToken()
        LET lstr_token = lstr_token.toLowerCase()
        CASE
        WHEN lstr_token="yes"
          CALL DIALOG.setActionActive("yes",1)
          CALL DIALOG.setActionHidden("yes",0)
          IF lstr_token == pstr_answer THEN NEXT OPTION "yes" END IF
        WHEN lstr_token = "no"
          CALL DIALOG.setActionActive("no",1)
          CALL DIALOG.setActionHidden("no",0)
          IF lstr_token == pstr_answer THEN NEXT OPTION "no" END IF
        WHEN lstr_token = "ok"
          CALL DIALOG.setActionActive("ok",1)
          CALL DIALOG.setActionHidden("ok",0)
          IF lstr_token == pstr_answer THEN NEXT OPTION "ok" END IF
        WHEN lstr_token="cancel"
          CALL DIALOG.setActionActive("cancel",1)
          CALL DIALOG.setActionHidden("cancel",0)
          IF lstr_token == pstr_answer THEN NEXT OPTION "cancel" END IF
        OTHERWISE
          RETURN "error"
        END CASE
      END WHILE
    COMMAND "Yes"
      LET lstr_answer = "yes"
    COMMAND "No"
      LET lstr_answer = "no"
    COMMAND "Ok"
      LET lstr_answer = "ok"
    COMMAND "Cancel"
      LET lstr_answer = "cancel"
    ON ACTION close
      LET lstr_answer = "close"
  END MENU
  RETURN lstr_answer
END FUNCTION

#+ Fills a combobox according to an sql string that is construct by using the parameters
#+
#+ @param pstr_field_name name of the combobox
#+ @param pstr_table_name sql table names
#+ @param pstr_table_field_name sql fields name that will be selected for filling up the combobox
#+ @param pstr_where_clause sql where clause
#+ @param pstr_order_by sql order by clause
#+
FUNCTION ui_fill_combo(pstr_field_name,pstr_table_name,pstr_table_field_name,pstr_where_clause,pstr_order_by)
  DEFINE
    pstr_field_name STRING,
    pstr_table_name STRING,
    pstr_table_field_name STRING,
    pstr_where_clause STRING,
    pstr_order_by STRING,
    lstr_sql STRING, -- Variable that holds the sql query
    l_combo ui.ComboBox, -- Used to hold the combo box field object
    l_combo_id VARCHAR(255),
    l_combo_value VARCHAR(255)

  LET l_combo = ui.ComboBox.forName(pstr_field_name)
  CALL l_combo.clear()

  -- Fetch the values from database which are used to fill the combo box
  LET lstr_sql = SFMT("SELECT %1 FROM %2 %3 %4",pstr_table_field_name,pstr_table_name,pstr_where_clause,pstr_order_by)
  TRY
    DECLARE c_ui_fill_combo CURSOR FROM lstr_sql
    FOREACH c_ui_fill_combo
      INTO l_combo_id, l_combo_value
      CALL l_combo.addItem(l_combo_id CLIPPED, LSTR(l_combo_value CLIPPED))
    END FOREACH
    FREE c_ui_fill_combo
  CATCH
    CALL l_combo.clear()
  END TRY
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

#+ Upload an image/photo on the client side
#+ The given BYTE is only changed when the user uploads an image
#+
#+ @param p_image BYTE image
#+
#+ @returnType BYTE
#+ @return     image/photo binary, NULL in case of cancel
FUNCTION ui_upload_image(p_image)
  DEFINE
    p_image BYTE,
    lstr_os STRING,
    lstr_client_path STRING,
    lstr_client_filename STRING,
    lstr_server_filename STRING,
    lint_ret INTEGER,
    lstr_image_ext String

  TRY
    IF ui_is_mobile() THEN --Mobile client
      CALL ui.interface.frontcall("mobile","choosePhoto",[],[lstr_client_filename])
    ELSE --Desktop client
      IF ui_is_gdc() THEN
        CALL ui.Interface.frontCall("standard","feinfo", ["ostype"], [lstr_os])
        IF lstr_os = "WINDOWS" THEN
          CALL ui.Interface.frontCall( "standard", "getenv", ["USERPROFILE"], [lstr_client_path]) --Documents and Settings \ usr
        ELSE
          CALL ui.Interface.frontCall( "standard", "getenv", ["HOME"], [lstr_client_path] ) -- /home/usr
        END IF
      ELSE
        --GBC client
        LET lstr_client_path = "samplepath"
      END IF
      --user can select the directory for the export
      Let lstr_image_ext = base.Application.getResourceEntry("salfatixmedia.image.extensions")
      CALL ui.Interface.frontCall("standard","openfile", [lstr_client_path,"*.*",lstr_image_ext,%"Choose image to load :" ],lstr_client_filename)
    END IF
  CATCH
  END TRY
  IF lstr_client_filename.getLength() = 0 THEN --user cancels the directory selection
    RETURN -1
  END IF
  LET lstr_server_filename = SFMT("image_upload_%1_%2",FGL_GETPID(), util.Datetime.format(CURRENT, "%Y%m%d%H%M%S%F"))
  TRY
    CALL FGL_GETFILE(lstr_client_filename,lstr_server_filename)
    --release image resource is any
    IF p_image IS NOT NULL THEN FREE p_image END IF
    LOCATE p_image IN FILE lstr_server_filename
  CATCH
    LET lint_ret = STATUS
  END TRY
  RETURN lint_ret

END FUNCTION

#+ Get a node in the AUI tree
#+
#+ @param pstr_aui_node type of control (toolbar,group...)
#+ @param pstr_node_property attribute name (name,tag...)
#+ @param pstr_node_value search value (which 'name', which 'tag'...)
#+
#+ @returnType om.DomNode
#+ @return     aui tree node, NULL when not found
FUNCTION ui_get_node(pstr_aui_node, pstr_node_property, pstr_node_value)
  DEFINE
    pstr_aui_node STRING,
    pstr_node_property STRING,
    pstr_node_value STRING,
    lwindow ui.Window,
    lnode om.DomNode,
    lnodeList om.NodeList

  LET lwindow = ui.Window.getCurrent()
  LET lnode = lwindow.getNode()
  LET lnodeList = lnode.selectByPath(SFMT("//%1[@%2='%3']",pstr_aui_node, pstr_node_property, pstr_node_value))
  IF lnodeList.getLength() <> 1 THEN
    RETURN NULL
  END IF
  RETURN lnodeList.item(1)
END FUNCTION

#+ Change attribute's value inside the AUI tree
#+
#+ @code
#+ CALL ui_set_node_attribute("ToolBarItem","name","add","hidden","1")
#+ CALL ui_set_node_attribute("ToolBarSeparator","tag","list_s2","hidden","1")
#+
#+ @param pstr_aui_node type of control (toolbar,group...)
#+ @param pstr_node_property attribute name (name,tag...)
#+ @param pstr_node_value search value (which 'name', which 'tag'...)
#+ @param pstr_set_property attribute to be modified
#+ @param pstr_set_property_value value for the attribute pstr_set_property
#+
FUNCTION ui_set_node_attribute(pstr_aui_node, pstr_node_property, pstr_node_value, pstr_set_property, pstr_set_property_value)
  DEFINE
    pstr_aui_node STRING,
    pstr_node_property STRING,
    pstr_node_value STRING,
    pstr_set_property STRING,
    pstr_set_property_value STRING,
    l_node om.DomNode

  LET l_node = ui_get_node(pstr_aui_node, pstr_node_property, pstr_node_value)
  CALL l_node.setAttribute(pstr_set_property, pstr_set_property_value)

END FUNCTION

#+ Change attribute's value inside the AUI tree
#+
#+ @param pstr_aui_node type of control (toolbar,group...)
#+ @param pstr_node_property attribute name (name,tag...)
#+ @param pstr_node_value search value (which 'name', which 'tag'...)
#+ @param pstr_set_property attribute to be modified
#+ @param pstr_set_property_value value for the attribute pstr_set_property
#+
FUNCTION ui_set_node_child_attribute(pstr_aui_node, pstr_node_property, pstr_node_value, pstr_set_property, pstr_set_property_value)
  DEFINE
    pstr_aui_node STRING,
    pstr_node_property STRING,
    pstr_node_value STRING,
    pstr_set_property STRING,
    pstr_set_property_value STRING,
    l_node om.DomNode,
    l_child om.DomNode

  LET l_node = ui_get_node(pstr_aui_node, pstr_node_property, pstr_node_value)
  LET l_child = l_node.getFirstChild()
  CALL l_child.setAttribute(pstr_set_property, pstr_set_property_value)

END FUNCTION

#+ Build radiogroup items based on a dictionnary
#+
#+ @param p_combo combobox identifer
#+
FUNCTION ui_radiogroup_initializer(p_formfield_name, p_dict)
  DEFINE
    p_formfield_name STRING,
    p_dict DICTIONARY OF STRING,
    dict_keys DYNAMIC ARRAY OF STRING,
    l_node om.DomNode,
    l_radiogroup om.DomNode,
    l_child om.DomNode,
    i INTEGER

  LET l_node = ui_get_node("FormField","name",p_formfield_name)
  LET l_radiogroup = l_node.getFirstChild()
  LET dict_keys = p_dict.getKeys()
  FOR i = 1 TO dict_keys.getLength()
    LET l_child = l_radiogroup.createChild("Item")
    CALL l_child.setAttribute("name", dict_keys[i])
    CALL l_child.setAttribute("text", p_dict[dict_keys[i]])
    CALL l_radiogroup.appendChild(l_child)
  END FOR
END FUNCTION

#+ Launch the given URL
#+
#+ @param pstr_url url
FUNCTION ui_launch_url(pstr_url STRING)
  TRY
    CALL ui.Interface.frontcall("standard", "launchURL", [pstr_url] , [])
  CATCH
  END TRY
END FUNCTION

#+ Check if an action exist in current dialog
#+
#+ @param actionName Action Name
#+ @returnType Boolean
#+ @return     TRUE if exists, FALSE when not found
FUNCTION ui_action_exist(actionName STRING)
  DEFINE
    wId ui.Window,
    nId om.DomNode,
    lId om.NodeList,
    doesExist BOOLEAN

  LET doesExist = FALSE

  LET wId = ui.Window.getCurrent()
  LET nId = wId.getNode()
  LET lId = nId.selectByPath("//Action[@name='"||actionName.trim().toLowerCase()||"']")
  IF lId.getLength() > 0 THEN
    RETURN TRUE
  END IF
  RETURN FALSE

  RETURN doesExist
END FUNCTION

#+ Hide or Show an element on current window
#+
#+ @param eltName Element Name
#+ @param hideIt Boolean True=Hide, False=Show
FUNCTION ui_hideOrShowElementOnCurrentForm(eltName STRING,hideIt BOOLEAN)
  DEFINE
    Wid ui.Window,
    Fid ui.Form

  IF eltName IS NULL THEN
    RETURN
  END IF
  IF hideIt IS NULL THEN
    RETURN
  END IF
  LET Wid = ui.Window.getCurrent()
  IF Wid IS NOT NULL THEN
    LET Fid = Wid.getForm()
    IF Fid IS NOT NULL THEN
      TRY
        CALL Fid.setElementHidden(eltName,hideIt)
      CATCH
      END TRY
    END IF
  END IF
END FUNCTION

#+ Hide or Show a field on current window
#+
#+ @param fieldName Field Name
#+ @param hideIt Boolean True=Hide, False=Show
FUNCTION ui_hideOrShowFieldOnCurrentForm(fieldName STRING,hideIt BOOLEAN)
  DEFINE
    Wid ui.Window,
    Fid ui.Form

  IF fieldName IS NULL THEN
    RETURN
  END IF
  IF hideIt IS NULL THEN
    RETURN
  END IF
  LET Wid = ui.Window.getCurrent()
  IF Wid IS NOT NULL THEN
    LET Fid = Wid.getForm()
    IF Fid IS NOT NULL THEN
      TRY
        CALL Fid.setFieldHidden(fieldName,hideIt)
      CATCH
      END TRY
    END IF
  END IF
END FUNCTION

