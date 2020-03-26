/// FOURJS_START_COPYRIGHT(D,2014)
/// Property of Four Js*
/// (c) Copyright Four Js 2014, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('ButtonIcon4STBehavior', ['StyleBehaviorBase'],
  function(context, cls) {
    /**
     * @class ButtonIcon4STBehavior
     * @memberOf classes
     * @extends classes.StyleBehaviorBase
     */
    cls.ButtonIcon4STBehavior = context.oo.Singleton(cls.StyleBehaviorBase, function($super) {
      return /** @lends classes.ButtonIcon4STBehavior.prototype */ {
        __name: "ButtonIcon4STBehavior",

        usedStyleAttributes: ["buttonIcon"],
        /**
         * @inheritDoc
         */
        _apply: function(controller, data) {
          var widget = controller.getWidget();
          if (widget && widget.setButtonIcon) {
            var buttonIcon = controller.getAnchorNode().getStyleAttribute('buttonIcon');
            widget.setButtonIcon(buttonIcon);
          }
        }
      };
    });
  });
