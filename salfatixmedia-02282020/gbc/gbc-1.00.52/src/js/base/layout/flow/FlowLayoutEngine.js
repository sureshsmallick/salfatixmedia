/// FOURJS_START_COPYRIGHT(D,2019)
/// Property of Four Js*
/// (c) Copyright Four Js 2019, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('FlowLayoutEngine', ['LayoutEngineBase'],
  function(context, cls) {

    /**
     * Layout engine for container that will flow items in continuous dropdown
     * Note that it should be applied to WidgetGroupBase widgets only
     * @class FlowLayoutEngine
     * @memberOf classes
     * @extends classes.LayoutEngineBase
     */
    cls.FlowLayoutEngine = context.oo.Class(cls.LayoutEngineBase, function($super) {
      return /** @lends classes.FlowLayoutEngine.prototype */ {
        __name: "FlowLayoutEngine",

        /** @type {Number} */
        _childrenWidth: 0,

        /** @type {Number} */
        _containerWidth: 0,

        /** @type {classes.FlowDecoratorWidget} **/
        _flowDecoratorWidget: null,

        /**
         * Define the widget used for flowing (usually 3dots)
         * @param {classes.FlowDecoratorWidget} flowDecoratorWidget
         */
        setFlowDecoratorWidget: function(flowDecoratorWidget) {
          this._flowDecoratorWidget = flowDecoratorWidget;
        },

        /**
         * Get the widget used for flowing
         * @return {classes.FlowDecoratorWidget}
         */
        getFlowDecoratorWidget: function() {
          return this._flowDecoratorWidget;
        },

        /**
         * @inheritDoc
         */
        notifyLayoutApplied: function() {
          $super.notifyLayoutApplied.call(this);

          if (this._needRefresh()) { // No need to refresh everytime
            if (this._throttle) {
              window.clearTimeout(this._throttle);
            }
            this._throttle = this._registerTimeout(function() {
              this._refresh();
              this._throttle = null;
            }.bind(this), 200);
          }
        },

        /**
         * Refresh the flowing items
         * @private
         */
        _refresh: function() {
          var containerWidth = this.getContainerWidth();
          var childrenTotalWidth = this.getChildrenWidth();
          // If the children width is more than the container width, we need to flow some children
          this._flowItems(childrenTotalWidth > containerWidth);
        },

        /**
         * Flow or unflow items
         * @param {Boolean} flow - true to flow items if necessary, false to unflow them
         * @private
         */
        _flowItems: function(flow) {
          var flowingChildren = [];
          var widget = this._widget;
          var flowDecoratorWidget = this.getFlowDecoratorWidget();
          var childrenWidth = this.getChildrenWidth();
          var containerWidth = this.getContainerWidth();

          // Flow items after size calculation: add to the dropdown
          if (flow) {
            flowDecoratorWidget.enable(true);
            var currentChildrenWidth = this.getChildrenWidth();

            var children = widget.getChildren().slice(0);
            // Each item width starting from the last is compared to total width
            children.reverse().reduce(function(prev, child) {
              if (prev >= containerWidth) {
                flowDecoratorWidget.flowChild(child, true); // flow this child
              }
              return prev - child.getLayoutInformation().getRawMeasure().getWidth();
            }, currentChildrenWidth);
          }
          // Unflow items after size calculation: remove from top of the dropdown to add it at the end of the parent
          else {
            flowingChildren = flowDecoratorWidget.getFlowingChildren();
            flowingChildren.reduce(function(prev, child) {
              var width = prev + child.getLayoutInformation().getRawMeasure().getWidth();
              if (width <= containerWidth) {
                flowDecoratorWidget.flowChild(child, false); // unflow this child
              }
              return width;
            }, childrenWidth);
          }
        },

        /**
         * Check if refresh is necessary
         * @return {boolean} true if need a refresh, false otherwise
         * @private
         */
        _needRefresh: function() {
          var currentChildrenWidth = this.getChildrenWidth();
          var currentContainerWidth = this.getContainerWidth();

          // No need to refresh if either of container and/or children total width did not change
          if (this._childrenWidth !== currentChildrenWidth || this._containerWidth !== currentContainerWidth) {
            // If changed, update those values
            this._childrenWidth = currentChildrenWidth;
            this._containerWidth = currentContainerWidth;
            return true;
          } else {
            return false;
          }
        },

        /**
         * Calculate the total width of the children
         * @return {*}
         */
        getChildrenWidth: function() {
          return this._widget.getChildren().slice(0).reduce(function(prev, child) {
            return prev + child.getLayoutInformation().getRawMeasure().getWidth();
          }, 0);
        },

        /**
         * Calculate the container Width, take the 3dots icon into account
         * @return {number}
         */
        getContainerWidth: function() {
          return this._widget.getLayoutInformation().getRawMeasure().getWidth() - this._widget.getDecoratorWidth();
        },

      };
    });
  });
