var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

module.exports = function(BasePlugin) {
  var gdocsPlugin;
  return gdocsPlugin = (function(_super) {

    __extends(gdocsPlugin, _super);

    function gdocsPlugin() {
      return gdocsPlugin.__super__.constructor.apply(this, arguments);
    }

    gdocsPlugin.prototype.name = 'gdocs';

    gdocsPlugin.prototype.config = {
      collectionName: 'gDocs',
      relativePath: 'gDocs',
      postUrl: '/newGoogleDoc',
      extension: '.html',
      blockHtml: "<section class=\"gDocs-section\">\n\n	<div class=\"gDoc-new\">\n		<h2>New Page</h2>\n\n		<form action=\"/newGoogleDoc\" method=\"POST\">\n			<input type=\"hidden\" name=\"for\" value=\"<%= @document.id %>\" />\n			<input type=\"text\" placeholder=\"Title\" name=\"title\" /> <br/>\n			<input type=\"url\" placeholder=\"Google Doc URL\" name=\"gDocUrl\" /> <br/>\n			<input type=\"submit\" class=\"btn\" value=\"Publish\" />\n		</form>\n	</div>\n\n</section>".replace(/^\s+|\n\s*|\s+$/g, '')
    };

    gdocsPlugin.prototype.extendTemplateData = function(_arg) {
      var config, docpad, templateData;
      templateData = _arg.templateData;
      docpad = this.docpad, config = this.config;
      templateData.getGoogleDocsBlock = function() {
        this.referencesOthers();
        return config.blockHtml;
      };
      templateData.getGoogleDocs = function() {
        return docpad.getCollection(config.collectionName).findAll({
          "for": this.document.id
        });
      };
      return this;
    };

    gdocsPlugin.prototype.extendCollections = function() {
      var config, database, docpad, gDocs;
      docpad = this.docpad, config = this.config;
      database = docpad.getDatabase();
      gDocs = database.findAllLive({
        relativePath: {
          $startsWith: config.relativePath
        }
      }, [
        {
          date: -1
        }
      ]);
      docpad.setCollection(config.collectionName, gDocs);
      return this;
    };

    gdocsPlugin.prototype.serverExtend = function(opts) {
      var config, database, docpad, server;
      server = opts.server;
      docpad = this.docpad, config = this.config;
      database = docpad.getDatabase();
      server.post(config.postUrl, function(req, res, next) {
        var $contents, attributes, cheerio, date, dateString, dateTime, docFor, docTitle, fileFullPath, fileRelativePath, filename, gDoc, gDocData, gDocUri, request;
        date = new Date();
        dateTime = date.getTime();
        dateString = date.toString();
        docTitle = req.body.title || ("" + dateString);
        filename = "" + docTitle + config.extension;
        fileRelativePath = "" + config.relativePath + "/" + filename;
        fileFullPath = docpad.config.documentsPaths[0] + ("/" + fileRelativePath);
        gDocUri = req.body.gDocUrl || '';
        docFor = req.body["for"] || '';
        /*
        				Module dependencies.
        */


//-----------------------Sams Slight Alterations
function bleh(gdoc_contents){

          gDocData = "---\ntitle: \"" + docTitle + "\"\nurl: \"" + gDocUri + "\"\nlayout: \"default\"\ndate: \"" + (date.toISOString()) + "\"\n---\n" + gdoc_contents;
        attributes = {
          data: gDocData,
          date: date,
          filename: filename,
          relativePath: fileRelativePath,
          fullPath: fileFullPath
        };
        gDoc = docpad.ensureDocument(attributes);
        return docpad.loadDocument(gDoc, function(err) {
          if (err) {
            return next(err);
          }
          database.add(gDoc);
          docpad.once('generateAfter', function(err) {
            if (err) {
              return next(err);
            }
            return res.redirect('back');
          });
          return gDoc.writeSource(function(err) {
            if (err) {
              return next(err);
            }
          });
        });

}



//-------------------------------------------------


        cheerio = require("cheerio");
        request = require("request");
        console.log("Mumbo Jumbo");

        request({
          uri: gDocUri
        }, function(err, response, body) {
          console.log(err);
          if (err && response.statusCode !== 200) {
            console.log("Request error.");
          }
          
          var $ = cheerio.load(body);
          $contents = $("#contents");
          console.log($contents);
          bleh($contents);
        });
      });
      return this;
    };

    return gdocsPlugin;

  })(BasePlugin);
};
