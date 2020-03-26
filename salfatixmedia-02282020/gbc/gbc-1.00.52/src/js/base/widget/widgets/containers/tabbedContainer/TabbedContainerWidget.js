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

modulum('TabbedContainerWidget', ['FolderWidget', 'WidgetFactory'],
  function(context, cls) {

    /**
     * Tabbed container widget.
     * @class TabbedContainerWidget
     * @memberOf classes
     * @extends classes.FolderWidget
     */
    cls.TabbedContainerWidget = context.oo.Class(cls.FolderWidget, function($super) {
      return /** @lends classes.TabbedContainerWidget.prototype */ {
        __name: "TabbedContainerWidget",
        __templateName: "FolderWidget",

        /**
         * @inheritDoc
         */
        destroy: function() {
          this.destroyChildren();
          $super.destroy.call(this);
        },

        /**
         * @inheritDoc
         */
        _initLayout: function() {
          this.setTabPosition("top");
          this._layoutInformation = new cls.LayoutInformation(this);
          this._layoutEngine = new cls.NoLayoutEngine(this);
        },

        /**
         * @inheritDoc
         */
        _onTitleClick: function(page) {
          this.setCurrentPage(page);
        }
      };
    });
    cls.WidgetFactory.registerBuilder('TabbedContainer', cls.TabbedContainerWidget);
  });
