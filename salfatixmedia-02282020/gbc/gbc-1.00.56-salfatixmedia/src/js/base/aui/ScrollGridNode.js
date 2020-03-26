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

modulum('ScrollGridNode', ['StandardNode', 'NodeFactory'],
  function(context, cls) {
    /**
     * @class ScrollGridNode
     * @memberOf classes
     * @extends classes.StandardNode
     */
    cls.ScrollGridNode = context.oo.Class(cls.StandardNode, function($super) {
      return /** @lends classes.ScrollGridNode.prototype */ {
        /**
         * @inheritDoc
         */
        autoCreateChildrenControllers: function() {
          // Stretchable and Paged ScrollGrids have their custom
          // line controllers in StretchableScrollGridPageSizeVMBehavior
          return this.attribute("wantFixedPageSize") !== 0;
        }
      };
    });
    cls.NodeFactory.register("ScrollGrid", cls.ScrollGridNode);
  });
