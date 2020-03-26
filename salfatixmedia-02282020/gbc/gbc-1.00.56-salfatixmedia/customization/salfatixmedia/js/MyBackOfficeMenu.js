/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2018. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('MyBackOfficeMenu', ['WidgetBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * @class MyBackOfficeMenu
     * @memberOf classes
     * @extends classes.WidgetBase
     */
    cls.MyBackOfficeMenu = context.oo.Class(cls.WidgetBase, function($super) {
      return /** @lends classes.MyBackOfficeMenu.prototype */ {
        __name: "MyBackOfficeMenu",
        _model: null,
        constructor: function(opts) {
          $super.constructor.call(this, opts);
          this._model = new cls.ModelHelper(this);
          //this._element.on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_viewmainpanel")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_viewbrands")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_addbrand")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_viewcampaigns")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_addcampaign")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_viewinfluencers")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_addinfluencer")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_viewbousers")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_addbouser")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_signin")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_editprofile")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_logout")[0].on("click", this._onClick.bind(this));

          this._element.getElementsByClassName("img_salfatixlogo")[0].src = gbc.ThemeService.getResource("img/logo.png");
          this._element.getElementsByClassName("img_viewmainpanel")[0].src = gbc.ThemeService.getResource("img/home.png");
          this._element.getElementsByClassName("img_dropbtn")[0].src = gbc.ThemeService.getResource("img/caret-down.png");
          this._element.getElementsByClassName("img_editprofile")[0].src = gbc.ThemeService.getResource("img/user.png");
          this._element.getElementsByClassName("img_logout")[0].src = gbc.ThemeService.getResource("img/signout.png");
        },
        _onClick: function( event ) {
          document.getElementById('clickedfrom').innerHTML=event.currentTarget.id;
          this._model.executeActionByName("customaction");
        }
      };
    });
  }
);
