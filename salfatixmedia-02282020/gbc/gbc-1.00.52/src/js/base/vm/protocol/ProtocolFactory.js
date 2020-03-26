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

modulum('ProtocolFactory', ['ApplicationServiceFactory'],

  function(context, cls) {
    cls.ApplicationServiceFactory.register("NoProtocolInterface", cls.NoInterface);
    cls.ApplicationServiceFactory.register("UAProtocolInterface", cls.UAInterface);
    cls.ApplicationServiceFactory.register("DirectProtocolInterface", cls.DirectInterface);
  });
