/// FOURJS_START_COPYRIGHT(D,2017)
/// Property of Four Js*
/// (c) Copyright Four Js 2017, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('ListViewRowWidget', ['WidgetGroupBase'],
  function(context, cls) {

    /**
     * ListViewRow widget.
     * @class ListViewRowWidget
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     * @publicdoc
     */
    cls.ListViewRowWidget = context.oo.Class(cls.WidgetGroupBase, function($super) {
      return /** @lends classes.ListViewRowWidget.prototype */ {
        __name: "ListViewRowWidget",

        /** @type boolean */
        _current: false,
        /** @type classes.ImageWidget */
        _imageWidget: null,
        /** @type boolean */
        _horizontalLayout: false,

        /** @type Element */
        _imageElement: null,

        /**
         * @inheritDoc
         */
        _initElement: function() {
          this._ignoreLayout = true;
          $super._initElement.call(this);

          this._imageElement = this._element.getElementsByClassName("gbc_ListViewRowImage")[0];
          this._element.onDoubleTap("ListViewRowWidget", this._onDoubleClick.bind(this));
        },

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          // no layout
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          this._element.offDoubleTap("ListViewRowWidget");

          if (this._imageWidget) {
            this._imageWidget.destroy();
            this._imageWidget = null;
          }
          this._imageElement = null;
          this.destroyChildren();
          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        manageMouseClick: function(domEvent) {
          // Send a request focus only if none of the child widgets has been clicked
          // Otherwise, the request has already been sent
          var childClicked = false;
          for (var i = 0; !childClicked && i < this._children.length; ++i) {
            childClicked = domEvent.target.isElementOrChildOf(this._children[i].getElement());
          }
          if (!childClicked) {
            this.getTableWidgetBase().requestFocusFromWidget(this._children[0], domEvent);
          }
          return true;
        },

        /**
         * @inheritDoc
         */
        manageMouseDblClick: function(domEvent) {
          this._onDoubleClick(domEvent);
          return false;
        },

        /**
         * Handle double click on row event
         * @param {Object} event
         */
        _onDoubleClick: function(event) {
          this.getTableWidgetBase().emit(context.constants.widgetEvents.rowAction);
        },

        /**
         * @inheritDoc
         */
        addChildWidget: function(widget, options) {
          if (this._children.length > 2) {
            throw "A listview item can only contain two children";
          }
          $super.addChildWidget.call(this, widget, options);
        },

        /**
         * Sets the first and second widgets layout type to horizontal or vertical
         * @param {boolean} horizontal true for horizontal layout, false otherwise
         */
        setHorizontalLayout: function(horizontal) {
          this._horizontalLayout = horizontal;
          this._element.toggleClass('horizontal', horizontal);
        },

        /**
         * @return {boolean} true if the layout is horizontal
         */
        isHorizontalLayout: function() {
          return this._horizontalLayout;
        },

        /**
         * Set image of the row
         * @param {string} path - image path
         */
        setImage: function(path) {
          if (path && path !== "") {
            if (!this._imageWidget) {
              this._imageWidget = cls.WidgetFactory.createWidget("Image", this.getBuildParameters());
              this._imageWidget.setParentWidget(this);
              this._imageElement.appendChild(this._imageWidget.getElement());
            }
            this._imageWidget.setSrc(path);

            // fix for ie11, this browser is not able to auto resize an SVG
            if (window.browserInfo.isIE) {
              var width = null;
              if (path.startsWith("font:")) {
                width = this.getParentWidget().getRowHeight() + "px";
              }
              this.setStyle(" .gbc_ImageWidget", {
                "width": width
              });
            } // end ie11 fix

            this._imageWidget.getElement().removeClass("hidden");
            this._imageElement.removeClass("hidden");

          } else if (this._imageWidget) {
            this._imageElement.addClass("hidden");
          }
        },

        /**
         * Returns the number of line in the row
         * @returns {number} number of line in the row
         * @publicdoc
         */
        getLineCount: function() {
          if (this._horizontalLayout) {
            return Math.min(this.getChildren().length, 1);
          } else {
            return this.getChildren().length;
          }
        },

        /**
         * Sets if the row is the current one
         * @param {boolean} current - true if row is the current one, false otherwise
         * @publicdoc
         */
        setCurrent: function(current) {
          if (this._current !== current) {
            this._current = current;
            if (!!current) {
              this._element.addClass("currentRow");
            } else {
              this._element.removeClass("currentRow");
            }
          }
        },

        /**
         * @inheritDoc
         */
        isLayoutMeasureable: function(deep) {
          return true;
        }
      };
    });
    cls.WidgetFactory.registerBuilder('ListViewRow', cls.ListViewRowWidget);
  });
