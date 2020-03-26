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

modulum('NoControllerNode', ['NodeBase', 'NodeFactory'],
  function(context, cls) {
    /**
     * @class NoControllerNode
     * @memberOf classes
     * @extends classes.NodeBase
     */
    cls.NoControllerNode = context.oo.Class(cls.NodeBase, function() {
      return /** @lends classes.NoControllerNode.prototype */ {};
    });
    cls.NodeFactory.register("ActionDefaultList", cls.NoControllerNode);
    cls.NodeFactory.register("StyleAttribute", cls.NoControllerNode);
    cls.NodeFactory.register("ImageFonts", cls.NoControllerNode);
    cls.NodeFactory.register("DialogInfo", cls.NoControllerNode);
  });
