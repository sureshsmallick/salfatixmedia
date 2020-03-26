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
  const path = require("path"),
    fs = require("fs"),
    fse = require("fs-extra");
  require("./pathes")(grunt);

  grunt.registerTask("__touch-default", "create dist/_default if not exist", function() {
    let _defaultPath = path.join(grunt.__pwd, "dist/_default");
    try {
      fs.accessSync(_defaultPath, fs.R_OK);
    } catch (e) {
      fse.mkdirsSync(path.dirname(_defaultPath));
      fs.writeFileSync(_defaultPath, "web", "utf8");
    }
  });

  grunt.config.merge({
    __clean: {
      localdist: [grunt.__gbc.pathes.distWeb]
    }
  });
  grunt.loadNpmTasks("grunt-contrib-clean");
  grunt.renameTask("clean", "__clean");

  require("./web/libraries")(grunt);
  require("./web/templates")(grunt);
  require("./web/locales")(grunt);
  require("./web/compilejs")(grunt);
  require("./web/injection")(grunt);
  require("./web/resources")(grunt);
  require("./web/themes/themes")(grunt);
  require("./web/html")(grunt);

  var dependencies = [
    "__clean:localdist", "__touch-default",
    "__libraries", "__templates", "__locales", "__compilejs",
    "__resources", "__themes", "__html", "__injection"
  ];
  if (grunt.option("create-zip")) {
    try {
      require("../internal/preArchive")(grunt);
      dependencies.push("__preArchive");
    } catch (e) {}
    require("./makeGz")(grunt);
    require("./zipArchive")(grunt);
    dependencies.push("__makeGz", "__archive");
  }
  grunt.registerTask("__compile", dependencies);
};
