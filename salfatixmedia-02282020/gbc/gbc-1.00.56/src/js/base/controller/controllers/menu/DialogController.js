/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('DialogController', ['ControllerBase', 'ControllerFactory'],
  function(context, cls) {
    /**
     * @class DialogController
     * @memberOf classes
     * @extends classes.ControllerBase
     */
    cls.DialogController = context.oo.Class(cls.ControllerBase, function($super) {
      return /** @lends classes.DialogController.prototype */ {
        __name: "DialogController",
        _initBehaviors: function() {
          $super._initBehaviors.call(this);

          // These behaviors should stay added at first
          // WARNING : DO NOT ADD BEHAVIORS BEFORE
          this._addBehavior(cls.LayoutInfoVMBehavior);
          this._addBehavior(cls.StyleVMBehavior);
          // END WARNING

          // pseudo-selector behaviors
          this._addBehavior(cls.ActivePseudoSelectorBehavior);
          // 4st behaviors
          this._addBehavior(cls.Border4STBehavior);
          this._addBehavior(cls.Reverse4STBehavior);

          // vm behaviors
          this._addBehavior(cls.MenuEnabledVMBehavior);
          this._addBehavior(cls.ColorVMBehavior);
          this._addBehavior(cls.BackgroundColorVMBehavior);
          this._addBehavior(cls.FontWeightVMBehavior);
          this._addBehavior(cls.TextDecorationVMBehavior);
          this._addBehavior(cls.FontFamilyVMBehavior);

          // 4ST styles
          this._addBehavior(cls.ActionPanelPosition4STBehavior);
          this._addBehavior(cls.ActionPanelButtonTextAlign4STBehavior);
          this._addBehavior(cls.ActionPanelButtonTextHidden4STBehavior);
        },

        /**
         * @inheritDoc
         */
        attachUI: function() {
          if (this._widget) {
            var chromeBar = this.isInChromeBar() ? this.getUINode().getWidget().getChromeBarWidget() : false;
            if (!chromeBar) {
              this.getAnchorNode().getAncestor('Window').getController().getWidget().addMenu(this._widget);
            } else {
              chromeBar.addMenu(this._widget);
            }
          }
        }
      };
    });
    cls.ControllerFactory.register("Dialog", cls.DialogController);

  });
