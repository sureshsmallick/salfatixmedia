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

modulum('StyleListNode', ['NodeBase', 'NodeFactory'],
  function(context, cls) {
    /**
     * @class StyleListNode
     * @memberOf classes
     * @extends classes.NodeBase
     */
    cls.StyleListNode = context.oo.Class(cls.NodeBase, function($super) {
      return /** @lends classes.StyleListNode.prototype */ {
        constructor: function(parent, tag, id, attributes, app) {
          $super.constructor.call(this, parent, tag, id, attributes, app);
          this.getApplication().styleListsChanged = true;
        },

        destroy: function() {
          this.getApplication().styleListsChanged = true;
          $super.destroy.call(this);
        },

        populateMatchingStyles: function(matchingAttributesByPseudoSelectors, node) {
          var children = this.getRawChildren();
          for (var i = 0; i < children.length; i++) {
            var styleNode = children[i];
            styleNode.populateMatchingStyles(matchingAttributesByPseudoSelectors, node);
          }
        }
      };
    });
    cls.NodeFactory.register("StyleList", cls.StyleListNode);
  });
