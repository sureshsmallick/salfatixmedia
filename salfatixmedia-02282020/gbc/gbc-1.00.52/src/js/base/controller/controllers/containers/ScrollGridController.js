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

modulum('ScrollGridController', ['ControllerBase', 'ControllerFactory'],
  function(context, cls) {
    /**
     * @class ScrollGridController
     * @memberOf classes
     * @extends classes.ControllerBase
     */
    cls.ScrollGridController = context.oo.Class(cls.ControllerBase, function($super) {
      return /** @lends classes.ScrollGridController.prototype */ {
        __name: "ScrollGridController",
        /** @type {?classes.ScrollGridLineController[]} */
        _lineControllers: null,
        /** @type {?boolean} */
        _isPagedScrollGrid: null,
        /** @type {number} */
        _currentRow: -1,

        /**
         * @inheritDoc
         */
        _initBehaviors: function() {
          $super._initBehaviors.call(this);

          var isStretchable = this.getAnchorNode().attribute("wantFixedPageSize") === 0;
          this.nativeVerticalScroll = isStretchable;

          if (isStretchable) {
            this._lineControllers = [];
          }

          // These behaviors should stay added at first
          // WARNING : DO NOT ADD BEHAVIORS BEFORE
          this._addBehavior(cls.LayoutInfoVMBehavior);
          // END WARNING

          // pseudo-selector behaviors
          this._addBehavior(cls.ActivePseudoSelectorBehavior);

          // vm behaviors
          this._addBehavior(cls.StyleVMBehavior);
          this._addBehavior(cls.EnabledVMBehavior);
          this._addBehavior(cls.HiddenVMBehavior);
          this._addBehavior(cls.BackgroundColorVMBehavior);
          this._addBehavior(cls.FontFamilyVMBehavior);
          if (isStretchable) {
            this._addBehavior(cls.NativeScrollVMBehavior);
            this._addBehavior(cls.StretchableScrollGridPageSizeVMBehavior);
          } else {
            this._addBehavior(cls.ScrollVMBehavior);
          }

          // 4st behaviors
          this._addBehavior(cls.Border4STBehavior);
          this._addBehavior(cls.Reverse4STBehavior);
          this._addBehavior(cls.RowActionTrigger4STBehavior);
          this._addBehavior(cls.Highlight4STBehavior);

          //ui behaviors
          this._addBehavior(cls.RowActionUIBehavior);
          if (this.isPagedScrollGrid()) {
            this._addBehavior(cls.OnLayoutPagedUIBehavior);
            this._addBehavior(cls.ScrollOffsetUIBehavior);
          } else {
            this._addBehavior(cls.ScrollUIBehavior);
            if (isStretchable) {
              this._addBehavior(cls.OnLayoutUIBehavior);
            }
          }
        },

        /**
         * @inheritDoc
         */
        _createWidget: function(type) {
          var uiWidget = this.getUINode().getController().getWidget();
          var wantFixedPageSize = this.getAnchorNode().attribute("wantFixedPageSize") !== 0;
          var widgetKind = wantFixedPageSize ? 'ScrollGrid' : 'StretchableScrollGrid';

          return cls.WidgetFactory.createWidget(widgetKind, {
            appHash: this.getAnchorNode().getApplication().applicationHash,
            auiTag: this.getAnchorNode().getId(),
            uiWidget: uiWidget
          }, this.getAnchorNode());
        },

        /**
         * Sends the updated value to the DVM
         * @private
         */
        sendWidgetValue: function() {
          var ui = this.getUINode();
          var focusedNode = ui.getApplication().getNode(ui.attribute('focus'));
          var focusedWidgetController = focusedNode.getController();
          if (focusedWidgetController.sendWidgetValue) {
            focusedWidgetController.sendWidgetValue();
          }
        },

        /**
         * Add a ScrollGrid line controller
         * @param {classes.ScrollGridLineController} lineController
         */
        pushLineController: function(lineController) {
          this._lineControllers.push(lineController);
        },

        /**
         * Removes the last ScrollGrid line controller
         * @returns {classes.ScrollGridLineController}
         */
        popLineController: function() {
          return this._lineControllers.pop();
        },

        /**
         * @param {number} index index of the line controller
         * @returns {classes.ScrollGridLineController} the line controller
         */
        getLineController: function(index) {
          return this._lineControllers[index];
        },

        /**
         * @returns {number} the number of line controllers
         */
        getLineControllersCount: function() {
          return this._lineControllers.length;
        },

        /**
         * @param {number} currentRow the new current row
         */
        setCurrentRow: function(currentRow) {
          this._currentRow = currentRow;
        },

        /**
         * @returns {number} the current row
         */
        getCurrentRow: function() {
          return this._currentRow;
        },

        /**
         * @return {boolean} true if this is a paged ScrollGrid
         */
        isPagedScrollGrid: function() {
          if (this._isPagedScrollGrid === null && this.getAnchorNode()) {
            var anchorNode = this.getAnchorNode();
            this._isPagedScrollGrid = anchorNode._initialStyleAttributes.customWidget === "pagedScrollGrid" && anchorNode.attribute(
              "wantFixedPageSize") === 0;
          }
          return this._isPagedScrollGrid;
        },

        /**
         * @inheritDoc
         */
        ensureVisible: function(executeAction) {
          var widget = this.getAnchorNode().getWidget();
          widget.emit(context.constants.widgetEvents.splitViewChanged, widget);
          return $super.ensureVisible.call(this, executeAction);
        }
      };
    });
    cls.ControllerFactory.register("ScrollGrid", cls.ScrollGridController);

  });
