/// FOURJS_START_COPYRIGHT(D,2015)
/// Property of Four Js*
/// (c) Copyright Four Js 2015, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

'use strict';

modulum('HLineWidget', ['ColoredWidgetBase', 'WidgetFactory'],
  function(context, cls) {

    /**
     * HLine widget.
     * @class HLineWidget
     * @memberOf classes
     * @extends classes.ColoredWidgetBase
     */
    cls.HLineWidget = context.oo.Class(cls.ColoredWidgetBase, function($super) {
      return /** @lends classes.HLineWidget.prototype */ {
        __name: 'HLineWidget',

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          this._layoutInformation = new cls.LayoutInformation(this);
          this._layoutEngine = new cls.LeafLayoutEngine(this);
        }
      };
    });
    cls.WidgetFactory.registerBuilder('HLine', cls.HLineWidget);
  });
