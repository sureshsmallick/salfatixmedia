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

modulum('PagedScrollGridWidget', ['WidgetGroupBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * Paged Scroll Grid widget to display Scroll grid with tiles
     * @class PagedScrollGridWidget
     * @memberOf classes
     * @extends classes.WidgetGroupBase
     * @publicdoc
     */
    cls.PagedScrollGridWidget = context.oo.Class(cls.WidgetGroupBase, function($super) {

      return /** @lends classes.PagedScrollGridWidget.prototype */ {
        __name: "PagedScrollGridWidget",
        _rowActionTriggerByDoubleClick: true,
        _currentRow: 0,
        _focusOnField: false,

        /** styles */
        _highlightColor: null,
        _highlightTextColor: null,
        _highlightCurrentRow: null,
        _highlightCurrentRowCssSelector: ":not(.disabled) .gbc_PagedScrollGridWidget.highlight.currentRow",
        _highlightCurrentCellCssSelector: ":not(.disabled) .gbc_PagedScrollGridWidget .g_GridElement >.currentRow",
        _highlightCurrentCell: null,

        _paginationWidget: null,
        _onOffsetHandler: null,

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          $super._initLayout.call(this);
          this._layoutEngine = new cls.StretchableScrollLayoutEngine(this);
          this._layoutInformation.getStretched().setDefaultX(true);
          this._layoutInformation.getStretched().setDefaultY(true);
        },

        /**
         * @inheritDoc
         */
        _initElement: function() {
          $super._initElement.call(this);
          this._paginationWidget = cls.WidgetFactory.createWidget("Pagination", this.getBuildParameters());
          // Forward scroll events
          this._onOffsetHandler = this._paginationWidget.when(context.constants.widgetEvents.offset, function(event) {
            this.emit(context.constants.widgetEvents.offset, event.data[0]);
          }.bind(this));
          this._element.appendChild(this._paginationWidget.getElement());
        },

        /**
         * @inheritDoc
         */
        destroy: function() {
          if (this._onOffsetHandler) {
            this._onOffsetHandler();
            this._onOffsetHandler = null;
          }
          this._paginationWidget.destroy();
          this._paginationWidget = null;

          this.destroyChildren();
          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        manageMouseClick: function(domEvent) {
          if (domEvent.target.isElementOrChildOf(this._containerElement)) {
            cls.ScrollGridWidget._onClick.call(this, domEvent);
          }
          return true;
        },

        /**
         * @inheritDoc
         */
        manageMouseDblClick: function(domEvent) {
          if (domEvent.target.isElementOrChildOf(this._containerElement)) {
            cls.ScrollGridWidget._onDblClick.call(this, domEvent);
          }
          return true;
        },

        /**
         * @inheritDoc
         */
        addChildWidget: function(widget, options) {
          $super.addChildWidget.call(this, widget, options);
          widget.removeClass("gbc_WidgetBase_standalone");
          widget.addClass("gbc_WidgetBase_in_array");
        },

        /**
         * Indicates  how the row action must be triggered.
         * @param {boolean} b - true if must be triggered by doubleClick, false otherwise
         */
        setRowActionTriggerByDoubleClick: function(b) {
          this._rowActionTriggerByDoubleClick = b;
        },

        /**
         * Defines if focus is on a field or (default) on a row
         * @param {boolean} focusOnField - true if focus on field activated
         */
        setFocusOnField: function(focusOnField) {
          if (this._focusOnField !== focusOnField) {
            this._focusOnField = focusOnField;
            this.updateHighlight();
          }
        },

        /**
         * Returns if focus is on a field (table item) (by default focus is on a row)
         * @returns {boolean} true if focus on field activated
         */
        hasFocusOnField: function() {
          return this._focusOnField;
        },

        /**
         * Get the Data area height
         * @returns {number} scroll data area width
         */
        getDataAreaWidth: function() {
          return this.getContainerElement().getBoundingClientRect().width;
        },

        /**
         * Get the Data area height
         * @returns {number} scroll data area height
         */
        getDataAreaHeight: function() {
          return this.getContainerElement().getBoundingClientRect().height;
        },

        /**
         * Get the width of a Row
         * @return {number} row width or 1;
         */
        getRowWidth: function() {
          var children = this.getChildren();
          if (children.length !== 0) {
            return children[0].getElement().getBoundingClientRect().width;
          }
          return 0;
        },

        /**
         * Get the height of a Row
         * @return {number} row height or 1;
         */
        getRowHeight: function() {
          var children = this.getChildren();
          if (children.length !== 0) {
            return children[0].getElement().getBoundingClientRect().height;
          }
          return 0;
        },

        /**
         * @param {number} size - size of the dataset
         * @param {number} pageSize - viewport size
         * @param {number} offset - viewport offset
         */
        updateContentPosition: function(size, pageSize, offset) {
          this._paginationWidget.updateContentPosition(size, pageSize, offset);
        },

        /**
         * Changes current row
         * @param {number} row - current row
         * @publicdoc
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
         * Returns current row
         * @returns {number} current row
         * @publicdoc
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
         * Defines the highlighted text color of current row
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
         * @param {boolean} b - true if must be highlighted
         */
        setHighlightCurrentRow: function(b) {
          this._highlightCurrentRow = b;
        },

        /**
         * Check if the current row is highlighted
         * @returns {?boolean} true if current row is highlighted
         */
        isHighlightCurrentRow: function() {
          return this._highlightCurrentRow;
        },

        /**
         * Indicates if the current cell must be highlighted
         * @param {boolean} b - true if it must be highlighted
         */
        setHighlightCurrentCell: function(b) {
          this._highlightCurrentCell = b;
        },

        /**
         * Check if the current cell is highlighted
         * @returns {?boolean} true if current cell is highlighted
         */
        isHighlightCurrentCell: function() {
          return this._highlightCurrentCell;
        },

        /**
         * Update highlight row and cell
         */
        updateHighlight: function() {
          this.setCurrentRow(this._currentRow);
        },

        /**
         * @return {classes.PaginationWidget} the pagination widget
         */
        getPaginationWidget: function() {
          return this._paginationWidget;
        }
      };
    });
    cls.WidgetFactory.registerBuilder('ScrollGrid[customWidget=pagedScrollGrid]', cls.PagedScrollGridWidget);
    cls.WidgetFactory.registerBuilder('StretchableScrollGrid[customWidget=pagedScrollGrid]', cls.PagedScrollGridWidget);
  });
