/// FOURJS_START_COPYRIGHT(D,2018)
/// Property of Four Js*
/// (c) Copyright Four Js 2018, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

modulum('ChromeBarItemLayoutEngine', ['LayoutEngineBase'],
  function(context, cls) {
    /** Use empty layout definition to enable measure mechanism
     * @class ChromeBarItemLayoutEngine
     * @memberOf classes
     * @extends classes.LayoutEngineBase
     */
    cls.ChromeBarItemLayoutEngine = context.oo.Class(cls.LayoutEngineBase, function($super) {
      return /** @lends classes.ChromeBarItemLayoutEngine.prototype */ {
        __name: "ChromeBarItemLayoutEngine",

      };
    });
  });
