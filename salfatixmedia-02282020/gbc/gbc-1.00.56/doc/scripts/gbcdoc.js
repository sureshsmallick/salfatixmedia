/// FOURJS_START_COPYRIGHT(D,2017)
/// Property of Four Js*
/// (c) Copyright Four Js 2017, 2019. All Rights Reserved.
/// * Trademark of Four Js Development Tools Europe Ltd
///   in the United States and elsewhere
///
/// This file can be modified by licensees according to the
/// product manual.
/// FOURJS_END_COPYRIGHT

"use strict";

(
  /**
   *
   * @param {Window} window
   */
  function (window) {

    var store = {
      getCompact: function () {
        return window.localStorage.getItem("compact") === "true";
      },
      setCompact: function (compact) {
        window.localStorage.setItem("compact", compact);
      },
      isExpanded: function (name) {
        return window.localStorage.getItem("expand_" + name) === "true";
      },
      setExpanded: function (name, expanded) {
        window.localStorage.setItem("expand_" + name, expanded);
      }
    };

    var gbcdoc = {
      updateCompact: function () {
        window.document.body.classList[store.getCompact() ? "add" : "remove"]("compact-view");
        window.document.body.classList[store.getCompact() ? "remove" : "add"]("expand-view");
      },
      setCompact: function (compact) {
        store.setCompact(compact);
        gbcdoc.updateCompact();
      },
      toggleCompact: function () {
        gbcdoc.setCompact(!store.getCompact());
      }
    };
    window.gbcdoc = gbcdoc;
    var currentHash = null;

    var ensureHashVisible = function(hash) {
      var element = window.document.body.querySelector(hash), item = element;
      while (item){
        if (item.classList.contains("panel-collapsed")){
          item.classList.remove("panel-collapsed");
        }
        item = item.parentElement;
      }
      if(element){
        element.scrollIntoView();
      }
    };

    var checkHash = function() {
      if (window.location.hash && window.location.hash !== currentHash){
        ensureHashVisible(window.location.hash);
        currentHash = window.location.hash;
      }
    };
    window.onpopstate = function() {
      checkHash();
    };
    gbcdoc.updateCompact();
    checkHash();
  })(window);