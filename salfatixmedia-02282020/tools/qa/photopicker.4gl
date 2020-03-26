Main
  Define 
    posttype   SmallInt,
    fileUri    String,
    donePosts  Dynamic Array Of Record
      lastPost   String
               End Record,
    formId     ui.Form

  Open Form w_form From "photopicker"
  Display Form w_form

  Dialog Attributes ( Unbuffered )
    Input By Name posttype
      On Change posttype
        Case posttype
          When 3
            Call Dialog.setActionActive("selectvid",True)
            Call Dialog.setActionActive("selectpic",False)
          When Null
            Call Dialog.setActionActive("selectvid",False)
            Call Dialog.setActionActive("selectpic",False)
          Otherwise
            Call Dialog.setActionActive("selectvid",True)
            Call Dialog.setActionActive("selectpic",True)
        End Case
    End Input
    Display Array donePosts To srDonePosts.*
      On Action delete
        Call donePosts.deleteElement(DIALOG.getCurrentRow("srdoneposts"))
    End Display
    Before Dialog
      Call Dialog.setActionActive("selectvid",False)
      Call Dialog.setActionActive("selectpic",False)
      Let formId = Dialog.getForm()
    On Action selectvid
      Call ui.Interface.frontCall("mobile", "chooseVideo", [], [fileUri])
      Call donePosts.appendElement()
      Let donePosts[donePosts.getLength()].lastPost = fileUri
      Call formId.setElementHidden("postsent",False)
      display fileUri
    On Action selectpic
      Call ui.Interface.frontCall("mobile", "choosePhoto", [], [fileUri])
      Call donePosts.appendElement()
      Let donePosts[donePosts.getLength()].lastPost = fileUri
      Call formId.setElementHidden("postsent",False)
      display fileUri
    On Action cancel
      Exit Dialog
  End Dialog

end main
