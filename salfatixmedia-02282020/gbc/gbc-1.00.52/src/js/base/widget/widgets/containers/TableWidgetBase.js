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

modulum('TableWidgetBase', ['WidgetGroupBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * TableWidgetBase widget (abstract class for TableWidget & ListViewWidget).
     * @class TableWidgetBase
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     * @publicdoc
     */
    cls.TableWidgetBase = context.oo.Class(cls.WidgetGroupBase, function($super) {
      return /** @lends classes.TableWidgetBase.prototype */ {
        __name: "TableWidgetBase",

        /** @type {boolean} */
        __virtual: true,

        /** @type {number} */
        _currentRow: 0,
        /** @type {number} */
        _size: 0,
        /** @type {number} */
        _offset: 0,
        /** @type {number} */
        _pageSize: 0,
        /** @type {?number} */
        _firstPageSize: null,
        /** @type {boolean} */
        _fixedPageSize: false,
        /** @type {number} */
        _visibleRows: 0,

        /** @type {boolean} */
        _inputMode: false,
        /** @type {number} */
        _rowHeight: 0,

        /** @type {?string} */
        _highlightColor: null,
        /** @type {?string} */
        _highlightTextColor: null,
        /** @type {?boolean} */
        _highlightCurrentRow: null,
        /** @type {boolean} */
        _isPageVisible: true,
        /** @type {classes.FolderWidgetBase} */
        _folderPageWidget: null,

        /** @function */
        _uiActivateHandler: null,

        /** @type {HTMLElement} */
        _scrollAreaElement: null,

        /**
         * @constructs
         * @param {*} opts - Options passed to the constructor
         */
        constructor: function(opts) {
          opts = opts || {};
          this._uiWidget = opts.uiWidget;
          this._folderPageWidget = opts.folderPageWidget;

          this._isPageVisible = !this._folderPageWidget || (!!this._folderPageWidget.getParentWidget() && this._folderPageWidget.getParentWidget()
            .getCurrentPage() === this._folderPageWidget);

          $super.constructor.call(this, opts);
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          this._isPageVisible = false;
          if (this._uiActivateHandler) {
            this._uiActivateHandler();
            this._uiActivateHandler = null;
          }

          this._folderPageWidget = null;

          this._scrollAreaElement = null;

          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        _initElement: function() {
          $super._initElement.call(this);
          this.setFocusable(true);

          this._uiActivateHandler = this._uiWidget.onActivate(this.updateVerticalScroll.bind(this, true));
        },

        /**
         * @inheritDoc
         */
        resetLayout: function() {
          $super.resetLayout.call(this);
          this._rowHeight = 0;
        },

        /**
         * Set the DOM focus to the widget
         * @param {boolean} [fromMouse] - true if focus comes from mouse event
         * @publicdoc
         */
        domFocus: function(fromMouse) {
          var focusAndScroll = !fromMouse;
          if (focusAndScroll) {
            this._element.domFocus();
          } else {
            // try to not scroll when focus
            this._element.domFocus(null, this.getFormWidget().getContainerElement());
          }
        },

        /**
         * Change current row
         * @param {number} row - new current row
         * @param {boolean} [ensureRowVisible] - if true scroll to be sure row is visible (useful when first row is partially visible)
         */
        setCurrentRow: function(row, ensureRowVisible) {
          // TO BE IMPLEMENTED
        },

        /** Returns current row
         * @returns {number} current row
         * @publicdoc
         */
        getCurrentRow: function() {
          return this._currentRow;
        },

        /**
         * Defines the table pageSize
         * @param {number} pageSize - page size
         */
        setPageSize: function(pageSize) {
          this._setFirstPageSize(pageSize);
          this._pageSize = pageSize;
        },

        /**
         * Keep the first pageSize
         * @param {number} pageSize - page size
         */
        _setFirstPageSize: function(pageSize) {
          if (this._firstPageSize === null) {
            this._firstPageSize = pageSize;
          }
        },

        /**
         * Returns page size
         * @returns {?number} the page size
         * @publicdoc
         */
        getPageSize: function() {
          return this._pageSize;
        },

        /**
         * Defines if pageSize is fixed
         * @param {boolean} fixed - true if page size is fixed
         */
        setFixedPageSize: function(fixed) {
          if (this._fixedPageSize !== fixed) {
            this._fixedPageSize = fixed;
            this._layoutInformation.getStretched().setDefaultY(true);
          }
        },

        /**
         * Returns if pageSize is fixed
         * @returns {boolean} true if pageSize is fixed
         * @publicdoc
         */
        isFixedPageSize: function() {
          return this._fixedPageSize;
        },

        /**
         * Returns table size
         * @returns {number} the table size
         * @publicdoc
         */
        getSize: function() {
          return this._size;
        },

        /**
         * Defines the table size (total number of row)
         * @param {number} size - size value
         */
        setSize: function(size) {
          this._size = size;
        },

        /**
         * Defines the table offset
         * @param {number} offset - offset value
         */
        setOffset: function(offset) {
          this._offset = offset;
        },

        /**
         * Returns table offset
         * @returns {number} the table offset
         * @publicdoc
         */
        getOffset: function() {
          return this._offset;
        },

        /**
         * Sets the number of visible rows
         * @param {number} visibleRows - number of visible rows
         */
        setVisibleRows: function(visibleRows) {
          this._visibleRows = visibleRows;
        },

        /**
         * Returns number of visible rows
         * @returns {number} the number of visible rows
         */
        getVisibleRows: function() {
          return this._visibleRows;
        },

        /**
         * Sets if table is in "input" mode.
         * @param {boolean} b - input mode
         * @publicdoc
         */
        setInputMode: function(b) {
          if (this._inputMode !== b) {
            this._inputMode = b;
            this._element.toggleClass("inputMode", !!b);
          }
        },

        /**
         * Returns if table is in input mode.
         * @returns {boolean} true if input mode
         * @publicdoc
         */
        isInputMode: function() {
          return this._inputMode;
        },

        /**
         * Returns if table is in display mode.
         * @returns {boolean} true if display mode
         * @publicdoc
         */
        isDisplayMode: function() {
          return !this._inputMode;
        },

        /**
         * Sets the height of rows
         * @param {number} height - row height (pixels)
         * @publicdoc
         */
        setRowHeight: function(height) {
          this._rowHeight = height;
        },

        /**
         * Returns the row height in pixels
         * @returns {number} row height
         * @publicdoc
         */
        getRowHeight: function() {
          return this._rowHeight;
        },

        /**
         * Call when a widget in the table request the focus
         * @param {classes.WidgetBase} widget - widget that request focus
         * @param {Object} event - event that request focus
         */
        requestFocusFromWidget: function(widget, event) {
          widget.emit(context.constants.widgetEvents.requestFocus, event);
        },

        /**
         * @returns {number} table data area height
         */
        getDataAreaHeight: function() {
          return this.getLayoutInformation().getAllocated().getHeight() - this.getLayoutInformation().getDecorating().getHeight();
        },

        /**
         * @returns {number} table data area width
         */
        getDataAreaWidth: function() {
          return this.getLayoutInformation().getAllocated().getWidth() - this.getLayoutInformation().getDecorating().getWidth();
        },

        /**
         * Defines the highlight color of rows for the table
         * @param {string} color - CSS color
         */
        setHighlightColor: function(color) {
          // TO BE IMPLEMENTED
        },

        /**
         * Defines the highlighted text color of rows for the table
         * @param {string} color - CSS color
         */
        setHighlightTextColor: function(color) {
          // TO BE IMPLEMENTED
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
         * Update vertical scroll
         * @param {boolean} [forceScroll] - true to force scrolling
         */
        updateVerticalScroll: function(forceScroll) {
          this.updateContentPosition(this._size, this._pageSize, this._offset, forceScroll);
        },

        /**
         * Sets vertical scroll parameters
         * BEWARE this code should be the same as ScrollGridWidget::updateContentPosition
         * @param {?number} size
         * @param {?number} pageSize
         * @param {?number} offset
         * @param {boolean} forceScroll
         */
        updateContentPosition: function(size, pageSize, offset, forceScroll) {
          // TO BE IMPLEMENTED
        },

        /**
         * Returns scrollable area DOM Element
         * @returns {HTMLElement} scrollable area DOM Element
         */
        getScrollableArea: function() {
          // TO BE IMPLEMENTED
        }

      };
    });
  });
