/// FOURJS_START_COPYRIGHT(D,2016)
/// Property of Four Js*
/// (c) Copyright Four Js 2016, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
/// 
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

module.exports = function(grunt) {
  grunt.config.merge({
    connect: {
      doc: {
        options: {
          base: "doc",
          useAvailablePort: true,
          keepalive: true,
          open: true
        }
      }
    }
  });
  grunt.loadNpmTasks("grunt-contrib-connect");

  grunt.registerTask("doc", "Open technical docs in a local server.", ["connect:doc"]);

};
