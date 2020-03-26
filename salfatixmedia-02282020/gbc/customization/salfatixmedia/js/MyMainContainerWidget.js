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

modulum('MyMainContainerWidget', ['MainContainerWidget', 'WidgetFactory'],
  function(context, cls) {

    /**
     * @class MyMainContainerWidget
     * @memberOf classes
     * @extends classes.MainContainerWidget
     */
    cls.MyMainContainerWidget = context.oo.Class(cls.MainContainerWidget, function($super) {
      return /** @lends classes.MyMainContainerWidget.prototype */ {
        __name: "MyMainContainerWidget",

        constructor: function(opts) {
          $super.constructor.call(this, opts);

          var x;
          if (gbc.bootstrapInfo.appName.startsWith("salfatixmedia4brands") || gbc.bootstrapInfo.appName.startsWith("brands")) {
            x = new cls.MyBrandMenu(opts);
          }
          if (gbc.bootstrapInfo.appName.startsWith("salfatixmedia4backoffice") || gbc.bootstrapInfo.appName.startsWith("backoffice")) {
            x = new cls.MyBackOfficeMenu(opts);
          }
          if (gbc.bootstrapInfo.appName.startsWith("validation") || gbc.bootstrapInfo.appName.startsWith("resetpassword")) {
            this.getElement().querySelector("foobar").innerHTML = '<div class="topnav" id="myTopnav"><div class="salfatixlogo"><a href="https://www.salfatixmedia.com/" target="_self"><img src="https://static.wixstatic.com/media/3201d9_57980f35b11f4fc595e7afa32186d250~mv2.png/v1/fill/w_51,h_51,al_c,usm_0.66_1.00_0.01/3201d9_57980f35b11f4fc595e7afa32186d250~mv2.png"/></a></div><div class="navbrand">Salfatix Media</div></div>'; 
          }
          if ( x ) { /* not : null,undefined,NaN,"",0,false */
            x.setParentWidget(this);
            this.getElement().querySelector("foobar").appendChild(x.getElement());              
          }
        }
      };
    });

    /*
     *  This is a sample widget that would replace the default one in GBC
     *  To activate it, please uncomment the line below. This will override
     *  the original widget registration to this one.
     */

    cls.WidgetFactory.registerBuilder('MainContainer', cls.MyMainContainerWidget);
  });
