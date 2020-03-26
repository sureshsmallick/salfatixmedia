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

modulum('PropertyArrayNode', ['StandardNode', 'NodeFactory'],
  function(context, cls) {
    /**
     * @class PropertyArrayNode
     * @memberOf classes
     * @extends classes.StandardNode
     */
    cls.PropertyArrayNode = context.oo.Class(cls.StandardNode, function($super) {
      return /** @lends classes.PropertyArrayNode.prototype */ {
        constructor: function(parent, tag, id, attributes, app) {
          this._canEmitNodeMutation = true;
          $super.constructor.call(this, parent, tag, id, attributes, app);
        }
      };
    });
    cls.NodeFactory.register("PropertyArray", cls.PropertyArrayNode);
  });
