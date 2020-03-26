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
  var local = require("./common/init")(grunt);
  require("./common/syschecks")(grunt);
  if (local.taskmatch(/^clean\w*$/)) {
    require("./common/clean")(grunt);
  } else if (local.taskmatch(/^buildnumber$/)) {
    require("./common/buildinfo")(grunt);
  } else if (local.taskmatch(/^doc?$/)) {
    require("./doc/jsdoc")(grunt);
  } else if (local.taskmatch(/^dev$/) || local.taskmatch(/^watch:\w*$/)) {
    require("./build/watch")(grunt);
  } else if (local.taskmatch(/^help$/)) {
    require("./common/help")(grunt);
  } else if (local.taskmatch(/^(compile\w*)|(default)$/) || local.taskmatch()) {
    require("./common/buildinfo")(grunt);
    if (grunt.__gbc.configFile.compile.customization === "ALL") {
      require("./build/buildall")(grunt);
      grunt.registerTask("default", "Compile GBC.", ["__compileall"]);
    } else {
      require("./build/build")(grunt);
      grunt.registerTask("default", "Compile GBC.", ["__compile"]);
    }
  } else {
    grunt.registerTask("default", "Compile GBC.", []);
  }
};
