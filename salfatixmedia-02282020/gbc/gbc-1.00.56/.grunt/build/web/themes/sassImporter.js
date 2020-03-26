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
  const fs = require("fs"),
    path = require("path"),
    ThemeVariablesCompiler = require("./ThemeVariablesCompiler");

  class SassImporter {
    constructor(themesPathes) {
      this._themesPathes = themesPathes;
      this._aliasPathes = {};
    }

    _jsonToScss(data) {
      return data && typeof data === 'object' && new ThemeVariablesCompiler(data).scssRender() || "";
    }
    _empty(fn) {
      fn({
        contents: ""
      });
    }
    _file(fn, url) {
      fn({
        file: url
      });
    }

    _tryReadJSON(filepath) {
      try {
        return grunt.file.readJSON(filepath);
      } catch (e) {
        return {};
      }
    }

    _readJsonVars(done) {
      const ThemeProducer = require(path.join(grunt.__pwd, "src/theme/lib/ThemeProducer"));
      let producer = new ThemeProducer(path.join(grunt.__pwd, "src/theme/definitions/main-definition.json")),
        filePath = path.join(grunt.__pwd, "src/theme/theme.scss.json"),
        files = [this._tryReadJSON(filePath)];
      producer.prepare();
      producer.analyze(filePath, files[0], grunt);
      if (grunt.__gbc.config.customization) {
        filePath = path.join(grunt.__gbc.pathes.customizationPath, "theme.scss.json");
        let contents = this._tryReadJSON(filePath);
        producer.analyze(filePath, contents, grunt);
        files.push(contents);
      }
      if (this._themesPathes) {
        files.push(...this._themesPathes.map(p => {
          filePath = path.join(p, "theme.scss.json");
          let contents = this._tryReadJSON(filePath);
          producer.analyze(filePath, contents, grunt);
          return contents;
        }));
      }
      producer.setOverrides(...files);
      done({
        contents: this._jsonToScss(producer.produce())
      });
    }

    importer(url, file, done) {
      let result = null,
        localUrl = url;
      if (/__CUSTOMIZATION_SCSS_VARIABLES__/.test(localUrl)) {
        this._aliasPathes.__CUSTOMIZATION_SCSS_VARIABLES__ = path.dirname(file);
        let contents = [...this._themesPathes.map(p => path.relative(path.dirname(file), path.join(p, "/sass/themeVariables")))];
        if (grunt.__gbc.config.customization) {
          contents.unshift(path.relative(path.dirname(file), path.join(grunt.__gbc.pathes.customizationPath, "/sass/customVariables")));
        }
        contents = contents.map(p => `@import "${p.replace(/\\/g, "/")}";`).join("\n");
        result = done({
          contents: contents
        });
      } else if (/__CUSTOMIZATION_ENTRY_POINT__/.test(localUrl)) {
        this._aliasPathes.__CUSTOMIZATION_ENTRY_POINT__ = path.dirname(file);
        let contents = [...this._themesPathes.map(p => path.relative(path.dirname(file), path.join(p, "/sass/theme")))];
        if (grunt.__gbc.config.customization) {
          contents.unshift(path.relative(path.dirname(file), path.join(grunt.__gbc.pathes.customizationPath, "/sass/customization")));
        }
        contents = contents.map(p => `@import "${p.replace(/\\/g, "/")}";`).join("\n");
        result = done({
          contents: contents
        });
      } else if (/__VARIABLES__/.test(localUrl)) {
        this._aliasPathes.__VARIABLES__ = path.dirname(file);
        result = this._readJsonVars(done);
      } else {
        if (!/\.scss$/.test(path.basename(localUrl))) {
          localUrl = localUrl + ".scss";
        }
        let fullPath = path.resolve(this._aliasPathes[file] || path.dirname(file), localUrl);
        try {
          fs.accessSync(fullPath, fs.R_OK);
          result = this._file(done, fullPath);
        } catch (e) {
          try {
            fs.accessSync(path.resolve(path.dirname(fullPath), '_' + path.basename(fullPath)), fs.R_OK);
            result = this._file(done, path.resolve(path.dirname(fullPath), '_' + path.basename(fullPath)));
          } catch (e2) {
            result = this._empty(done);
          }
        }
      }
      return result;
    }
  }

  return SassImporter;
};
