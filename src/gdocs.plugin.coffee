# Export
module.exports = (BasePlugin) ->
	# Define
	class gDocsPlugin extends BasePlugin
		# Name
		name: 'gdocs'

		# Config
		config:
			collectionName: 'gDocs'
			relativePath: 'gDocs'
			postUrl: '/newGoogleDoc'
			extension: '.html'
			blockHtml: """
				<section class="gDocs-section">

					<div class="gDoc-new">
						<h2>New Page</h2>
						<script type="text/javascript" src="tinymce/jscripts/tiny_mce/tiny_mce.js"></script>

						<script type="text/javascript">
						tinyMCE.init({
						                theme : "advanced",
								        mode : "textareas",
								        plugins : "fullpage",
								        theme_advanced_buttons3_add : "fullpage"
						});
						</script>
						<form action="/newGoogleDoc" method="POST">
							<input type="hidden" name="for" value="<%= @document.id %>" />
							<input type="text" placeholder="Title" name="title" /> <br/>
							<select name="cat">
							  <option value="TT">Tubular Tuesdays</option>
							  <option value="BB">Bitchin’ Blogs</option>
							  <option value="DA">Dear Abby</option>
							</select> <br />
              				<textarea name="content" cols="50" rows="15">This is some content that will be editable with TinyMCE.</textarea>
							<input type="submit" class="btn" value="Publish" />
						</form>
					</div>

				</section>
				""".replace(/^\s+|\n\s*|\s+$/g,'')

		# Extend Template Data
		# Add our form to our template data
		extendTemplateData: ({templateData}) ->
			# Prepare
			{docpad,config} = @

			# getCommentsBlock
			templateData.getGoogleDocsBlock = ->
				@referencesOthers()
				return config.blockHtml

			# getComments
			templateData.getGoogleDocs = ->
				return docpad.getCollection(config.collectionName).findAll(for:@document.id)

			# Chain
			@


		# Extend Collections
		# Create our live collection for our comments
		extendCollections: ->
			# Prepare
			{docpad,config} = @
			database = docpad.getDatabase()

			# Create the collection
			gDocs = database.findAllLive({relativePath: $startsWith: config.relativePath},[date:-1])

			# Set the collection
			docpad.setCollection(config.collectionName, gDocs)

			# Chain
			@


		# Server Extend
		# Add our handling for posting the comment
		serverExtend: (opts) ->
			# Prepare
			{server} = opts
			{docpad,config} = @
			database = docpad.getDatabase()

			# Publish Handing
			server.post config.postUrl, (req,res,next) ->
				# Prepare
				upload_file = (req, res) ->
				  req.setBodyEncoding "binary"
				  stream = new multipart.Stream(req)
				  stream.addListener "part", (part) ->
				    part.addListener "body", (chunk) ->
				      progress = (stream.bytesReceived / stream.bytesTotal * 100).toFixed(2)
				      mb = (stream.bytesTotal / 1024 / 1024).toFixed(1)
				      sys.print "Uploading " + mb + "mb (" + progress + "%)\r"
				  # chunk could be appended to a file if the uploaded file needs to be saved
				  stream.addListener "complete", ->
				    res.sendHeader 200,
				      "Content-Type": "text/plain"

				    res.sendBody "Thanks for playing!"
				    res.finish()
				    sys.puts "\n=> Done"

				date = new Date()
				dateTime = date.getTime()
				dateString = date.toString()
				cat = req.body.cat
				docTitle = req.body.title or "#{dateString}"
				filename = "#{docTitle}#{config.extension}"
				fileRelativePath = "#{config.relativePath}/#{cat}/#{filename}"
				fileFullPath = docpad.config.documentsPaths[0]+"/#{fileRelativePath}"

				# Extract Url
				gDocUri = req.body.gDocUrl or ''
				docFor = req.body.for or ''

#-----------------------Sam's Slight Alterations 
				gCons = (gdoc_contents, snip, img) ->
					console.log "gCons" + gdoc_contents
					# gDoc data
					gDocData = """
					---
					title: "#{docTitle}"
					url: "#{gDocUri}"
					layout: "default"
					date: "#{date.toISOString()}"
					snip: "#{snip}"
					imgsrc: "#{img}"
					---
					#{gdoc_contents}
					"""

					# Package attributes
					attributes =
						data: gDocData
						date: date
						filename: filename
						relativePath: fileRelativePath
						fullPath: fileFullPath

					# Create document from attributes
					gDoc = docpad.ensureDocument(attributes)

					# Load the document
					docpad.loadDocument gDoc, (err) ->
						# Check
						return next(err)  if err

						# Add to the database
						database.add(gDoc)

						# Listen for regeneration
						docpad.once 'generateAfter', (err) ->
							# Check
							return next(err)  if err

							# Update browser
							res.redirect('back')

						# Write source which will trigger the regeneration
						gDoc.writeSource (err) ->
							# Check
							return next(err)  if err
 #------------------------------------------------- Sam !

				###
				Module dependencies.
				###
				cheerio = require("cheerio")
				request = require("request")				
				
				#Tell the request that we want to fetch Published Google Doc, send the results to a callback function
				request
				  uri: gDocUri
				, (err, response, body) ->
				#  self = this
				#  self.items = new Array() #I feel like I want to save my results in an array
				    
					  #Just a basic error check
					  console.log err
					    
					  #Use jQuery just as in any regular HTML page 
					    
					  $ = cheerio.load(body)
					  $body = $(body)
					 # $contents = $("#contents")
					  $snip = $("#contents p").first().text().substring(0,30)
					  $img = $("#contents img").first().attr("src")
					  console.log($img)
					  console.log "request" + $body
					  gCons($body, $snip, $img)

			# Done
			@
