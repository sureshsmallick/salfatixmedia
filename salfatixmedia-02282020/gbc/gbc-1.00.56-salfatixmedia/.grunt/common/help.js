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
  grunt.registerTask("help", "show available commands", function() {
    console.log("#########################");
    console.log("# Available grunt tasks #");
    console.log("#########################");
    console.log("");
    console.log("grunt [default] [--customization=NONE] [--compile-mode=dev|cdev|prod] [--build-dist=<build-dist>] [--create-zip]");
    console.log("    compiles the default GBC without customization in 'dist/web' or 'dist/<build-dist>' if defined");
    console.log("    if --compile-mode is defined, compiles in specified mode (dev:every file is provided separately, " +
      "cdev[default]:files are packed, prod:files are packed and minified)");
    console.log("    if --create-zip is defined, creates a runtime zip in archive/");
    console.log("");
    console.log("grunt --customization=<customizationId> [--compile-mode=dev|cdev|prod] [--build-dist=<build-dist>] [--create-zip]");
    console.log("    compiles GBC with the given customization in 'dist/<customizationId>' or 'dist/<build-dist>' if defined");
    console.log("    if --compile-mode is defined, compiles in specified mode (dev:every file is provided separately, " +
      "cdev[default]:files are packed, prod:files are packed and minified)");
    console.log("    if --create-zip is defined, creates a runtime zip in archive/");
    console.log("");
    console.log("grunt --customization=ALL [--compile-mode=dev|cdev|prod] [--create-zip]");
    console.log("    compiles GBC without customization in 'dist/web' and every customization in 'customization/' folder");
    console.log("    if --compile-mode is defined, compiles in specified mode (dev:every file is provided separately, " +
      "cdev[default]:files are packed, prod:files are packed and minified)");
    console.log("    if --create-zip is defined, creates a runtime zip in archive/ for each customization");
    console.log("");
    console.log("grunt doc");
    console.log("    opens the technical documentation locally");
    console.log("");
    console.log("grunt clean");
    console.log("    erases the .cache/, dist/, archive/ folders");
    console.log("");
    console.log("grunt cleanall");
    console.log("    erases the .cache/, dist/, archive/, node_modules/ folders");
    console.log("");
    console.log("grunt dev [--customization=<customizationId>]");
    console.log("    compiles GBC (possibly with given customization) and live watches for source changes");
    console.log("");
    console.log("grunt help");
    console.log("    displays this present help");
    console.log("");

  });
};
