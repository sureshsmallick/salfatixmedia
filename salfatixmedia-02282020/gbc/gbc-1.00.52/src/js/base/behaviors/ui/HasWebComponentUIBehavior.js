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

modulum('HasWebComponentUIBehavior', ['UIBehaviorBase'],
  function(context, cls) {
    /**
     * @class HasWebComponentUIBehavior
     * @memberOf classes
     * @extends classes.UIBehaviorBase
     */
    cls.HasWebComponentUIBehavior = context.oo.Singleton(cls.UIBehaviorBase, function($super) {
      return /** @lends classes.HasWebComponentUIBehavior.prototype */ {
        /** @type {string} */
        __name: "HasWebComponentUIBehavior",
        /**
         * @inheritDoc
         */
        _attachWidget: function(controller, data) {
          if (!!controller.getWidget() && controller.getWidget()._iframeElement) {
            var windowNode = controller.getAnchorNode().getAncestor("Window");
            //Tell application it contains a window with webcomponent
            var application = windowNode.getAncestor("UserInterface").getApplication(),
              applicationWidget = application.getUI().getWidget();
            applicationWidget.setHasWebComponent(true);

            //Tell window it contains a webcomponent
            var windowWidget = windowNode.getController().getWidget();
            windowWidget.setHasWebComponent(true);

          }
        },
        /**
         * @inheritDoc
         */
        _detachWidget: function(controller, data) {
          //TODO many Webcomp

        }

      };
    });
  });
