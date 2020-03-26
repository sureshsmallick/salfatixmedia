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

modulum('StretchableScrollLayoutEngine', ['LayoutEngineBase'],
  function(context, cls) {
    /**
     * @class StretchableScrollLayoutEngine
     * @memberOf classes
     * @extends classes.LayoutEngineBase
     */
    cls.StretchableScrollLayoutEngine = context.oo.Class(cls.LeafLayoutEngine, function($super) {
      return /** @lends classes.StretchableScrollLayoutEngine.prototype */ {
        __name: "StretchableScrollLayoutEngine",

        /**
         * @inheritDoc
         */
        getRenderableChildren: function() {
          return this._widget && this._widget.getChildren && this._widget.getChildren() || [];
        },

        /**
         * @inheritDoc
         */
        measureDecoration: function() {
          $super.measureDecoration.call(this);
          var paginationWidget = this._widget.getPaginationWidget ? this._widget.getPaginationWidget() : null;
          var paginationHeight = paginationWidget ? paginationWidget.getElement().getBoundingClientRect().height : 0;
          var layoutInfo = this._widget.getLayoutInformation();
          layoutInfo.setDecorating(0, paginationHeight);
        },

        /**
         * @inheritDoc
         */
        adjustMeasure: function() {
          var layoutInfo = this._widget.getLayoutInformation();
          var children = this.getRenderableChildren();
          var decorationHeight = layoutInfo.getDecorating().getHeight(true);

          if (children.length > 0) {
            var childMinimal = children[0].getLayoutInformation().getMinimal();
            layoutInfo.setMinimal(
              Math.max(layoutInfo.getMinimal().getWidth(true), childMinimal.getWidth(true)),
              Math.max(layoutInfo.getMinimal().getHeight(true), childMinimal.getHeight(true) + decorationHeight)
            );
          } else {
            layoutInfo.setMinimal(0, decorationHeight);
          }
          var sizeX = layoutInfo.getMinimal().getWidth(true);
          var sizeY = layoutInfo.getMinimal().getHeight(true);
          layoutInfo.setPreferred(sizeX, sizeY);
          layoutInfo.setMeasured(sizeX, sizeY);
        }
      };
    });
  });
