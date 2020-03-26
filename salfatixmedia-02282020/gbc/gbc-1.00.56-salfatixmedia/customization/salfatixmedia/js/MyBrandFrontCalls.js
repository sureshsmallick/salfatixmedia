/// FOURJS_START_COPYRIGHT(D,2014)
/// Property of Four Js*
/// (c) Copyright Four Js 2014, 2018. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('FrontCallService.modules.mybrandmodule', ['FrontCallService'],
  function(context, cls) {
    context.FrontCallService.modules.mybrandmodule = {

      myCustomSyncFunction: function (name) {
        if (name === undefined) {
          this.parametersError();
          return;
        }
        if (name.length === 0) {
          this.runtimeError("name shouldn't be empty");
          return;
        }

        return ["Hello " + name + " !"];
      },
      replace_html: function (id, value) {
        document.getElementById(id).innerHTML=value;
        return ["0"];
      },
      forgotpassword_page: function () {
        document.getElementById('slftxaction_viewcampaigns').style.display="none";
        document.getElementById('slftxaction_addcampaign').style.display="none";
        document.getElementById('slftxaction_signin').style.display="none";
        document.getElementById('dropdownlogin').style.display="none";
        return ["0"];
      },
      credentials_page: function () {
        document.getElementById('slftxaction_viewcampaigns').style.display="none";
        document.getElementById('slftxaction_addcampaign').style.display="none";
        document.getElementById('slftxaction_signin').style.display="none";
        document.getElementById('dropdownlogin').style.display="none";
        return ["0"];
      },
      addbrand_page: function (value) {
        document.getElementById('slftxaction_viewcampaigns').style.display="none";
        document.getElementById('slftxaction_addcampaign').style.display="none";
        document.getElementById('slftxaction_signin').style.display="inherit";
        document.getElementById('dropdownlogin').style.display="none";
        return ["0"];
      },
      updatebrand_page: function (value) {
        document.getElementById('slftxaction_viewcampaigns').style.display="inherit";
        document.getElementById('slftxaction_addcampaign').style.display="none";
        document.getElementById('slftxaction_signin').style.display="none";
        document.getElementById('dropdownlogin').style.display="inherit";
        document.getElementById('dropbtnloginname').innerHTML="Hi, "+value;
        return ["0"];
      },
      campaignlist_page: function (value) {
        document.getElementById('slftxaction_viewcampaigns').style.display="inherit";
        document.getElementById('slftxaction_addcampaign').style.display="flex";
        document.getElementById('slftxaction_signin').style.display="none";
        document.getElementById('dropdownlogin').style.display="inherit";
        document.getElementById('dropbtnloginname').innerHTML="Hi, "+value;
        return ["0"];
      },
      campaignmenu_page: function (value) {
        document.getElementById('slftxaction_viewcampaigns').style.display="inherit";
        document.getElementById('slftxaction_addcampaign').style.display="none";
        document.getElementById('slftxaction_signin').style.display="none";
        document.getElementById('dropdownlogin').style.display="inherit";
        document.getElementById('dropbtnloginname').innerHTML="Hi, "+value;
        return ["0"];
      },
      campaigngrid_page: function (value) {
        document.getElementById('slftxaction_viewcampaigns').style.display="inherit";
        document.getElementById('slftxaction_addcampaign').style.display="none";
        document.getElementById('slftxaction_signin').style.display="none";
        document.getElementById('dropdownlogin').style.display="inherit";
        document.getElementById('dropbtnloginname').innerHTML="Hi, "+value;
        return ["0"];
      },
      getclickedaction: function () {
        var x = document.getElementById('clickedfrom').innerHTML;
        return [document.getElementById('clickedfrom').innerHTML];
      },

      myCustomAsyncFunction: function (name) {
        if (name === undefined) {
          this.parametersError();
          return;
        }
        if (name.length === 0) {
          this.runtimeError("name shouldn't be empty");
          return;
        }

        window.setTimeout(function () {
          this.setReturnValues(["After 5s, Hello " + name + " !"]);
        }.bind(this), 5000);
      }
    };
  }
);