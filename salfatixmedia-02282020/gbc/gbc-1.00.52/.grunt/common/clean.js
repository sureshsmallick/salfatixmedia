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

module.exports = function(grunt) {
  grunt.config.merge({
    __clean: {
      default: ["dist", ".cache", "archive"],
      dependencies: ["node_modules", /*for older*/ "bower_components"]
    }
  });
  grunt.loadNpmTasks("grunt-contrib-clean");
  grunt.renameTask("clean", "__clean");
  grunt.registerTask("clean", ["__clean:default"]);
  grunt.registerTask("cleanall", ["clean", "__clean:dependencies"]);
};
