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

modulum('StretchableScrollGridPageSizeVMBehavior', ['BehaviorBase'],
  function(context, cls) {
    /**
     * @class StretchableScrollGridPageSizeVMBehavior
     * @memberOf classes
     * @extends classes.BehaviorBase
     */
    cls.StretchableScrollGridPageSizeVMBehavior = context.oo.Singleton(cls.BehaviorBase, function($super) {
      return /** @lends classes.StretchableScrollGridPageSizeVMBehavior.prototype */ {
        __name: "StretchableScrollGridPageSizeVMBehavior",

        watchedAttributes: {
          anchor: ['wantFixedPageSize', 'size', 'offset', 'pageSize', 'bufferSize']
        },
        /**
         *
         * @param controller
         * @param data
         */
        setup: function(controller, data) {
          data.linesCount = 0;
        },

        /**
         * @inheritDoc
         */
        _apply: function(controller, data) {
          if (data.animationFrameOffset) {
            window.cancelAnimationFrame(data.animationFrameOffset);
          }
          // This requestAnimationFrame is needed as we have to create lines only once the layout has been done
          data.animationFrameOffset = window.requestAnimationFrame(
            function() { // TODO Check if we can use LayoutApplicationService.onAfterLayout
              data.animationFrameOffset = 0;
              context.styler.bufferize();
              var scrollGridNode = controller.getAnchorNode();
              if (scrollGridNode) {
                var size = scrollGridNode.attribute('size');
                var pageSize = scrollGridNode.attribute('pageSize');
                var bufferSize = scrollGridNode.attribute('bufferSize');
                var offset = scrollGridNode.attribute('offset');
                var count = Math.max(pageSize, bufferSize);
                var lineIndex;
                var lineController;
                var linesCount = controller.getLineControllersCount();
                if (linesCount !== count) {
                  for (lineIndex = linesCount; lineIndex < count; ++lineIndex) {
                    // Add widgets
                    lineController = new cls.ScrollGridLineController(scrollGridNode, lineIndex);
                    scrollGridNode.getController().getWidget().addChildWidget(lineController.getWidget());
                    controller.pushLineController(lineController);
                  }
                  for (lineIndex = linesCount - 1; lineIndex >= count; --lineIndex) {
                    // Remove Widgets
                    lineController = controller.popLineController();
                    lineController.destroy();
                  }
                  controller.getWidget().updateHighlight();
                }
                // Add the new line to the DOM but set its visibility to hidden.
                // It will be displayed in the after layout handler below.
                // This avoids flashs with SVG images during the initial render.
                for (lineIndex = 0; lineIndex < controller.getLineControllersCount(); ++lineIndex) {
                  lineController = controller.getLineController(lineIndex);
                  var hidden = offset + lineIndex >= size;
                  lineController.getWidget().setHidden(hidden);
                  lineController.getWidget().addClass('loading-line');
                }
                context.styler.flush();
                var layoutService = scrollGridNode.getApplication().layout;
                layoutService.refreshLayout({
                  resize: true
                });
                layoutService.afterLayout(function() {
                  for (lineIndex = 0; lineIndex < controller.getLineControllersCount(); ++lineIndex) {
                    lineController = controller.getLineController(lineIndex);
                    if (lineController) {
                      var lineWidget = lineController.getWidget();
                      if (lineWidget && lineWidget.getElement()) {
                        lineWidget.removeClass('loading-line');
                      }
                    }
                  }
                  //We must recalculate the scroll div height after gridline count update
                  if (controller.getWidget().isInstanceOf(cls.StretchableScrollGridWidget)) {
                    controller.getWidget().updateVerticalScroll(false);
                  }

                }.bind(this), true);
              }
            }.bind(this));
        },

        /**
         * @inheritDoc
         */
        _detach: function(controller, data) {
          if (data.animationFrameOffset) {
            window.cancelAnimationFrame(data.animationFrameOffset);
            data.animationFrameOffset = 0;
          }
        },
      };
    });
  }
);
