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

modulum('FolderWidget', ['FolderWidgetBase'],
  function(context, cls) {

    /**
     * Folder widget.
     * @class FolderWidget
     * @memberOf classes
     * @extends classes.FolderWidgetBase
     * @publicdoc Widgets
     */
    cls.FolderWidget = context.oo.Class(cls.FolderWidgetBase, function($super) {
      return /** @lends classes.FolderWidget.prototype */ {
        __name: "FolderWidget",

        /** @type {HTMLElement} */
        _tabsTitlesElement: null,
        /** @type {String} */
        _tabsPosition: "top",
        /** @type {cls.ScrollTabDecorator} */
        _scroller: null,

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          this._layoutInformation = new cls.LayoutInformation(this);
          this._layoutEngine = new cls.FolderLayoutEngine(this);
        },

        /**
         * @inheritDoc
         */
        _initContainerElement: function() {
          $super._initContainerElement.call(this);
          this._tabsTitlesElement = this._element.getElementsByClassName("mt-tab-titles-container")[0];

          this._scroller = new cls.ScrollTabDecorator(this);
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          if (this._scroller) {
            this._scroller.destroy();
            this._scroller = null;
          }
          if (this._tabsTitlesElement) {
            this._tabsTitlesElement = null;
          }
          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        addChildWidget: function(widget, options) {
          /** @type classes.PageWidget */
          var pageWidget = widget;

          var titleWidget = pageWidget.getTitleWidget();
          this._tabsTitlesElement.appendChild(titleWidget.getElement());

          $super.addChildWidget.call(this, pageWidget, options);
        },

        /**
         * @inheritDoc
         */
        setCurrentPage: function(page, executeAction) {
          var modified = $super.setCurrentPage.call(this, page, executeAction);
          if (modified) {
            this.scrollTo(this._currentPage);
          }
          return modified;
        },

        /**
         * Get tabs position
         * @return {string} tabs pos: top, right, bottom, left
         * @publicdoc
         */
        getTabsPosition: function() {
          return this._tabsPosition;
        },

        /**
         * Set the tabs position
         * @param {string} position - could be top, right, bottom or left
         * @publicdoc
         */
        setTabPosition: function(position) {
          if (["top", "bottom", "left", "right"].indexOf(position) < 0) {
            position = "top";
          }
          this._element.setAttribute("__FolderWidget", position);
          this._scroller.updatePosition("__FolderWidget", position);

          this._tabsPosition = position;
        },

        /**
         * Go to the given page
         * @param {classes.PageWidget} page - page to navigate to
         * @publicdoc
         */
        scrollTo: function(page) {
          var title = page && page.getTitleWidget();
          if (title) {
            this._scroller.scrollTo(title.getElement());
          }
          this._scroller.refreshScrollers();
        },

        /**
         * Update visibility of scrollers
         */
        updateScrollersVisibility: function() {
          var isVertical = ["left", "right"].indexOf(this._tabsPosition) >= 0;
          var isHorizontal = ["top", "bottom"].indexOf(this._tabsPosition) >= 0;

          var sizeAttr = isVertical ? "height" : isHorizontal ? "width" : false;

          if (sizeAttr && this._scroller) {
            // Check if there is space enough to display the full bar or need scrolling
            var tabsTitlesSize = this._tabsTitlesElement.getBoundingClientRect()[sizeAttr];
            var tabsTitlesHostSize = this._scroller._tabsTitlesHost.getBoundingClientRect()[sizeAttr];

            if (tabsTitlesHostSize - tabsTitlesSize <= 0) {
              this._scroller.showScroller(true);
            } else {
              this._scroller.showScroller(false);
            }
          }
        }
      };
    });
    cls.WidgetFactory.registerBuilder('Folder', cls.FolderWidget);
  });
