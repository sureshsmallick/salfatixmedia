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

modulum('MyBrandMenu', ['WidgetBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * @class MyBrandMenu
     * @memberOf classes
     * @extends classes.WidgetBase
     */
    cls.MyBrandMenu = context.oo.Class(cls.WidgetBase, function($super) {
      return /** @lends classes.MyBrandMenu.prototype */ {
        __name: "MyBrandMenu",
        _model: null,
        constructor: function(opts) {
          $super.constructor.call(this, opts);
          this._model = new cls.ModelHelper(this);
          //this._element.on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("salfatixlogo")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_viewcampaigns")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_addcampaign")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_signin")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_editprofile")[0].on("click", this._onClick.bind(this));
          this._element.getElementsByClassName("slftxaction_logout")[0].on("click", this._onClick.bind(this));

          this._element.getElementsByClassName("img_salfatixlogo")[0].src = gbc.ThemeService.getResource("img/logo.png");
          this._element.getElementsByClassName("img_dropbtn")[0].src = gbc.ThemeService.getResource("img/caret-down.png");
          this._element.getElementsByClassName("img_editprofile")[0].src = gbc.ThemeService.getResource("img/user.png");
          this._element.getElementsByClassName("img_logout")[0].src = gbc.ThemeService.getResource("img/signout.png");

        },
        _onClick: function( event ) {
          var x = event.currentTarget.id;
          var y = true;
          if (x === 'salfatixlogo') {
            if (document.getElementById('slftxaction_viewcampaigns').style.display !== 'none') {
              x = "slftxaction_viewcampaigns";
            } else {
                y = false;
            }
          }
          if (y === true) {
            document.getElementById('clickedfrom').innerHTML=x;
            this._model.executeActionByName("customaction");
          }
        }
      };
    });
  }
);
