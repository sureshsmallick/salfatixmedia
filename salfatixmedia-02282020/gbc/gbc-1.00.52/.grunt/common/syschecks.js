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
  // Project configuration.
  grunt.config.merge({
    "node_version": {
      options: {
        alwaysInstall: false,
        errorLevel: 'fatal',
        globals: [],
        maxBuffer: 200 * 1024,
        nvm: false,
        override: ''
      }
    }
  });

  grunt.loadNpmTasks('grunt-node-version');

  grunt.task.run(["node_version"]);
};
