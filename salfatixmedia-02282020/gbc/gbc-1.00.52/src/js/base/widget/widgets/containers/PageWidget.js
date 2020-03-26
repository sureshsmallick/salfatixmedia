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

modulum('PageWidget', ['WidgetGroupBase'],
  function(context, cls) {

    /**
     * Page widget.
     * @class PageWidget
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     * @publicdoc Widgets
     */
    cls.PageWidget = context.oo.Class(cls.WidgetGroupBase, function($super) {
      return /** @lends classes.PageWidget.prototype */ {
        __name: "PageWidget",

        /**
         * the title widget
         * @type {classes.PageTitleWidget}
         */
        _title: null,
        _clickHandler: null,
        _onActivationHandler: null,
        _pageActivateHandler: null,
        _pageDisableHandler: null,

        /**
         * @inheritDoc
         */
        _initElement: function() {
          $super._initElement.call(this);
          this._title = cls.WidgetFactory.createWidget("PageTitle", this.getBuildParameters());
          this._clickHandler = this._title.when(context.constants.widgetEvents.click, function(event) {
            this.emit(context.constants.widgetEvents.click);
          }.bind(this));
          this._onActivationHandler = this.when(context.constants.widgetEvents.ready, this._onActivation.bind(this));
          this.setAriaAttribute("labelledby", this._title.getRootClassName());
        },
        /**
         * @inheritDoc
         */
        _initLayout: function() {
          this._layoutInformation = new cls.LayoutInformation(this);
          this._layoutEngine = new cls.PageLayoutEngine(this);
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          if (this._pageActivateHandler) {
            this._pageActivateHandler();
            this._pageActivateHandler = null;
          }
          if (this._pageDisableHandler) {
            this._pageDisableHandler();
            this._pageDisableHandler = null;
          }
          if (this._onActivationHandler) {
            this._onActivationHandler();
            this._onActivationHandler = null;
          }
          if (this._clickHandler) {
            this._clickHandler();
          }
          this._title.destroy();
          this._title = null;

          $super.destroy.call(this);
        },

        activate: function() {
          this.emit(context.constants.widgetEvents.activate);
        },

        onActivate: function(hook) {
          return this.when(context.constants.widgetEvents.activate, hook);
        },

        disable: function() {
          this.emit(context.constants.widgetEvents.disable);
        },

        onDisable: function(hook) {
          return this.when(context.constants.widgetEvents.disable, hook);
        },

        _onActivation: function(event, widget, parentPageWidget) {
          if (parentPageWidget) {
            this._pageActivateHandler = parentPageWidget.onActivate(this.activate.bind(this));
            this._pageDisableHandler = parentPageWidget.onDisable(this.disable.bind(this));
          }
        },

        /**
         * Returns index of the pager in the parent folder
         * @returns {number} index of the page in the folder
         */
        getPageIndex: function() {
          var parent = this.getParentWidget();
          if (!!parent) {
            return parent.getChildren().indexOf(this);
          }
          return -1;
        },

        /**
         * @returns {classes.PageTitleWidget} the title widget
         */
        getTitleWidget: function() {
          return this._title;
        },

        /**
         * @inheritDoc
         */
        addChildWidget: function(widget, options) {
          if (this._children.length !== 0) {
            throw "A page can only contain a single child";
          }
          $super.addChildWidget.call(this, widget, options);
        },

        /**
         * @param {string} text the text to display in the header
         */
        setText: function(text) {
          this._title.setText(text);
        },

        /**
         * @returns {string} the text to display in the header
         */
        getText: function() {
          return this._title.getText();
        },

        /**
         * @param {string} image the URL of the image or a font-image URL: font:[fontname]:[character]:[color] to display in the header
         */
        setImage: function(image) {
          this._title.setImage(image);
        },

        /**
         * @returns {string} the URL of the displayed image or a font-image URL: font:[fontname]:[character]:[color]
         */
        getImage: function() {
          return this._title.getImage();
        },
        /**
         * @inheritDoc
         */
        setHidden: function(hidden) {
          if (this._hidden !== hidden) {
            this.getParentWidget().emit(context.constants.widgetEvents.pageVisibility);
          }

          $super.setHidden.call(this, hidden);

          this._title.setHidden(hidden);
          // if current is hidden, we need to display another one
          if (this.getParentWidget().getCurrentPage() === this && this.isHidden()) {
            // if focused node is inside a folder page, display that one otherwise display next not hidden page.
            this.getParentWidget().updateCurrentPage();
          }

        },
        /**
         * @inheritDoc
         */
        isVisible: function() {
          return this.getParentWidget().getCurrentPage() === this && !this.isHidden();
        },
        /**
         * @inheritDoc
         */
        isLayoutMeasureable: function(deep) {
          return true;
        }
      };
    });
    cls.WidgetFactory.registerBuilder('Page', cls.PageWidget);
  });
