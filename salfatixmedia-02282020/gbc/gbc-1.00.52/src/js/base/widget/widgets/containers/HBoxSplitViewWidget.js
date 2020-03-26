/// FOURJS_START_COPYRIGHT(D,2018)
/// Property of Four Js*
/// (c) Copyright Four Js 2018, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('HBoxSplitViewWidget', ['HBoxWidget', 'WidgetFactory'],
  /**
   * @param {gbc} context
   * @param {classes} cls
   */
  function(context, cls) {

    /**
     * HBoxSplitViewWidget widget is an advanced HBox widget. It can acts as a normal HBox or as SplitView
     * with each child group displayed full viewport
     * @class HBoxSplitViewWidget
     * @memberOf classes
     * @extends classes.FolderWidgetBase
     * @publicdoc Widgets
     */
    cls.HBoxSplitViewWidget = context.oo.Class(cls.HBoxWidget, function($super) {
      return /** @lends classes.HBoxSplitViewWidget.prototype */ {
        __name: "HBoxSplitViewWidget",

        /**
         * index of current hbox child group being visible.
         * @type {number}
         */
        _currentDisplayedGroupIndex: 0,
        /**
         * group display on restore vm focus handler
         * @type {Function}
         */
        _displayGroupActiveHandlers: null,
        /**
         * swipe event handler
         * @type {Function}
         */
        _swipeHandler: null,
        /**
         * screen size/orientation handler. Disable or enable SplitView mechanism depending of screen size
         * @type {Function}
         */
        _screenSizeHandler: null,
        /**
         * resize handler used in screen resize setTimeout
         * @type {Function}
         */
        _resizeHandle: null,
        /**
         * UserInterface widget of current HBoxSplitView
         * @type {classes.UserInterfaceWidget}
         */
        _uiWidget: null,

        /**
         * @inheritDoc
         */
        constructor: function(opts) {
          opts = opts || {};
          this._uiWidget = opts.uiWidget;
          $super.constructor.call(this, opts);
        },

        /**
         * @inheritDoc
         */
        _initContainerElement: function() {
          $super._initContainerElement.call(this);
          this._displayGroupActiveHandlers = [];
          // Listen to mobile orientation and disable/enable splitview mechanism if screen size condition is met
          this._screenSizeHandler = context.HostService.onScreenResize(function() {
            if (this._resizeHandle) {
              this._clearTimeout(this._resizeHandle);
            }
            this._resizeHandle = this._registerTimeout(this._initSplitView.bind(this), 100);
          }.bind(this));

          // disable/enable splitview mechanism if screen size condition is met
          this._initSplitView();
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          if (this._resizeHandle) {
            this._clearTimeout(this._resizeHandle);
            this._resizeHandle = null;
          }
          if (this._screenSizeHandler) {
            this._screenSizeHandler();
            this._screenSizeHandler = null;
          }
          this._uiWidget = null;
          this._releaseSplitViewHandlers();

          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          this._layoutInformation = new cls.LayoutInformation(this);
          // attach corresponding layout engine
          if (this.isSplitView()) {
            this._layoutEngine = new cls.SplitViewLayoutEngine(this);
            this._layoutInformation.getStretched().setDefaultX(true);
            this._layoutInformation.getStretched().setDefaultY(true);
          } else {
            this._layoutEngine = new cls.HBoxLayoutEngine(this);
            this._layoutInformation.getStretched().setDefaultX(false);
            this._layoutInformation.getStretched().setDefaultY(false);

          }
        },

        /**
         * @inheritDoc
         */
        addChildWidget: function(widget, options) {
          $super.addChildWidget.call(this, widget, options);
          if (this.isSplitView()) {
            if (widget instanceof cls.SplitterWidget) {
              widget.setHidden(true);
            } else {
              this._displayGroupActiveHandlers.push(widget.when(context.constants.widgetEvents.splitViewChanged, this._displayFocusedGroup
                .bind(this)));
            }
          }
        },

        /**
         * Check if HBox should split view
         * @returns {boolean}
         */
        isSplitView: function() {
          return window.innerWidth <= context.ThemeService.getValue("mt-responsive-screen-width-breakpoint");
        },

        /**
         * Initialise SplitView or HBox depending of splitview condition match
         * @private
         */
        _initSplitView: function() {
          this._resizeHandle = null;

          if (this.isSplitView()) {
            this._enableSplitView();
            this._isSplitView = true;
          } else {
            this._disableSplitView();
            this._isSplitView = false;
          }
        },

        /**
         * Transform normal HBox into a SplitView
         * @private
         */
        _enableSplitView: function() {
          if (!this._isSplitView) {

            this._displayGroupActiveHandlers.length = 0;

            // Update the layout engine and register children in it.
            var oldEngine = this._layoutEngine;
            this._layoutEngine = new cls.SplitViewLayoutEngine(this);
            for (var i = this.getChildren().length - 1; i >= 0; i--) {
              var child = this.getChildren()[i];
              if (child instanceof cls.SplitterWidget) { // hide splitter in splitview
                child.setHidden(true);
              } else { // each child group need to listen to focus to display. Mostly needed for folder pages.
                this._displayGroupActiveHandlers.push(child.when(context.constants.widgetEvents.splitViewChanged, this._displayFocusedGroup
                  .bind(this)));
              }
              oldEngine.unregisterChild(child);
              this._layoutEngine.registerChild(child);
            }
            // measures new layout
            context.SessionService.getCurrent().getCurrentApplication().layout.refreshLayout();

            // global listening to focus change
            if (this._uiWidget) {
              this._displayGroupActiveHandlers.push(this._uiWidget.when(context.constants
                .widgetEvents.splitViewChanged,
                this._displayFocusedGroup.bind(this)));
            }
            // add swipe mechanism
            this._swipeHandler = this._displayGroupByDirection.bind(this);

            this._containerElement.onSwipe("HBoxSplitViewWidget", this._swipeHandler, {
              direction: "all",
              velocity: 0.7
            });
            // display current focused widget group
            if (this.getUserInterfaceWidget()) {
              this._displayFocusedGroup();
            }
          }
        },

        /**
         * Transform a SplitView into an HBox
         * @private
         */
        _disableSplitView: function() {
          if (this._isSplitView) {
            // Update the layout engine and register children in it.
            var oldEngine = this._layoutEngine;
            this._layoutEngine = new cls.HBoxLayoutEngine(this);
            for (var i = this.getChildren().length - 1; i >= 0; i--) {
              var child = this.getChildren()[i];
              child.getLayoutInformation().getHostElement().removeClass("out_left").removeClass("out_right");
              if (child instanceof cls.SplitterWidget) {
                child.setHidden(false);
              }
              oldEngine.unregisterChild(child);
              this._layoutEngine.registerChild(child);
            }
            // relayout splitters
            this.initSplitterLayoutEngine();
            // measure new layout
            context.SessionService.getCurrent().getCurrentApplication().layout.refreshLayout();
            // destroy previous splitview handlers
            this._releaseSplitViewHandlers();
          }
        },

        /**
         * Delete splitview focus & swipe related listeners
         * @private
         */
        _releaseSplitViewHandlers: function() {
          if (this._swipeHandler) {
            this._containerElement.offSwipe("HBoxSplitViewWidget", "all");
            this._swipeHandler = null;
          }
          if (this._displayGroupActiveHandlers) {
            for (var i = 0; i < this._displayGroupActiveHandlers.length; i++) {
              this._displayGroupActiveHandlers[i]();
              this._displayGroupActiveHandlers[i] = null;
            }
            this._displayGroupActiveHandlers.length = 0;
          }
        },

        /**
         * Display parent group (hbox direct child boxelement) of the VM focused widget
         * @private
         */
        _displayFocusedGroup: function(data, caller, focusedWidget) {
          var newVmFocusWidget = focusedWidget ? focusedWidget : this.getUserInterfaceWidget().getVMFocusedWidget();
          if (newVmFocusWidget) {
            var i = 0;
            var child = null;
            // detect new focused element group position
            for (i = 0; i < this.getChildren().length; i++) {
              child = this.getChildren()[i];
              if (newVmFocusWidget === child || newVmFocusWidget.isChildOf(child)) {
                // manage left or right moving in animation
                this._currentDisplayedGroupIndex = i;
                break;
              }
            }

            // update other groups css class to position them to left or right of current group
            for (i = 0; i < this.getChildren().length; i++) {
              child = this.getChildren()[i];
              var boxElement = child.getLayoutInformation().getHostElement();
              if (i < this._currentDisplayedGroupIndex) { // left hidden groups
                if (!boxElement.hasClass("out_left")) {
                  boxElement.addClass("out_left");
                }
                if (boxElement.hasClass("out_right")) {
                  boxElement.removeClass("out_right");
                }
              } else if (i > this._currentDisplayedGroupIndex) { // right hidden groups
                if (!boxElement.hasClass("out_right")) {
                  boxElement.addClass("out_right");
                }
                if (boxElement.hasClass("out_left")) {
                  boxElement.removeClass("out_left");
                }
              }
            }

          }
          // Display current focused group or first group by default (if none focused)
          var groupToDisplay = this.getChildren()[this._currentDisplayedGroupIndex];
          if (groupToDisplay) {
            this._displayGroupElement(groupToDisplay.getLayoutInformation().getHostElement());
          }

        },

        /**
         * Display previous or next group depending of the swipe direction
         * @param {string} direction - direction of the swipe
         * @param {number} distance - distance of the swipe
         * @private
         */
        _displayGroupByDirection: function(direction, distance) {
          if (Math.abs(distance) > 100 && (direction === "left" || direction === "right")) {
            var newIndex = direction === "left" ? 1 : (direction === "right" ? -1 : 0);
            if (newIndex !== 0) {
              // find next or previous visible group
              var currentGroup = this.getChildren()[this._currentDisplayedGroupIndex];
              var newGroup = null;
              var index = this._currentDisplayedGroupIndex + newIndex;
              while ((newGroup = this.getChildren()[index]) && newGroup.isHidden()) {
                index += newIndex;
              }
              // display new group as a slide from right/left depending of current group related position
              if (newGroup && currentGroup) {
                this._currentDisplayedGroupIndex = index;
                if (!currentGroup.getLayoutInformation().getHostElement().hasClass("out_" + direction)) {
                  currentGroup.getLayoutInformation().getHostElement().addClass("out_" + direction);
                }
                this._displayGroupElement(newGroup.getLayoutInformation().getHostElement());
                return true;
              }
            }
          }
          return false;
        },

        /**
         * Display group element passed as parameter
         * @param {Element} group - box element
         * @private
         */
        _displayGroupElement: function(groupElement) {
          if (groupElement.hasClass("out_left")) {
            groupElement.removeClass("out_left");
          }
          if (groupElement.hasClass("out_right")) {
            groupElement.removeClass("out_right");
          }
        }
      };
    });
    cls.WidgetFactory.registerBuilder("HBoxSplitView", cls.HBoxSplitViewWidget);
  });
