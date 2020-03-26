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

modulum('StretchableScrollGridWidget', ['WidgetGroupBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * Stretchable scroll grid widget.
     * @class StretchableScrollGridWidget
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     * @publicdoc
     */
    cls.StretchableScrollGridWidget = context.oo.Class(cls.WidgetGroupBase, function($super) {

      return /** @lends classes.StretchableScrollGridWidget.prototype */ {
        __name: "StretchableScrollGridWidget",
        /** @type {?number} */
        _pageSize: null,
        /** @type {?number} */
        _size: null,
        /** @type {?number} */
        _offset: null,
        /** @type {?number} */
        lastSentOffset: null,
        /** @type {boolean} */
        _rowActionTriggerByDoubleClick: true,
        /** @type {number} */
        _rowHeight: 0,
        /** @type {number} */
        _currentRow: 0,
        /** @type {boolean} */
        _focusOnField: false,

        /** Handlers */
        _uiActivateHandler: null,

        /** styles */
        _highlightColor: null,
        _highlightTextColor: null,
        _highlightCurrentRow: null,
        _highlightCurrentRowCssSelector: ":not(.disabled) .gbc_StretchableScrollGridLineWidget.highlight.currentRow",
        _highlightCurrentCellCssSelector: ":not(.disabled) .gbc_StretchableScrollGridLineWidget .g_GridElement >.currentRow",
        _highlightCurrentCell: null,

        /**
         * @constructs
         * @param {*} opts - Options passed to the constructor
         */
        constructor: function(opts) {
          opts = opts || {};
          this._uiWidget = opts.uiWidget;
          $super.constructor.call(this, opts);
        },

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          this._layoutInformation = new cls.LayoutInformation(this);
          this._layoutEngine = new cls.StretchableScrollLayoutEngine(this);
          this._layoutInformation.getStretched().setDefaultX(true);
          this._layoutInformation.getStretched().setDefaultY(true);
        },

        /**
         * @inheritDoc
         */
        _initElement: function() {
          $super._initElement.call(this);

          this._element.on('scroll.StretchableScrollGridWidget', function(event) {
            this.emit(context.constants.widgetEvents.scroll, event, this.getRowHeight());
          }.bind(this));
          this._uiActivateHandler = this._uiWidget.onActivate(this.updateVerticalScroll.bind(this, true));
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          if (this._uiActivateHandler) {
            this._uiActivateHandler();
            this._uiActivateHandler = null;
          }

          this._element.off('scroll.StretchableScrollGridWidget');

          this.destroyChildren();
          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        manageMouseClick: function(domEvent) {
          cls.ScrollGridWidget._onClick.call(this, domEvent);
          return true;
        },

        /**
         * @inheritDoc
         */
        manageMouseDblClick: function(domEvent) {
          cls.ScrollGridWidget._onDblClick.call(this, domEvent);
          return true;
        },

        /**
         * Indicates how the row action must be triggered.
         * @param {boolean} b - true if action is triggered by double click (else it is single click)
         */
        setRowActionTriggerByDoubleClick: function(b) {
          this._rowActionTriggerByDoubleClick = b;
        },

        /**
         * Defines if focus in on a field or (default) on a row
         * @param {boolean} focusOnField - true if focus on field activated
         */
        setFocusOnField: function(focusOnField) {
          if (this._focusOnField !== focusOnField) {
            this._focusOnField = focusOnField;
            this.updateHighlight();
          }
        },

        /**
         * Returns if focus is on a field (by default focus is on a row)
         * @returns {boolean} true if focus on field activated
         */
        hasFocusOnField: function() {
          return this._focusOnField;
        },

        /**
         * @returns {number} scroll grid data area height
         */
        getDataAreaHeight: function() {
          return this.getLayoutInformation().getAvailable().getHeight();
        },

        /**
         * Returns scrollable area DOM Element
         * @returns {HTMLElement} scrollable area DOM Element
         */
        getScrollableArea: function() {
          return this.getElement();
        },

        /**
         * Returns the row height in pixels
         * @returns {number} row height
         * @publicdoc
         */
        getRowHeight: function() {
          if (this._rowHeight === 0 && this.getChildren().length !== 0) {
            this._rowHeight = this.getChildren()[0]._element.getBoundingClientRect().height;
          }
          return this._rowHeight;
        },

        /**
         * Defines the scroll grid pageSize
         * @param {number} pageSize - page size
         */
        setPageSize: function(pageSize) {
          this._pageSize = pageSize;
        },

        /**
         * Defines the scroll grid size (total number of row)
         * @param {number} size - size value
         */
        setSize: function(size) {
          this._size = size;
        },

        /**
         * Defines the scroll grid offset
         * @param {number} offset - offset value
         */
        setOffset: function(offset) {
          this._offset = offset;
        },

        /**
         * Update vertical scroll
         * @param {boolean} forceScroll - true to force scrolling
         */
        updateVerticalScroll: function(forceScroll) {
          this.updateContentPosition(this._size, this._pageSize, this._offset, forceScroll);
        },

        /**
         * Sets vertical scroll parameters
         * BEWARE this code should be the same as TableWidget::updateContentPosition
         * @param {?number} size
         * @param {?number} pageSize
         * @param {?number} offset
         * @param {boolean} forceScroll
         */
        updateContentPosition: function(size, pageSize, offset, forceScroll) {
          this.setSize(size);
          this._pageSize = pageSize;

          var top = offset * this.getRowHeight();
          var height = (size - offset) * this.getRowHeight();

          this.setStyle("> .containerElement", {
            "margin-top": top + "px",
            "height": height + "px"
          });

          if (!!forceScroll || (this.lastSentOffset === null || this.lastSentOffset === offset) && offset !== this._offset) {
            this._offset = offset;
            // need to do this because to scroll we need to wait the style "height" set just before is really applied in the dom
            this._registerAnimationFrame(function() {
              this.getScrollableArea().scrollTop = top;
            }.bind(this));
          }

          this.lastSentOffset = null;
        },

        /**
         * Change current row
         * @param {number} row - new current row
         */
        setCurrentRow: function(row) {
          this._currentRow = row;
          var children = this.getChildren();
          var length = children.length;
          for (var i = 0; i < length; ++i) {
            var rowWidget = children[i];
            rowWidget.setCurrent(i === row);
          }
        },

        /**
         * @returns {number} the current row
         */
        getCurrentRow: function() {
          return this._currentRow;
        },

        /**
         * Defines the highlight color of rows, used for selected rows
         * @param {string} color - CSS color
         */
        setHighlightColor: function(color) {

          if (this._highlightColor !== color) {
            this._highlightColor = color;

            color = (color === null ? null : color + " !important");
            this.setStyle({
              selector: this._highlightCurrentRowCssSelector,
              appliesOnRoot: true
            }, {
              "background-color": color
            });

            this.setStyle({
              selector: this._highlightCurrentCellCssSelector,
              appliesOnRoot: true
            }, {
              "background-color": color
            });
          }
        },

        /**
         * Defines the highlighted text color of rows, used for selected rows
         * @param {string} color - CSS color
         */
        setHighlightTextColor: function(color) {

          if (this._highlightTextColor !== color) {
            this._highlightTextColor = color;

            color = (color === null ? null : color + " !important");
            this.setStyle({
              selector: this._highlightCurrentCellCssSelector,
              appliesOnRoot: true
            }, {
              "color": color,
              "fill": color
            });
          }
        },

        /**
         * Indicates if the current row must be highlighted
         * @param {boolean} b - true if current row must be highlighted
         */
        setHighlightCurrentRow: function(b) {
          this._highlightCurrentRow = b;
        },

        /**
         * Return if the current row must be highlighted
         * @returns {?boolean} true if current row must be highlighted
         * @publicdoc
         */
        isHighlightCurrentRow: function() {
          return this._highlightCurrentRow;
        },

        /**
         * Indicates if the current cell must be highlighted
         * @param {boolean} b - true if current cell must be highlighted
         */
        setHighlightCurrentCell: function(b) {
          this._highlightCurrentCell = b;
        },

        /**
         * Return if the current cell must be highlighted
         * @returns {?boolean} true if current cell must be highlighted
         * @publicdoc
         */
        isHighlightCurrentCell: function() {
          return this._highlightCurrentCell;
        },

        /**
         * Update highlight row and cell
         */
        updateHighlight: function() {
          this.setCurrentRow(this._currentRow);
        }

      };
    });
    cls.WidgetFactory.registerBuilder('StretchableScrollGrid', cls.StretchableScrollGridWidget);
  });
