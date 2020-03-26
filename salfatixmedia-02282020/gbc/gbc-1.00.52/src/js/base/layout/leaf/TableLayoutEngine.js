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

modulum('TableLayoutEngine', ['TableLayoutEngineBase'],
  function(context, cls) {
    /**
     * @class TableLayoutEngine
     * @memberOf classes
     * @extends classes.TableLayoutEngineBase
     */
    cls.TableLayoutEngine = context.oo.Class(cls.TableLayoutEngineBase, function($super) {
      return /** @lends classes.TableLayoutEngine.prototype */ {
        __name: "TableLayoutEngine",

        /**
         * @inheritDoc
         */
        reset: function(recursive) {
          $super.reset.call(this, recursive);
          if (this._widget) {
            var columns = this._widget.getColumns(),
              len = columns && columns.length || 0,
              i = 0;
            // reset layout of each columns
            for (; i < len; i++) {
              columns[i].resetLayout();
            }
          }
        },

        /**
         * @inheritDoc
         */
        prepareMeasure: function() {
          $super.prepareMeasure.call(this);

          // Need to call prepareMeasure on each first item of all columns
          // because we measure the first items to define the rowHeight
          var columns = this._widget.getColumns();
          for (var i = 0; i < columns.length; i++) {
            var columnWidget = columns[i];
            if (!columnWidget._firstWidgetPreparedMeasure) {
              var columnItemWidget = columnWidget.getChildren()[0];
              if (columnItemWidget) {
                var widget = columnItemWidget.getChildren()[0];
                if (widget) {
                  widget._layoutEngine.prepareMeasure();
                  columnWidget._firstWidgetPreparedMeasure = true;
                }
              }
            }
          }
        },

        /**
         * @inheritDoc
         */
        measure: function() {
          $super.measure.call(this);
          var layoutInfo = this._widget.getLayoutInformation();

          // For each columns, measureSize to compute table width and rowHeight
          var columns = this._widget.getColumns(),
            len = columns.length,
            i, perVisibleColumn = [];
          var computePreferredWidth = 0;
          for (i = 0; i < len; i++) {
            var columnWidget = columns[i];

            // Measure width/height of first item of the column
            // and set column width and table row height
            columnWidget.measureSize();

            if (!columnWidget.isHidden()) {
              perVisibleColumn.push(columnWidget.getWidth());
              computePreferredWidth += columnWidget.getWidth();
            }
          }

          // Compute preferred size
          if (!this._initialPreferredSize) {
            this._initialPreferredSize = true;
            var rowHeight = this._widget.getRowHeight();
            var sizeHint = layoutInfo.getSizeHint();
            if (!sizeHint.getWidth()) {
              layoutInfo.getPreferred().setWidth(Math.round(computePreferredWidth));
            } else if (cls.Size.isCols(sizeHint.getWidth())) {
              var count = parseInt(sizeHint.getWidth(), 10),
                colsLen = perVisibleColumn.slice(0, count).reduce(function(pv, cv) {
                  return pv + cv;
                }, 0);
              layoutInfo.getPreferred().setWidth(Math.round(colsLen));
            }
            if (!!sizeHint.getHeight()) {
              // translate height into number of rows
              var preferredPageSize = Math.max(this._translateHeight(sizeHint.getHeight(), layoutInfo.getCharSize().getHeight(),
                rowHeight), 1);
              this._widget._firstPageSize = preferredPageSize;
            }
            var h = this._widget._firstPageSize ? this._widget._firstPageSize * rowHeight : 1;
            layoutInfo.getPreferred().setHeight(Math.round(h + layoutInfo.getDecorating().getHeight()));
          }
        },

        /**
         * @inheritDoc
         */
        measureDecoration: function() {
          var footerElement = this._widget.hasFooter() ? this._widget.getColumnsFooter() : null;
          var scrollAreaElementWidth = this._widget.getScrollableArea().offsetWidth;
          if (this._widget.hasLeftFrozenColumns()) {
            scrollAreaElementWidth += this._widget.getLeftScrollableArea().offsetWidth;
          }
          if (this._widget.hasRightFrozenColumns()) {
            scrollAreaElementWidth += this._widget.getRightScrollableArea().offsetWidth;
          }

          // computation of decorationHeight and decorationWidth are not the same because of g_measuring css rules in TableWidget.scss
          var decorateHeight = this._widget.getElement().offsetHeight + (!!
            footerElement ?
            footerElement.offsetHeight : 0);
          var decorateWidth = this._widget.getElement().offsetWidth - scrollAreaElementWidth;

          this._getLayoutInfo().setDecorating(decorateWidth + window.scrollBarSize, decorateHeight + window.scrollBarSize);
        }
      };
    });
  });
